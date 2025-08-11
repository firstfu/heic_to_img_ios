//
//  AnimatedComponents.swift
//  heic_to_img_ios
//
//  Created by firstfu on 2025/8/10.
//

import SwiftUI

// MARK: - 現代化環形進度指示器
struct CircularProgressView: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    
    @State private var animatedProgress: Double = 0
    @State private var showPercentage = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3
    
    init(progress: Double, lineWidth: CGFloat = 15, size: CGFloat = 150) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // 背景模糊圓圈
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 34/255, green: 197/255, blue: 94/255).opacity(0.05),
                            Color(red: 6/255, green: 182/255, blue: 212/255).opacity(0.02)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size + 20, height: size + 20)
                .scaleEffect(pulseScale)
                .blur(radius: 10)
            
            // 內層背景圓環
            Circle()
                .stroke(
                    Color.dynamic(
                        light: Color.gray.opacity(0.15),
                        dark: Color.white.opacity(0.1)
                    ),
                    lineWidth: lineWidth * 0.6
                )
                .frame(width: size, height: size)
            
            // 主背景圓環
            Circle()
                .stroke(
                    Color.dynamic(
                        light: Color.gray.opacity(0.08),
                        dark: Color.white.opacity(0.05)
                    ),
                    lineWidth: lineWidth
                )
                .frame(width: size, height: size)
            
            // 發光進度圓環 (背景層)
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 34/255, green: 197/255, blue: 94/255).opacity(0.4),
                            Color(red: 6/255, green: 182/255, blue: 212/255).opacity(0.3)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(
                        lineWidth: lineWidth * 1.5,
                        lineCap: .round
                    )
                )
                .frame(width: size, height: size)
                .rotationEffect(Angle(degrees: -90))
                .blur(radius: 6)
                .opacity(glowOpacity)
            
            // 主進度圓環
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 34/255, green: 197/255, blue: 94/255),    // 翠綠色
                            Color(red: 6/255, green: 182/255, blue: 212/255)      // 青色
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .frame(width: size, height: size)
                .rotationEffect(Angle(degrees: -90))
                .animation(.spring(response: 0.8, dampingFraction: 0.8), value: animatedProgress)
            
            // 進度端點光暈
            if animatedProgress > 0 {
                Circle()
                    .fill(Color(red: 34/255, green: 197/255, blue: 94/255))
                    .frame(width: lineWidth + 4, height: lineWidth + 4)
                    .position(
                        x: size / 2 + (size / 2) * cos(2 * .pi * animatedProgress - .pi / 2),
                        y: size / 2 + (size / 2) * sin(2 * .pi * animatedProgress - .pi / 2)
                    )
                    .shadow(color: Color(red: 34/255, green: 197/255, blue: 94/255), radius: 8)
                    .opacity(animatedProgress > 0 ? 1 : 0)
            }
            
            // 中心內容區
            ZStack {
                // 內部背景
                Circle()
                    .fill(
                        Color.dynamic(
                            light: Color.white.opacity(0.9),
                            dark: Color(red: 25/255, green: 25/255, blue: 45/255).opacity(0.9)
                        )
                    )
                    .frame(width: size * 0.7, height: size * 0.7)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 34/255, green: 197/255, blue: 94/255).opacity(0.1),
                                        Color(red: 6/255, green: 182/255, blue: 212/255).opacity(0.05)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                
                // 進度百分比
                VStack(spacing: 2) {
                    Text("\(Int(animatedProgress * 100))")
                        .font(.system(size: size * 0.25, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 34/255, green: 197/255, blue: 94/255),
                                    Color(red: 6/255, green: 182/255, blue: 212/255)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(showPercentage ? 1.0 : 0.5)
                        .opacity(showPercentage ? 1.0 : 0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showPercentage)
                    
                    Text("%")
                        .font(.system(size: size * 0.1, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.dynamic(
                            light: AppColors.textSecondary,
                            dark: AppColors.darkTextSecondary
                        ))
                        .opacity(showPercentage ? 0.8 : 0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.1), value: showPercentage)
                }
            }
        }
        .onAppear {
            // 開始動畫
            withAnimation(.easeOut(duration: 1.0)) {
                animatedProgress = progress
            }
            
            // 延遲顯示百分比
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showPercentage = true
                }
            }
            
            // 脈動效果
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
            }
            
            // 發光效果
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowOpacity = 0.6
            }
        }
        .onChange(of: progress) { newValue in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - 成功動畫視圖
struct SuccessAnimationView: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var checkmarkProgress: CGFloat = 0
    @State private var circleRotation: Double = 0
    @State private var showParticles = false
    
    let size: CGFloat
    let onComplete: (() -> Void)?
    
    init(size: CGFloat = 100, onComplete: (() -> Void)? = nil) {
        self.size = size
        self.onComplete = onComplete
    }
    
    var body: some View {
        ZStack {
            // 背景圓圈
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 34/255, green: 197/255, blue: 94/255).opacity(0.1),
                            Color(red: 34/255, green: 197/255, blue: 94/255).opacity(0.2)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .scaleEffect(scale * 1.2)
                .opacity(opacity * 0.5)
            
            // 主圓圈
            Circle()
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 34/255, green: 197/255, blue: 94/255),
                            Color(red: 16/255, green: 185/255, blue: 129/255)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: size, height: size)
                .scaleEffect(scale)
                .rotationEffect(.degrees(circleRotation))
                .opacity(opacity)
            
            // 勾勾動畫
            CheckmarkShape()
                .trim(from: 0, to: checkmarkProgress)
                .stroke(
                    Color(red: 34/255, green: 197/255, blue: 94/255),
                    style: StrokeStyle(
                        lineWidth: size * 0.06,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .frame(width: size * 0.5, height: size * 0.5)
                .opacity(opacity)
            
            // 粒子效果
            if showParticles {
                ForEach(0..<8, id: \.self) { index in
                    ParticleView(
                        color: Color(red: 34/255, green: 197/255, blue: 94/255),
                        size: size * 0.05,
                        delay: Double(index) * 0.05
                    )
                    .offset(
                        x: cos(Double(index) * .pi / 4) * size * 0.7,
                        y: sin(Double(index) * .pi / 4) * size * 0.7
                    )
                }
            }
        }
        .onAppear {
            // 階段 1: 圓圈出現
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
            
            // 階段 2: 圓圈旋轉
            withAnimation(.linear(duration: 0.3).delay(0.2)) {
                circleRotation = 360
            }
            
            // 階段 3: 勾勾動畫
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                checkmarkProgress = 1.0
            }
            
            // 階段 4: 粒子效果
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                showParticles = true
            }
            
            // 完成回調
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                onComplete?()
            }
        }
    }
}

// MARK: - 勾勾形狀
struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        // 定義勾勾的三個點
        let start = CGPoint(x: width * 0.2, y: height * 0.5)
        let middle = CGPoint(x: width * 0.45, y: height * 0.7)
        let end = CGPoint(x: width * 0.8, y: height * 0.3)
        
        path.move(to: start)
        path.addLine(to: middle)
        path.addLine(to: end)
        
        return path
    }
}

// MARK: - 粒子視圖
struct ParticleView: View {
    let color: Color
    let size: CGFloat
    let delay: Double
    
    @State private var offset: CGSize = .zero
    @State private var opacity: Double = 1
    @State private var scale: CGFloat = 1
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .scaleEffect(scale)
            .opacity(opacity)
            .offset(offset)
            .onAppear {
                withAnimation(.easeOut(duration: 1.0).delay(delay)) {
                    offset = CGSize(
                        width: CGFloat.random(in: -50...50),
                        height: CGFloat.random(in: -100...(-50))
                    )
                    opacity = 0
                    scale = 0.3
                }
            }
    }
}

// MARK: - 波紋動畫視圖
struct RippleEffectView: View {
    @State private var ripples: [RippleData] = []
    let color: Color
    
    var body: some View {
        ZStack {
            ForEach(ripples) { ripple in
                Circle()
                    .stroke(color.opacity(ripple.opacity), lineWidth: 2)
                    .scaleEffect(ripple.scale)
                    .opacity(ripple.opacity)
                    .animation(.easeOut(duration: 1.5), value: ripple.scale)
            }
        }
        .onAppear {
            startRippleAnimation()
        }
    }
    
    private func startRippleAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { _ in
            let newRipple = RippleData()
            ripples.append(newRipple)
            
            withAnimation(.easeOut(duration: 1.5)) {
                if let index = ripples.firstIndex(where: { $0.id == newRipple.id }) {
                    ripples[index].scale = 2.0
                    ripples[index].opacity = 0
                }
            }
            
            // 清理完成的波紋
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                ripples.removeAll { $0.id == newRipple.id }
            }
        }
    }
}

struct RippleData: Identifiable {
    let id = UUID()
    var scale: CGFloat = 0.5
    var opacity: Double = 0.8
}

// MARK: - 脈動按鈕
struct PulsatingButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    @State private var isPulsating = false
    @State private var isPressed = false
    
    init(title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                action()
            }
        }) {
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    // 脈動層
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 80/255, green: 70/255, blue: 230/255),
                                    Color(red: 124/255, green: 58/255, blue: 237/255)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(isPulsating ? 1.05 : 1.0)
                        .opacity(isPulsating ? 0.8 : 0)
                    
                    // 主按鈕層
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 80/255, green: 70/255, blue: 230/255),
                                    Color(red: 124/255, green: 58/255, blue: 237/255)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .shadow(
                color: Color(red: 80/255, green: 70/255, blue: 230/255).opacity(0.4),
                radius: isPulsating ? 20 : 10,
                x: 0,
                y: 5
            )
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isPulsating = true
            }
        }
    }
}

// MARK: - 檔案卡片動畫
struct AnimatedFileCard: View {
    let fileName: String
    let fileSize: String
    let isProcessing: Bool
    
    @State private var appear = false
    @State private var processingRotation: Double = 0
    
    var body: some View {
        HStack(spacing: 16) {
            // 檔案圖示
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 90/255, green: 120/255, blue: 255/255).opacity(0.1),
                                Color(red: 150/255, green: 60/255, blue: 255/255).opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Image(systemName: isProcessing ? "arrow.triangle.2.circlepath" : "photo.fill")
                    .font(.system(size: 24, weight: .medium))
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
                    .rotationEffect(.degrees(isProcessing ? processingRotation : 0))
            }
            
            // 檔案資訊
            VStack(alignment: .leading, spacing: 4) {
                Text(fileName)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(Color.dynamic(
                        light: AppColors.textPrimary,
                        dark: AppColors.darkTextPrimary
                    ))
                    .lineLimit(1)
                
                Text(fileSize)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(Color.dynamic(
                        light: AppColors.textSecondary,
                        dark: AppColors.darkTextSecondary
                    ))
            }
            
            Spacer()
            
            // 狀態指示器
            if isProcessing {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.dynamic(
                    light: Color.white,
                    dark: Color(red: 30/255, green: 30/255, blue: 50/255)
                ))
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: 5,
                    x: 0,
                    y: 2
                )
        )
        .scaleEffect(appear ? 1.0 : 0.8)
        .opacity(appear ? 1.0 : 0)
        .offset(y: appear ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appear = true
            }
            
            if isProcessing {
                withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                    processingRotation = 360
                }
            }
        }
    }
}