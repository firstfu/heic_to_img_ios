//
//  DropZoneView.swift
//  heic_to_img_ios
//
//  Created by firstfu on 2025/8/10.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - 檔案選擇區域視圖
struct DropZoneView: View {
    let onFilePickerTap: () -> Void
    var onPhotoLibraryTap: (() -> Void)? = nil
    
    @State private var showBounceAnimation = false
    @State private var showRippleEffect = false
    @State private var glowAnimation = false
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            // 主要選擇區域
            VStack(spacing: AppSpacing.md) {
                // 圖標
                ZStack {
                    // 背景圓圈
                    Circle()
                        .fill(AppColors.primaryGradient.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    // 漣漪效果
                    if showRippleEffect {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .stroke(AppColors.primaryBlue.opacity(0.3), lineWidth: 2)
                                .frame(width: 80, height: 80)
                                .scaleEffect(showRippleEffect ? 2.0 : 1.0)
                                .opacity(showRippleEffect ? 0 : 0.8)
                                .animation(
                                    .easeOut(duration: 1.5).delay(Double(index) * 0.2).repeatForever(autoreverses: false),
                                    value: showRippleEffect
                                )
                        }
                    }
                    
                    // 主圖標
                    Image(systemName: "photo.stack")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(AppColors.primaryGradient)
                        .scaleEffect(showBounceAnimation ? 1.1 : 1.0)
                        .animation(AppAnimations.bouncy, value: showBounceAnimation)
                }
                
                // 文字說明
                VStack(spacing: AppSpacing.sm) {
                    Text("選擇 HEIC 圖片")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.dynamic(
                            light: AppColors.textPrimary,
                            dark: AppColors.darkTextPrimary
                        ))
                    
                    Text("點擊按鈕選擇要轉換的圖片")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(Color.dynamic(
                            light: AppColors.textSecondary,
                            dark: AppColors.darkTextSecondary
                        ))
                        .multilineTextAlignment(.center)
                }
            }
            
            // 分隔線
            HStack {
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: 1)
                
                Text("或")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textTertiary)
                    .padding(.horizontal, AppSpacing.md)
                
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: 1)
            }
            
            // 檔案選擇按鈕
            VStack(spacing: AppSpacing.md) {
                // 檔案選擇按鈕
                Button(action: onFilePickerTap) {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text("從檔案選擇")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 90/255, green: 120/255, blue: 255/255),
                                Color(red: 150/255, green: 60/255, blue: 255/255)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    .shadow(
                        color: Color(red: 90/255, green: 120/255, blue: 255/255).opacity(0.3),
                        radius: 10,
                        x: 0,
                        y: 5
                    )
                }
                
                // 相簿按鈕
                if let onPhotoLibraryTap = onPhotoLibraryTap {
                    Button(action: onPhotoLibraryTap) {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "photo.fill.on.rectangle.fill")
                                .font(.system(size: 16, weight: .semibold))
                            
                            Text("從相簿選擇")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(Color(red: 90/255, green: 120/255, blue: 255/255))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color(red: 90/255, green: 120/255, blue: 255/255).opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(
                                            Color(red: 90/255, green: 120/255, blue: 255/255).opacity(0.3),
                                            lineWidth: 1.5
                                        )
                                )
                        )
                    }
                }
            }
        }
        .padding(AppSpacing.xl)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 250)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .fill(
                    Color.dynamic(
                        light: AppColors.cardBackground,
                        dark: AppColors.darkCardBackground
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.lg)
                        .stroke(
                            Color.dynamic(
                                light: AppColors.cardBorder,
                                dark: AppColors.darkCardBorder
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(
            color: AppShadows.medium.color,
            radius: AppShadows.medium.radius,
            x: AppShadows.medium.x,
            y: AppShadows.medium.y
        )
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // 啟動漣漪效果
        showRippleEffect = true
        
        // 週期性彈跳動畫
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation(AppAnimations.bouncy) {
                showBounceAnimation.toggle()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(AppAnimations.bouncy) {
                    showBounceAnimation.toggle()
                }
            }
        }
    }
    
}

// MARK: - 已選檔案列表視圖
struct SelectedFilesView: View {
    @Binding var selectedFiles: [FileItem]
    let onRemoveFile: (Int) -> Void
    let onStartConversion: () -> Void
    
    @State private var selectedIndices: Set<Int> = []
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    private var gridColumns: [GridItem] {
        let columnCount = horizontalSizeClass == .regular ? 5 : 3
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: columnCount)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 標題和操作
            headerView
            
            // 檔案網格
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: gridColumns, spacing: 12) {
                    ForEach(Array(selectedFiles.enumerated()), id: \.element.id) { index, fileItem in
                        FileCardView(
                            fileItem: fileItem,
                            isSelected: selectedIndices.contains(index),
                            onTap: { toggleSelection(for: index) },
                            onRemove: { removeFile(at: index) }
                        )
                        .id(fileItem.id)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        ))
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(maxHeight: 320)
            
            // 轉換按鈕
            ConversionButton(
                fileCount: selectedFiles.count,
                isEnabled: !selectedFiles.isEmpty,
                onStartConversion: onStartConversion
            )
        }
        .padding(20)
        .background(
            ZStack {
                // 底層漸層背景
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.dynamic(
                                    light: Color.white,
                                    dark: Color(red: 25/255, green: 25/255, blue: 35/255)
                                ),
                                Color.dynamic(
                                    light: Color(red: 250/255, green: 250/255, blue: 255/255),
                                    dark: Color(red: 20/255, green: 20/255, blue: 30/255)
                                )
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // 玻璃化效果層
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial.opacity(0.5))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.secondary.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(
            color: AppColors.primaryBlue.opacity(0.08),
            radius: 20,
            x: 0,
            y: 10
        )
    }
    
    private var headerView: some View {
        HStack(alignment: .center) {
            // 左側：標題和統計
            HStack(spacing: 12) {
                // 圖片堆疊圖標
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppColors.primaryBlue.opacity(0.1),
                                    AppColors.primaryPurple.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "photo.stack.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AppColors.primaryGradient)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("已選圖片")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.dynamic(
                            light: AppColors.textPrimary,
                            dark: AppColors.darkTextPrimary
                        ))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            // 檔案數量
                            HStack(spacing: 2) {
                                Image(systemName: "doc.fill")
                                    .font(.system(size: 10))
                                Text("\(selectedFiles.count)/\(ProcessingLimits.maxBatchFiles)")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(selectedFiles.count > ProcessingLimits.maxBatchFiles * 4/5 ? AppColors.warningOrange : AppColors.textSecondary)
                            
                            Text("•")
                                .foregroundColor(AppColors.textTertiary)
                            
                            // 總大小
                            Text(totalFileSize)
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(isNearSizeLimit ? AppColors.warningOrange : AppColors.textSecondary)
                        }
                        
                        // 限制提示（當接近限制時顯示）
                        if isNearLimits {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(AppColors.warningOrange)
                                
                                Text(limitWarningText)
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .foregroundColor(AppColors.warningOrange)
                            }
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }
                    }
                }
            }
            
            Spacer()
            
            // 右側：操作按鈕
            HStack(spacing: 8) {
                // 批量刪除按鈕
                if !selectedIndices.isEmpty {
                    Button(action: removeSelectedFiles) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.system(size: 12, weight: .medium))
                            Text("\(selectedIndices.count)")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.red.opacity(0.9))
                        )
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                // 清空全部按鈕
                Button(action: clearAllFiles) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color.secondary.opacity(0.6))
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.01))
                                .frame(width: 32, height: 32)
                        )
                }
            }
        }
    }
    
    private var totalFileSize: String {
        let totalBytes = selectedFiles.reduce(0) { $0 + $1.size }
        let totalMB = ProcessingLimits.totalSizeInMB(selectedFiles)
        let maxMB = Double(ProcessingLimits.maxTotalSizeMB)
        return "\(ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)) / \(Int(maxMB))MB"
    }
    
    private var isNearSizeLimit: Bool {
        let totalMB = ProcessingLimits.totalSizeInMB(selectedFiles)
        let maxMB = Double(ProcessingLimits.maxTotalSizeMB)
        return totalMB > maxMB * 0.8
    }
    
    private var isNearLimits: Bool {
        let isNearCount = selectedFiles.count > ProcessingLimits.maxBatchFiles * 4/5
        return isNearCount || isNearSizeLimit
    }
    
    private var limitWarningText: String {
        if selectedFiles.count > ProcessingLimits.maxBatchFiles * 4/5 && isNearSizeLimit {
            return "接近數量和大小限制"
        } else if selectedFiles.count > ProcessingLimits.maxBatchFiles * 4/5 {
            return "接近數量限制"
        } else if isNearSizeLimit {
            return "接近大小限制"
        }
        return ""
    }
    
    // MARK: - 功能方法
    
    private func toggleSelection(for index: Int) {
        withAnimation(AppAnimations.bouncy) {
            if selectedIndices.contains(index) {
                selectedIndices.remove(index)
            } else {
                selectedIndices.insert(index)
            }
        }
    }
    
    private func removeFile(at index: Int) {
        withAnimation(.easeOut) {
            selectedIndices.remove(index)
            onRemoveFile(index)
        }
    }
    
    private func removeSelectedFiles() {
        let indicesToRemove = selectedIndices.sorted(by: >)
        withAnimation(.easeOut) {
            for index in indicesToRemove {
                onRemoveFile(index)
            }
            selectedIndices.removeAll()
        }
    }
    
    private func clearAllFiles() {
        withAnimation(.easeOut) {
            selectedFiles.removeAll()
            selectedIndices.removeAll()
        }
    }
}

// MARK: - 標頭操作按鈕樣式
struct HeaderActionButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: 30, height: 30)
            .background(color.opacity(0.8))
            .clipShape(Circle())
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(AppAnimations.spring, value: configuration.isPressed)
    }
}

// MARK: - 轉換按鈕組件
struct ConversionButton: View {
    let fileCount: Int
    let isEnabled: Bool
    let onStartConversion: () -> Void
    
    @EnvironmentObject private var appState: AppState
    
    private var buttonText: String {
        // MVP 版本：總是顯示立即轉換
        return "立即轉換"
        // if !appState.isPro && appState.remainingFreeConversions <= 0 {
        //     return "升級 Pro 繼續轉換"
        // } else if !appState.isPro && fileCount > 1 {
        //     return "升級 Pro 批量轉換"
        // } else {
        //     return "立即轉換"
        // }
    }
    
    private var shouldUpgrade: Bool {
        // MVP 版本：永遠不需要升級
        return false
        // return !appState.isPro && (appState.remainingFreeConversions <= 0 || fileCount > 1)
    }
    
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // MVP 版本：註解掉免費版限制提示
            // if !appState.isPro && fileCount > 0 {
            //     HStack(spacing: AppSpacing.xs) {
            //         Image(systemName: "info.circle.fill")
            //             .font(.system(size: 12, weight: .medium))
            //             .foregroundColor(AppColors.warningOrange)
            //     
            //         if fileCount > 1 {
            //             Text("免費版僅支援單檔轉換")
            //         } else if appState.remainingFreeConversions <= 0 {
            //             Text("免費轉換次數已用完")
            //         } else {
            //             Text("剩餘 \(appState.remainingFreeConversions) 次免費轉換")
            //         }
            //     }
            //     .font(.system(size: 12, weight: .medium, design: .rounded))
            //     .foregroundColor(AppColors.warningOrange)
            //     .padding(.horizontal, AppSpacing.md)
            //     .padding(.vertical, AppSpacing.sm)
            //     .frame(maxWidth: .infinity)
            //     .background(
            //         RoundedRectangle(cornerRadius: AppRadius.sm)
            //             .fill(AppColors.warningOrange.opacity(0.1))
            //     )
            // }
            
            // 轉換按鈕
            Button(action: {
                // MVP 版本：直接開始轉換，不檢查升級
                // if shouldUpgrade {
                //     appState.showProUpgrade = true
                // } else {
                    onStartConversion()
                // }
            }) {
                HStack(spacing: AppSpacing.sm) {
                    // MVP 版本：總是顯示轉換圖示
                    Image(systemName: "bolt.circle.fill") // shouldUpgrade ? "crown.fill" : "bolt.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                    
                    Text(buttonText)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: shouldUpgrade ? [
                            AppColors.warningOrange,
                            AppColors.warningOrange.opacity(0.8)
                        ] : [
                            Color(red: 90/255, green: 120/255, blue: 255/255),
                            Color(red: 150/255, green: 60/255, blue: 255/255)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .shadow(
                    color: (shouldUpgrade ? AppColors.warningOrange : Color(red: 90/255, green: 120/255, blue: 255/255)).opacity(0.3),
                    radius: 10,
                    x: 0,
                    y: 5
                )
            }
            .disabled(!isEnabled)
            .opacity(isEnabled ? 1.0 : 0.6)
            .animation(AppAnimations.easeOut, value: isEnabled)
            .animation(AppAnimations.easeOut, value: shouldUpgrade)
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: AppSpacing.lg) {
        DropZoneView(
            onFilePickerTap: {
                print("檔案選擇器點擊")
            },
            onPhotoLibraryTap: {
                print("相簿選擇器點擊")
            }
        )
        
        SelectedFilesView(
            selectedFiles: .constant([]),
            onRemoveFile: { _ in },
            onStartConversion: { }
        )
    }
    .padding()
    .background(
        LinearGradient(
            colors: [
                Color(red: 250/255, green: 250/255, blue: 255/255),
                Color(red: 240/255, green: 245/255, blue: 255/255)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    )
}