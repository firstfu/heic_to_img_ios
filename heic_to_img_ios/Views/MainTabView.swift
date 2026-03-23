//
//  MainTabView.swift
//  heic_to_img_ios
//
//  Created by firstfu on 2025/8/10.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var settings: ConversionSettings
    
    var body: some View {
        ZStack {
            // 背景漸層
            backgroundGradient
                .ignoresSafeArea()
            
            if appState.showWelcome && appState.isFirstLaunch {
                WelcomeView()
                    .transition(.opacity.combined(with: .scale))
            } else {
                tabContent
            }
        }
        .animation(AppAnimations.spring, value: appState.showWelcome)
        .alert("錯誤", isPresented: $appState.showErrorAlert) {
            Button("確定") {
                appState.clearError()
            }
        } message: {
            if let error = appState.currentError {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text(error.localizedDescription)
                    if let suggestion = error.recoverySuggestion {
                        Text(suggestion)
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
        }
        .sheet(isPresented: $appState.showProUpgrade) {
            ProUpgradeView()
        }
    }
    
    private var backgroundGradient: some View {
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
    }
    
    private var tabContent: some View {
        TabView(selection: $appState.currentTab) {
            // 轉換頁面
            ConversionView()
                .tabItem {
                    Label(AppTab.convert.title, systemImage: AppTab.convert.icon)
                }
                .tag(AppTab.convert)
            
            // 結果頁面
            ResultsView()
                .tabItem {
                    Label(AppTab.results.title, systemImage: AppTab.results.icon)
                }
                .tag(AppTab.results)
                .badge(appState.conversionResults.isEmpty ? 0 : appState.conversionResults.count)
            
            // 設定頁面
            SettingsView()
                .tabItem {
                    Label(AppTab.settings.title, systemImage: AppTab.settings.icon)
                }
                .tag(AppTab.settings)
        }
        .tint(AppColors.primaryBlue)
        .onAppear {
            configureTabBarAppearance()
        }
    }
    
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.1)
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - 歡迎頁面
struct WelcomeView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showContent = false
    @State private var animationOffset: CGFloat = 50
    
    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()
            
            // Logo 和標題
            VStack(spacing: AppSpacing.lg) {
                // App Icon 動畫
                ZStack {
                    // 背景光暈效果
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 90/255, green: 120/255, blue: 255/255).opacity(0.3),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 20,
                                endRadius: 100
                            )
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(showContent ? 1.2 : 0.8)
                        .opacity(showContent ? 0.6 : 0)
                        .animation(AppAnimations.spring.delay(0.1), value: showContent)
                    
                    Image(systemName: "photo.stack.fill")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 90/255, green: 120/255, blue: 255/255),
                                    Color(red: 150/255, green: 60/255, blue: 255/255)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(showContent ? 1.0 : 0.5)
                        .rotationEffect(.degrees(showContent ? 0 : -10))
                        .animation(AppAnimations.bouncy.delay(0.2), value: showContent)
                        .shadow(
                            color: Color(red: 90/255, green: 120/255, blue: 255/255).opacity(0.3),
                            radius: 20,
                            x: 0,
                            y: 10
                        )
                }
                
                // 標題文字
                VStack(spacing: AppSpacing.sm) {
                    Text("HEIC 極速轉檔專家")
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 90/255, green: 120/255, blue: 255/255),  // 更商業的藍色
                                    Color(red: 120/255, green: 80/255, blue: 255/255),   // 紫藍漸變
                                    Color(red: 150/255, green: 60/255, blue: 255/255)    // 深紫色
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .offset(y: showContent ? 0 : animationOffset)
                        .opacity(showContent ? 1 : 0)
                        .animation(AppAnimations.spring.delay(0.4), value: showContent)
                    
                    Text("一鍵轉換 • 極致品質 • 簡單易用")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundColor(Color.dynamic(
                            light: AppColors.textSecondary,
                            dark: AppColors.darkTextSecondary
                        ))
                        .multilineTextAlignment(.center)
                        .offset(y: showContent ? 0 : animationOffset)
                        .opacity(showContent ? 1 : 0)
                        .animation(AppAnimations.spring.delay(0.6), value: showContent)
                }
            }
            
            Spacer()
            
            // 功能特點
            VStack(spacing: AppSpacing.lg) {
                FeatureRow(
                    icon: "bolt.circle.fill",
                    title: "⚡ 極速轉換",
                    description: "一秒完成轉換，節省您的寶貴時間",
                    delay: 0.8,
                    gradientColors: [.orange, .pink]
                )
                
                FeatureRow(
                    icon: "photo.circle.fill",
                    title: "💎 頂級品質",
                    description: "保持原始畫質，完美呈現每個細節",
                    delay: 1.0,
                    gradientColors: [.green, .mint]
                )
                
                FeatureRow(
                    icon: "hand.tap.fill",
                    title: "🎯 簡單操作",
                    description: "選擇檔案，一鍵轉換，輕鬆搞定",
                    delay: 1.2,
                    gradientColors: [.blue, .purple]
                )
            }
            .offset(y: showContent ? 0 : animationOffset)
            .opacity(showContent ? 1 : 0)
            .animation(AppAnimations.spring.delay(1.4), value: showContent)
            
            Spacer()
            
            // 開始按鈕
            Button(action: {
                withAnimation(AppAnimations.spring) {
                    appState.showWelcome = false
                }
            }) {
                HStack(spacing: AppSpacing.sm) {
                    Text("立即體驗")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 18, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
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
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .shadow(
                    color: Color(red: 90/255, green: 120/255, blue: 255/255).opacity(0.4),
                    radius: 15,
                    x: 0,
                    y: 8
                )
            }
            .scaleEffect(showContent ? 1.0 : 0.8)
            .opacity(showContent ? 1 : 0)
            .animation(AppAnimations.bouncy.delay(1.6), value: showContent)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xl)
        }
        .padding(AppSpacing.lg)
        .onAppear {
            withAnimation {
                showContent = true
            }
        }
    }
}

// MARK: - 功能特點行
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let delay: Double
    let gradientColors: [Color]
    @State private var showContent = false
    @State private var pulseAnimation = false
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Icon with gradient background
            ZStack {
                // 背景圓圈
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: gradientColors.map { $0.opacity(0.2) }),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 45, height: 45)
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    .opacity(pulseAnimation ? 0.5 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(delay),
                        value: pulseAnimation
                    )
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: gradientColors),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .frame(width: 45)
            .scaleEffect(showContent ? 1.0 : 0.5)
            .animation(AppAnimations.bouncy.delay(delay), value: showContent)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.dynamic(
                        light: AppColors.textPrimary,
                        dark: AppColors.darkTextPrimary
                    ))
                
                Text(description)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(Color.dynamic(
                        light: AppColors.textSecondary,
                        dark: AppColors.darkTextSecondary
                    ))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(Color.dynamic(
                    light: Color.white.opacity(0.8),
                    dark: Color(red: 30/255, green: 30/255, blue: 50/255).opacity(0.5)
                ))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: gradientColors.map { $0.opacity(0.2) }),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(
            color: gradientColors.first?.opacity(0.1) ?? Color.clear,
            radius: 8,
            x: 0,
            y: 4
        )
        .opacity(showContent ? 1 : 0)
        .offset(x: showContent ? 0 : -30)
        .animation(AppAnimations.spring.delay(delay + 0.1), value: showContent)
        .onAppear {
            showContent = true
            pulseAnimation = true
        }
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
        .environmentObject(AppState())
        .environmentObject(ConversionSettings())
}