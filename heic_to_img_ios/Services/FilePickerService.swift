//
//  FilePickerService.swift
//  heic_to_img_ios
//
//  Created by firstfu on 2025/8/10.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers
import PhotosUI

// MARK: - 檔案選擇服務
class FilePickerService: NSObject, ObservableObject {
    static let shared = FilePickerService()
    
    @Published var selectedFiles: [FileItem] = []
    @Published var isPickerPresented = false
    @Published var pickerType: PickerType = .document
    
    private var completion: (([FileItem]) -> Void)?
    
    enum PickerType {
        case document
        case photos
        case camera
    }
    
    // MARK: - 檔案選擇器
    func presentDocumentPicker(from viewController: UIViewController, completion: @escaping ([FileItem]) -> Void) {
        self.completion = completion
        
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.heic, .heif], asCopy: true)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = true
        documentPicker.shouldShowFileExtensions = true
        
        viewController.present(documentPicker, animated: true)
    }
    
    // MARK: - 相片選擇器 (僅HEIC格式)
    func presentPhotosPicker(from viewController: UIViewController, completion: @escaping ([FileItem]) -> Void) {
        self.completion = completion
        
        // 先顯示提示訊息
        let alertController = UIAlertController(
            title: "選擇 HEIC 圖片",
            message: "此功能只支援 HEIC/HEIF 格式的圖片。在相簿中只會顯示符合格式的圖片。",
            preferredStyle: .alert
        )
        
        alertController.addAction(UIAlertAction(title: "繼續", style: .default) { _ in
            var configuration = PHPickerConfiguration()
            configuration.selectionLimit = 0 // 無限制
            
            // 嘗試設定只顯示 HEIC 格式的圖片
            if #available(iOS 15.0, *) {
                // iOS 15+ 支援更精確的過濾
                configuration.filter = PHPickerFilter.any(of: [
                    .images
                ])
            } else {
                configuration.filter = .images
            }
            
            configuration.preferredAssetRepresentationMode = .current // 保持原始格式
            
            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = self
            
            viewController.present(picker, animated: true)
        })
        
        alertController.addAction(UIAlertAction(title: "取消", style: .cancel) { _ in
            completion([])
        })
        
        viewController.present(alertController, animated: true)
    }
    
    // MARK: - 相機選擇器
    func presentCamera(from viewController: UIViewController, completion: @escaping ([FileItem]) -> Void) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            print("❌ 相機不可用")
            return
        }
        
        self.completion = completion
        
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.mediaTypes = [UTType.image.identifier]
        imagePicker.delegate = self
        
        viewController.present(imagePicker, animated: true)
    }
    
    // MARK: - 檔案處理
    func handleFileURLs(_ urls: [URL]) -> [FileItem] {
        var validFiles: [FileItem] = []
        
        for url in urls {
            do {
                let _ = try FileManagerService.shared.validateFile(url)
                let copiedURL = try FileManagerService.shared.copyToAppDirectory(url)
                let finalFileItem = FileItem(url: copiedURL)
                validFiles.append(finalFileItem)
            } catch {
                print("❌ 無法處理檔案 \(url.lastPathComponent): \(error)")
            }
        }
        
        return validFiles
    }
    
    // MARK: - 檔案驗證
    func validateFiles(_ files: [FileItem]) -> (valid: [FileItem], invalid: [String]) {
        var validFiles: [FileItem] = []
        var invalidReasons: [String] = []
        
        for file in files {
            if let url = file.url {
                do {
                    let _ = try FileManagerService.shared.validateFile(url)
                    validFiles.append(file)
                } catch {
                    invalidReasons.append("\(file.name): \(error.localizedDescription)")
                }
            } else if file.data != nil {
                // For in-memory data, we can perform basic checks if needed,
                // but for now, we'll consider it valid.
                validFiles.append(file)
            } else {
                invalidReasons.append("\(file.name): 無效的檔案項目")
            }
        }
        
        return (valid: validFiles, invalid: invalidReasons)
    }
}

// MARK: - UIDocumentPickerDelegate
extension FilePickerService: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let fileItems = handleFileURLs(urls)
        completion?(fileItems)
        completion = nil
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        completion?([])
        completion = nil
    }
}

// MARK: - PHPickerViewControllerDelegate
extension FilePickerService: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard !results.isEmpty else {
            completion?([])
            completion = nil
            return
        }
        
        var fileItems: [FileItem] = []
        let group = DispatchGroup()
        
        // 只處理 HEIC 格式的圖片
        let heicResults = results.filter { result in
            result.itemProvider.hasItemConformingToTypeIdentifier(UTType.heic.identifier)
        }
        
        // 如果沒有 HEIC 格式的圖片，顯示提示並返回空結果
        if heicResults.isEmpty {
            print("⚠️ 所選圖片中沒有 HEIC 格式，請選擇 HEIC 圖片")
            
            // 在主線程顯示友善的錯誤提示
            DispatchQueue.main.async {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootViewController = window.rootViewController {
                    
                    let alertController = UIAlertController(
                        title: "沒有找到 HEIC 圖片",
                        message: "您選擇的圖片中沒有 HEIC 格式的檔案。請選擇以 .heic 或 .heif 結尾的圖片。\n\n💡 提示：通常由 iPhone 7 或更新機型拍攝的 Live Photos 或原始照片會是 HEIC 格式。",
                        preferredStyle: .alert
                    )
                    
                    alertController.addAction(UIAlertAction(title: "重新選擇", style: .default) { _ in
                        // 重新開啟相簿選擇器
                        self.presentPhotosPicker(from: rootViewController) { files in
                            self.completion?(files)
                        }
                    })
                    
                    alertController.addAction(UIAlertAction(title: "取消", style: .cancel) { _ in
                        self.completion?([])
                        self.completion = nil
                    })
                    
                    rootViewController.present(alertController, animated: true)
                }
            }
            return
        }
        
        for result in heicResults {
            group.enter()
            
            // 載入 HEIC 格式
            result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.heic.identifier) { url, error in
                defer { group.leave() }
                
                guard let url = url, error == nil else {
                    print("❌ 載入 HEIC 失敗: \(error?.localizedDescription ?? "未知錯誤")")
                    if let error = error as NSError? {
                        print("   錯誤碼: \(error.code)")
                        print("   錯誤域: \(error.domain)")
                    }
                    return
                }
                
                do {
                    // 確保可以存取檔案
                    _ = url.startAccessingSecurityScopedResource()
                    defer { url.stopAccessingSecurityScopedResource() }
                    
                    // 讀取檔案資料
                    let data = try Data(contentsOf: url)
                    
                    // 生成唯一檔名
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyyMMdd_HHmmss"
                    let dateString = formatter.string(from: Date())
                    let filename = "PHPicker_\(dateString)_\(url.lastPathComponent)"
                    
                    // 使用系統臨時目錄
                    let systemTempDir = FileManager.default.temporaryDirectory
                    let tempURL = systemTempDir.appendingPathComponent(filename)
                    
                    // 寫入檔案
                    try data.write(to: tempURL)
                    
                    let fileItem = FileItem(url: tempURL)
                    fileItems.append(fileItem)
                    print("✅ 成功處理 PHPicker HEIC: \(filename), 大小: \(data.count) bytes")
                } catch {
                    print("❌ 處理 HEIC 失敗: \(error.localizedDescription)")
                    let nsError = error as NSError
                    print("   錯誤碼: \(nsError.code)")
                    print("   錯誤域: \(nsError.domain)")
                }
            }
        }
        
        group.notify(queue: .main) {
            print("✅ 成功載入 \(fileItems.count) 個 HEIC 檔案")
            self.completion?(fileItems)
            self.completion = nil
        }
    }
}

// MARK: - UIImagePickerControllerDelegate
extension FilePickerService: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        guard let image = info[.originalImage] as? UIImage else {
            completion?([])
            completion = nil
            return
        }
        
        // 保存拍攝的照片到臨時目錄
        let dateString = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: "+", with: "_")
        let fileName = "Camera_\(dateString).heic"
        let tempURL = FileManagerService.shared.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            if let heicData = image.heicData() {
                try heicData.write(to: tempURL)
                let fileItem = FileItem(url: tempURL)
                completion?([fileItem])
            } else {
                completion?([])
            }
        } catch {
            print("❌ 保存相機照片失敗: \(error)")
            completion?([])
        }
        
        completion = nil
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        completion?([])
        completion = nil
    }
}

// MARK: - UIImage HEIC 擴展
extension UIImage {
    func heicData(compressionQuality: CGFloat = 0.8) -> Data? {
        guard let cgImage = self.cgImage else { return nil }
        
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.heic.identifier as CFString, 1, nil) else {
            return nil
        }
        
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: compressionQuality
        ]
        
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        
        return data as Data
    }
}

// MARK: - SwiftUI 檔案選擇器包裝器
struct FilePickerView: UIViewControllerRepresentable {
    let pickerType: FilePickerService.PickerType
    let onFilesSelected: ([FileItem]) -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        return UIViewController() // 佔位符，實際不會顯示
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // 當視圖出現時自動呈現選擇器
        DispatchQueue.main.async {
            switch pickerType {
            case .document:
                FilePickerService.shared.presentDocumentPicker(from: uiViewController, completion: onFilesSelected)
            case .photos:
                FilePickerService.shared.presentPhotosPicker(from: uiViewController, completion: onFilesSelected)
            case .camera:
                FilePickerService.shared.presentCamera(from: uiViewController, completion: onFilesSelected)
            }
        }
    }
}

// MARK: - SwiftUI 整合
extension View {
    func fileImporter(
        isPresented: Binding<Bool>,
        allowedContentTypes: [UTType] = [.heic, .heif],
        allowsMultipleSelection: Bool = true,
        onCompletion: @escaping ([FileItem]) -> Void
    ) -> some View {
        self.background(
            FileImporterWrapper(
                isPresented: isPresented,
                allowedContentTypes: allowedContentTypes,
                allowsMultipleSelection: allowsMultipleSelection,
                onCompletion: onCompletion
            )
        )
    }
}

struct FileImporterWrapper: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let allowedContentTypes: [UTType]
    let allowsMultipleSelection: Bool
    let onCompletion: ([FileItem]) -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        return UIViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if isPresented && uiViewController.presentedViewController == nil {
            let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedContentTypes, asCopy: true)
            picker.allowsMultipleSelection = allowsMultipleSelection
            picker.delegate = context.coordinator
            
            uiViewController.present(picker, animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: FileImporterWrapper
        
        init(_ parent: FileImporterWrapper) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.isPresented = false
            let fileItems = FilePickerService.shared.handleFileURLs(urls)
            parent.onCompletion(fileItems)
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.isPresented = false
            parent.onCompletion([])
        }
    }
}