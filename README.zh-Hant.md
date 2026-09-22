# KeyTrace

[简体中文](README.md) | **繁體中文** | [English](README.en.md) | [日本語](README.ja.md) | [Español](README.es.md) | [Français](README.fr.md) | [Deutsch](README.de.md)

macOS 本地鍵鼠統計與 3D 熱力圖按動影片導出工具。

改編自 [xuhk/XAssistant](https://github.com/xuhk/XAssistant) 的功能與創意，使用 Swift 原生重新實現。這是非官方 macOS 版本，未複製上游 Windows 原始碼或素材，與原作者無隸屬關係。本項目採用 [MIT 許可證](LICENSE)。

## 功能

- 菜單欄後台記錄鍵鼠按動，查看每日統計與鍵盤熱力圖。
- 識別內置、外接鍵盤，提供 MacBook 與帶數字鍵區的 Mac 鍵盤佈局，並可手動選擇。
- 選擇開始、結束時間，支持“最開始”和“現在”快捷操作。
- 將鍵位按動動畫和累計熱力圖導出為 1080p、30 fps MP4，保存到“下載”資料夾；自動壓縮無操作間隔。
- 可選擇包含或不包含滑鼠，速度支持 0.5× 至 256×（含 128×）。
- 熱力圖上限可隨當前累計最高按動數動態變化，或固定為所選範圍內最終最高按動數。
- 片尾保留最終熱力圖 5 秒，攝像機緩慢旋轉。
- 每次按下都有同步敲擊聲，不同物理鍵位使用不同音色；支持鍵盤敲擊（默認）、機械鍵盤、柔和敲擊和靜音。

## 安裝

公開測試版 **v0.4.2-beta.1**；應用程式 **0.4.2，build 14**。需要 **Apple Silicon（arm64）、macOS 13+**，不支援 Intel。**臨時簽名，未經 Apple 公證；更新後可能需要重新授權。**

從 [公開測試版頁面](https://github.com/nope-gao/KeyTrace/releases/tag/v0.4.2-beta.1) 下載 [應用 ZIP](https://github.com/nope-gao/KeyTrace/releases/download/v0.4.2-beta.1/KeyTrace-arm64.zip) 與 [SHA256SUMS](https://github.com/nope-gao/KeyTrace/releases/download/v0.4.2-beta.1/SHA256SUMS)，使用下方命令校驗。GitHub 自動產生的 Source code ZIP 不是應用程式。解壓後將 **KeyTrace.app** 放入 `~/Applications` 再開啟。

```bash
# In the folder containing the downloaded ZIP and SHA256SUMS
awk '$2 == "KeyTrace-arm64.zip"' SHA256SUMS | shasum -a 256 -c -
```

終端安裝明確選擇此 Pre-release，不使用 `/latest`：

```bash
curl -fsSL https://raw.githubusercontent.com/nope-gao/KeyTrace/v0.4.2-beta.1/install.sh -o /tmp/keytrace-install.sh
bash /tmp/keytrace-install.sh --version v0.4.2-beta.1
```

安裝器檢查 SHA-256、版本與簽名，不需要 sudo。應用執行中會停止；相同套件不變更；不相容的簽名會在替換前被阻止。需要遷移時先退出並備份舊 app，再手動替換及重新授權；歷史資料保留。

首次開啟若被阻擋，確認來源後使用「系統設定 → 隱私權與安全性 → 強制打開」，僅批准此應用。不要停用 Gatekeeper、SIP 或整個系統的安全防護。若系統或組織政策不允許例外，請停止安裝。

到「隱私權與安全性 → 輸入監控」，加入實際安裝位置的 KeyTrace 並啟用，退出後重新開啟；若暫停，按「繼續」。實際按鍵、點擊滑鼠，確認最新記錄時間及計數增加。開關啟用不等於記錄成功。更新後若無效，退出並移除舊項目，再加入新版；必要時執行下方只針對此應用的重設命令，再手動授權。

```bash
tccutil reset ListenEvent app.keytrace.mac
```

KeyTrace 使用獨立的資料目錄，不會自動匯入其他應用程式的記錄。首次安裝需單獨開啟輸入監控。

## 界面語言

首次啓動默認“跟隨系統”，按 macOS 的首選語言列表選擇已支持的語言。支持 **簡體中文、繁體中文、English、日本語、Español、Français、Deutsch**；列表中沒有支持的語言時回退到英文。可在窗口底部手動選擇，或恢復“跟隨系統”，設置會保存。

界面、菜單、已有狀態提示、日期與數字格式、滑鼠標注、功能鍵名稱和影片字幕統一使用所選語言。字母鍵保留物理 ANSI 佈局。影片使用開始導出時的語言，避免中途切換造成混用；導出期間不能手動切換語言。macOS 自己的權限彈窗和底層錯誤詳情由系統控制語言。

## 影片聲音

“聲音”提供鍵盤敲擊、機械鍵盤、柔和敲擊、靜音四種選擇，默認鍵盤敲擊。每個物理鍵位有確定且不同的短促音色，僅在按下時觸發，並與首個顯示按下的動畫幀對齊。加速後的密集按動會疊加混音；選擇不包含滑鼠時也不會混入滑鼠點擊聲。片尾保留安靜的 5 秒展示。

聲音由程序合成，不使用麥克風，不採集真實鍵盤錄音，也不依賴外部音效素材。有聲導出使用 48 kHz AAC 音軌；靜音模式不生成音軌。

## 從原始碼構建

```bash
xcode-select --install
bash build.sh
```

本機構建使用臨時簽名，替換既有應用程式可能需要重新授權。

## 使用

導出時選擇時間範圍、速度、滑鼠選項及熱力圖模式，點擊“導出影片到下載”。沒有記錄的時間段無法補錄。

## 本地數據與隱私

數據保存在 `~/Library/Application Support/KeyTrace/`，不主動上傳，也不包含遙測。安裝腳本會連接 GitHub 下載版本。

為支持動畫回放，會保存按下/松開時間、物理鍵位、設備信息及事件順序；還會記錄應用名稱、Bundle ID 和使用時長統計。不讀取輸入法最終文字、窗口標題、網頁地址或滑鼠坐標。**鍵位及其順序仍可能推斷輸入內容，因此事件記錄屬於敏感數據；請勿公開上傳數據目錄。**

暫停停止新按動和使用時長統計，但保留歷史。資料為本機明文，不會自動到期刪除；退出後可將資料目錄、匯出快取及不需要的影片移到垃圾桶。

`~/Library/Application Support/KeyTrace/` · `~/Library/Caches/KeyTrace/VideoJobs/` · `~/Downloads/KeyTrace-*.mp4`

## 已知限制

- 主要支持 ANSI 鍵盤佈局，ISO/JIS 等佈局尚未完整適配；自動識別不保證覆蓋所有第三方設備。
- Fn、多媒體鍵及安全輸入場景可能無法完整記錄；Touch ID 不作為普通按鍵記錄。
- 多鍵盤同時使用時，設備歸屬可能存在限制；長按自動重復不作為多次獨立按動累計。
- 本項目使用 SceneKit、Metal 和 AVFoundation 直接渲染影片，不依賴 Blender。
