//
//  LaunchScreenView.swift
//  heic_to_img_ios
//
//  Created by firstfu on 2025/8/14.
//

import SwiftUI

/// ImageMaster 應用程式的啟動畫面
/// 提供品牌化的載入體驗，包含動畫和視覺效果
struct LaunchScreenView: View {
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0.0
    @State private var titleOpacity: Double = 0.0
    @State private var subtitleOpacity: Double = 0.0
    @State private var loadingOpacity: Double = 0.0
    @State private var pulseAnimation: Bool = false
    
    var body: some View {
        ZStack {
            // 背景漸層
            backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: AppSpacing.xl) {
                Spacer()
                
                // Logo 區域
                logoSection
                
                // 文字區域
                textSection
                
                Spacer()
                
                // 載入指示器
                loadingSection
            }
            .padding(AppSpacing.xl)
        }
        .onAppear {
            startAnimationSequence()
        }
    }
    
    // MARK: - 背景漸層
    private var backgroundGradient: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        AppColors.brandBlue,
                        AppColors.brandPurple
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
    
    // MARK: - Logo 區域
    private var logoSection: some View {
        VStack(spacing: AppSpacing.lg) {
            // App 圖示
            RoundedRectangle(cornerRadius: AppRadius.xl)
                .fill(Color.white.opacity(0.2))
                .frame(width: 120, height: 120)
                .overlay(
                    Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(.white)
                        .symbolEffect(.pulse, isActive: pulseAnimation)
                )
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
        }
    }
    
    // MARK: - 文字區域
    private var textSection: some View {
        VStack(spacing: AppSpacing.md) {
            // 主標題
            Text("ImageMaster")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .opacity(titleOpacity)
            
            // 副標題
            Text("HEIC 圖片轉換專家")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .opacity(subtitleOpacity)
        }
    }
    
    // MARK: - 載入指示器
    private var loadingSection: some View {
        VStack(spacing: AppSpacing.md) {
            // 脈動點指示器
            HStack(spacing: AppSpacing.sm) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 8, height: 8)
                        .scaleEffect(pulseAnimation ? 1.5 : 1.0)
                        .animation(
                            .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: pulseAnimation
                        )
                }
            }
            .opacity(loadingOpacity)
            
            // 載入文字
            Text("載入中...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .opacity(loadingOpacity)
        }
    }
    
    // MARK: - 動畫序列
    private func startAnimationSequence() {
        // 第一階段：Logo 淡入並放大 (0.0s - 0.5s)
        withAnimation(.easeOut(duration: 0.5)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // 第二階段：主標題淡入 (0.3s - 0.8s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.5)) {
                titleOpacity = 1.0
            }
        }
        
        // 第三階段：副標題淡入 (0.6s - 1.1s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.5)) {
                subtitleOpacity = 1.0
            }
        }
        
        // 第四階段：載入指示器淡入並開始脈動 (0.9s - 1.4s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.easeOut(duration: 0.5)) {
                loadingOpacity = 1.0
                pulseAnimation = true
            }
        }
    }
}

// MARK: - 預覽
#Preview("啟動畫面 - 淺色模式") {
    LaunchScreenView()
        .preferredColorScheme(.light)
}

#Preview("啟動畫面 - 深色模式") {
    LaunchScreenView()
        .preferredColorScheme(.dark)
}