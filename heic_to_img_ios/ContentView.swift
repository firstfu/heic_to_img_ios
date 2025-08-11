/*
 * 功能：應用程式內容視圖（備用入口點）
 * 
 * 描述：提供應用程式的備用內容視圖
 * - 作為 MainTabView 的包裝器
 * - 設置環境對象供子視圖使用
 * - 主要用於開發和測試目的
 * 
 * 注意：主要入口點現在是 MainTabView，此文件保留作為備用
 * 
 * 創建時間：2025/8/10
 * 作者：firstfu
 */

//
//  ContentView.swift
//  heic_to_img_ios
//
//  Created by firstfu on 2025/8/10.
//

import SwiftUI

/// 備用內容視圖結構體
/// 包裝主要的 TabView 介面並提供環境對象
struct ContentView: View {
    /// 視圖主體，包含主要的標籤頁視圖
    var body: some View {
        MainTabView()
            // 注入應用狀態環境對象
            .environmentObject(AppState())
            // 注入轉換設定環境對象
            .environmentObject(ConversionSettings())
    }
}

/// SwiftUI 預覽
/// 用於 Xcode 預覽和設計時測試
#Preview {
    ContentView()
}
