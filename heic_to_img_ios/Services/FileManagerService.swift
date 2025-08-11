//
//  FileManagerService.swift
//  heic_to_img_ios
//
//  Created by firstfu on 2025/8/10.
//

import UIKit
import Photos
import PhotosUI
import UniformTypeIdentifiers
import CoreImage

// MARK: - 檔案管理服務
class FileManagerService: NSObject, ObservableObject {
    static let shared = FileManagerService()
    
    // MARK: - 發布屬性
    @Published var photosAuthorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published var thumbnailCache: [String: UIImage] = [:]
    
    private let fileManager = FileManager.default
    private let thumbnailQueue = DispatchQueue(label: "com.heicmaster.thumbnails", qos: .userInitiated)
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    
    // MARK: - 目錄路徑
    var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    var appDataDirectory: URL {
        let url = documentsDirectory.appendingPathComponent("HeicMaster", isDirectory: true)
        ensureDirectoryExists(url)
        return url
    }
    
    var convertedFilesDirectory: URL {
        let url = appDataDirectory.appendingPathComponent("Converted", isDirectory: true)
        ensureDirectoryExists(url)
        return url
    }
    
    var temporaryDirectory: URL {
        // 使用系統臨時目錄，避免權限問題
        let systemTempDir = FileManager.default.temporaryDirectory
        let appTempDir = systemTempDir.appendingPathComponent("HeicMaster", isDirectory: true)
        ensureDirectoryExists(appTempDir)
        return appTempDir
    }
    
    override init() {
        super.init()
        checkPhotosPermission()
        setupDirectories()
        cleanupOldFiles()
    }
    
    // MARK: - 目錄管理
    private func setupDirectories() {
        let directories = [appDataDirectory, convertedFilesDirectory, temporaryDirectory]
        
        for directory in directories {
            ensureDirectoryExists(directory)
        }
    }
    
    private func ensureDirectoryExists(_ url: URL) {
        do {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        } catch {
            print("❌ 創建目錄失敗: \(url.path), 錯誤: \(error)")
        }
    }
    
    // MARK: - 權限管理
    func checkPhotosPermission() {
        photosAuthorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    func requestPhotosPermission() async -> PHAuthorizationStatus {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        await MainActor.run {
            self.photosAuthorizationStatus = status
        }
        return status
    }
    
    // MARK: - HEIC 檔案檢測
    func findHEICFiles() async -> [FileItem] {
        let status = await requestPhotosPermission()
        
        guard status == .authorized || status == .limited else {
            return []
        }
        
        return await withCheckedContinuation { continuation in
            var heicFiles: [FileItem] = []
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "mediaSubtype & %d != 0", PHAssetMediaSubtype.photoHDR.rawValue)
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            
            let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            
            let group = DispatchGroup()
            
            assets.enumerateObjects { (asset, index, stop) in
                // 使用 PHAssetResource 安全地檢查 HEIC 格式
                let resources = PHAssetResource.assetResources(for: asset)
                var isHEIC = false
                
                for resource in resources {
                    let uti = resource.uniformTypeIdentifier.lowercased()
                    if uti.contains("heic") || uti.contains("heif") || 
                       resource.originalFilename.lowercased().hasSuffix(".heic") ||
                       resource.originalFilename.lowercased().hasSuffix(".heif") {
                        isHEIC = true
                        break
                    }
                }
                
                if isHEIC {
                    group.enter()
                    
                    let options = PHImageRequestOptions()
                    options.isSynchronous = false
                    options.isNetworkAccessAllowed = true
                    options.version = .current  // 請求當前版本
                    options.deliveryMode = .highQualityFormat  // 高品質格式
                    options.resizeMode = .none  // 不調整大小
                    
                    PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, uti, orientation, info in
                        defer { group.leave() }
                        
                        if let uti = uti,
                           (uti.lowercased().contains("heic") || uti.lowercased().contains("heif") || 
                            uti == UTType.heic.identifier || uti == UTType.heif.identifier),
                           let data = data {
                            
                            // 創建臨時檔案，使用安全的檔名和系統臨時目錄
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyyMMdd_HHmmss"
                            let dateString = formatter.string(from: asset.creationDate ?? Date())
                            
                            let safeIdentifier = asset.localIdentifier
                                .replacingOccurrences(of: "/", with: "_")
                                .replacingOccurrences(of: "\\", with: "_")
                            
                            // 使用系統臨時目錄
                            let systemTempDir = FileManager.default.temporaryDirectory
                            let tempURL = systemTempDir.appendingPathComponent("HEIC_\(dateString)_\(safeIdentifier).heic")
                            
                            do {
                                // 確保目錄存在
                                try FileManager.default.createDirectory(
                                    at: systemTempDir,
                                    withIntermediateDirectories: true,
                                    attributes: nil
                                )
                                
                                // 如果檔案已存在，先刪除
                                if FileManager.default.fileExists(atPath: tempURL.path) {
                                    try FileManager.default.removeItem(at: tempURL)
                                }
                                
                                try data.write(to: tempURL)
                                let fileItem = FileItem(url: tempURL)
                                heicFiles.append(fileItem)
                                print("✅ 找到 HEIC 檔案: \(tempURL.lastPathComponent)")
                            } catch {
                                print("❌ 寫入臨時檔案失敗: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
            
            group.notify(queue: .main) {
                continuation.resume(returning: heicFiles)
            }
        }
    }
    
    // MARK: - 檔案操作
    func validateFile(_ url: URL) throws -> FileItem {
        guard url.startAccessingSecurityScopedResource() else {
            throw FileError.accessDenied
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        // 檢查檔案是否存在
        guard fileManager.fileExists(atPath: url.path) else {
            throw FileError.fileNotFound
        }
        
        // 檢查檔案格式
        let pathExtension = url.pathExtension.lowercased()
        guard pathExtension == "heic" || pathExtension == "heif" else {
            throw FileError.unsupportedFormat
        }
        
        // 檢查檔案大小
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        
        guard fileSize > 0 else {
            throw FileError.emptyFile
        }
        
        guard fileSize <= AppConstants.maxFileSize else {
            throw FileError.fileTooLarge
        }
        
        return FileItem(url: url)
    }
    
    func copyToAppDirectory(_ url: URL) throws -> URL {
        // 嘗試存取安全範圍資源（可能不需要）
        let needsSecurityScope = url.startAccessingSecurityScopedResource()
        defer { 
            if needsSecurityScope {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        // 檢查臨時目錄是否可寫
        let tempDir = temporaryDirectory
        if !fileManager.isWritableFile(atPath: tempDir.path) {
            print("❌ 臨時目錄不可寫: \(tempDir.path)")
            // 嘗試使用備用目錄
            let alternativeTempDir = FileManager.default.temporaryDirectory
            ensureDirectoryExists(alternativeTempDir)
            if !fileManager.isWritableFile(atPath: alternativeTempDir.path) {
                throw FileError.accessDenied
            }
        }
        
        let fileName = url.lastPathComponent
        let destinationURL = tempDir.appendingPathComponent(fileName)
        
        // 如果檔案已存在，生成唯一名稱
        var finalURL = destinationURL
        var counter = 1
        while fileManager.fileExists(atPath: finalURL.path) {
            let baseName = url.deletingPathExtension().lastPathComponent
            let fileExtension = url.pathExtension
            let newFileName = "\(baseName)_\(counter).\(fileExtension)"
            finalURL = tempDir.appendingPathComponent(newFileName)
            counter += 1
        }
        
        do {
            try fileManager.copyItem(at: url, to: finalURL)
            print("✅ 成功複製檔案到: \(finalURL.lastPathComponent)")
            return finalURL
        } catch {
            print("❌ 複製檔案失敗: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - 縮圖生成
    func generateThumbnail(for fileItem: FileItem) async -> UIImage? {
        let cacheKey = fileItem.url?.path ?? fileItem.name
        
        // 檢查快取
        if let cachedThumbnail = thumbnailCache[cacheKey] {
            return cachedThumbnail
        }
        
        return await withCheckedContinuation { continuation in
            thumbnailQueue.async { [weak self] in
                guard let self = self else { return }
                let thumbnail = self.createThumbnail(from: fileItem)
                
                DispatchQueue.main.async {
                    if let thumbnail = thumbnail {
                        self.thumbnailCache[cacheKey] = thumbnail
                    }
                    continuation.resume(returning: thumbnail)
                }
            }
        }
    }
    
    private func createThumbnail(from fileItem: FileItem) -> UIImage? {
        let imageSource: CGImageSource?
        
        if let url = fileItem.url {
            guard url.startAccessingSecurityScopedResource() else {
                return nil
            }
            defer { url.stopAccessingSecurityScopedResource() }
            imageSource = CGImageSourceCreateWithURL(url as CFURL, nil)
        } else if let data = fileItem.data {
            imageSource = CGImageSourceCreateWithData(data as CFData, nil)
        } else {
            return nil
        }
        
        guard let source = imageSource else {
            return nil
        }
        
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: max(AppConstants.previewSize.width, AppConstants.previewSize.height)
        ]
        
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - 檔案保存
    func saveToPhotos(_ url: URL) async throws {
        let status = await requestPhotosPermission()
        
        guard status == .authorized else {
            throw FileError.accessDenied
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.shared().performChanges({
                PHAssetCreationRequest.creationRequestForAssetFromImage(atFileURL: url)
            }) { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? FileError.saveFailed)
                }
            }
        }
    }
    
    func shareFiles(_ urls: [URL]) -> UIActivityViewController {
        let activityViewController = UIActivityViewController(
            activityItems: urls,
            applicationActivities: nil
        )
        
        activityViewController.excludedActivityTypes = [
            .assignToContact,
            .addToReadingList,
            .postToVimeo
        ]
        
        return activityViewController
    }
    
    // MARK: - 檔案清理
    func cleanupOldFiles() {
        cleanupDirectory(temporaryDirectory, olderThanDays: 1)
        cleanupDirectory(convertedFilesDirectory, olderThanDays: 30)
    }
    
    private func cleanupDirectory(_ directory: URL, olderThanDays days: Int) {
        do {
            let files = try fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.creationDateKey],
                options: .skipsHiddenFiles
            )
            
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            
            for fileURL in files {
                let resourceValues = try fileURL.resourceValues(forKeys: [.creationDateKey])
                if let creationDate = resourceValues.creationDate,
                   creationDate < cutoffDate {
                    try fileManager.removeItem(at: fileURL)
                    print("🗑️ 已清理舊檔案: \(fileURL.lastPathComponent)")
                }
            }
            
        } catch {
            print("❌ 清理目錄失敗: \(error)")
        }
    }
    
    func deleteFile(_ url: URL) throws {
        try fileManager.removeItem(at: url)
        thumbnailCache.removeValue(forKey: url.path)
    }
    
    // MARK: - 檔案資訊
    func getFileSize(_ url: URL) -> Int64 {
        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
    
    func getAvailableStorage() -> Int64 {
        do {
            let attributes = try fileManager.attributesOfFileSystem(forPath: documentsDirectory.path)
            return attributes[.systemFreeSize] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
    
    func formatFileSize(_ bytes: Int64) -> String {
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

// MARK: - 檔案錯誤
enum FileError: LocalizedError {
    case fileNotFound
    case accessDenied
    case unsupportedFormat
    case fileTooLarge
    case emptyFile
    case saveFailed
    case insufficientStorage
    case corrupted
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "檔案不存在"
        case .accessDenied:
            return "存取權限被拒絕"
        case .unsupportedFormat:
            return "不支援的檔案格式"
        case .fileTooLarge:
            return "檔案過大"
        case .emptyFile:
            return "檔案為空"
        case .saveFailed:
            return "保存檔案失敗"
        case .insufficientStorage:
            return "儲存空間不足"
        case .corrupted:
            return "檔案已損壞"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .fileNotFound:
            return "請確認檔案路徑是否正確"
        case .accessDenied:
            return "請在設定中允許應用程式存取相片"
        case .unsupportedFormat:
            return "請選擇 HEIC 或 HEIF 格式的檔案"
        case .fileTooLarge:
            return "請選擇小於 \(AppConstants.maxFileSize / (1024 * 1024))MB 的檔案"
        case .emptyFile:
            return "請選擇有效的圖像檔案"
        case .saveFailed:
            return "請確認有足夠的儲存空間"
        case .insufficientStorage:
            return "請清理設備儲存空間"
        case .corrupted:
            return "請選擇其他檔案"
        }
    }
}

// MARK: - 檔案類型檢測擴展
extension FileItem {
    var fileSize: String {
        return FileManagerService.shared.formatFileSize(size)
    }
    
    func generateThumbnail() async -> UIImage? {
        return await FileManagerService.shared.generateThumbnail(for: self)
    }
}
