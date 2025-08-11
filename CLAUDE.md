# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 專案概覽
這是一個 iOS 應用程式專案，用於將 HEIC 格式的圖片轉換為其他格式（PNG、JPEG）。應用程式使用 SwiftUI 框架開發，支援 iOS 18.0 以上版本。

## 建置與執行指令

### Xcode 專案操作
```bash
# 建置專案
xcodebuild -project heic_to_img_ios.xcodeproj -scheme heic_to_img_ios -configuration Debug build

# 清理建置
xcodebuild -project heic_to_img_ios.xcodeproj clean

# 建置並執行在模擬器
xcodebuild -project heic_to_img_ios.xcodeproj -scheme heic_to_img_ios -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build

# 列出可用的模擬器
xcrun simctl list devices

# 啟動模擬器並安裝應用
xcrun simctl boot "iPhone 16 Pro"
xcodebuild -project heic_to_img_ios.xcodeproj -scheme heic_to_img_ios -destination 'platform=iOS Simulator,name=iPhone 16 Pro' install

# 執行測試（如有）
xcodebuild test -project heic_to_img_ios.xcodeproj -scheme heic_to_img_ios -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

### SwiftLint（如需要）
```bash
# 執行程式碼風格檢查
swiftlint

# 自動修正可修正的問題
swiftlint --fix
```

## 專案架構

### 應用程式流程
1. **MainTabView**: 應用程式主導航，包含三個 Tab（轉換、結果、設定）
2. **ConversionView**: 主要轉換介面，整合 HEICPhotoPicker 和 DropZoneView
3. **ImageConverter Service**: 處理實際的圖片格式轉換，支援批次處理
4. **AppState**: 使用 @Observable 管理全局狀態，追蹤轉換進度和結果

### 核心元件結構
- **heic_to_img_iosApp.swift**: 應用程式入口點，管理全局狀態（ConversionSettings、AppState）
- **Views/**: SwiftUI 視圖層
  - MainTabView: 主要的 Tab 導航結構
  - ConversionView: 圖片轉換的主介面，整合檔案選擇和拖放功能
  - ResultsView: 顯示轉換結果和批次操作
  - SettingsView: 應用設定介面（格式、品質、尺寸調整）
  - ProUpgradeView: 專業版升級介面
  - HEICPhotoPicker: 相簿選擇器元件
- **Services/**: 業務邏輯層
  - ImageConverter: 核心轉換服務，使用 CoreImage 和 ImageIO 框架進行圖片處理
  - FileManagerService: 檔案管理服務，處理檔案存取和儲存
  - FilePickerService: 檔案選擇服務，支援多選和格式過濾
- **Models/**: 資料模型
  - ConversionModels: 轉換相關的資料結構（ConversionFormat, ConversionSettings, FileItem）
  - AppState: 應用程式狀態管理，使用 @Observable 協議
- **Components/**: 可重用的 UI 元件
  - UIComponents: 通用 UI 元件（按鈕、卡片、進度指示器）
  - AnimatedComponents: 動畫元件（載入動畫、轉場效果）
  - DropZoneView: 拖放區域元件，支援多檔案拖放
- **Utilities/**: 工具類
  - DesignSystem: 設計系統定義（顏色、字型、間距）

### 技術棧與依賴
- **框架**: SwiftUI、UIKit（橋接）、PhotosUI
- **圖像處理**: CoreImage、ImageIO
- **併發處理**: Combine、DispatchQueue、async/await
- **最低支援版本**: iOS 18.0
- **Swift 版本**: 5.0
- **Xcode 版本**: 16.4+
- **專案格式**: Xcode 16.4 檔案系統同步群組（fileSystemSynchronizedGroups）

### 權限需求
應用程式需要以下權限（需在 Info.plist 中配置）：
- NSPhotoLibraryUsageDescription: 存取相簿讀取 HEIC 照片
- NSPhotoLibraryAddUsageDescription: 儲存轉換後的照片到相簿

### 開發注意事項
- 所有註解和使用者介面文字使用繁體中文
- 使用 iOS 最新版本的 API 和最佳實踐
- 圖片轉換使用 GPU 加速（通過 CIContext 配置）
- 併發操作使用專用的 DispatchQueue (com.heicmaster.conversion)
- 支援批次處理，使用 DispatchGroup 管理多個轉換任務
- DerivedData 已包含在專案中，包含編譯快取和模組快取

### 相關專案
- **API 專案路徑**: /Users/firstfu/Desktop/heic_to_img_workspace/heic_to_img_api
  - FastAPI 後端服務，提供 HEIC 轉換 REST API
  - 執行指令: `uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload`
  - 使用 pillow-heif 進行伺服器端圖片轉換
  - Python 3.11+ 環境，使用 uv 管理依賴