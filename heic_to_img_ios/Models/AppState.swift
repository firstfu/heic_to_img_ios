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
    
    // MARK: - 選擇模式狀態
    /// 是否處於選擇模式
    @Published var isSelectionMode: Bool = false
    /// 已選擇的結果項目 ID 集合
    @Published var selectedResultIds: Set<UUID> = []
    
    // MARK: - 錯誤處理
    /// 當前發生的錯誤
    @Published var currentError: AppError?
    /// 是否顯示錯誤警告對話框
    @Published var showErrorAlert: Bool = false
    
    // MARK: - Pro 版本狀態
    /// 是否已購買 Pro 版本（從 StoreManager 取得）
    var isPro: Bool {
        StoreManager.shared.isPro
    }
    /// 是否顯示 Pro 版本升級畫面
    @Published var showProUpgrade: Bool = false
    /// 免費版本剩餘的轉換次數（從 DailyUsageTracker 取得）
    var remainingFreeConversions: Int {
        DailyUsageTracker.shared.remainingConversions
    }

    /// Combine 訂閱存儲
    private var cancellables = Set<AnyCancellable>()

    /// 初始化方法，載入用戶偏好設定並訂閱 StoreManager 狀態變化
    init() {
        loadUserPreferences()

        // 訂閱 StoreManager 的狀態變化，轉發給 AppState 的觀察者
        StoreManager.shared.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        // 訂閱 DailyUsageTracker 的狀態變化
        DailyUsageTracker.shared.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    /// 從 UserDefaults 載入用戶偏好設定
    private func loadUserPreferences() {
        isFirstLaunch = !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")

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
        // 免費版限制檢查
        if !isPro {
            // 檢查批次限制（免費版僅支援單檔案）
            if selectedFiles.count > FreeTierLimits.maxBatchFiles {
                showProUpgrade = true
                return
            }
            // 檢查每日轉換次數限制
            if !DailyUsageTracker.shared.canConvert {
                showProUpgrade = true
                return
            }
            // 免費版強制設定
            settings.outputFormat = .jpeg
            settings.jpegQuality = FreeTierLimits.fixedQuality
            settings.preserveMetadata = FreeTierLimits.preserveMetadata
            settings.shouldResize = false
        }

        isConverting = true
        conversionJobs = selectedFiles.map { ConversionJob(fileItem: $0, settings: settings) }
        overallProgress = 0.0
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

    /// 執行購買專業版流程
    func upgradeToPro() {
        Task { @MainActor in
            let success = await StoreManager.shared.purchase()
            if success {
                showProUpgrade = false
            }
        }
    }

    /// 恢復之前的購買紀錄
    func restorePurchases() {
        Task { @MainActor in
            await StoreManager.shared.restorePurchases()
            if isPro {
                showProUpgrade = false
            }
        }
    }

    /// 免費版轉換完成後記錄使用次數
    /// - Parameter count: 完成的轉換數量
    func recordFreeConversion(count: Int) {
        if !isPro {
            DailyUsageTracker.shared.recordConversion(count: count)
        }
    }
    
    // MARK: - 選擇模式管理
    /// 開始選擇模式
    func startSelectionMode() {
        isSelectionMode = true
        selectedResultIds.removeAll()
    }
    
    /// 結束選擇模式
    func endSelectionMode() {
        isSelectionMode = false
        selectedResultIds.removeAll()
    }
    
    /// 切換選擇模式
    func toggleSelectionMode() {
        if isSelectionMode {
            endSelectionMode()
        } else {
            startSelectionMode()
        }
    }
    
    /// 切換項目的選擇狀態
    /// - Parameter resultId: 結果項目的 ID
    func toggleSelection(for resultId: UUID) {
        if selectedResultIds.contains(resultId) {
            selectedResultIds.remove(resultId)
        } else {
            selectedResultIds.insert(resultId)
        }
    }
    
    /// 選擇全部項目
    func selectAllResults() {
        selectedResultIds = Set(conversionResults.map { $0.id })
    }
    
    /// 取消選擇全部項目
    func deselectAllResults() {
        selectedResultIds.removeAll()
    }
    
    /// 獲取已選擇的結果項目
    var selectedResults: [ConversionResult] {
        return conversionResults.filter { selectedResultIds.contains($0.id) }
    }
    
    /// 是否有選擇的項目
    var hasSelectedResults: Bool {
        return !selectedResultIds.isEmpty
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