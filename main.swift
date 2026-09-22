import Cocoa
import SwiftUI
import ServiceManagement

func writePrivateData(_ data:Data,to url:URL) throws {
    try data.write(to:url,options:.atomic)
    try FileManager.default.setAttributes([.posixPermissions:0o600],ofItemAtPath:url.path)
}

struct AppUsage: Codable { var name: String; var seconds: Double = 0 }
struct Day: Codable {
    var keys = 0
    var left = 0
    var right = 0
    var other = 0
    var awake: Double = 0
    var active: Double = 0
    var apps: [String: AppUsage] = [:]
    var deviceKeys: [String: [String: Int]]? = nil
}
func dayKey(_ date: Date = Date()) -> String {
    let f = DateFormatter(); f.locale=Locale(identifier:"en_US_POSIX"); f.calendar=Calendar(identifier:.gregorian); f.dateFormat = "yyyy-MM-dd"; return f.string(from: date)
}
func duration(_ seconds: Double) -> String {
    let n = Int(seconds); return L("\(n / 3600) 小时 \(n % 3600 / 60) 分 \(n % 60) 秒", "\(n / 3600)h \(n % 3600 / 60)m \(n % 60)s")
}
final class Tracker: ObservableObject {
    @Published var days: [String: Day] = [:]
    @Published var paused = UserDefaults.standard.bool(forKey: "paused")
    @Published var inputOK = false
    @Published var error: LocalizedMessage = ""
    @Published var login = SMAppService.mainApp.status == .enabled
    let folder = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/KeyTrace")
    var file: URL { folder.appendingPathComponent("statistics.json") }
    @Published var keyboards: [String: KeyboardProfile] = [:]
    @Published var exporting = false
    @Published var exportStatus: LocalizedMessage = ""
    @Published var lastVideoURL: URL?
    @Published var earliestEvent: Date?
    @Published var latestEvent: Date?
    @Published var boundsLoading = true
    @Published var recordedEventCount = 0
    @Published var exportProgress = 0.0
    @Published var recordingSince: Date = {
        let saved=UserDefaults.standard.double(forKey:"eventRecordingSince")
        if saved>0 {return Date(timeIntervalSince1970:saved)}
        let now=Date();UserDefaults.standard.set(now.timeIntervalSince1970,forKey:"eventRecordingSince");return now
    }()
    lazy var eventStore = EventStore(folder: folder.appendingPathComponent("Events"))
    var recordedHeld: Set<String> = []
    var recentHID: [String:[Double]] = [:]
    var recentFallback: [String:[Double]] = [:]
    var fallbackKeyOwners: [String:String] = [:]
    var inputEpoch = 0
    var videoTask: Process?
    var videoCache: URL?
    var videoProgressTimer: Timer?
    var exportCancelled = false
    var keyboardMonitor = KeyboardMonitor()
    var lastKeyboardID: String?
    var lastInput = Date.distantPast
    var tap: CFMachPort?
    var source: CFRunLoopSource?
    var timer: Timer?
    var last = Date()
    var sleeping = false
    var locked = false
    var ticks = 0
    var previousApp: NSRunningApplication?
    var observers: [NSObjectProtocol] = []
    init() {
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes:[.posixPermissions:0o700])
            try FileManager.default.setAttributes([.posixPermissions:0o700],ofItemAtPath:folder.path)
            for name in ["statistics.json","keyboards.json"] {
                let path=folder.appendingPathComponent(name).path
                if FileManager.default.fileExists(atPath:path) {try FileManager.default.setAttributes([.posixPermissions:0o600],ofItemAtPath:path)}
            }
            if FileManager.default.fileExists(atPath: file.path) {
                do { days = try JSONDecoder().decode([String: Day].self, from: Data(contentsOf: file)) }
                catch {
                    let backup = folder.appendingPathComponent("statistics-unreadable-\(Int(Date().timeIntervalSince1970)).json")
                    try FileManager.default.copyItem(at: file, to: backup)
                    self.error = M("旧数据无法读取，已备份：\(backup.lastPathComponent)", "Could not read old data. Backup: \(backup.lastPathComponent)")
                }
            }
        } catch { self.error = M("数据目录错误：\(error.localizedDescription)", "Data folder error: \(error.localizedDescription)") }
        previousApp = NSWorkspace.shared.frontmostApplication
        let center = NSWorkspace.shared.notificationCenter
        observers.append(center.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in self?.tick(); self?.inputEpoch += 1; self?.resetInput(); self?.sleeping = true; self?.save() })
        observers.append(center.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in self?.sleeping = false; self?.last = Date() })
        observers.append(center.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) { [weak self] _ in self?.tick(); self?.previousApp = NSWorkspace.shared.frontmostApplication })
        for (name, value) in [("com.apple.screenIsLocked", true), ("com.apple.screenIsUnlocked", false)] {
            observers.append(DistributedNotificationCenter.default().addObserver(forName: Notification.Name(name), object: nil, queue: .main) { [weak self] _ in self?.tick(); self?.inputEpoch += 1; self?.resetInput(); self?.locked = value; self?.last = Date(); self?.save() })
        }
        eventStore.onError = { [weak self] message in DispatchQueue.main.async { self?.error=message } }
        resetInput()
        let store=eventStore
        DispatchQueue.global(qos:.utility).async { [weak self] in
            do {
                let bounds=try store.availableRange()
                DispatchQueue.main.async {
                    guard let self else {return}
                    if let first=bounds.0 {self.earliestEvent=min(first,self.earliestEvent ?? first)}
                    if let last=bounds.1 {self.latestEvent=max(last,self.latestEvent ?? last)}
                    self.boundsLoading=false
                }
            } catch {DispatchQueue.main.async {self?.boundsLoading=false;self?.error=M("无法读取记录时间：\(error.localizedDescription)", "Could not read recording dates: \(error.localizedDescription)")}}
        }
        setupKeyboards()
        connectInput()
        timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(timer!, forMode: .common)
    }
    func tick() {
        let now = Date(); let start = last; let elapsed = now.timeIntervalSince(start); last = now
        if !paused && !sleeping && !locked && elapsed > 0 && elapsed < 5 {
            let systemIdle = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: CGEventType(rawValue: UInt32.max)!)
            let idle = min(systemIdle, now.timeIntervalSince(lastInput))
            var cursor = start
            while cursor < now {
                let boundary = Calendar.current.startOfDay(for: cursor).addingTimeInterval(1)
                let next = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: boundary))!
                let end = min(next, now); let seconds = end.timeIntervalSince(cursor)
                let key = dayKey(cursor); var d = days[key] ?? Day(); d.awake += seconds
                if idle < 60 {
                    d.active += seconds
                    if let app = previousApp {
                        let id = app.bundleIdentifier ?? app.localizedName ?? "unknown"
                        var usage = d.apps[id] ?? AppUsage(name: app.localizedName ?? id)
                        usage.seconds += seconds; d.apps[id] = usage
                    }
                }
                days[key] = d; cursor = end
            }
        }
        ticks += 1
        if ticks % 10 == 0 { save(); connectInput(); login = SMAppService.mainApp.status == .enabled }
    }
    func disconnectEventTap() {
        if let source {CFRunLoopRemoveSource(CFRunLoopGetMain(),source,.commonModes)}
        if let tap {CGEvent.tapEnable(tap:tap,enable:false);CFMachPortInvalidate(tap)}
        source=nil;tap=nil;inputOK=false
    }
    func connectInput() {
        guard CGPreflightListenEventAccess() else {
            if inputOK {inputEpoch+=1;resetInput()}
            disconnectEventTap();keyboardMonitor.stop();return
        }
        if !keyboardMonitor.opened {keyboardMonitor.stop();keyboardMonitor.start()}
        if let tap, CFMachPortIsValid(tap) {
            CGEvent.tapEnable(tap:tap,enable:true)
            if CGEvent.tapIsEnabled(tap:tap) {inputOK=true;return}
        }
        // A disabled or invalid port must be recreated, not retried forever.
        disconnectEventTap()
        let mask = [CGEventType.keyDown, .keyUp, .flagsChanged, .leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp, .otherMouseDown, .otherMouseUp].reduce(CGEventMask(0)) { $0 | (CGEventMask(1) << $1.rawValue) }
        tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .listenOnly, eventsOfInterest: mask, callback: { _, type, event, context in
            guard let context else { return Unmanaged.passUnretained(event) }
            let tracker = Unmanaged<Tracker>.fromOpaque(context).takeUnretainedValue()
            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                if let tap = tracker.tap { CGEvent.tapEnable(tap: tap, enable: true) }
            } else { tracker.handleInput(type, event) }
            return Unmanaged.passUnretained(event)
        }, userInfo: Unmanaged.passUnretained(self).toOpaque())
        if let tap {
            source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true); inputOK = CGEvent.tapIsEnabled(tap:tap)
        } else { inputOK = false }
    }
    func requestInput() {
        _ = CGRequestListenEventAccess()
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!)
        connectInput()
    }
    func togglePause() { tick(); inputEpoch+=1; resetInput(); paused.toggle(); UserDefaults.standard.set(paused, forKey: "paused"); save() }
    func toggleLogin() {
        do {
            if SMAppService.mainApp.status == .enabled { try SMAppService.mainApp.unregister() }
            else { try SMAppService.mainApp.register() }
            login = SMAppService.mainApp.status == .enabled
            if SMAppService.mainApp.status == .requiresApproval { SMAppService.openSystemSettingsLoginItems() }
        } catch { self.error = M("登录启动设置失败：\(error.localizedDescription)", "Could not change launch at login: \(error.localizedDescription)") }
    }
    func save() {
        eventStore.flush()
        do { let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]; try writePrivateData(encoder.encode(days),to:file); try writePrivateData(encoder.encode(keyboards),to:folder.appendingPathComponent("keyboards.json")) }
        catch { self.error = M("保存失败：\(error.localizedDescription)", "Save failed: \(error.localizedDescription)") }
    }

}
struct Dashboard: View {
    @ObservedObject private var language = AppLanguage.shared
    @ObservedObject var tracker: Tracker
    @State private var details=false
    @State private var selected=dayKey()
    var body: some View {
        VStack(spacing:0) {
            HStack {
                Text("KeyTrace").font(.title3.weight(.semibold))
                Spacer()
                Circle().fill(tracker.paused ? Color.orange : (tracker.inputOK ? .green : .orange)).frame(width:6,height:6)
                Text(tracker.paused ? L("已暂停", "Paused") : (tracker.inputOK ? L("正在记录", "Recording") : L("等待权限", "Permission needed"))).font(.callout).foregroundStyle(.secondary)
                Button(tracker.paused ? L("继续", "Resume") : L("暂停", "Pause")) {tracker.togglePause()}.controlSize(.small)
            }.padding(.horizontal,22).padding(.vertical,16)
            Divider()
            ScrollView {
                VStack(alignment:.leading,spacing:18) {
                    if !tracker.inputOK {
                        HStack(alignment:.center) {
                            VStack(alignment:.leading,spacing:3) {
                                Text(L("开启输入监控后才能记录", "Enable Input Monitoring to record")).font(.callout.weight(.medium))
                                Text(L("允许 KeyTrace 记录键鼠按动。", "Allow KeyTrace to record key presses and mouse clicks.")).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button(L("打开设置", "Open Settings")) {tracker.requestInput()}
                        }.padding(12).background(Color.orange.opacity(0.08),in:RoundedRectangle(cornerRadius:8))
                    }
                    VideoExportPanel(tracker:tracker)
                    Divider()
                    DisclosureGroup(L("统计与键盘热力图", "Statistics & keyboard heatmap"),isExpanded:$details) {
                        VStack(alignment:.leading,spacing:12) {
                            Picker(L("日期", "Date"),selection:$selected) {ForEach(Array(Set(tracker.days.keys).union([dayKey()])).sorted().reversed(),id:\.self) {Text(localizedDay($0)).tag($0)}}.frame(width:220)
                            let d=tracker.days[selected] ?? Day()
                            HStack {Text(L("键盘 \(d.keys)", "Keys \(d.keys)"));Text(L("鼠标 \(d.left+d.right+d.other)", "Clicks \(d.left+d.right+d.other)"));Spacer();Text(L("活跃 \(duration(d.active))", "Active \(duration(d.active))")).foregroundStyle(.secondary)}.font(.callout)
                            KeyboardPanel(tracker:tracker,day:selected)
                            ForEach(d.apps.keys.sorted {(d.apps[$0]?.seconds ?? 0)>(d.apps[$1]?.seconds ?? 0)},id:\.self) {key in
                                if let usage=d.apps[key] {HStack {Text(usage.name);Spacer();Text(duration(usage.seconds)).foregroundStyle(.secondary)}.font(.caption)}
                            }
                        }.padding(.top,12)
                    }.font(.callout)
                    if !tracker.error.isEmpty {Text(tracker.error.text).font(.caption).foregroundStyle(.red).textSelection(.enabled)}
                }.padding(22)
            }
            Divider()
            HStack {
                Toggle(L("登录时启动", "Launch at login"),isOn:Binding(get:{tracker.login},set:{_ in tracker.toggleLogin()})).toggleStyle(.checkbox)
                Spacer()
                Picker(L("语言", "Language"), selection: $language.selection) {
                    Text(L("跟随系统", "Follow system")).tag("system")
                    ForEach(AppLanguage.supported,id: \.self) {code in Text(AppLanguage.names[code] ?? code).tag(code)}
                }.labelsHidden().frame(width:140).disabled(tracker.exporting)
                Button(L("数据文件夹", "Data folder")) {tracker.save();NSWorkspace.shared.open(tracker.folder)}.buttonStyle(.link)
            }.font(.caption).padding(.horizontal,22).padding(.vertical,12)
        }.frame(minWidth:600,minHeight:560)
        .environment(\.locale, AppLanguage.locale)
    }
}
final class Delegate: NSObject, NSApplicationDelegate {
    var tracker: Tracker!
    var status: NSStatusItem!
    var window: NSWindow!
    func applicationDidFinishLaunching(_ notification: Notification) {
        tracker = Tracker()
        status = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        status.button?.image = NSImage(systemSymbolName: "chart.bar.xaxis", accessibilityDescription: L("KeyTrace 活动统计", "KeyTrace activity statistics"))
        rebuildMenu()
        NotificationCenter.default.addObserver(self, selector: #selector(rebuildMenu), name: .appLanguageChanged, object: nil)
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 620, height: 560), styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        window.title = "KeyTrace"; window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: Dashboard(tracker: tracker)); window.center()
        if !UserDefaults.standard.bool(forKey: "hasLaunched") { show(); UserDefaults.standard.set(true, forKey: "hasLaunched") }
    }
    @objc func rebuildMenu() {
        status.button?.setAccessibilityLabel(L("KeyTrace 活动统计", "KeyTrace activity statistics"))
        let menu = NSMenu()
        for (title, action) in [(L("查看统计", "Show dashboard"), #selector(show)), (L("暂停 / 继续记录", "Pause / resume recording"), #selector(pause)), (L("输入监控权限…", "Input Monitoring…"), #selector(permission)), (L("退出 KeyTrace", "Quit KeyTrace"), #selector(quit))] { let item = NSMenuItem(title: title, action: action, keyEquivalent: ""); item.target = self; menu.addItem(item) }
        status.menu = menu
    }
    @objc func show() { window.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true) }
    @objc func pause() { tracker.togglePause(); status.button?.image = NSImage(systemSymbolName: tracker.paused ? "pause.circle" : "chart.bar.xaxis", accessibilityDescription: "KeyTrace") }
    @objc func permission() { tracker.requestInput() }
    @objc func quit() { tracker.tick(); tracker.resetInput(); tracker.save(); NSApp.terminate(nil) }
    func applicationWillTerminate(_ notification: Notification) {
        tracker?.save()
        if let task=tracker?.videoTask,task.isRunning {task.terminate();task.waitUntilExit()}
        if let cache=tracker?.videoCache {try? FileManager.default.removeItem(at:cache)}
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool { show(); return true }
}
if let index=CommandLine.arguments.firstIndex(of:"--render-video"), CommandLine.arguments.count>index+1 {
    do {
        let job=try JSONDecoder().decode(VideoJob.self,from:Data(contentsOf:URL(fileURLWithPath:CommandLine.arguments[index+1])))
        try KeyboardMovie.render(job)
    } catch { fputs("VIDEO_ERROR: \(error.localizedDescription)\n",stderr);exit(1) }
} else {
    let app = NSApplication.shared
    let delegate = Delegate(); app.delegate = delegate; app.setActivationPolicy(.accessory); app.run()
}
