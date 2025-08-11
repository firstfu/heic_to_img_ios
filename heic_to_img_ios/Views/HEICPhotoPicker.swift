//
//  HEICPhotoPicker.swift
//  heic_to_img_ios
//
//  Created by firstfu on 2025/8/10.
//

import SwiftUI
import Photos
import PhotosUI

// MARK: - HEIC 專用相片選擇器
struct HEICPhotoPicker: View {
    @Environment(\.dismiss) private var dismiss
    @State private var heicAssets: [PHAsset] = []
    @State private var selectedAssets: Set<String> = []
    @State private var isLoading = true
    @State private var thumbnailCache: [String: UIImage] = [:]
    @State private var showNoHEICAlert = false
    
    let onFilesSelected: ([FileItem]) -> Void
    
    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 2)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                Color.dynamic(
                    light: Color(UIColor.systemBackground),
                    dark: Color(red: 15/255, green: 15/255, blue: 25/255)
                )
                .ignoresSafeArea()
                
                if isLoading {
                    // 載入中
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(AppColors.primaryBlue)
                        
                        Text("正在搜尋 HEIC 圖片...")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                    }
                } else if heicAssets.isEmpty {
                    // 沒有 HEIC 圖片
                    VStack(spacing: 20) {
                        Image(systemName: "photo.badge.exclamationmark")
                            .font(.system(size: 60))
                            .foregroundColor(AppColors.textTertiary)
                        
                        Text("未找到 HEIC 格式圖片")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("您的相簿中沒有 HEIC 格式的圖片。\n請使用 iPhone 7 或更新機型拍攝照片。")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button("關閉") {
                            dismiss()
                        }
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(AppColors.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                } else {
                    // 顯示 HEIC 圖片網格
                    VStack(spacing: 0) {
                        // 選擇狀態欄
                        if !selectedAssets.isEmpty {
                            HStack {
                                Text("已選擇 \(selectedAssets.count) 張圖片")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(AppColors.textSecondary)
                                
                                Spacer()
                                
                                Button("清除選擇") {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedAssets.removeAll()
                                    }
                                }
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(AppColors.primaryBlue)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                Color.dynamic(
                                    light: AppColors.primaryBlue.opacity(0.05),
                                    dark: AppColors.primaryBlue.opacity(0.1)
                                )
                            )
                        }
                        
                        // 圖片網格
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 2) {
                                ForEach(heicAssets, id: \.localIdentifier) { asset in
                                    HEICPhotoCell(
                                        asset: asset,
                                        isSelected: selectedAssets.contains(asset.localIdentifier),
                                        thumbnail: thumbnailCache[asset.localIdentifier]
                                    ) {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            toggleSelection(for: asset)
                                        }
                                    }
                                    .onAppear {
                                        loadThumbnail(for: asset)
                                    }
                                }
                            }
                            .padding(2)
                        }
                    }
                }
            }
            .navigationTitle("選擇 HEIC 圖片")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.primaryBlue)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        processSelectedAssets()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(selectedAssets.isEmpty ? AppColors.textTertiary : AppColors.primaryBlue)
                    .disabled(selectedAssets.isEmpty)
                }
            }
        }
        .onAppear {
            loadHEICAssets()
        }
        .alert("沒有找到 HEIC 圖片", isPresented: $showNoHEICAlert) {
            Button("確定") {
                dismiss()
            }
        } message: {
            Text("您的相簿中沒有 HEIC 格式的圖片。")
        }
    }
    
    // MARK: - 載入 HEIC 資源
    private func loadHEICAssets() {
        Task {
            // 先檢查當前權限狀態
            let currentStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            var status = currentStatus
            
            // 如果尚未決定，才請求權限
            if currentStatus == .notDetermined {
                status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            }
            
            // 處理不同的權限狀態
            guard status == .authorized || status == .limited else {
                await MainActor.run {
                    isLoading = false
                    
                    // 根據不同狀態顯示不同的錯誤訊息
                    if status == .denied {
                        print("❌ 權限被拒絕，請在設定中開啟相簿權限")
                    } else if status == .restricted {
                        print("❌ 權限受限，可能是家長控制或企業管理限制")
                    }
                    
                    showNoHEICAlert = true
                }
                return
            }
            
            // 如果是有限權限，提示使用者
            if status == .limited {
                print("⚠️ 有限相簿存取權限，只能存取使用者選擇的照片")
            }
            
            // 獲取所有圖片資源
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            
            let allAssets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            
            // 在背景執行緒中逐步處理，並在主執行緒上更新 UI
            DispatchQueue.global(qos: .userInitiated).async {
                var foundHeic = false
                
                allAssets.enumerateObjects { (asset, _, stop) in
                    let resources = PHAssetResource.assetResources(for: asset)
                    for resource in resources {
                        let uti = resource.uniformTypeIdentifier.lowercased()
                        if uti.contains("heic") || uti.contains("heif") ||
                           uti == "public.heic" || uti == "public.heif" ||
                           resource.originalFilename.lowercased().hasSuffix(".heic") ||
                           resource.originalFilename.lowercased().hasSuffix(".heif") {
                            
                            // 在主執行緒上更新 UI
                            DispatchQueue.main.async {
                                if !foundHeic {
                                    // 找到第一張後，就關閉載入提示
                                    self.isLoading = false
                                    foundHeic = true
                                }
                                self.heicAssets.append(asset)
                            }
                            break
                        }
                    }
                }
                
                // 迴圈結束後，如果一張都沒找到，則顯示提示
                DispatchQueue.main.async {
                    if !foundHeic {
                        self.isLoading = false
                        self.showNoHEICAlert = true
                    }
                }
            }
        }
    }
    
    // MARK: - 載入縮圖
    private func loadThumbnail(for asset: PHAsset) {
        guard thumbnailCache[asset.localIdentifier] == nil else { return }
        
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.resizeMode = .fast
        options.deliveryMode = .opportunistic
        
        let targetSize = CGSize(width: 200, height: 200)
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            if let image = image {
                DispatchQueue.main.async {
                    self.thumbnailCache[asset.localIdentifier] = image
                }
            }
        }
    }
    
    // MARK: - 選擇邏輯
    private func toggleSelection(for asset: PHAsset) {
        if selectedAssets.contains(asset.localIdentifier) {
            selectedAssets.remove(asset.localIdentifier)
        } else {
            selectedAssets.insert(asset.localIdentifier)
        }
    }
    
    // MARK: - 處理選中的資源
    private func processSelectedAssets() {
        guard !selectedAssets.isEmpty else { return }
        
        Task {
            var fileItems: [FileItem] = []
            
            for assetId in selectedAssets {
                guard let asset = heicAssets.first(where: { $0.localIdentifier == assetId }) else {
                    continue
                }
                
                // 使用 PHImageManager 來獲取 HEIC 資料（在實機上更可靠）
                let options = PHImageRequestOptions()
                options.version = .current
                options.deliveryMode = .highQualityFormat
                options.isNetworkAccessAllowed = true
                options.isSynchronous = false
                options.resizeMode = .none
                
                await withCheckedContinuation { continuation in
                    // 使用 requestImageDataAndOrientation 來獲取原始 HEIC 資料
                    PHImageManager.default().requestImageDataAndOrientation(
                        for: asset,
                        options: options
                    ) { imageData, dataUTI, orientation, info in
                        
                        // 檢查是否為 HEIC 格式
                        guard let data = imageData,
                              let uti = dataUTI,
                              (uti.lowercased().contains("heic") || 
                               uti.lowercased().contains("heif") ||
                               uti == "public.heic" || 
                               uti == "public.heif") else {
                            
                            // 診斷為何無法取得資料
                            if let error = info?[PHImageErrorKey] as? Error {
                                print("❌ PHImageErrorKey: \(error.localizedDescription)")
                            }
                            if let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool, isDegraded {
                                print("⚠️ 收到降級版本，跳過")
                            }
                            if imageData == nil {
                                print("❌ 無法取得圖片資料")
                            }
                            if dataUTI == nil || !(dataUTI?.lowercased().contains("heic") ?? false) {
                                print("❌ 不是 HEIC 格式: \(dataUTI ?? "nil")")
                            }
                            
                            continuation.resume()
                            return
                        }
                        
                        // 生成檔案名稱
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyyMMdd_HHmmss"
                        let dateString = formatter.string(from: asset.creationDate ?? Date())
                        
                        // 取得原始檔名（如果有的話）
                        let resources = PHAssetResource.assetResources(for: asset)
                        var originalFilename = "IMG_\(dateString).heic"
                        if let firstResource = resources.first(where: { $0.type == .photo }) {
                            let cleanName = firstResource.originalFilename
                                .replacingOccurrences(of: "/", with: "_")
                                .replacingOccurrences(of: "\\", with: "_")
                                .replacingOccurrences(of: ":", with: "_")
                            if !cleanName.isEmpty {
                                originalFilename = cleanName
                            }
                        }
                        
                        let filename = "HEIC_\(dateString)_\(originalFilename)"
                        
                        // 直接使用記憶體資料，不寫入檔案系統
                        let fileItem = FileItem(
                            data: data, 
                            name: filename, 
                            creationDate: asset.creationDate
                        )
                        fileItems.append(fileItem)
                        print("✅ 成功處理 HEIC: \(originalFilename), 大小: \(data.count) bytes")
                        
                        continuation.resume()
                    }
                }
            }
            
            await MainActor.run {
                onFilesSelected(fileItems)
                dismiss()
            }
        }
    }
}

// MARK: - 圖片單元格
struct HEICPhotoCell: View {
    let asset: PHAsset
    let isSelected: Bool
    let thumbnail: UIImage?
    let onTap: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // 圖片
            Group {
                if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(AppColors.textTertiary)
                        )
                }
            }
            
            // 選擇指示器
            if isSelected {
                VStack {
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(AppColors.primaryBlue)
                                .frame(width: 24, height: 24)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(8)
                    }
                    Spacer()
                }
            }
            
            // 選擇遮罩
            if isSelected {
                Rectangle()
                    .fill(AppColors.primaryBlue.opacity(0.2))
                    .allowsHitTesting(false)
            }
            
            // HEIC 標籤
            VStack {
                Spacer()
                HStack {
                    Text("HEIC")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.black.opacity(0.6))
                        )
                        .padding(4)
                    Spacer()
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    HEICPhotoPicker { files in
        print("Selected \(files.count) files")
    }
}