//
//  ProUpgradeView.swift
//  heic_to_img_ios
//
//  Created by firstfu on 2025/8/10.
//

import SwiftUI

struct ProUpgradeView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var storeManager: StoreManager
    @Environment(\.presentationMode) var presentationMode
    @State private var showContent = false
    @State private var showErrorAlert = false

    // 漸層色
    private let accentGold = Color(red: 255/255, green: 200/255, blue: 60/255)
    private let accentAmber = Color(red: 245/255, green: 158/255, blue: 11/255)

    var body: some View {
        ZStack {
            // 背景
            backgroundLayer

            // 內容
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // 關閉按鈕
                    closeButton

                    // 頂部 Hero 區域
                    heroSection
                        .padding(.top, 8)

                    // Pro 功能亮點
                    proFeaturesSection
                        .padding(.top, 32)

                    // 價格 + CTA
                    pricingAndCTASection
                        .padding(.top, 28)
                        .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
        }
        .alert("提示", isPresented: $showErrorAlert) {
            Button("確定") {
                storeManager.errorMessage = nil
            }
        } message: {
            Text(storeManager.errorMessage ?? "")
        }
        .onChange(of: storeManager.errorMessage) { _, newValue in
            showErrorAlert = newValue != nil
        }
    }

    // MARK: - 背景層

    private var backgroundLayer: some View {
        ZStack {
            Color.dynamic(
                light: Color(red: 248/255, green: 249/255, blue: 255/255),
                dark: Color(red: 12/255, green: 12/255, blue: 20/255)
            )
            .ignoresSafeArea()

            // 頂部光暈
            VStack {
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppColors.primaryBlue.opacity(0.15),
                                AppColors.primaryPurple.opacity(0.08),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 300)
                    .offset(y: -60)

                Spacer()
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - 關閉按鈕

    private var closeButton: some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.dynamic(
                        light: AppColors.textSecondary,
                        dark: AppColors.darkTextSecondary
                    ))
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color.dynamic(
                                light: Color.black.opacity(0.05),
                                dark: Color.white.opacity(0.08)
                            ))
                    )
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    // MARK: - Hero 區域

    private var heroSection: some View {
        VStack(spacing: 16) {
            // 皇冠圖示 + 光暈
            ZStack {
                // 外圈光暈
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accentGold.opacity(0.25), Color.clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 55
                        )
                    )
                    .frame(width: 110, height: 110)

                // 皇冠底盤
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [accentGold.opacity(0.2), accentAmber.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "crown.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [accentGold, accentAmber],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .scaleEffect(showContent ? 1.0 : 0.5)
            .opacity(showContent ? 1 : 0)

            VStack(spacing: 8) {
                Text("升級專業版")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color.dynamic(
                        light: AppColors.textPrimary,
                        dark: AppColors.darkTextPrimary
                    ))

                Text("一次購買，永久解鎖所有進階功能")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(Color.dynamic(
                        light: AppColors.textSecondary,
                        dark: AppColors.darkTextSecondary
                    ))
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 15)
        }
    }

    // MARK: - Pro 功能區

    private var proFeaturesSection: some View {
        VStack(spacing: 12) {
            ProFeatureRow(
                icon: "square.stack.3d.up.fill",
                iconColor: AppColors.primaryBlue,
                title: "無限制批次轉換",
                subtitle: "一次最多轉換 50 個檔案",
                show: showContent,
                delay: 0.15
            )

            ProFeatureRow(
                icon: "infinity",
                iconColor: AppColors.primaryPurple,
                title: "無限制轉換次數",
                subtitle: "不再受每日 3 次的限制",
                show: showContent,
                delay: 0.25
            )

            ProFeatureRow(
                icon: "doc.on.doc.fill",
                iconColor: Color(red: 16/255, green: 185/255, blue: 129/255),
                title: "JPEG + PNG 雙格式",
                subtitle: "自由選擇最適合的輸出格式",
                show: showContent,
                delay: 0.35
            )

            ProFeatureRow(
                icon: "slider.horizontal.3",
                iconColor: accentAmber,
                title: "自由品質調整",
                subtitle: "10% ~ 100% 精確控制壓縮品質",
                show: showContent,
                delay: 0.45
            )

            ProFeatureRow(
                icon: "info.circle.fill",
                iconColor: Color(red: 99/255, green: 102/255, blue: 241/255),
                title: "完整保留 EXIF 資料",
                subtitle: "地點、時間等照片資訊不遺失",
                show: showContent,
                delay: 0.55
            )

            ProFeatureRow(
                icon: "arrow.up.left.and.arrow.down.right",
                iconColor: Color(red: 236/255, green: 72/255, blue: 153/255),
                title: "尺寸調整",
                subtitle: "自訂縮放與最大尺寸限制",
                show: showContent,
                delay: 0.65
            )
        }
        .padding(.horizontal, 20)
    }

    // MARK: - 價格 + CTA

    private var pricingAndCTASection: some View {
        VStack(spacing: 16) {
            // 價格卡片
            VStack(spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(storeManager.proProduct?.displayPrice ?? "NT$ 90")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundColor(Color.dynamic(
                            light: AppColors.textPrimary,
                            dark: AppColors.darkTextPrimary
                        ))

                    Text("/ 永久")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(Color.dynamic(
                            light: AppColors.textSecondary,
                            dark: AppColors.darkTextSecondary
                        ))
                }

                Text("買一次，用一輩子，不用訂閱")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(Color.dynamic(
                        light: AppColors.textTertiary,
                        dark: AppColors.darkTextSecondary
                    ))
            }
            .opacity(showContent ? 1 : 0)
            .scaleEffect(showContent ? 1 : 0.9)

            // 購買按鈕
            Button(action: {
                Task {
                    let success = await storeManager.purchase()
                    if success {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }) {
                HStack(spacing: 8) {
                    if storeManager.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 15, weight: .semibold))
                    }

                    Text(storeManager.isLoading ? "處理中..." : "立即升級")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    LinearGradient(
                        colors: [AppColors.primaryBlue, AppColors.primaryPurple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(
                    color: AppColors.primaryBlue.opacity(0.35),
                    radius: 12,
                    x: 0,
                    y: 6
                )
            }
            .disabled(storeManager.isLoading)
            .scaleEffect(showContent ? 1 : 0.9)
            .opacity(showContent ? 1 : 0)

            // 恢復購買
            Button(action: {
                Task {
                    await storeManager.restorePurchases()
                    if storeManager.isPro {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }) {
                Text("恢復購買")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color.dynamic(
                        light: AppColors.textSecondary,
                        dark: AppColors.darkTextSecondary
                    ))
            }
            .disabled(storeManager.isLoading)
            .opacity(showContent ? 1 : 0)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Pro 功能行元件

struct ProFeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let show: Bool
    let delay: Double

    var body: some View {
        HStack(spacing: 14) {
            // 圖示
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 42, height: 42)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            // 文字
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.dynamic(
                        light: AppColors.textPrimary,
                        dark: AppColors.darkTextPrimary
                    ))

                Text(subtitle)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(Color.dynamic(
                        light: AppColors.textSecondary,
                        dark: AppColors.darkTextSecondary
                    ))
            }

            Spacer()

            // 打勾
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppColors.primaryBlue, AppColors.primaryPurple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.dynamic(
                    light: Color.white,
                    dark: Color(red: 24/255, green: 24/255, blue: 38/255)
                ))
                .shadow(
                    color: Color.black.opacity(0.04),
                    radius: 8,
                    x: 0,
                    y: 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.dynamic(
                    light: Color.black.opacity(0.04),
                    dark: Color.white.opacity(0.06)
                ), lineWidth: 1)
        )
        .opacity(show ? 1 : 0)
        .offset(x: show ? 0 : -20)
        .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(delay), value: show)
    }
}

#Preview {
    ProUpgradeView()
        .environmentObject(AppState())
        .environmentObject(StoreManager.shared)
}
