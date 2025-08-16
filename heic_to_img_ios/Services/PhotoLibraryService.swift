import Foundation
import Photos
import UIKit

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
        
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetCreationRequest.creationRequestForAssetFromImage(atFileURL: url)
        }
    }
    
    func saveMultipleImagesToPhotoLibrary(urls: [URL]) async throws {
        guard await requestPhotoLibraryPermission() else {
            throw PhotoLibraryError.permissionDenied
        }
        
        let validURLs = urls.filter { FileManager.default.fileExists(atPath: $0.path) }
        
        guard !validURLs.isEmpty else {
            throw PhotoLibraryError.noValidFiles
        }
        
        try await PHPhotoLibrary.shared().performChanges {
            for url in validURLs {
                PHAssetCreationRequest.creationRequestForAssetFromImage(atFileURL: url)
            }
        }
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