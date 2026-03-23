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
    @State private var showClearConfirmation = false
    
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
                // Pro 版本狀態
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            if appState.isPro {
                                Text("HEIC 轉檔專家 Pro")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(AppColors.brandBlue)

                                Text("專業版已啟用")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(AppColors.successGreen)
                            } else {
                                Text("HEIC 轉檔專家")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color.dynamic(
                                        light: AppColors.textPrimary,
                                        dark: AppColors.darkTextPrimary
                                    ))

                                Text("今日剩餘 \(appState.remainingFreeConversions) 次免費轉換")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(AppColors.warningOrange)
                            }
                        }

                        Spacer()

                        if !appState.isPro {
                            Button("升級") {
                                appState.showProUpgrade = true
                            }
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(AppColors.brandBlue)
                        }
                    }
                }
                
                // 批次處理設定
                Section(header: Text("批次處理設定").foregroundColor(Color.dynamic(
                    light: AppColors.textSecondary,
                    dark: AppColors.darkTextSecondary
                ))) {
                    // 檔案數量限制資訊
                    HStack {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("單次轉換限制")
                                .foregroundColor(Color.dynamic(
                                    light: AppColors.textPrimary,
                                    dark: AppColors.darkTextPrimary
                                ))
                            
                            Text("最多 \(ProcessingLimits.maxBatchFiles) 個檔案 / \(ProcessingLimits.maxTotalSizeMB)MB")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.dynamic(
                                    light: AppColors.textSecondary,
                                    dark: AppColors.darkTextSecondary
                                ))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "doc.on.doc.fill")
                            .foregroundColor(AppColors.brandBlue)
                    }
                    
                    // ZIP 打包限制資訊
                    HStack {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("ZIP 打包限制")
                                .foregroundColor(Color.dynamic(
                                    light: AppColors.textPrimary,
                                    dark: AppColors.darkTextPrimary
                                ))
                            
                            Text("最多 \(ProcessingLimits.maxZipFiles) 個檔案 / \(ProcessingLimits.maxZipSizeMB)MB")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.dynamic(
                                    light: AppColors.textSecondary,
                                    dark: AppColors.darkTextSecondary
                                ))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "archivebox.fill")
                            .foregroundColor(AppColors.brandBlue)
                    }
                    
                    // 自動分割說明
                    HStack {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("智能分割")
                                .foregroundColor(Color.dynamic(
                                    light: AppColors.textPrimary,
                                    dark: AppColors.darkTextPrimary
                                ))
                            
                            Text("超過 \(ProcessingLimits.autoSplitZipThreshold) 個檔案時自動分割")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.dynamic(
                                    light: AppColors.textSecondary,
                                    dark: AppColors.darkTextSecondary
                                ))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "scissors")
                            .foregroundColor(.orange)
                    }
                }
                
                // 關於
                Section(header: Text("關於應用程式").foregroundColor(Color.dynamic(
                    light: AppColors.textSecondary,
                    dark: AppColors.darkTextSecondary
                ))) {
                    HStack {
                        Text("版本")
                            .foregroundColor(Color.dynamic(
                                light: AppColors.textPrimary,
                                dark: AppColors.darkTextPrimary
                            ))
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(Color.dynamic(
                                light: AppColors.textSecondary,
                                dark: AppColors.darkTextSecondary
                            ))
                    }
                    
                    Button("聯絡我們") {
                        if let url = URL(string: "mailto:\(AppConstants.supportEmail)") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .foregroundColor(AppColors.brandBlue)
                    
                    NavigationLink(destination: PrivacyPolicyView()) {
                        Text("隱私權政策")
                            .foregroundColor(AppColors.brandBlue)
                    }
                    
                    NavigationLink(destination: TermsOfServiceView()) {
                        Text("使用者條款")
                            .foregroundColor(AppColors.brandBlue)
                    }
                    
                    if !appState.isPro {
                        Button("恢復購買") {
                            appState.restorePurchases()
                        }
                        .foregroundColor(AppColors.brandBlue)
                    }

                    Button("重置設定") {
                        settings.reset()
                    }
                    .foregroundColor(AppColors.warningOrange)

                    Button("清除轉換記錄") {
                        showClearConfirmation = true
                    }
                    .foregroundColor(.red)
                }
            }
            .scrollContentBackground(.hidden)
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
            .alert("確認清除", isPresented: $showClearConfirmation) {
                Button("取消", role: .cancel) { }
                Button("清除", role: .destructive) {
                    clearConversionRecords()
                }
            } message: {
                Text("確定要清除所有轉換記錄和檔案嗎？此操作無法復原。")
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private func clearConversionRecords() {
        // 刪除所有本地檔案
        for result in appState.conversionResults {
            try? FileManager.default.removeItem(at: result.outputURL)
        }
        
        // 清除轉換記錄
        appState.conversionResults.removeAll()
        
        // 清除統計資料
        appState.lastConversionStats = nil
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
        .environmentObject(ConversionSettings())
}