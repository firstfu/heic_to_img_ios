//
//  ProUpgradeView.swift
//  heic_to_img_ios
//
//  Created by firstfu on 2025/8/10.
//

import SwiftUI

struct ProUpgradeView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @State private var showFeatures = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // 頂部圖示和標題
                    VStack(spacing: AppSpacing.lg) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60, weight: .bold))
                            .foregroundStyle(AppColors.primaryGradient)
                            .scaleEffect(showFeatures ? 1.0 : 0.8)
                            .animation(AppAnimations.bouncy.delay(0.2), value: showFeatures)
                        
                        VStack(spacing: AppSpacing.sm) {
                            Text("升級到專業版")
                                .font(AppFonts.title1)
                                .fontWeight(.bold)
                                .foregroundStyle(AppColors.primaryGradient)
                                .opacity(showFeatures ? 1 : 0)
                                .offset(y: showFeatures ? 0 : 20)
                                .animation(AppAnimations.spring.delay(0.4), value: showFeatures)
                            
                            Text("解鎖所有功能，享受無限制的專業體驗")
                                .font(AppFonts.callout)
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .opacity(showFeatures ? 1 : 0)
                                .offset(y: showFeatures ? 0 : 20)
                                .animation(AppAnimations.spring.delay(0.6), value: showFeatures)
                        }
                    }
                    .padding(.top, AppSpacing.lg)
                    
                    // 功能對比
                    VStack(spacing: AppSpacing.md) {
                        FeatureComparisonRow(
                            feature: "批次轉換",
                            freeLimit: "單檔案",
                            proFeature: "無限制批次",
                            delay: 0.8
                        )
                        
                        FeatureComparisonRow(
                            feature: "轉換次數",
                            freeLimit: "僅3次",
                            proFeature: "無限制使用",
                            delay: 1.0
                        )
                        
                        FeatureComparisonRow(
                            feature: "保留圖片資訊",
                            freeLimit: "不保留",
                            proFeature: "完整保留",
                            delay: 1.2
                        )
                        
                        FeatureComparisonRow(
                            feature: "圖片品質",
                            freeLimit: "標準",
                            proFeature: "最佳品質",
                            delay: 1.4
                        )
                        
                        FeatureComparisonRow(
                            feature: "客戶支援",
                            freeLimit: "基本支援",
                            proFeature: "優先支援",
                            delay: 1.6
                        )
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .opacity(showFeatures ? 1 : 0)
                    .offset(y: showFeatures ? 0 : 30)
                    .animation(AppAnimations.spring.delay(1.8), value: showFeatures)
                    
                    // 價格信息
                    VStack(spacing: AppSpacing.md) {
                        VStack(spacing: AppSpacing.sm) {
                            Text("💎 限時優惠")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(AppColors.warningOrange)
                            
                            HStack(alignment: .bottom, spacing: AppSpacing.sm) {
                                Text("NT$ 90")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(AppColors.primaryBlue)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("原價 NT$ 150")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppColors.textSecondary)
                                        .strikethrough()
                                    
                                    Text("永久使用")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(AppColors.successGreen)
                                }
                            }
                            
                            Text("一次購買，永久享受專業功能")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    .padding(.vertical, AppSpacing.lg)
                    .frame(maxWidth: .infinity)
                    .cardStyle()
                    .padding(.horizontal, AppSpacing.lg)
                    .scaleEffect(showFeatures ? 1.0 : 0.9)
                    .opacity(showFeatures ? 1 : 0)
                    .animation(AppAnimations.bouncy.delay(2.0), value: showFeatures)
                    
                    Spacer(minLength: AppSpacing.xl)
                    
                    // 購買按鈕
                    VStack(spacing: AppSpacing.md) {
                        Button(action: {
                            // TODO: 實作 In-App Purchase
                            // 暫時直接升級用於測試
                            appState.upgradeToPro()
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 16, weight: .medium))
                                
                                Text("立即升級")
                                    .font(AppFonts.bodyMedium)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .primaryButtonStyle()
                        .scaleEffect(showFeatures ? 1.0 : 0.9)
                        .opacity(showFeatures ? 1 : 0)
                        .animation(AppAnimations.bouncy.delay(2.2), value: showFeatures)
                        
                        Button("恢復購買") {
                            appState.restorePurchases()
                        }
                        .font(AppFonts.callout)
                        .foregroundColor(AppColors.primaryBlue)
                        .opacity(showFeatures ? 1 : 0)
                        .animation(AppAnimations.spring.delay(2.4), value: showFeatures)
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.xl)
                }
            }
            .background(
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
            )
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            withAnimation {
                showFeatures = true
            }
        }
    }
}

struct FeatureComparisonRow: View {
    let feature: String
    let freeLimit: String
    let proFeature: String
    let delay: Double
    @State private var showContent = false
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // 功能名稱
            Text(feature)
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 免費版限制
            VStack(alignment: .center, spacing: AppSpacing.xs) {
                Text("免費版")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textTertiary)
                
                Text(freeLimit)
                    .font(AppFonts.callout)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            
            // Pro 版功能
            VStack(alignment: .center, spacing: AppSpacing.xs) {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 10))
                        .foregroundColor(AppColors.primaryBlue)
                    
                    Text("專業版")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.primaryBlue)
                }
                
                Text(proFeature)
                    .font(AppFonts.callout)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.primaryBlue)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, AppSpacing.sm)
        .padding(.horizontal, AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(Color.dynamic(
                    light: AppColors.cardBackground,
                    dark: AppColors.darkCardBackground
                ))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .stroke(Color.dynamic(
                            light: AppColors.cardBorder,
                            dark: AppColors.darkCardBorder
                        ), lineWidth: 1)
                )
        )
        .scaleEffect(showContent ? 1.0 : 0.9)
        .opacity(showContent ? 1 : 0)
        .animation(AppAnimations.spring.delay(delay), value: showContent)
        .onAppear {
            showContent = true
        }
    }
}

#Preview {
    ProUpgradeView()
        .environmentObject(AppState())
}