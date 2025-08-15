//
//  ConversionView.swift
//  heic_to_img_ios
//
//  Created by firstfu on 2025/8/10.
//

import SwiftUI
import UniformTypeIdentifiers

struct ConversionView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var settings: ConversionSettings
    @StateObject private var fileManagerService = FileManagerService.shared
    @StateObject private var imageConverter = ImageConverter.shared
    
    @State private var showFileImporter = false
    @State private var showPhotoPicker = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showPhotoLibrary = false
    @State private var showFirstTimeHint = false
    @State private var showQualitySettings = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景層 - 放在最底層
                LinearGradient(
                    colors: [
                        Color.dynamic(
                            light: Color(red: 250/255, green: 250/255, blue: 255/255),
                            dark: Color(red: 15/255, green: 15/255, blue: 25/255)
                        ),
                        Color.dynamic(
                            light: Color(red: 240/255, green: 245/255, blue: 255/255),
                            dark: Color(red: 25/255, green: 25/255, blue: 45/255)
                        )
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // 內容層
                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        // 標題
                        headerView
                        
                        // 主要內容區域
                        VStack(spacing: AppSpacing.lg) {
                            // 檔案選擇或已選檔案
                            ZStack {
                                if appState.selectedFiles.isEmpty {
                                    dropZoneView
                                        .overlay(
                                            // 首次使用提示
                                            firstTimeHint,
                                            alignment: .topTrailing
                                        )
                                } else {
                                    selectedFilesView
                                }
                            }
                            
                            // 轉換進度
                            if appState.isConverting {
                                conversionProgressView
                            }
                            
                            // MVP 版本：註解掉免費版限制提示
                            // if !appState.isPro && !appState.isConverting {
                            //     proUpgradePrompt
                            // }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                    }
                    .padding(.bottom, 100) // 為底部標籤欄預留空間
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showQualitySettings = true
                    }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppColors.primaryBlue)
                    }
                }
            }
            .navigationBarHidden(false)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("")
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.heic, .heif],
                allowsMultipleSelection: true
            ) { files in
                handleSelectedFiles(files)
            }
            .sheet(isPresented: $showPhotoLibrary) {
                HEICPhotoPicker(onFilesSelected: { files in
                    handleSelectedFiles(files)
                })
            }
            .sheet(isPresented: $showQualitySettings) {
                QualitySettingsPopover()
                    .environmentObject(settings)
                    .environmentObject(appState)
            }
            .alert("錯誤", isPresented: $showError) {
                Button("確定") { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                // 檢查是否首次使用
                let hasShownHint = UserDefaults.standard.bool(forKey: "hasShownFirstTimeHint")
                if !hasShownHint && appState.selectedFiles.isEmpty {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showFirstTimeHint = true
                        }
                        
                        // 5秒後自動隱藏
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                showFirstTimeHint = false
                            }
                        }
                        
                        UserDefaults.standard.set(true, forKey: "hasShownFirstTimeHint")
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
    
    // MARK: - 視圖組件
    
    private var headerView: some View {
        VStack(spacing: AppSpacing.lg) {
            // 主標題帶動畫
            HStack(spacing: 12) {
                Image(systemName: "wand.and.rays")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(AppColors.primaryGradient)
                    .rotationEffect(.degrees(appState.isConverting ? 360 : 0))
                    .animation(
                        appState.isConverting ?
                        .linear(duration: 2).repeatForever(autoreverses: false) :
                        .default,
                        value: appState.isConverting
                    )
                
                Text("HEIC 轉檔專家")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 90/255, green: 120/255, blue: 255/255),
                                Color(red: 150/255, green: 60/255, blue: 255/255)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .padding(.top, AppSpacing.md)
            
            VStack(spacing: AppSpacing.md) {
                // 副標題
                Text(appState.isConverting ? 
                     "⚡ 正在極速轉換，請稍候..." : 
                     "簡單三步驟：選擇 → 轉換 → 完成")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color.dynamic(
                        light: AppColors.textSecondary,
                        dark: AppColors.darkTextSecondary
                    ))
                    .animation(AppAnimations.smooth, value: appState.isConverting)
                
                // 特色標籤
                HStack(spacing: AppSpacing.sm) {
                    FeatureTag(text: "極速轉換", icon: "bolt.fill", color: .orange)
                    FeatureTag(text: "無損品質", icon: "checkmark.shield.fill", color: .green)
                    FeatureTag(text: "簡單易用", icon: "hand.tap.fill", color: .blue)
                }
            }
        }
        .padding(.horizontal, AppSpacing.md)
    }
    
    private var dropZoneView: some View {
        DropZoneView(
            onFilePickerTap: {
                showFileImporter = true
            },
            onPhotoLibraryTap: {
                showPhotoLibrary = true
            }
        )
    }
    
    private var selectedFilesView: some View {
        SelectedFilesView(
            selectedFiles: $appState.selectedFiles,
            onRemoveFile: { index in
                appState.removeFile(at: index)
            },
            onStartConversion: {
                startConversion()
            }
        )
    }
    
    private var conversionProgressView: some View {
        VStack(spacing: AppSpacing.xl) {
            progressIndicatorSection
            progressDescriptionSection
            fileProgressList
            successAnimationSection
        }
        .padding(AppSpacing.lg)
        .background(progressViewBackground)
        .shadow(
            color: AppColors.primaryBlue.opacity(0.1),
            radius: 20,
            x: 0,
            y: 10
        )
    }
    
    private var progressIndicatorSection: some View {
        CircularProgressView(
            progress: appState.overallProgress,
            lineWidth: 15,
            size: 150
        )
        .padding(.top, AppSpacing.lg)
    }
    
    private var progressDescriptionSection: some View {
        VStack(spacing: AppSpacing.sm) {
            Text("正在極速轉換中...")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(progressGradient)
            
            Text("已完成 \(completedJobsCount) / \(totalJobsCount) 個檔案")
                .font(AppFonts.callout)
                .foregroundColor(Color.dynamic(
                    light: AppColors.textSecondary,
                    dark: AppColors.darkTextSecondary
                ))
        }
    }
    
    private var fileProgressList: some View {
        LazyVStack(spacing: AppSpacing.md) {
            ForEach(appState.conversionJobs) { job in
                AnimatedFileCard(
                    fileName: job.fileItem.name,
                    fileSize: formatFileSize(job.fileItem.size),
                    isProcessing: job.status == .processing
                )
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }
        }
        .padding(.horizontal, AppSpacing.sm)
    }
    
    @ViewBuilder
    private var successAnimationSection: some View {
        if appState.overallProgress >= 1.0 && !appState.isConverting {
            VStack(spacing: AppSpacing.md) {
                SuccessAnimationView(size: 80) {
                    // 動畫完成後的回調
                }
                
                // 成功提示和分享按鈕
                VStack(spacing: AppSpacing.sm) {
                    Text("轉換完成！🎉")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppColors.primaryGradient)
                    
                    Text("快來查看轉換結果吧")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.bottom, AppSpacing.sm)
                    
                    HStack(spacing: AppSpacing.sm) {
                        // 查看結果按鈕
                        Button("查看結果") {
                            appState.currentTab = .results
                        }
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(AppColors.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        
                        // 繼續轉換按鈕
                        Button("繼續轉換") {
                            // 重置狀態
                            withAnimation {
                                appState.conversionResults.removeAll()
                                appState.overallProgress = 0.0
                            }
                        }
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.brandBlue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(AppColors.brandBlue.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(AppColors.brandBlue.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
            }
            .padding(.top, AppSpacing.md)
        }
    }
    
    private var progressViewBackground: some View {
        RoundedRectangle(cornerRadius: AppRadius.xl)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.xl)
                    .stroke(progressBorderGradient, lineWidth: 1)
            )
    }
    
    private var progressGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                AppColors.primaryBlue,
                AppColors.primaryPurple
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private var progressBorderGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                AppColors.primaryBlue.opacity(0.3),
                AppColors.primaryPurple.opacity(0.3)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var completedJobsCount: Int {
        appState.conversionJobs.filter { $0.status == .completed }.count
    }
    
    private var totalJobsCount: Int {
        appState.conversionJobs.count
    }
    
    // 輔助函數：格式化檔案大小
    private func formatFileSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    private var firstTimeHint: some View {
        Group {
            if showFirstTimeHint {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.warningOrange)
                        
                        Text("小貼士")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(AppColors.warningOrange)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showFirstTimeHint = false
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppColors.textTertiary)
                        }
                    }
                    
                    Text("點擊下方按鈕選擇 HEIC 圖片開始轉換")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(AppSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .fill(
                            Color.dynamic(
                                light: AppColors.warningOrange.opacity(0.1),
                                dark: AppColors.warningOrange.opacity(0.15)
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.md)
                                .stroke(AppColors.warningOrange.opacity(0.3), lineWidth: 1)
                        )
                )
                .frame(maxWidth: 200)
                .offset(x: -20, y: 20)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                    removal: .scale(scale: 0.8).combined(with: .opacity)
                ))
            }
        }
    }
    
    private var proUpgradePrompt: some View {
        VStack(spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.md) {
                // 左側圖示和資訊
                HStack(spacing: AppSpacing.sm) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        AppColors.warningOrange.opacity(0.2),
                                        AppColors.warningOrange.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "gift.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppColors.warningOrange)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("免費版限制")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.dynamic(
                                light: AppColors.textPrimary,
                                dark: AppColors.darkTextPrimary
                            ))
                        
                        Text("剩餘 \(appState.remainingFreeConversions) 次轉換")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.warningOrange)
                    }
                }
                
                Spacer()
                
                // 升級按鈕
                Button("升級 Pro") {
                    appState.showProUpgrade = true
                }
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            AppColors.primaryBlue,
                            AppColors.primaryPurple
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(
                    Color.dynamic(
                        light: AppColors.warningOrange.opacity(0.05),
                        dark: AppColors.warningOrange.opacity(0.1)
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .stroke(
                            AppColors.warningOrange.opacity(0.2),
                            lineWidth: 1
                        )
                )
        )
    }
    
    // MARK: - 功能方法
    
    private func handleSelectedFiles(_ files: [FileItem]) {
        let validation = FilePickerService.shared.validateFiles(files)
        
        if !validation.invalid.isEmpty {
            errorMessage = validation.invalid.joined(separator: "\n")
            showError = true
        }
        
        if !validation.valid.isEmpty {
            // 檢查是否超過檔案數量限制
            let totalFiles = appState.selectedFiles.count + validation.valid.count
            if totalFiles > ProcessingLimits.maxBatchFiles {
                let availableSlots = ProcessingLimits.maxBatchFiles - appState.selectedFiles.count
                if availableSlots > 0 {
                    let limitedFiles = Array(validation.valid.prefix(availableSlots))
                    appState.addFiles(limitedFiles)
                    errorMessage = "單次最多只能轉換 \(ProcessingLimits.maxBatchFiles) 個檔案，已選取前 \(limitedFiles.count) 個檔案。\n\n如需轉換更多檔案，請分批處理。"
                } else {
                    errorMessage = "已達到單次轉換上限（\(ProcessingLimits.maxBatchFiles) 個檔案）。\n\n請先清空當前檔案或分批處理。"
                }
                showError = true
                return
            }
            
            // 檢查是否超過總檔案大小限制
            let potentialFiles = appState.selectedFiles + validation.valid
            if ProcessingLimits.exceedsSizeLimit(potentialFiles) {
                let currentSizeMB = ProcessingLimits.totalSizeInMB(appState.selectedFiles)
                let maxSizeMB = Double(ProcessingLimits.maxTotalSizeMB)
                let remainingSizeMB = maxSizeMB - currentSizeMB
                
                if remainingSizeMB > 0 {
                    // 嘗試添加部分檔案
                    var addedFiles: [FileItem] = []
                    var currentSize = currentSizeMB
                    
                    for file in validation.valid {
                        let fileSizeMB = Double(file.size) / (1024 * 1024)
                        if currentSize + fileSizeMB <= maxSizeMB {
                            addedFiles.append(file)
                            currentSize += fileSizeMB
                        }
                    }
                    
                    if !addedFiles.isEmpty {
                        appState.addFiles(addedFiles)
                        errorMessage = "總檔案大小超過 \(ProcessingLimits.maxTotalSizeMB)MB 限制，已選取部分檔案（\(addedFiles.count) 個）。\n\n剩餘檔案請分批處理。"
                    } else {
                        errorMessage = "檔案太大，已達到 \(ProcessingLimits.maxTotalSizeMB)MB 的大小限制。\n\n請先清空當前檔案或選擇較小的檔案。"
                    }
                } else {
                    errorMessage = "已達到 \(ProcessingLimits.maxTotalSizeMB)MB 的大小限制。\n\n請先清空當前檔案或分批處理。"
                }
                showError = true
                return
            }
            
            appState.addFiles(validation.valid)
        }
    }
    
    private func startConversion() {
        // MVP 版本：註解掉 Pro 版本限制檢查
        // if !appState.isPro && appState.selectedFiles.count > 1 {
        //     appState.showProUpgrade = true
        //     return
        // }
        // 
        // if !appState.isPro && appState.remainingFreeConversions <= 0 {
        //     appState.showProUpgrade = true
        //     return
        // }
        
        appState.startConversion(with: settings)
        
        // 開始批次轉換
        imageConverter.convertBatchFiles(
            appState.selectedFiles,
            settings: settings,
            progressHandler: { progress, completed, total in
                DispatchQueue.main.async {
                    appState.overallProgress = progress
                }
            }
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let results):
                    print("✅ 轉換成功，共 \(results.count) 個檔案")
                    
                    // 直接將轉換結果添加到狀態中
                    appState.conversionResults.append(contentsOf: results)
                    
                    // 將對應的任務標記為完成
                    for conversionResult in results {
                        if let jobIndex = appState.conversionJobs.firstIndex(where: { $0.fileItem.id == conversionResult.originalFile.id }) {
                            appState.conversionJobs[jobIndex].status = .completed
                            appState.conversionJobs[jobIndex].outputURL = conversionResult.outputURL
                            appState.conversionJobs[jobIndex].progress = 1.0
                        }
                    }
                    
                    // 更新整體進度
                    appState.overallProgress = 1.0
                    appState.isConverting = false
                    
                    // 生成統計資料
                    let stats = BatchConversionStats()
                    stats.totalFiles = results.count
                    stats.completedFiles = results.count
                    stats.failedFiles = 0
                    
                    for result in results {
                        stats.totalOriginalSize += result.originalSize
                        stats.totalOutputSize += result.outputSize
                        stats.totalProcessingTime += result.processingTime
                    }
                    
                    appState.lastConversionStats = stats
                    
                    // 延遲後清空檔案和任務，並切換到結果頁面
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        appState.selectedFiles.removeAll()
                        appState.conversionJobs.removeAll()
                        appState.currentTab = .results
                    }
                    
                case .failure(let error):
                    print("❌ 轉換失敗：\(error.localizedDescription)")
                    
                    // 顯示更詳細的錯誤訊息
                    let errorMessage: String
                    if let apiError = error as? APIError {
                        errorMessage = apiError.errorDescription ?? "API 錯誤"
                    } else if let conversionError = error as? ConversionError {
                        errorMessage = conversionError.errorDescription ?? "轉換錯誤"
                    } else {
                        errorMessage = error.localizedDescription
                    }
                    
                    self.errorMessage = errorMessage
                    self.showError = true
                    appState.isConverting = false
                }
            }
        }
    }
}

// MARK: - 任務進度行視圖
struct JobProgressRowView: View {
    @ObservedObject var job: ConversionJob
    
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            // 狀態圖標
            Image(systemName: statusIcon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(job.status.color)
                .frame(width: 20)
            
            // 檔案名稱
            Text(job.fileItem.name)
                .font(AppFonts.callout)
                .foregroundColor(Color.dynamic(
                    light: AppColors.textPrimary,
                    dark: AppColors.darkTextPrimary
                ))
                .lineLimit(1)
                .truncationMode(.middle)
            
            Spacer()
            
            // 狀態文字或進度
            if case .processing = job.status {
                HStack(spacing: AppSpacing.xs) {
                    ProgressView()
                        .scaleEffect(0.7)
                    
                    Text("\(Int(job.progress * 100))%")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .monospaced()
                }
            } else {
                Text(job.status.displayText)
                    .font(AppFonts.caption)
                    .foregroundColor(job.status.color)
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }
    
    private var statusIcon: String {
        switch job.status {
        case .pending:
            return "clock"
        case .processing:
            return "arrow.triangle.2.circlepath"
        case .completed:
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.circle.fill"
        }
    }
}

// MARK: - 特色標籤組件
struct FeatureTag: View {
    let text: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
            
            Text(text)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(color.opacity(0.3), lineWidth: 0.5)
        )
    }
}


// MARK: - 圖片品質設定彈窗
struct QualitySettingsPopover: View {
    @EnvironmentObject private var settings: ConversionSettings
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    private var qualityText: String {
        switch settings.jpegQuality {
        case 0.5:
            return "標準品質"
        case 0.75:
            return "高品質"
        case 1.0:
            return "最佳品質"
        default:
            return "高品質"
        }
    }
    
    private var qualityDescription: String {
        switch settings.jpegQuality {
        case 0.5:
            return "檔案較小，適合分享和儲存"
        case 0.75:
            return "平衡品質與檔案大小"
        case 1.0:
            return "最高品質，檔案較大"
        default:
            return "平衡品質與檔案大小"
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 標題欄
                HStack {
                    Text("轉換設定")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    AppColors.primaryBlue,
                                    AppColors.primaryPurple
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Spacer()
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(Color.secondary.opacity(0.6))
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)
                
                Divider()
                    .overlay(Color.secondary.opacity(0.1))
                
                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        // 輸出格式選擇
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Label("輸出格式", systemImage: "doc.badge.arrow.up")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(Color.dynamic(
                                    light: AppColors.textPrimary,
                                    dark: AppColors.darkTextPrimary
                                ))
                            
                            HStack(spacing: AppSpacing.sm) {
                                ForEach(ConversionFormat.allCases, id: \.self) { format in
                                    formatButton(format)
                                }
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        
                        // JPEG 品質設定（只在選擇 JPEG 時顯示）
                        if settings.outputFormat == .jpeg {
                            VStack(alignment: .leading, spacing: AppSpacing.md) {
                                HStack {
                                    Label("圖片品質", systemImage: "sparkles")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundColor(Color.dynamic(
                                            light: AppColors.textPrimary,
                                            dark: AppColors.darkTextPrimary
                                        ))
                                    
                                    Spacer()
                                    
                                    Text(qualityText)
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(AppColors.primaryBlue)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 4)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(AppColors.primaryBlue.opacity(0.1))
                                        )
                                }
                                
                                // 品質滑桿
                                VStack(spacing: AppSpacing.sm) {
                                    ZStack(alignment: .leading) {
                                        // 背景軌道
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.secondary.opacity(0.1))
                                            .frame(height: 8)
                                            .padding(.horizontal, 16) // match Slider's intrinsic insets
                                        
                                        // 填充軌道
                                        GeometryReader { geometry in
                                            VStack {
                                                Spacer(minLength: 0)
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(
                                                        LinearGradient(
                                                            gradient: Gradient(colors: [
                                                                AppColors.primaryBlue,
                                                                AppColors.primaryPurple
                                                            ]),
                                                            startPoint: .leading,
                                                            endPoint: .trailing
                                                        )
                                                    )
                                                    .frame(
                                                        width: geometry.size.width * CGFloat((settings.jpegQuality - 0.5) / 0.5),
                                                        height: 8
                                                    )
                                                Spacer(minLength: 0)
                                            }
                                        }
                                        .padding(.horizontal, 16) // match Slider's intrinsic insets
                                        
                                        // 滑桿
                                        Slider(value: $settings.jpegQuality, in: 0.5...1.0, step: 0.25)
                                            .tint(.clear)
                                    }
                                    // Provide enough vertical space for the thumb to align with the track
                                    .frame(height: 44)
                                    
                                    // 品質指示器
                                    HStack {
                                        Text("較小檔案")
                                            .font(.system(size: 11, weight: .medium, design: .rounded))
                                            .foregroundColor(Color.dynamic(
                                                light: AppColors.textTertiary,
                                                dark: AppColors.darkTextSecondary
                                            ))
                                        
                                        Spacer()
                                        
                                        Text("較高品質")
                                            .font(.system(size: 11, weight: .medium, design: .rounded))
                                            .foregroundColor(Color.dynamic(
                                                light: AppColors.textTertiary,
                                                dark: AppColors.darkTextSecondary
                                            ))
                                    }
                                }
                                
                                // 品質說明
                                HStack(spacing: AppSpacing.xs) {
                                    Image(systemName: "info.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppColors.primaryBlue.opacity(0.6))
                                    
                                    Text(qualityDescription)
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(Color.dynamic(
                                            light: AppColors.textSecondary,
                                            dark: AppColors.darkTextSecondary
                                        ))
                                }
                                .padding(AppSpacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(AppColors.primaryBlue.opacity(0.05))
                                )
                            }
                            .padding(.horizontal, AppSpacing.lg)
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .scale.combined(with: .opacity)
                            ))
                        }
                        
                        // 進階設定
                        if appState.isPro {
                            VStack(alignment: .leading, spacing: AppSpacing.md) {
                                Label("進階設定", systemImage: "gearshape.2")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color.dynamic(
                                        light: AppColors.textPrimary,
                                        dark: AppColors.darkTextPrimary
                                    ))
                                
                                Toggle(isOn: $settings.preserveMetadata) {
                                    HStack {
                                        Image(systemName: "info.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(AppColors.primaryBlue)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("保留圖片資訊")
                                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                                .foregroundColor(Color.dynamic(
                                                    light: AppColors.textPrimary,
                                                    dark: AppColors.darkTextPrimary
                                                ))
                                            
                                            Text("保留 EXIF 資料如拍攝時間、地點等")
                                                .font(.system(size: 11, weight: .regular, design: .rounded))
                                                .foregroundColor(Color.dynamic(
                                                    light: AppColors.textSecondary,
                                                    dark: AppColors.darkTextSecondary
                                                ))
                                        }
                                    }
                                }
                                .tint(AppColors.primaryBlue)
                                .padding(AppSpacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.secondary.opacity(0.05))
                                )
                            }
                            .padding(.horizontal, AppSpacing.lg)
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .scale.combined(with: .opacity)
                            ))
                        }
                        
                        // 預覽區域
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Label("預估效果", systemImage: "eye")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(Color.dynamic(
                                    light: AppColors.textPrimary,
                                    dark: AppColors.darkTextPrimary
                                ))
                            
                            HStack(spacing: AppSpacing.lg) {
                                // 檔案大小預估
                                VStack(spacing: AppSpacing.xs) {
                                    Image(systemName: "doc.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(AppColors.primaryBlue)
                                    
                                    Text("檔案大小")
                                        .font(.system(size: 11, weight: .medium, design: .rounded))
                                        .foregroundColor(Color.dynamic(
                                            light: AppColors.textSecondary,
                                            dark: AppColors.darkTextSecondary
                                        ))
                                    
                                    Text(estimatedSizeText)
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .foregroundColor(Color.dynamic(
                                            light: AppColors.textPrimary,
                                            dark: AppColors.darkTextPrimary
                                        ))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppSpacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.secondary.opacity(0.05))
                                )
                                
                                // 品質等級
                                VStack(spacing: AppSpacing.xs) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(AppColors.warningOrange)
                                    
                                    Text("品質等級")
                                        .font(.system(size: 11, weight: .medium, design: .rounded))
                                        .foregroundColor(Color.dynamic(
                                            light: AppColors.textSecondary,
                                            dark: AppColors.darkTextSecondary
                                        ))
                                    
                                    HStack(spacing: 2) {
                                        ForEach(0..<qualityStars, id: \.self) { _ in
                                            Image(systemName: "star.fill")
                                                .font(.system(size: 10))
                                                .foregroundColor(AppColors.warningOrange)
                                        }
                                        ForEach(0..<(5-qualityStars), id: \.self) { _ in
                                            Image(systemName: "star")
                                                .font(.system(size: 10))
                                                .foregroundColor(AppColors.warningOrange.opacity(0.3))
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppSpacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.secondary.opacity(0.05))
                                )
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        
                        // 確認按鈕
                        Button(action: {
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                Text("確認設定")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        AppColors.primaryBlue,
                                        AppColors.primaryPurple
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(
                                color: AppColors.primaryBlue.opacity(0.3),
                                radius: 8,
                                x: 0,
                                y: 4
                            )
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.bottom, AppSpacing.lg)
                    }
                    .padding(.top, AppSpacing.lg)
                }
            }
            .background(
                Color.dynamic(
                    light: Color.white,
                    dark: Color(red: 20/255, green: 20/255, blue: 30/255)
                )
            )
            .navigationBarHidden(true)
        }
    }
    
    @ViewBuilder
    private func formatButton(_ format: ConversionFormat) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                settings.outputFormat = format
            }
        }) {
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: format.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(
                        settings.outputFormat == format ?
                        .white : AppColors.primaryBlue
                    )
                
                Text(format.displayName)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(
                        settings.outputFormat == format ?
                        .white : AppColors.textPrimary
                    )
                
                Text(format == .png ? "無損格式" : "壓縮格式")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(
                        settings.outputFormat == format ?
                        .white.opacity(0.8) : AppColors.textSecondary
                    )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        settings.outputFormat == format ?
                        LinearGradient(
                            gradient: Gradient(colors: [
                                AppColors.primaryBlue,
                                AppColors.primaryPurple
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.secondary.opacity(0.05),
                                Color.secondary.opacity(0.05)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        settings.outputFormat == format ?
                        Color.clear : Color.secondary.opacity(0.2),
                        lineWidth: 1
                    )
            )
        }
    }
    
    private var estimatedSizeText: String {
        if settings.outputFormat == .png {
            return "較大"
        } else {
            switch settings.jpegQuality {
            case 0.5:
                return "最小"
            case 0.75:
                return "中等"
            case 1.0:
                return "較大"
            default:
                return "中等"
            }
        }
    }
    
    private var qualityStars: Int {
        if settings.outputFormat == .png {
            return 5
        } else {
            switch settings.jpegQuality {
            case 0.5:
                return 3
            case 0.75:
                return 4
            case 1.0:
                return 5
            default:
                return 4
            }
        }
    }
}

#Preview {
    ConversionView()
        .environmentObject(AppState())
        .environmentObject(ConversionSettings())
}