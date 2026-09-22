# KeyTrace

**简体中文** | [繁體中文](README.zh-Hant.md) | [English](README.en.md) | [日本語](README.ja.md) | [Español](README.es.md) | [Français](README.fr.md) | [Deutsch](README.de.md)

macOS 本地键鼠统计与 3D 热力图按动视频导出工具。

改编自 [xuhk/XAssistant](https://github.com/xuhk/XAssistant) 的功能与创意，使用 Swift 原生重新实现。这是非官方 macOS 版本，未复制上游 Windows 源码或素材，与原作者无隶属关系。本项目采用 [MIT 许可证](LICENSE)。

## 功能

- 菜单栏后台记录键鼠按动，查看每日统计与键盘热力图。
- 识别内置、外接键盘，提供 MacBook 与带数字区的 Mac 键盘布局，并可手动选择。
- 选择开始、结束时间，支持“最开始”和“现在”快捷操作。
- 将键位按动动画和累计热力图导出为 1080p、30 fps MP4，保存到“下载”文件夹；自动压缩无操作间隔。
- 可选择包含或不包含鼠标，速度支持 0.5× 至 1024×（含 128× / 256× / 512×）。
- 热力图上限可随当前累计最高按动数动态变化，或固定为所选范围内最终最高按动数。
- 片尾保留最终热力图 5 秒，摄像机缓慢旋转。
- 每次按下都有同步敲击声，不同物理键位使用不同音色；支持键盘敲击（默认）、机械键盘、柔和敲击和静音。

## 安装

公开测试版 **v0.4.3-beta.1**；应用版本 **0.4.3，build 15**。需要 **Apple Silicon（arm64）、macOS 13+**，不支持 Intel。**临时签名，未经过 Apple 公证；更新后可能需要重新授权。**

从 [公开测试版页面](https://github.com/nope-gao/KeyTrace/releases/tag/v0.4.3-beta.1) 下载 [应用 ZIP](https://github.com/nope-gao/KeyTrace/releases/download/v0.4.3-beta.1/KeyTrace-arm64.zip) 与 [SHA256SUMS](https://github.com/nope-gao/KeyTrace/releases/download/v0.4.3-beta.1/SHA256SUMS)，使用下方命令校验。GitHub 自动生成的 Source code ZIP 不是应用。解压后将 **KeyTrace.app** 放入 `~/Applications`，再打开。

```bash
# In the folder containing the downloaded ZIP and SHA256SUMS
awk '$2 == "KeyTrace-arm64.zip"' SHA256SUMS | shasum -a 256 -c -
```

终端安装（明确选择此 Pre-release，不使用 `/latest`）：

```bash
curl -fsSL https://raw.githubusercontent.com/nope-gao/KeyTrace/v0.4.3-beta.1/install.sh -o /tmp/keytrace-install.sh
bash /tmp/keytrace-install.sh --version v0.4.3-beta.1
```

安装器检查 SHA-256、应用版本和签名，不需要 sudo。应用运行中会停止；已是同一包则不改动；更新签名不兼容时会在替换前停止，不自动覆盖已授权应用。需要迁移时，先退出、备份旧 app，再手动替换并重新授权；历史数据保留。

首次打开若被 macOS 拦截，确认来源后使用「系统设置 → 隐私与安全性 → 仍要打开」，仅批准这个应用。不要关闭 Gatekeeper、SIP 或整个系统的安全保护。若系统/单位策略不允许例外，请停止安装。

然后进入「隐私与安全性 → 输入监控」，添加**实际安装位置**的 KeyTrace 并开启，退出后重新打开；若显示暂停，点「继续」。实际按键和点击鼠标，确认最新记录时间与计数增长。仅看到开关开启不算成功。更新后若开关开着却不记录：退出应用，移除旧条目，再添加新 app；必要时运行下方只针对本应用的重置命令，再手动授权。

```bash
tccutil reset ListenEvent app.keytrace.mac
```

KeyTrace 使用独立的数据目录，不自动导入其他应用的记录。首次安装需要单独开启输入监控。

## 固定时长

选择“固定时长”可指定视频总秒数，默认 **60 秒（1 分钟）**，包含最后 **5 秒旋转**。程序对去除空档后的按动自动加速或减速，适配指定时长；支持 6–86400 秒。

## 界面语言

首次启动默认“跟随系统”，按 macOS 的首选语言列表选择已支持的语言。支持 **简体中文、繁體中文、English、日本語、Español、Français、Deutsch**；列表中没有支持的语言时回退到英文。可在窗口底部手动选择，或恢复“跟随系统”，设置会保存。

界面、菜单、已有状态提示、日期与数字格式、鼠标标注、功能键名称和视频字幕统一使用所选语言。字母键保留物理 ANSI 布局。视频使用开始导出时的语言，避免中途切换造成混用；导出期间不能手动切换语言。macOS 自己的权限弹窗和底层错误详情由系统控制语言。

## 视频声音

“声音”提供键盘敲击、机械键盘、柔和敲击、静音四种选择，默认键盘敲击。每个物理键位有确定且不同的短促音色，仅在按下时触发，并与首个显示按下的动画帧对齐。加速后的密集按动会叠加混音；选择不包含鼠标时也不会混入鼠标点击声。片尾保留安静的 5 秒展示。

声音由程序合成，不使用麦克风，不采集真实键盘录音，也不依赖外部音效素材。有声导出使用 48 kHz AAC 音轨；静音模式不生成音轨。

## 从源码构建

```bash
xcode-select --install
bash build.sh
```

本地构建使用临时签名，替换已有应用可能需要重新授权。

## 使用

导出时选择时间范围、速度、鼠标选项及热力图模式，点击“导出视频到下载”。没有记录的时间段无法补录。

## 本地数据与隐私

数据保存在 `~/Library/Application Support/KeyTrace/`，不主动上传，也不包含遥测。安装脚本会连接 GitHub 下载版本。

为支持动画回放，会保存按下/松开时间、物理键位、设备信息及事件顺序；还会记录应用名称、Bundle ID 和使用时长统计。不读取输入法最终文字、窗口标题、网页地址或鼠标坐标。**键位及其顺序仍可能推断输入内容，因此事件记录属于敏感数据；请勿公开上传数据目录。**

暂停停止新按动和使用时长统计，但保留历史数据。数据为本地明文，没有自动到期删除；退出后可将数据目录、导出缓存及不需要的视频移到废纸篓。

`~/Library/Application Support/KeyTrace/` · `~/Library/Caches/KeyTrace/VideoJobs/` · `~/Downloads/KeyTrace-*.mp4`

## 已知限制

- 主要支持 ANSI 键盘布局，ISO/JIS 等布局尚未完整适配；自动识别不保证覆盖所有第三方设备。
- Fn、多媒体键及安全输入场景可能无法完整记录；Touch ID 不作为普通按键记录。
- 多键盘同时使用时，设备归属可能存在限制；长按自动重复不作为多次独立按动累计。
- 本项目使用 SceneKit、Metal 和 AVFoundation 直接渲染视频，不依赖 Blender。
