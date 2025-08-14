//
//  TermsOfServiceView.swift
//  heic_to_img_ios
//
//  Created by firstfu on 2025/8/14.
//

import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                
                Text("使用者條款")
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
                    
                    // 服務條款
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("1. 服務條款")
                            .font(AppFonts.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.brandBlue)
                        
                        Text("歡迎使用 HEIC 轉檔專家（以下簡稱「本應用程式」）。使用本應用程式即表示您同意遵守以下使用者條款。如果您不同意這些條款，請勿使用本應用程式。")
                            .font(AppFonts.body)
                            .foregroundColor(Color.dynamic(
                                light: AppColors.textPrimary,
                                dark: AppColors.darkTextPrimary
                            ))
                    }
                    
                    // 服務說明
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("2. 服務說明")
                            .font(AppFonts.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.brandBlue)
                        
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("本應用程式提供以下服務：")
                                .font(AppFonts.body)
                                .foregroundColor(Color.dynamic(
                                    light: AppColors.textPrimary,
                                    dark: AppColors.darkTextPrimary
                                ))
                            
                            Text("• HEIC 格式圖片轉換為 PNG、JPEG 格式")
                                .font(AppFonts.body)
                                .foregroundColor(Color.dynamic(
                                    light: AppColors.textSecondary,
                                    dark: AppColors.darkTextSecondary
                                ))
                            
                            Text("• 批次處理多個圖片檔案")
                                .font(AppFonts.body)
                                .foregroundColor(Color.dynamic(
                                    light: AppColors.textSecondary,
                                    dark: AppColors.darkTextSecondary
                                ))
                            
                            Text("• 圖片品質和尺寸調整")
                                .font(AppFonts.body)
                                .foregroundColor(Color.dynamic(
                                    light: AppColors.textSecondary,
                                    dark: AppColors.darkTextSecondary
                                ))
                        }
                    }
                    
                    // 使用限制
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("3. 使用限制")
                            .font(AppFonts.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.brandBlue)
                        
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("使用本應用程式時，您同意不會：")
                                .font(AppFonts.body)
                                .foregroundColor(Color.dynamic(
                                    light: AppColors.textPrimary,
                                    dark: AppColors.darkTextPrimary
                                ))
                            
                            Text("• 上傳或轉換非法、有害或違反法律的內容")
                                .font(AppFonts.body)
                                .foregroundColor(Color.dynamic(
                                    light: AppColors.textSecondary,
                                    dark: AppColors.darkTextSecondary
                                ))
                            
                            Text("• 嘗試反向工程、解編譯或修改應用程式")
                                .font(AppFonts.body)
                                .foregroundColor(Color.dynamic(
                                    light: AppColors.textSecondary,
                                    dark: AppColors.darkTextSecondary
                                ))
                            
                            Text("• 干擾或破壞應用程式的正常運行")
                                .font(AppFonts.body)
                                .foregroundColor(Color.dynamic(
                                    light: AppColors.textSecondary,
                                    dark: AppColors.darkTextSecondary
                                ))
                            
                            Text("• 將應用程式用於商業用途（除非另有授權）")
                                .font(AppFonts.body)
                                .foregroundColor(Color.dynamic(
                                    light: AppColors.textSecondary,
                                    dark: AppColors.darkTextSecondary
                                ))
                        }
                    }
                    
                    // 智慧財產權
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("4. 智慧財產權")
                            .font(AppFonts.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.brandBlue)
                        
                        Text("本應用程式及其所有相關內容（包括但不限於軟體、設計、商標、標誌）均受智慧財產權法保護。您僅獲得有限的使用授權，不得複製、分發或創建衍生作品。")
                            .font(AppFonts.body)
                            .foregroundColor(Color.dynamic(
                                light: AppColors.textPrimary,
                                dark: AppColors.darkTextPrimary
                            ))
                    }
                    
                    // 免責聲明
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("5. 免責聲明")
                            .font(AppFonts.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.brandBlue)
                        
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("本應用程式按「現況」提供服務，我們不保證：")
                                .font(AppFonts.body)
                                .foregroundColor(Color.dynamic(
                                    light: AppColors.textPrimary,
                                    dark: AppColors.darkTextPrimary
                                ))
                            
                            Text("• 服務的連續性、準確性或可靠性")
                                .font(AppFonts.body)
                                .foregroundColor(Color.dynamic(
                                    light: AppColors.textSecondary,
                                    dark: AppColors.darkTextSecondary
                                ))
                            
                            Text("• 轉換結果的完美品質")
                                .font(AppFonts.body)
                                .foregroundColor(Color.dynamic(
                                    light: AppColors.textSecondary,
                                    dark: AppColors.darkTextSecondary
                                ))
                            
                            Text("• 服務不會中斷或出現錯誤")
                                .font(AppFonts.body)
                                .foregroundColor(Color.dynamic(
                                    light: AppColors.textSecondary,
                                    dark: AppColors.darkTextSecondary
                                ))
                        }
                    }
                    
                    // 責任限制
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("6. 責任限制")
                            .font(AppFonts.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.brandBlue)
                        
                        Text("在法律允許的最大範圍內，我們不對以下情況承擔責任：")
                            .font(AppFonts.body)
                            .foregroundColor(Color.dynamic(
                                light: AppColors.textPrimary,
                                dark: AppColors.darkTextPrimary
                            ))
                        
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("• 因使用或無法使用本應用程式而產生的任何損失")
                                .font(AppFonts.body)
                                .foregroundColor(Color.dynamic(
                                    light: AppColors.textSecondary,
                                    dark: AppColors.darkTextSecondary
                                ))
                            
                            Text("• 資料損失或設備損壞")
                                .font(AppFonts.body)
                                .foregroundColor(Color.dynamic(
                                    light: AppColors.textSecondary,
                                    dark: AppColors.darkTextSecondary
                                ))
                            
                            Text("• 間接、偶然或後果性損害")
                                .font(AppFonts.body)
                                .foregroundColor(Color.dynamic(
                                    light: AppColors.textSecondary,
                                    dark: AppColors.darkTextSecondary
                                ))
                        }
                    }
                    
                    // 服務變更與終止
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("7. 服務變更與終止")
                            .font(AppFonts.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.brandBlue)
                        
                        Text("我們保留隨時修改、暫停或終止服務的權利，無需事先通知。我們也可能因違反使用條款而終止您的使用權限。")
                            .font(AppFonts.body)
                            .foregroundColor(Color.dynamic(
                                light: AppColors.textPrimary,
                                dark: AppColors.darkTextPrimary
                            ))
                    }
                    
                    // 適用法律
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("8. 適用法律")
                            .font(AppFonts.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.brandBlue)
                        
                        Text("本使用者條款受中華民國法律管轄。任何爭議應由臺灣地區有管轄權的法院審理。")
                            .font(AppFonts.body)
                            .foregroundColor(Color.dynamic(
                                light: AppColors.textPrimary,
                                dark: AppColors.darkTextPrimary
                            ))
                    }
                    
                    // 條款變更
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("9. 條款變更")
                            .font(AppFonts.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.brandBlue)
                        
                        Text("我們可能會不定期更新本使用者條款。重大變更將透過應用程式內通知或其他適當方式告知使用者。繼續使用應用程式即表示您接受更新後的條款。")
                            .font(AppFonts.body)
                            .foregroundColor(Color.dynamic(
                                light: AppColors.textPrimary,
                                dark: AppColors.darkTextPrimary
                            ))
                    }
                    
                    // 聯絡資訊
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("10. 聯絡我們")
                            .font(AppFonts.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.brandBlue)
                        
                        Text("如果您對本使用者條款有任何疑問，請透過以下方式聯絡我們：")
                            .font(AppFonts.body)
                            .foregroundColor(Color.dynamic(
                                light: AppColors.textPrimary,
                                dark: AppColors.darkTextPrimary
                            ))
                        
                        Text("電子郵件：\(AppConstants.supportEmail)")
                            .font(AppFonts.body)
                            .foregroundColor(AppColors.brandBlue)
                    }
                }
            }
            .padding(AppSpacing.lg)
        }
        .navigationTitle("使用者條款")
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
        TermsOfServiceView()
    }
}