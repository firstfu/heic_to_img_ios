//
//  DesignSystem.swift
//  heic_to_img_ios
//
//  Created by firstfu on 2025/8/10.
//

import SwiftUI

// MARK: - 應用程式色彩系統
struct AppColors {
    // 主色調 - 現代藍紫漸層
    static let primaryBlue = Color(red: 90/255, green: 120/255, blue: 255/255) // #5A78FF - 更柔和的藍色
    static let primaryPurple = Color(red: 150/255, green: 60/255, blue: 255/255) // #963CFF - 鮮豔紫色

    // 品牌色彩變化
    static let brandBlue = Color(red: 90/255, green: 120/255, blue: 255/255)
    static let brandPurple = Color(red: 150/255, green: 60/255, blue: 255/255)
    static let brandAccent = Color(red: 120/255, green: 90/255, blue: 255/255) // 中間色調

    // 漸層色彩
    static let primaryGradient = LinearGradient(
        colors: [brandBlue, brandPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // 柔和漸層（用於背景）
    static let softGradient = LinearGradient(
        colors: [brandBlue.opacity(0.1), brandPurple.opacity(0.05)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 250/255, green: 250/255, blue: 255/255),
            Color(red: 240/255, green: 245/255, blue: 255/255)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    // 深色模式背景漸層
    static let darkBackgroundGradient = LinearGradient(
        colors: [
            Color(red: 15/255, green: 15/255, blue: 25/255),
            Color(red: 25/255, green: 25/255, blue: 45/255)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    // 狀態色彩
    static let successGreen = Color(red: 34/255, green: 197/255, blue: 94/255) // #22c55e
    static let warningOrange = Color(red: 251/255, green: 146/255, blue: 60/255) // #fb923c
    static let errorRed = Color(red: 239/255, green: 68/255, blue: 68/255) // #ef4444

    // 中性色彩
    static let cardBackground = Color(red: 255/255, green: 255/255, blue: 255/255, opacity: 0.9)
    static let cardBorder = Color(red: 226/255, green: 232/255, blue: 240/255) // #e2e8f0
    static let textPrimary = Color(red: 30/255, green: 41/255, blue: 59/255) // #1e293b
    static let textSecondary = Color(red: 100/255, green: 116/255, blue: 139/255) // #64748b
    static let textTertiary = Color(red: 148/255, green: 163/255, blue: 184/255) // #94a3b8

    // 深色模式對應色彩
    static let darkCardBackground = Color(red: 30/255, green: 30/255, blue: 50/255, opacity: 0.9)
    static let darkCardBorder = Color(red: 55/255, green: 65/255, blue: 81/255) // #374151
    static let darkTextPrimary = Color(red: 248/255, green: 250/255, blue: 252/255) // #f8fafc
    static let darkTextSecondary = Color(red: 203/255, green: 213/255, blue: 225/255) // #cbd5e1
}

// MARK: - 字體系統
struct AppFonts {
    // 標題字體
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let title1 = Font.system(size: 28, weight: .bold, design: .rounded)
    static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)

    // 內文字體
    static let body = Font.system(size: 17, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 17, weight: .medium, design: .default)
    static let callout = Font.system(size: 16, weight: .regular, design: .default)
    static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
    static let footnote = Font.system(size: 13, weight: .regular, design: .default)
    static let caption = Font.system(size: 12, weight: .regular, design: .default)

    // 特殊字體
    static let heroTitle = Font.system(size: 48, weight: .heavy, design: .rounded)
    static let number = Font.system(size: 24, weight: .bold, design: .monospaced)
}

// MARK: - 間距系統
struct AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let xxxl: CGFloat = 64
}

// MARK: - 圓角系統
struct AppRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let full: CGFloat = 9999
}

// MARK: - 陰影系統
struct AppShadows {
    static let small = Shadow(
        color: Color.black.opacity(0.1),
        radius: 2,
        x: 0,
        y: 1
    )

    static let medium = Shadow(
        color: Color.black.opacity(0.1),
        radius: 8,
        x: 0,
        y: 4
    )

    static let large = Shadow(
        color: Color.black.opacity(0.15),
        radius: 20,
        x: 0,
        y: 10
    )
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - 動畫常數
struct AppAnimations {
    static let fastDuration: Double = 0.2
    static let normalDuration: Double = 0.3
    static let slowDuration: Double = 0.5

    static let easeOut = Animation.easeOut(duration: normalDuration)
    static let easeIn = Animation.easeIn(duration: normalDuration)
    static let spring = Animation.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)
    static let bouncy = Animation.spring(response: 0.6, dampingFraction: 0.6, blendDuration: 0)

    // 新增專業動畫
    static let smooth = Animation.smooth(duration: 0.5)
    static let snappy = Animation.snappy(duration: 0.3)
    static let interactive = Animation.interactiveSpring(response: 0.3, dampingFraction: 0.8, blendDuration: 0.2)
    static let gentle = Animation.easeInOut(duration: 0.4)
    static let elastic = Animation.interpolatingSpring(stiffness: 180, damping: 15)
}

// MARK: - 設備常數
struct AppConstants {
    static let maxFileSize: Int64 = 100 * 1024 * 1024 // 100MB
    static let maxBatchSize: Int = 50
    static let thumbnailSize: CGSize = CGSize(width: 120, height: 120)
    static let previewSize: CGSize = CGSize(width: 300, height: 300)

    // App Store 連結和其他常數
    static let appStoreURL = "https://apps.apple.com/app/heicmaster-pro/id123456789"
    static let supportEmail = "firefirstfu@gmail.com"
    static let privacyPolicyURL = "https://heicmaster.com/privacy"
    static let termsURL = "https://heicmaster.com/terms"
}

// MARK: - UI 擴展
extension Color {
    static func dynamic(light: Color, dark: Color) -> Color {
        return Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

extension View {
    func cardStyle() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .fill(Color.dynamic(
                        light: AppColors.cardBackground,
                        dark: AppColors.darkCardBackground
                    ))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.lg)
                            .stroke(Color.dynamic(
                                light: AppColors.cardBorder,
                                dark: AppColors.darkCardBorder
                            ), lineWidth: 1)
                    )
            )
            .shadow(color: AppShadows.medium.color,
                   radius: AppShadows.medium.radius,
                   x: AppShadows.medium.x,
                   y: AppShadows.medium.y)
    }

    func primaryButtonStyle() -> some View {
        self
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
            .background(AppColors.primaryGradient)
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .shadow(color: AppColors.brandBlue.opacity(0.3),
                   radius: 10, x: 0, y: 5)
    }

    func modernButtonStyle() -> some View {
        self
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        AppColors.brandBlue,
                        AppColors.brandPurple
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .shadow(
                color: AppColors.brandBlue.opacity(0.3),
                radius: 15,
                x: 0,
                y: 8
            )
    }

    func secondaryButtonStyle() -> some View {
        self
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundColor(AppColors.brandBlue)
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(AppColors.brandBlue.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(AppColors.brandBlue.opacity(0.3), lineWidth: 1.5)
                    )
            )
    }

    func glassEffect() -> some View {
        self
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppRadius.lg))
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    func modernCardStyle() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .fill(Color.dynamic(
                        light: AppColors.cardBackground,
                        dark: AppColors.darkCardBackground
                    ))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.lg)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        AppColors.brandBlue.opacity(0.1),
                                        AppColors.brandPurple.opacity(0.05)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(
                color: AppColors.brandBlue.opacity(0.08),
                radius: 20,
                x: 0,
                y: 10
            )
    }
}