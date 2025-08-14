# HeicMaster - HEIC 圖片轉換器

一個功能完整的 iOS 應用程式，專門用於將 HEIC 格式的照片轉換為其他常見格式（PNG、JPEG）。

## 功能特色

- ✅ **批次轉換**: 支援一次選取多張 HEIC 照片進行轉換
- ✅ **多種格式**: 輸出 PNG、JPEG 格式
- ✅ **品質控制**: 可調整輸出品質設定
- ✅ **尺寸調整**: 支援自訂輸出尺寸
- ✅ **拖放支援**: 直覺的檔案拖放操作
- ✅ **進度追蹤**: 即時顯示轉換進度
- ✅ **相簿整合**: 直接存取相簿中的 HEIC 照片

## 系統需求

- iOS 18.0 或以上版本
- Xcode 16.4 或以上版本
- Swift 5.0

## 專案架構

```
heic_to_img_ios/
├── heic_to_img_iosApp.swift    # 應用程式入口點
├── Views/                      # SwiftUI 視圖層
│   ├── MainTabView.swift       # 主要 Tab 導航
│   ├── ConversionView.swift    # 轉換介面
│   ├── ResultsView.swift       # 結果顯示
│   ├── SettingsView.swift      # 設定頁面
│   ├── LaunchScreenView.swift  # 啟動畫面
│   └── HEICPhotoPicker.swift   # 照片選擇器
├── Services/                   # 業務邏輯層
│   ├── ImageConverter.swift    # 圖片轉換服務
│   ├── FileManagerService.swift # 檔案管理
│   └── FilePickerService.swift # 檔案選擇
├── Models/                     # 資料模型
│   ├── ConversionModels.swift  # 轉換相關模型
│   └── AppState.swift          # 應用狀態管理
├── Components/                 # UI 元件
│   ├── UIComponents.swift      # 通用 UI 元件
│   ├── AnimatedComponents.swift # 動畫元件
│   └── DropZoneView.swift      # 拖放區域
└── Utilities/                  # 工具類
    └── DesignSystem.swift      # 設計系統
```

## 建置與執行

### 必要權限

確保在 `Info.plist` 中包含以下權限：

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>需要存取照片庫以讀取 HEIC 照片</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>需要存取照片庫以儲存轉換後的照片</string>
```

### Xcode 建置

```bash
# 清理專案
xcodebuild -project heic_to_img_ios.xcodeproj clean

# 建置專案
xcodebuild -project heic_to_img_ios.xcodeproj -scheme heic_to_img_ios -configuration Debug build

# 在模擬器上建置並執行
xcodebuild -project heic_to_img_ios.xcodeproj -scheme heic_to_img_ios -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```

### 模擬器操作

```bash
# 列出可用模擬器
xcrun simctl list devices

# 啟動模擬器
xcrun simctl boot "iPhone 16 Pro"

# 安裝應用程式
xcodebuild -project heic_to_img_ios.xcodeproj -scheme heic_to_img_ios -destination 'platform=iOS Simulator,name=iPhone 16 Pro' install
```

### 程式碼風格檢查

```bash
# 執行 SwiftLint 檢查
swiftlint

# 自動修正問題
swiftlint --fix
```

## 技術棧

- **框架**: SwiftUI、UIKit、PhotosUI
- **圖像處理**: CoreImage、ImageIO
- **併發處理**: Combine、async/await
- **狀態管理**: @Observable 協議

## 相關專案

此專案搭配 FastAPI 後端服務使用：
- **API 專案位置**: `/Users/firstfu/Desktop/heic_to_img_workspace/heic_to_img_api`
- **執行指令**: `uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload`

## 開發注意事項

- 所有使用者介面文字使用繁體中文
- 使用 iOS 最新版本的 API 和最佳實踐
- 圖片轉換使用 GPU 加速優化
- 支援批次處理和併發操作
- 遵循 Apple Human Interface Guidelines

## 版本歷史

- v2.0: 新增啟動畫面，優化使用者體驗
- v1.0: 基礎 HEIC 轉換功能

## 授權

此專案僅供學習和開發用途。