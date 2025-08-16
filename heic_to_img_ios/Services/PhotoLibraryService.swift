import Foundation
import Photos
import UIKit
import CoreImage
import ImageIO
import UniformTypeIdentifiers

class PhotoLibraryService {
    
    static let shared = PhotoLibraryService()
    
    private init() {}
    
    func requestPhotoLibraryPermission() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        
        switch status {
        case .authorized, .limited:
            return true
        case .denied, .restricted:
            return false
        case .notDetermined:
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            return newStatus == .authorized || newStatus == .limited
        @unknown default:
            return false
        }
    }
    
    func saveImageToPhotoLibrary(at url: URL) async throws {
        guard await requestPhotoLibraryPermission() else {
            throw PhotoLibraryError.permissionDenied
        }
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw PhotoLibraryError.fileNotFound
        }
        
        let tempURL = try await createImageWithCurrentTimestamp(from: url)
        
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCreationRequest.creationRequestForAssetFromImage(atFileURL: tempURL)
            request?.creationDate = Date()
        }
        
        try? FileManager.default.removeItem(at: tempURL)
    }
    
    func saveMultipleImagesToPhotoLibrary(urls: [URL]) async throws {
        guard await requestPhotoLibraryPermission() else {
            throw PhotoLibraryError.permissionDenied
        }
        
        let validURLs = urls.filter { FileManager.default.fileExists(atPath: $0.path) }
        
        guard !validURLs.isEmpty else {
            throw PhotoLibraryError.noValidFiles
        }
        
        var tempURLs: [URL] = []
        
        for url in validURLs {
            let tempURL = try await createImageWithCurrentTimestamp(from: url)
            tempURLs.append(tempURL)
        }
        
        try await PHPhotoLibrary.shared().performChanges {
            for tempURL in tempURLs {
                let request = PHAssetCreationRequest.creationRequestForAssetFromImage(atFileURL: tempURL)
                request?.creationDate = Date()
            }
        }
        
        for tempURL in tempURLs {
            try? FileManager.default.removeItem(at: tempURL)
        }
    }
    
    private func createImageWithCurrentTimestamp(from sourceURL: URL) async throws -> URL {
        guard let imageSource = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil),
              let imageType = CGImageSourceGetType(imageSource) else {
            throw PhotoLibraryError.fileNotFound
        }
        
        let tempDirectory = FileManager.default.temporaryDirectory
        let filename = "\(UUID().uuidString)_\(Int(Date().timeIntervalSince1970)).jpg"
        let tempURL = tempDirectory.appendingPathComponent(filename)
        
        // 保留原始圖片的所有 metadata，包括方向資訊
        let originalMetadata = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] ?? [:]
        
        // 更新時間戳記但保留其他 metadata
        var updatedMetadata = originalMetadata
        
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        let dateString = dateFormatter.string(from: currentDate)
        
        // 更新 EXIF 資訊
        var exifDict = updatedMetadata[kCGImagePropertyExifDictionary as String] as? [String: Any] ?? [:]
        exifDict[kCGImagePropertyExifDateTimeOriginal as String] = dateString
        exifDict[kCGImagePropertyExifDateTimeDigitized as String] = dateString
        updatedMetadata[kCGImagePropertyExifDictionary as String] = exifDict
        
        // 更新 TIFF 資訊
        var tiffDict = updatedMetadata[kCGImagePropertyTIFFDictionary as String] as? [String: Any] ?? [:]
        tiffDict[kCGImagePropertyTIFFDateTime as String] = dateString
        updatedMetadata[kCGImagePropertyTIFFDictionary as String] = tiffDict
        
        // 創建新的圖片檔案，保留所有 metadata
        guard let imageDestination = CGImageDestinationCreateWithURL(tempURL as CFURL, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw PhotoLibraryError.fileNotFound
        }
        
        CGImageDestinationAddImage(imageDestination, cgImage, updatedMetadata as CFDictionary)
        
        guard CGImageDestinationFinalize(imageDestination) else {
            throw PhotoLibraryError.fileNotFound
        }
        
        return tempURL
    }
}

enum PhotoLibraryError: LocalizedError {
    case permissionDenied
    case fileNotFound
    case noValidFiles
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "無法存取相簿，請在設定中允許應用程式存取相簿"
        case .fileNotFound:
            return "找不到要儲存的檔案"
        case .noValidFiles:
            return "沒有可以儲存的有效檔案"
        }
    }
}