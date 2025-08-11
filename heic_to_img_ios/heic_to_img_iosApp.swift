/*
 * 功能：HEIC 圖片轉換應用程式的主入口點
 * 
 * 描述：定義 iOS 應用程式的主結構體和生命週期管理
 * - 管理應用程式級別的狀態對象
 * - 配置全局環境物件（轉換設定和應用狀態）
 * - 設定主要視窗和顏色主題
 * 
 * 創建時間：2025/8/10
 * 作者：firstfu
 */

//
//  heic_to_img_iosApp.swift
//  heic_to_img_ios
//
//  Created by firstfu on 2025/8/10.
//

import SwiftUI

/// HEIC Master Pro 應用程式的主結構體
/// 負責應用程式的啟動和全局狀態管理
@main
struct HeicMasterProApp: App {
    /// 轉換設定的狀態對象，管理格式、品質等轉換參數
    @StateObject private var conversionSettings = ConversionSettings()
    
    /// 應用程式狀態對象，管理主題、UI 狀態等全局設定
    @StateObject private var appState = AppState()
    
    /// 定義應用程式的場景配置
    var body: some Scene {
        WindowGroup {
            MainTabView()
                // 將轉換設定注入到環境中，供子視圖使用
                .environmentObject(conversionSettings)
                // 將應用狀態注入到環境中，供子視圖使用
                .environmentObject(appState)
                // 根據應用狀態設定顏色主題（淺色/深色模式）
                .preferredColorScheme(appState.colorScheme)
        }
    }
}
