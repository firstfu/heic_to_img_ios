//
//  UIComponents.swift
//  heic_to_img_ios
//
//  Created by firstfu on 2025/8/10.
//

import SwiftUI

// MARK: - 進度指示器
struct ProgressRing: View {
    let progress: Double
    let strokeWidth: CGFloat
    let size: CGFloat
    
    init(progress: Double, strokeWidth: CGFloat = 8, size: CGFloat = 60) {
        self.progress = progress
        self.strokeWidth = strokeWidth
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // 背景環
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: strokeWidth)
            
            // 進度環
            Circle()
                .trim(from: 0.0, to: min(progress, 1.0))
                .stroke(
                    AppColors.primaryGradient,
                    style: StrokeStyle(
                        lineWidth: strokeWidth,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(AppAnimations.easeOut, value: progress)
            
            // 中心文字
            Text("\(Int(progress * 100))%")
                .font(.system(size: size * 0.2, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.primaryGradient)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - 閃爍按鈕
struct ShimmerButton: View {
    let title: String
    let action: () -> Void
    @State private var shimmerOffset: CGFloat = -200
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title)
                    .font(AppFonts.bodyMedium)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(AppColors.primaryGradient)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                
                // 閃爍效果
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.3),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 50)
                    .offset(x: shimmerOffset)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                shimmerOffset = 200
            }
        }
    }
}

// MARK: - 檔案卡片
struct FileCardView: View {
    let fileItem: FileItem
    let isSelected: Bool
    let onTap: () -> Void
    let onRemove: () -> Void
    
    @State private var thumbnail: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            // 縮圖背景
            thumbnailView
            
            // 內容疊加
            overlayContent
            
            // 移除按鈕
            removeButton
            
            // 選中光暈效果
            if isSelected {
                selectionGlow
            }
        }
        .frame(height: 120)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .shadow(
            color: isSelected ? AppColors.primaryBlue.opacity(0.3) : AppShadows.medium.color,
            radius: isSelected ? 10 : AppShadows.medium.radius,
            x: AppShadows.medium.x,
            y: AppShadows.medium.y
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(AppAnimations.bouncy, value: isSelected)
        .onTapGesture(perform: onTap)
        .onAppear(perform: loadThumbnail)
    }
    
    @ViewBuilder
    private var thumbnailView: some View {
        if let thumbnail = thumbnail {
            Image(uiImage: thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            // 佔位符背景
            ZStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.dynamic(light: .gray.opacity(0.1), dark: .gray.opacity(0.2)),
                                Color.dynamic(light: .gray.opacity(0.05), dark: .gray.opacity(0.1))
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(AppColors.textTertiary.opacity(0.5))
                }
            }
        }
    }
    
    private var overlayContent: some View {
        VStack {
            Spacer()
            
            // 漸層遮罩
            HStack(spacing: AppSpacing.sm) {
                // 檔案資訊
                VStack(alignment: .leading, spacing: 2) {
                    Text(fileItem.name)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    Text(fileItem.formattedSize)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // 選中圖標
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(radius: 2)
            }
            .padding(AppSpacing.sm)
            .background(
                LinearGradient(
                    colors: [
                        .black.opacity(0.0),
                        .black.opacity(0.4),
                        .black.opacity(0.6)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
    
    private var removeButton: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: onRemove) {
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.5))
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .padding(AppSpacing.xs)
            }
            Spacer()
        }
    }
    
    private var selectionGlow: some View {
        RoundedRectangle(cornerRadius: AppRadius.lg)
            .stroke(
                LinearGradient(
                    colors: [
                        AppColors.primaryBlue.opacity(0.8),
                        AppColors.primaryPurple.opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 3
            )
            .blur(radius: 2)
    }
    
    private func loadThumbnail() {
        guard thumbnail == nil else { return }
        isLoading = true
        Task.detached(priority: .userInitiated) {
            let generatedThumbnail = await fileItem.generateThumbnail()
            await MainActor.run {
                self.thumbnail = generatedThumbnail
                self.isLoading = false
            }
        }
    }
}

// MARK: - 空狀態視圖
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        subtitle: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 60, weight: .light))
                .foregroundColor(AppColors.textTertiary)
            
            VStack(spacing: AppSpacing.sm) {
                Text(title)
                    .font(AppFonts.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textSecondary)
                
                Text(subtitle)
                    .font(AppFonts.callout)
                    .foregroundColor(AppColors.textTertiary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .primaryButtonStyle()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AppSpacing.xl)
    }
}

// MARK: - 統計卡片
struct StatsCardView: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let color: Color
    
    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        icon: String,
        color: Color = AppColors.primaryBlue
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
                
                Spacer()
                
                Text(title)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .textCase(.uppercase)
            }
            
            Text(value)
                .font(AppFonts.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

// MARK: - 動畫修飾器
struct PulseAnimation: ViewModifier {
    @State private var isPulsing = false
    let duration: Double
    let minOpacity: Double
    
    init(duration: Double = 1.0, minOpacity: Double = 0.5) {
        self.duration = duration
        self.minOpacity = minOpacity
    }
    
    func body(content: Content) -> some View {
        content
            .opacity(isPulsing ? minOpacity : 1.0)
            .animation(.easeInOut(duration: duration).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear {
                isPulsing = true
            }
    }
}

struct ShakeAnimation: ViewModifier {
    @State private var shakeOffset: CGFloat = 0
    let trigger: Bool
    
    func body(content: Content) -> some View {
        content
            .offset(x: shakeOffset)
            .onChange(of: trigger) {
                withAnimation(.default) {
                    shakeOffset = 5
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.default) {
                        shakeOffset = -5
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.default) {
                        shakeOffset = 0
                    }
                }
            }
    }
}

// MARK: - 視圖擴展
extension View {
    func pulse(duration: Double = 1.0, minOpacity: Double = 0.5) -> some View {
        modifier(PulseAnimation(duration: duration, minOpacity: minOpacity))
    }
    
    func shake(trigger: Bool) -> some View {
        modifier(ShakeAnimation(trigger: trigger))
    }
    
    func applyRoundedCorners(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// MARK: - 自定義形狀
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
