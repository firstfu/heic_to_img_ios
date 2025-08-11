//
//  SettingsView.swift
//  heic_to_img_ios
//
//  Created by firstfu on 2025/8/10.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var settings: ConversionSettings
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景層 - 放在最底層
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
                
                Form {
                // MVP 版本：顯示免費完整版本狀態
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("HEIC 轉檔專家")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(AppColors.brandBlue)
                            
                            Text("免費完整版")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(AppColors.successGreen)
                        }
                        
                        Spacer()
                    }
                }
                
                // 原始 Pro 狀態區塊 - 已註解
                // Section {
                //     HStack {
                //         VStack(alignment: .leading, spacing: AppSpacing.xs) {
                //             if appState.isPro {
                //                 Text("HEIC 轉檔專家 Pro")
                //                     .font(.system(size: 16, weight: .semibold, design: .rounded))
                //                     .foregroundColor(AppColors.brandBlue)
                //                 
                //                 Text("專業版已啟用")
                //                     .font(.system(size: 12, weight: .medium, design: .rounded))
                //                     .foregroundColor(AppColors.successGreen)
                //             } else {
                //                 Text("HEIC 轉檔專家")
                //                     .font(.system(size: 16, weight: .semibold, design: .rounded))
                //                     .foregroundColor(AppColors.textPrimary)
                //                 
                //                 Text("剩餘 \(appState.remainingFreeConversions) 次轉換")
                //                     .font(.system(size: 12, weight: .medium, design: .rounded))
                //                     .foregroundColor(AppColors.warningOrange)
                //             }
                //         }
                //         
                //         Spacer()
                //         
                //         if !appState.isPro {
                //             Button("升級") {
                //                 appState.showProUpgrade = true
                //             }
                //             .font(.system(size: 14, weight: .semibold, design: .rounded))
                //             .foregroundColor(AppColors.brandBlue)
                //         }
                //     }
                // }
                
                // 關於
                Section("關於應用程式") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    Button("聯絡我們") {
                        if let url = URL(string: "mailto:\(AppConstants.supportEmail)") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .foregroundColor(AppColors.brandBlue)
                    
                    Button("重置設定") {
                        settings.reset()
                    }
                    .foregroundColor(AppColors.warningOrange)
                }
            }
            .scrollContentBackground(.hidden)
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
        .environmentObject(ConversionSettings())
}