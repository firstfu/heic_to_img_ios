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
    @State private var isHovering = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // 主卡片內容
            VStack(spacing: 6) {
                // 縮圖容器
                ZStack {
                    thumbnailView
                        .frame(width: 75, height: 75)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    isSelected ?
                                    LinearGradient(
                                        colors: [AppColors.primaryBlue, AppColors.primaryPurple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ) :
                                    LinearGradient(
                                        colors: [Color.secondary.opacity(0.2), Color.secondary.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: isSelected ? 2.5 : 1
                                )
                        )
                    
                    // 選中標記
                    if isSelected {
                        VStack {
                            HStack {
                                Spacer()
                                ZStack {
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 20, height: 20)
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [AppColors.primaryBlue, AppColors.primaryPurple],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }
                                .offset(x: 5, y: -5)
                            }
                            Spacer()
                        }
                    }
                }
                
                // 檔案資訊
                VStack(spacing: 2) {
                    Text(fileItem.name)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(Color.dynamic(
                            light: AppColors.textPrimary,
                            dark: AppColors.darkTextPrimary
                        ))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    Text(fileItem.formattedSize)
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(.horizontal, 4)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        Color.dynamic(
                            light: isSelected ? AppColors.primaryBlue.opacity(0.05) : Color.white,
                            dark: isSelected ? AppColors.primaryBlue.opacity(0.1) : Color(red: 30/255, green: 30/255, blue: 40/255)
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        Color.dynamic(
                            light: isSelected ? AppColors.primaryBlue.opacity(0.2) : Color.secondary.opacity(0.1),
                            dark: isSelected ? AppColors.primaryBlue.opacity(0.3) : Color.secondary.opacity(0.2)
                        ),
                        lineWidth: 1
                    )
            )
            
            // 移除按鈕（懸停或選中時顯示）
            if isHovering || isSelected {
                Button(action: onRemove) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.9))
                            .frame(width: 18, height: 18)
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .offset(x: 5, y: -5)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .shadow(
            color: isSelected ? AppColors.primaryBlue.opacity(0.15) : Color.black.opacity(0.05),
            radius: isSelected ? 8 : 4,
            x: 0,
            y: isSelected ? 4 : 2
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(AppAnimations.smooth, value: isSelected)
        .onTapGesture(perform: onTap)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
        .onAppear(perform: loadThumbnail)
    }
    
    @ViewBuilder
    private var thumbnailView: some View {
        if let thumbnail = thumbnail {
            Image(uiImage: thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.black.opacity(0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        } else {
            // 佔位符背景
            ZStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.dynamic(light: Color(red: 245/255, green: 245/255, blue: 250/255), 
                                             dark: Color(red: 40/255, green: 40/255, blue: 50/255)),
                                Color.dynamic(light: Color(red: 240/255, green: 240/255, blue: 245/255), 
                                             dark: Color(red: 35/255, green: 35/255, blue: 45/255))
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                        .tint(AppColors.primaryBlue)
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 24, weight: .thin))
                        .foregroundColor(AppColors.textTertiary.opacity(0.4))
                }
            }
        }
    }
    
    
    private func loadThumbnail() {
        guard thumbnail == nil else { return }
        isLoading = true
        Task.detached(priority: .userInitiated) {
            let generatedThumbnail = await fileItem.generateThumbnail()
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.thumbnail = generatedThumbnail
                    self.isLoading = false
                }
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
