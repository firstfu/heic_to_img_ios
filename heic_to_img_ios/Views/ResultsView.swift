//
//  ResultsView.swift
//  heic_to_img_ios
//
//  Created by firstfu on 2025/8/10.
//

import SwiftUI

struct ResultsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showDeleteConfirmation = false
    @State private var selectedResult: ConversionResult?
    @State private var isCreatingZip = false
    @State private var zipError: Error?
    @State private var showZipError = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景層 - 放在最底層
                PremiumBackgroundView()
                
                // 內容層
                VStack(spacing: 0) {
                    if appState.conversionResults.isEmpty {
                        ResultsEmptyStateView()
                    } else {
                        // 統計資訊卡片
                        if let stats = appState.lastConversionStats {
                            ResultsStatsCardView(stats: stats)
                                .padding(.horizontal, 20)
                                .padding(.top, 16)
                        }
                        
                        // 一鍵清除全部按鈕
                        if !appState.conversionResults.isEmpty {
                            ClearAllButtonView {
                                selectedResult = nil
                                showDeleteConfirmation = true
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        }
                        
                        // 轉換結果列表
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(appState.conversionResults, id: \.id) { result in
                                    EnhancedResultRowView(
                                        result: result,
                                        isSelectionMode: appState.isSelectionMode,
                                        isSelected: appState.selectedResultIds.contains(result.id),
                                        onSelect: {
                                            appState.toggleSelection(for: result.id)
                                        },
                                        onDelete: {
                                            selectedResult = result
                                            showDeleteConfirmation = true
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                            .padding(.bottom, 100)
                        }
                    }
                }
                
                // 選擇模式底部工具列
                if appState.isSelectionMode {
                    VStack {
                        Spacer()
                        SelectionToolbarView(
                            selectedCount: appState.selectedResultIds.count,
                            isCreatingZip: isCreatingZip,
                            onCreateZip: createAndShareZip
                        )
                    }
                }
            }
            .navigationTitle("轉換結果")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !appState.conversionResults.isEmpty {
                    // 選擇模式按鈕
                    ToolbarItem(placement: .navigationBarLeading) {
                        if appState.isSelectionMode {
                            Button("取消") {
                                appState.endSelectionMode()
                            }
                        } else {
                            Button("選擇") {
                                appState.startSelectionMode()
                            }
                        }
                    }
                    
                    // 功能選單
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if appState.isSelectionMode {
                            Button(appState.selectedResultIds.count == appState.conversionResults.count ? "取消全選" : "全選") {
                                if appState.selectedResultIds.count == appState.conversionResults.count {
                                    appState.deselectAllResults()
                                } else {
                                    appState.selectAllResults()
                                }
                            }
                        } else {
                            Menu {
                                Button("分享全部", systemImage: "square.and.arrow.up") {
                                    shareAllResults()
                                }
                                
                                Divider()
                                
                                Button("清除全部", systemImage: "trash", role: .destructive) {
                                    showDeleteConfirmation = true
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
            }
            .alert("確認刪除", isPresented: $showDeleteConfirmation) {
                Button("取消", role: .cancel) { }
                Button("刪除", role: .destructive) {
                    if selectedResult != nil {
                        deleteResult(selectedResult!)
                    } else {
                        appState.conversionResults.removeAll()
                    }
                    selectedResult = nil
                }
            } message: {
                if selectedResult != nil {
                    Text("確定要刪除這個轉換結果嗎？")
                } else {
                    Text("確定要清除所有轉換結果嗎？此操作無法復原。")
                }
            }
            .alert("打包失敗", isPresented: $showZipError) {
                Button("確定", role: .cancel) { }
            } message: {
                Text(zipError?.localizedDescription ?? "無法建立 ZIP 檔案")
            }
        }
    }
    
    private func deleteResult(_ result: ConversionResult) {
        appState.conversionResults.removeAll { $0.id == result.id }
        
        // 刪除本地文件
        try? FileManager.default.removeItem(at: result.outputURL)
    }
    
    private func shareAllResults() {
        let urls = appState.conversionResults.map { $0.outputURL }
        shareFiles(urls: urls, description: "使用 HEIC 轉檔專家轉換的圖片")
    }
    
    private func createAndShareZip() {
        guard !appState.selectedResultIds.isEmpty else { return }
        
        let selectedResults = appState.selectedResults
        let urls = selectedResults.map { $0.outputURL }
        
        isCreatingZip = true
        
        SimpleZipService.createZip(from: urls, outputName: "HEIC轉換結果") { result in
            self.isCreatingZip = false
            
            switch result {
            case .success(let zipURL):
                shareFiles(urls: [zipURL], description: "使用 HEIC 轉檔專家轉換並打包的圖片")
                
                // 分享完成後清理臨時檔案
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    SimpleZipService.cleanupTempFile(at: zipURL)
                }
                
            case .failure(let error):
                self.zipError = error
                self.showZipError = true
            }
        }
    }
}

// MARK: - 一鍵清除全部按鈕視圖
struct ClearAllButtonView: View {
    let onClearAll: () -> Void
    
    var body: some View {
        Button(action: onClearAll) {
            HStack(spacing: 12) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("一鍵清除全部")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.red.opacity(0.9),
                                Color.red.opacity(0.8)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        Color.red.opacity(0.3),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: Color.red.opacity(0.3),
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 結果空狀態視圖
struct ResultsEmptyStateView: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // 精美的空狀態插圖
            ZStack {
                // 背景圓圈
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.08),
                                Color.purple.opacity(0.06)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                
                // 中間圓圈
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.12),
                                Color.purple.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                // 圖標
                Image(systemName: "photo.badge.checkmark.fill")
                    .font(.system(size: 42, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            // 文字描述
            VStack(spacing: 16) {
                Text("還沒有轉換記錄")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("轉換完成的圖片會出現在這裡\n方便您查看和分享")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - 結果統計卡片視圖
struct ResultsStatsCardView: View {
    let stats: BatchConversionStats
    
    var body: some View {
        VStack(spacing: 16) {
            // 標題
            HStack {
                Text("本次轉換統計")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                Spacer()
                
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
            }
            
            // 統計數據
            HStack(spacing: 20) {
                ResultsStatItemView(
                    icon: "checkmark.circle.fill",
                    value: "\(stats.completedFiles)",
                    label: "成功",
                    color: .green
                )
                
                ResultsStatItemView(
                    icon: "clock.fill",
                    value: String(format: "%.1fs", stats.averageProcessingTime),
                    label: "平均時間",
                    color: .blue
                )
                
                ResultsStatItemView(
                    icon: "arrow.down.circle.fill",
                    value: ByteCountFormatter.string(fromByteCount: abs(stats.totalSavedSpace), countStyle: .file),
                    label: stats.totalSavedSpace >= 0 ? "節省" : "增加",
                    color: stats.totalSavedSpace >= 0 ? .green : .orange
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    Color(.secondarySystemGroupedBackground)
                        .shadow(.inner(color: .black.opacity(0.05), radius: 1))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.5),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - 結果統計項目視圖  
struct ResultsStatItemView: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 增強的結果行視圖
struct EnhancedResultRowView: View {
    let result: ConversionResult
    let isSelectionMode: Bool
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    @State private var showingPreview = false
    
    var body: some View {
        HStack(spacing: 16) {
            // 選擇模式的 checkbox
            if isSelectionMode {
                Button(action: onSelect) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(isSelected ? .blue : .secondary)
                        .animation(.easeInOut(duration: 0.2), value: isSelected)
                }
                .buttonStyle(.plain)
            }
            
            // 檔案縮圖或圖標
            Button {
                if isSelectionMode {
                    onSelect()
                } else {
                    showingPreview = true
                }
            } label: {
                if let uiImage = UIImage(contentsOfFile: result.outputURL.path) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 64, height: 64)
                        .clipped()
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    isSelected ? Color.blue : Color.clear,
                                    lineWidth: isSelected ? 3 : 0
                                )
                                .animation(.easeInOut(duration: 0.2), value: isSelected)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.blue.opacity(0.1),
                                    Color.purple.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                        .overlay(
                            Image(systemName: "photo.fill")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.blue, Color.purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    isSelected ? Color.blue : Color.clear,
                                    lineWidth: isSelected ? 3 : 0
                                )
                                .animation(.easeInOut(duration: 0.2), value: isSelected)
                        )
                }
            }
            .buttonStyle(.plain)
            
            // 檔案資訊
            VStack(alignment: .leading, spacing: 8) {
                // 檔案名稱
                Text(result.originalFile.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                // 詳細資訊
                HStack(spacing: 12) {
                    // 處理時間
                    Label {
                        Text(String(format: "%.1fs", result.processingTime))
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                    } icon: {
                        Image(systemName: "clock")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.secondary)
                    
                    // 空間變化
                    Label {
                        Text(result.savedSpaceString)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                    } icon: {
                        Image(systemName: result.savedSpace >= 0 ? "arrow.down.circle" : "arrow.up.circle")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(result.savedSpace >= 0 ? .green : .orange)
                }
                
                // 檔案大小資訊
                HStack(spacing: 4) {
                    Text("原始: \(ByteCountFormatter.string(fromByteCount: result.originalSize, countStyle: .file))")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Text("→")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.tertiary)
                    
                    Text("\(ByteCountFormatter.string(fromByteCount: result.outputSize, countStyle: .file))")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 操作按鈕（非選擇模式時顯示）
            if !isSelectionMode {
                HStack(spacing: 8) {
                    // 分享按鈕
                    Button {
                        shareFile(url: result.outputURL)
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(ActionButtonStyle(backgroundColor: .blue))
                    
                    // 刪除按鈕
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(ActionButtonStyle(backgroundColor: .red))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    Color(.secondarySystemGroupedBackground)
                        .shadow(.inner(color: .black.opacity(0.05), radius: 1))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.5),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
        .fullScreenCover(isPresented: $showingPreview) {
            ImagePreviewView(imageURL: result.outputURL)
        }
    }
}

// MARK: - 操作按鈕樣式
struct ActionButtonStyle: ButtonStyle {
    let backgroundColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 36, height: 36)
            .background(
                Circle()
                    .fill(backgroundColor.opacity(0.1))
                    .overlay(
                        Circle()
                            .strokeBorder(backgroundColor.opacity(0.2), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - 圖片預覽視圖
struct ImagePreviewView: View {
    let imageURL: URL
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let uiImage = UIImage(contentsOfFile: imageURL.path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(offset)
                    .clipped()
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = lastScale * value
                            }
                            .onEnded { _ in
                                lastScale = scale
                                if scale < 1.0 {
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        scale = 1.0
                                        lastScale = 1.0
                                    }
                                }
                            }
                            .simultaneously(with:
                                DragGesture()
                                    .onChanged { value in
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                    .onEnded { _ in
                                        lastOffset = offset
                                    }
                            )
                    )
            } else {
                ProgressView()
                    .tint(.white)
            }
            
            // 關閉按鈕
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.trailing, 20)
                }
                .padding(.top, 50)
                Spacer()
            }
        }
        .onTapGesture(count: 2) {
            withAnimation(.easeInOut(duration: 0.3)) {
                if scale > 1.0 {
                    scale = 1.0
                    offset = .zero
                } else {
                    scale = 2.0
                }
                lastScale = scale
                lastOffset = offset
            }
        }
    }
}

// MARK: - 背景視圖
struct PremiumBackgroundView: View {
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea(.all)
            
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.02),
                    Color.purple.opacity(0.02),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(.all)
        }
    }
}

struct ResultRowView: View {
    let result: ConversionResult
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // 檔案圖示
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.sm)
                    .fill(AppColors.softGradient)
                    .frame(width: 54, height: 54)
                
                Image(systemName: "photo.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(AppColors.primaryGradient)
            }
            
            // 檔案資訊
            VStack(alignment: .leading, spacing: 4) {
                Text(result.originalFile.name)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(Color.dynamic(
                        light: AppColors.textPrimary,
                        dark: AppColors.darkTextPrimary
                    ))
                    .lineLimit(1)
                
                HStack(spacing: AppSpacing.xs) {
                    // 處理時間
                    HStack(spacing: 2) {
                        Image(systemName: "clock")
                            .font(.system(size: 10, weight: .medium))
                        Text(String(format: "%.1fs", result.processingTime))
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(Color.dynamic(
                        light: AppColors.textSecondary,
                        dark: AppColors.darkTextSecondary
                    ))
                    
                    Text("•")
                        .foregroundColor(AppColors.textTertiary)
                    
                    // 空間節省
                    Text(result.savedSpaceString)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(result.savedSpace > 0 ? AppColors.successGreen : AppColors.warningOrange)
                }
            }
            
            Spacer()
            
            // 分享按鈕
            Button(action: {
                handleShareFile()
            }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.brandBlue)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(AppColors.brandBlue.opacity(0.1))
                    )
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(Color.dynamic(
                    light: Color.white.opacity(0.8),
                    dark: Color(red: 30/255, green: 30/255, blue: 50/255).opacity(0.6)
                ))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(
                    Color.dynamic(
                        light: AppColors.brandBlue.opacity(0.08),
                        dark: AppColors.brandBlue.opacity(0.15)
                    ),
                    lineWidth: 1
                )
        )
    }
    
    private func handleShareFile() {
        shareFile(url: result.outputURL)
    }
}

// MARK: - 分享功能擴展
func shareFile(url: URL) {
    guard FileManager.default.fileExists(atPath: url.path) else {
        print("❌ 檔案不存在：\(url.path)")
        return
    }
    
    shareFiles(urls: [url], description: "使用 HEIC 轉檔專家轉換的圖片 🎉")
}

func shareFiles(urls: [URL], description: String) {
    // 準備分享內容
    var activityItems: [Any] = urls
    activityItems.insert(description, at: 0)
    
    let activityViewController = UIActivityViewController(
        activityItems: activityItems,
        applicationActivities: nil
    )
    
    // 排除一些不需要的分享選項
    activityViewController.excludedActivityTypes = [
        .assignToContact,
        .openInIBooks,
        .addToReadingList
    ]
    
    // 為 iPad 設定 popover
    if UIDevice.current.userInterfaceIdiom == .pad {
        activityViewController.popoverPresentationController?.sourceView = UIView()
        activityViewController.popoverPresentationController?.sourceRect = CGRect(
            x: UIScreen.main.bounds.width / 2,
            y: UIScreen.main.bounds.height / 2,
            width: 0,
            height: 0
        )
        activityViewController.popoverPresentationController?.permittedArrowDirections = []
    }
    
    // 呈現分享界面
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let window = windowScene.windows.first,
       let rootViewController = window.rootViewController {
        
        // 找到最頂層的 view controller
        var topController = rootViewController
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        
        topController.present(activityViewController, animated: true)
    }
}

// MARK: - 選擇模式底部工具列
struct SelectionToolbarView: View {
    let selectedCount: Int
    let isCreatingZip: Bool
    let onCreateZip: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 毛玻璃效果背景
            Rectangle()
                .fill(.ultraThinMaterial)
                .frame(height: 88)
                .overlay(
                    HStack(spacing: 20) {
                        // 已選擇項目數量
                        VStack(alignment: .leading, spacing: 4) {
                            Text("已選擇")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Text("\(selectedCount) 個項目")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        // 打包並分享按鈕
                        Button(action: onCreateZip) {
                            HStack(spacing: 8) {
                                if isCreatingZip {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.white)
                                } else {
                                    Image(systemName: "archivebox.fill")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                
                                Text(isCreatingZip ? "打包中..." : "打包分享")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(
                                        LinearGradient(
                                            colors: selectedCount > 0 ? [Color.blue, Color.purple] : [Color.gray],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                        }
                        .disabled(selectedCount == 0 || isCreatingZip)
                        .animation(.easeInOut(duration: 0.2), value: selectedCount)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 34) // 留出 Tab Bar 空間
                )
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }
}

#Preview {
    ResultsView()
        .environmentObject(AppState())
}
