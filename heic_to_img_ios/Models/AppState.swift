/*
 * 功能：應用程式全局狀態管理
 * 
 * 描述：管理整個應用程式的狀態和資料流
 * - 管理 UI 狀態（主題、標籤頁、歡迎畫面等）
 * - 管理轉換流程（選擇的檔案、轉換作業、進度）
 * - 管理轉換結果和統計資料
 * - 處理錯誤狀態和用戶提示
 * - 管理 Pro 版本功能和限制
 * - 提供用戶設定的持久化存儲
 * 
 * 創建時間：2025/8/10
 * 作者：firstfu
 */

//
//  AppState.swift
//  heic_to_img_ios
//
//  Created by firstfu on 2025/8/10.
//

import SwiftUI
import Combine

// MARK: - 應用程式狀態管理
/// 主要的應用程式狀態類別，遵循 ObservableObject 協議
/// 使用 @Published 包裝器讓 UI 能夠響應狀態變化
class AppState: ObservableObject {
    // MARK: - UI 狀態
    /// 當前的顏色主題（淺色/深色/跟隨系統）
    @Published var colorScheme: ColorScheme?
    /// 目前選中的標籤頁
    @Published var currentTab: AppTab = .convert
    /// 是否為首次啟動應用程式
    @Published var isFirstLaunch: Bool = true
    /// 是否顯示歡迎畫面
    @Published var showWelcome: Bool = true
    
    // MARK: - 轉換相關狀態
    /// 用戶選擇的待轉換檔案清單
    @Published var selectedFiles: [FileItem] = []
    /// 當前的轉換作業清單
    @Published var conversionJobs: [ConversionJob] = []
    /// 是否正在進行轉換作業
    @Published var isConverting: Bool = false
    /// 整體轉換進度（0.0 - 1.0）
    @Published var overallProgress: Double = 0.0
    
    // MARK: - 網路狀態
    /// 是否正在上傳檔案
    @Published var isUploading: Bool = false
    /// 是否正在下載檔案
    @Published var isDownloading: Bool = false
    /// 網路錯誤訊息
    @Published var networkError: String?
    
    // MARK: - 結果狀態
    /// 轉換結果的清單
    @Published var conversionResults: [ConversionResult] = []
    /// 最近一次批次轉換的統計資料
    @Published var lastConversionStats: BatchConversionStats?
    
    // MARK: - 錯誤處理
    /// 當前發生的錯誤
    @Published var currentError: AppError?
    /// 是否顯示錯誤警告對話框
    @Published var showErrorAlert: Bool = false
    
    // MARK: - Pro 版本狀態
    /// 是否已購買 Pro 版本
    // MVP 版本：預設為 true，讓所有用戶都能使用完整功能
    @Published var isPro: Bool = true // false
    /// 是否顯示 Pro 版本升級畫面
    // MVP 版本：不顯示升級畫面
    @Published var showProUpgrade: Bool = false
    /// 免費版本剩餘的轉換次數
    // MVP 版本：無限制
    @Published var remainingFreeConversions: Int = 999999 // 3
    
    /// 初始化方法，載入用戶偏好設定
    init() {
        loadUserPreferences()
    }
    
    /// 從 UserDefaults 載入用戶偏好設定
    /// 包含首次啟動狀態、Pro 版本狀態和免費轉換次數
    private func loadUserPreferences() {
        // 從 UserDefaults 載入用戶設定
        isFirstLaunch = !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        // MVP 版本：預設為 Pro
        isPro = true // UserDefaults.standard.bool(forKey: "isPro")
        remainingFreeConversions = 999999 // UserDefaults.standard.object(forKey: "remainingFreeConversions") as? Int ?? 3
        
        if isFirstLaunch {
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        }
    }
    
    // MARK: - 檔案管理
    /// 新增檔案到選擇清單，只保留 HEIC 格式檔案
    /// - Parameter files: 要新增的檔案清單
    func addFiles(_ files: [FileItem]) {
        let heicFiles = files.filter { $0.isHEIC }
        selectedFiles.append(contentsOf: heicFiles)
    }
    
    /// 移除指定索引的檔案
    /// - Parameter index: 要移除的檔案索引
    func removeFile(at index: Int) {
        guard index < selectedFiles.count else { return }
        selectedFiles.remove(at: index)
    }
    
    /// 清空所有已選擇的檔案和轉換作業
    func clearFiles() {
        selectedFiles.removeAll()
        conversionJobs.removeAll()
    }
    
    // MARK: - 轉換管理
    /// 開始轉換作業，檢查 Pro 版本限制
    /// - Parameter settings: 轉換設定參數
    func startConversion(with settings: ConversionSettings) {
        // MVP 版本：註解掉 Pro 版本限制檢查
        // if !isPro && selectedFiles.count > 1 {
        //     showProUpgrade = true
        //     return
        // }
        // 
        // if !isPro && remainingFreeConversions <= 0 {
        //     showProUpgrade = true
        //     return
        // }
        
        isConverting = true
        conversionJobs = selectedFiles.map { ConversionJob(fileItem: $0, settings: settings) }
        overallProgress = 0.0
        
        // MVP 版本：註解掉免費轉換次數更新
        // if !isPro {
        //     remainingFreeConversions = max(0, remainingFreeConversions - selectedFiles.count)
        //     UserDefaults.standard.set(remainingFreeConversions, forKey: "remainingFreeConversions")
        // }
    }
    
    func updateJobProgress(_ jobId: UUID, progress: Double) {
        if let index = conversionJobs.firstIndex(where: { $0.id == jobId }) {
            conversionJobs[index].progress = progress
            updateOverallProgress()
        }
    }
    
    func completeJob(_ jobId: UUID, result: ConversionResult) {
        if let index = conversionJobs.firstIndex(where: { $0.id == jobId }) {
            conversionJobs[index].status = .completed
            conversionJobs[index].outputURL = result.outputURL
            conversionResults.append(result)
            updateOverallProgress()
        }
        
        checkConversionComplete()
    }
    
    func failJob(_ jobId: UUID, error: Error) {
        if let index = conversionJobs.firstIndex(where: { $0.id == jobId }) {
            conversionJobs[index].status = .failed(error)
            conversionJobs[index].error = error
        }
        
        checkConversionComplete()
    }
    
    private func updateOverallProgress() {
        let totalProgress = conversionJobs.reduce(0.0) { $0 + $1.progress }
        overallProgress = totalProgress / Double(conversionJobs.count)
    }
    
    private func checkConversionComplete() {
        let completedOrFailed = conversionJobs.filter { 
            switch $0.status {
            case .completed, .failed:
                return true
            default:
                return false
            }
        }
        
        if completedOrFailed.count == conversionJobs.count && conversionJobs.count > 0 {
            isConverting = false
            generateConversionStats()
            
            print("✅ 所有轉換任務完成，轉換結果數量: \(conversionResults.count)")
            
            // 不自動切換到結果頁面，讓用戶選擇何時查看
            // currentTab = .results
            
            // 延遲清空轉換任務和重置進度，讓 UI 有時間更新
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.conversionJobs.removeAll()
                self.overallProgress = 0.0
            }
        }
    }
    
    private func generateConversionStats() {
        let stats = BatchConversionStats()
        stats.totalFiles = conversionJobs.count
        stats.completedFiles = conversionResults.count
        stats.failedFiles = conversionJobs.count - conversionResults.count
        
        for result in conversionResults {
            stats.totalOriginalSize += result.originalSize
            stats.totalOutputSize += result.outputSize
            stats.totalProcessingTime += result.processingTime
        }
        
        lastConversionStats = stats
    }
    
    // MARK: - 錯誤處理
    func showError(_ error: AppError) {
        currentError = error
        showErrorAlert = true
    }
    
    func clearError() {
        currentError = nil
        showErrorAlert = false
    }
    
    // MARK: - Pro 版本管理
    func upgradeToPro() {
        // MVP 版本：已預設為 Pro
        isPro = true
        UserDefaults.standard.set(true, forKey: "isPro")
        showProUpgrade = false
    }
    
    func restorePurchases() {
        // TODO: 實作 In-App Purchase 恢復邏輯
    }
}

// MARK: - Tab 列舉
/// 應用程式主要標籤頁的列舉
/// 定義了三個主要功能頁面
enum AppTab: String, CaseIterable {
    case convert = "convert"
    case results = "results"
    case settings = "settings"
    
    /// 標籤頁顯示文字
    var title: String {
        switch self {
        case .convert: return "轉換"
        case .results: return "結果"
        case .settings: return "設定"
        }
    }
    
    /// 標籤頁對應的 SF Symbol 圖示名稱
    var icon: String {
        switch self {
        case .convert: return "arrow.triangle.2.circlepath"
        case .results: return "folder.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

// MARK: - 錯誤類型
/// 應用程式錯誤類型列舉
/// 定義了各種可能發生的錯誤情況和對應的描述
enum AppError: Error, LocalizedError {
    case fileNotFound
    case unsupportedFormat
    case conversionFailed(String)
    case fileTooLarge
    case insufficientStorage
    case networkError
    case permissionDenied
    
    /// 錯誤訊息的中文描述
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "找不到圖片檔案"
        case .unsupportedFormat:
            return "檔案格式不支援"
        case .conversionFailed(let reason):
            return "轉換失敗：\(reason)"
        case .fileTooLarge:
            return "圖片檔案太大"
        case .insufficientStorage:
            return "手機空間不足"
        case .networkError:
            return "網路連線問題"
        case .permissionDenied:
            return "需要存取權限"
        }
    }
    
    /// 錯誤的解決建議
    var recoverySuggestion: String? {
        switch self {
        case .fileNotFound:
            return "請重新選擇圖片"
        case .unsupportedFormat:
            return "目前只支援 HEIC 格式圖片"
        case .conversionFailed:
            return "請稍後再試，或聯繫客服"
        case .fileTooLarge:
            return "請選擇小於 100MB 的圖片"
        case .insufficientStorage:
            return "請清理手機存儲空間後重試"
        case .networkError:
            return "請檢查網路連接後重試"
        case .permissionDenied:
            return "請前往設定開啟存取權限"
        }
    }
}