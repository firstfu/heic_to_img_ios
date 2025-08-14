//
//  PrivacyPolicyView.swift
//  heic_to_img_ios
//
//  Created by firstfu on 2025/8/14.
//

import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                
                Text("隱私權政策")
                    .font(AppFonts.title1)
                    .fontWeight(.bold)
                    .foregroundColor(Color.dynamic(
                        light: AppColors.textPrimary,
                        dark: AppColors.darkTextPrimary
                    ))
                    .padding(.top, AppSpacing.md)
                
                Text("最後更新日期：2025年8月")
                    .font(AppFonts.caption)
                    .foregroundColor(Color.dynamic(
                        light: AppColors.textSecondary,
                        dark: AppColors.darkTextSecondary
                    ))
                
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    
                    // 前言
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("前言")
                            .font(AppFonts.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.brandBlue)
                        
                        Text("HEIC 轉檔專家（以下簡稱「本應用程式」）重視您的隱私權。本隱私權政策說明我們如何收集、使用和保護您的個人資訊。")
                            .font(AppFonts.body)
                            .foregroundColor(Color.dynamic(
                                light: AppColors.textPrimary,
                                dark: AppColors.darkTextPrimary
                            ))
                    }
                    
                    // 資料收集
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("1. 資料收集")
                            .font(AppFonts.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.brandBlue)
                        
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("我們收集的資訊包括：")
                                .font(AppFonts.body)
                                .foregroundColor(Color.dynamic(
                                    light: AppColors.textPrimary,
                                    dark: AppColors.darkTextPrimary
                                ))
                            
                            Text("• 您主動上傳的 HEIC 圖片檔案")
                                .font(AppFonts.body)
                                .foregroundColor(Color.dynamic(
                                    light: AppColors.textSecondary,
                                    dark: AppColors.darkTextSecondary
                                ))
                            
                            Text("• 應用程式使用統計（如轉換次數、轉換格式偏好）")
                                .font(AppFonts.body)
                                .foregroundColor(Color.dynamic(
                                    light: AppColors.textSecondary,
                                    dark: AppColors.darkTextSecondary
                                ))
                            
                            Text("• 裝置資訊（iOS 版本、裝置型號）")
                                .font(AppFonts.body)
                                .foregroundColor(Color.dynamic(
                                    light: AppColors.textSecondary,
                                    dark: AppColors.darkTextSecondary
                                ))
                        }
                    }
                    
                    // 資料使用
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("2. 資料使用")
                            .font(AppFonts.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.brandBlue)
                        
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("我們使用您的資訊用於：")
                                .font(AppFonts.body)
                                .foregroundColor(Color.dynamic(
                                    light: AppColors.textPrimary,
                                    dark: AppColors.darkTextPrimary
                                ))
                            
                            Text("• 提供 HEIC 圖片轉換服務")
                                .font(AppFonts.body)
                                .foregroundColor(Color.dynamic(
                                    light: AppColors.textSecondary,
                                    dark: AppColors.darkTextSecondary
                                ))
                            
                            Text("• 改善應用程式功能和使用者體驗")
                                .font(AppFonts.body)
                                .foregroundColor(Color.dynamic(
                                    light: AppColors.textSecondary,
                                    dark: AppColors.darkTextSecondary
                                ))
                            
                            Text("• 提供技術支援和客戶服務")
                                .font(AppFonts.body)
                                .foregroundColor(Color.dynamic(
                                    light: AppColors.textSecondary,
                                    dark: AppColors.darkTextSecondary
                                ))
                        }
                    }
                    
                    // 資料儲存與安全
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("3. 資料儲存與安全")
                            .font(AppFonts.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.brandBlue)
                        
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("• 您的圖片僅在本機裝置上處理，不會上傳至我們的伺服器")
                                .font(AppFonts.body)
                                .foregroundColor(Color.dynamic(
                                    light: AppColors.textSecondary,
                                    dark: AppColors.darkTextSecondary
                                ))
                            
                            Text("• 轉換後的圖片儲存在您的裝置本機儲存空間")
                                .font(AppFonts.body)
                                .foregroundColor(Color.dynamic(
                                    light: AppColors.textSecondary,
                                    dark: AppColors.darkTextSecondary
                                ))
                            
                            Text("• 我們採用業界標準的安全措施保護您的資料")
                                .font(AppFonts.body)
                                .foregroundColor(Color.dynamic(
                                    light: AppColors.textSecondary,
                                    dark: AppColors.darkTextSecondary
                                ))
                        }
                    }
                    
                    // 資料分享
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("4. 資料分享")
                            .font(AppFonts.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.brandBlue)
                        
                        Text("我們不會將您的個人資料出售、出租或分享給第三方，除非：")
                            .font(AppFonts.body)
                            .foregroundColor(Color.dynamic(
                                light: AppColors.textPrimary,
                                dark: AppColors.darkTextPrimary
                            ))
                        
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("• 獲得您的明確同意")
                                .font(AppFonts.body)
                                .foregroundColor(Color.dynamic(
                                    light: AppColors.textSecondary,
                                    dark: AppColors.darkTextSecondary
                                ))
                            
                            Text("• 法律要求或政府機關要求")
                                .font(AppFonts.body)
                                .foregroundColor(Color.dynamic(
                                    light: AppColors.textSecondary,
                                    dark: AppColors.darkTextSecondary
                                ))
                        }
                    }
                    
                    // 使用者權利
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("5. 您的權利")
                            .font(AppFonts.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.brandBlue)
                        
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("您有權：")
                                .font(AppFonts.body)
                                .foregroundColor(Color.dynamic(
                                    light: AppColors.textPrimary,
                                    dark: AppColors.darkTextPrimary
                                ))
                            
                            Text("• 隨時刪除應用程式和相關資料")
                                .font(AppFonts.body)
                                .foregroundColor(Color.dynamic(
                                    light: AppColors.textSecondary,
                                    dark: AppColors.darkTextSecondary
                                ))
                            
                            Text("• 要求我們刪除您的使用統計資料")
                                .font(AppFonts.body)
                                .foregroundColor(Color.dynamic(
                                    light: AppColors.textSecondary,
                                    dark: AppColors.darkTextSecondary
                                ))
                            
                            Text("• 隨時聯絡我們詢問隱私權相關問題")
                                .font(AppFonts.body)
                                .foregroundColor(Color.dynamic(
                                    light: AppColors.textSecondary,
                                    dark: AppColors.darkTextSecondary
                                ))
                        }
                    }
                    
                    // 聯絡資訊
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("6. 聯絡我們")
                            .font(AppFonts.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.brandBlue)
                        
                        Text("如果您對本隱私權政策有任何疑問，請透過以下方式聯絡我們：")
                            .font(AppFonts.body)
                            .foregroundColor(Color.dynamic(
                                light: AppColors.textPrimary,
                                dark: AppColors.darkTextPrimary
                            ))
                        
                        Text("電子郵件：\(AppConstants.supportEmail)")
                            .font(AppFonts.body)
                            .foregroundColor(AppColors.brandBlue)
                    }
                    
                    // 政策更新
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("7. 政策更新")
                            .font(AppFonts.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.brandBlue)
                        
                        Text("我們可能會不定期更新本隱私權政策。任何重大變更都會透過應用程式內通知或其他適當方式告知您。")
                            .font(AppFonts.body)
                            .foregroundColor(Color.dynamic(
                                light: AppColors.textPrimary,
                                dark: AppColors.darkTextPrimary
                            ))
                    }
                }
            }
            .padding(AppSpacing.lg)
        }
        .navigationTitle("隱私權政策")
        .navigationBarTitleDisplayMode(.large)
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
    }
}

#Preview {
    NavigationView {
        PrivacyPolicyView()
    }
}