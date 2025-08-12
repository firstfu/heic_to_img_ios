//
//  LocalImageConverterService.swift
//  heic_to_img_ios
//
//  Created by firstfu on 2025/8/12.
//

import Foundation
import UIKit
import CoreImage
import ImageIO
import UniformTypeIdentifiers

// MARK: - 本地圖像轉換服務
class LocalImageConverterService {
    static let shared = LocalImageConverterService()

    // 使用 CIContext 進行 GPU 加速圖片處理
    private let ciContext: CIContext

    // 用於處理的並發佇列
    private let processingQueue = DispatchQueue(label: "com.heicmaster.imageProcessing", attributes: .concurrent)

    private init() {
        // 初始化 CIContext，優先使用 GPU
        if let eaglContext = EAGLContext(api: .openGLES3) ?? EAGLContext(api: .openGLES2) {
            self.ciContext = CIContext(eaglContext: eaglContext, options: [
                .priorityRequestLow: false,
                .useSoftwareRenderer: false
            ])
        } else {
            // 如果 OpenGL 不可用，使用預設 context
            self.ciContext = CIContext(options: [
                .priorityRequestLow: false,
                .useSoftwareRenderer: false
            ])
        }
    }

    // MARK: - 轉換單個檔案
    func convertFile(
        _ fileItem: FileItem,
        settings: ConversionSettings,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> ConversionResult {

        let startTime = Date()
        progressHandler(0.1)

        // 獲取圖片資料
        let imageData: Data
        if let data = fileItem.data {
            imageData = data
        } else if let url = fileItem.url {
            imageData = try Data(contentsOf: url)
        } else {
            throw ConversionError.invalidImageFormat
        }

        progressHandler(0.2)

        // 轉換圖片
        let (convertedData, originalSize) = try await convertImageData(
            imageData,
            fileName: fileItem.name,
            settings: settings,
            progressHandler: { progress in
                // 轉換進度佔 20%-80%
                progressHandler(0.2 + progress * 0.6)
            }
        )

        progressHandler(0.85)

        // 儲存轉換後的檔案
        let outputURL = try await saveConvertedFile(
            data: convertedData,
            originalFileName: fileItem.name,
            format: settings.outputFormat
        )

        progressHandler(0.95)

        let processingTime = Date().timeIntervalSince(startTime)

        // 創建轉換結果
        let result = ConversionResult(
            originalFile: fileItem,
            outputURL: outputURL,
            processingTime: processingTime,
            originalSize: Int64(originalSize),
            outputSize: Int64(convertedData.count)
        )

        progressHandler(1.0)

        return result
    }

    // MARK: - 批次轉換
    func convertBatchFiles(
        _ files: [FileItem],
        settings: ConversionSettings,
        progressHandler: @escaping (Double, Int, Int) -> Void
    ) async throws -> [ConversionResult] {

        var results: [ConversionResult] = []
        let totalFiles = files.count

        for (index, file) in files.enumerated() {
            do {
                let result = try await convertFile(
                    file,
                    settings: settings,
                    progressHandler: { _ in
                        // 個別檔案進度暫不處理
                    }
                )

                results.append(result)

            } catch {
                // 記錄錯誤但繼續處理其他檔案
                print("❌ 轉換檔案失敗 \(file.name): \(error)")
                throw error
            }

            // 更新整體進度
            let completedFiles = index + 1
            let progress = Double(completedFiles) / Double(totalFiles)

            await MainActor.run {
                progressHandler(progress, completedFiles, totalFiles)
            }
        }

        return results
    }

    // MARK: - 私有方法

    private func convertImageData(
        _ imageData: Data,
        fileName: String,
        settings: ConversionSettings,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> (Data, Int) {

        return try await withCheckedThrowingContinuation { continuation in
            processingQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: ConversionError.unknownError)
                    return
                }

                do {
                    progressHandler(0.1)

                    // 從資料創建圖片來源
                    guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil) else {
                        throw ConversionError.invalidImageFormat
                    }

                    // 獲取圖片屬性
                    let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any]
                    let originalSize = imageData.count

                    progressHandler(0.3)

                    // 創建 CGImage
                    guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
                        throw ConversionError.invalidImageFormat
                    }

                    progressHandler(0.5)

                    // 準備輸出資料
                    let outputData = NSMutableData()

                    // 根據輸出格式創建目標
                    let destinationType: CFString
                    let compressionQuality: CGFloat

                    switch settings.outputFormat {
                    case .jpeg:
                        destinationType = UTType.jpeg.identifier as CFString
                        compressionQuality = CGFloat(settings.jpegQuality)
                    case .png:
                        destinationType = UTType.png.identifier as CFString
                        compressionQuality = 1.0
                    }

                    guard let imageDestination = CGImageDestinationCreateWithData(
                        outputData as CFMutableData,
                        destinationType,
                        1,
                        nil
                    ) else {
                        throw ConversionError.saveFailed
                    }

                    progressHandler(0.7)

                    // 設定輸出選項
                    var outputProperties: [CFString: Any] = [:]

                    if settings.outputFormat == .jpeg {
                        outputProperties[kCGImageDestinationLossyCompressionQuality] = compressionQuality
                    }

                    // 保留元數據（如果設定）
                    if settings.preserveMetadata, let imageProperties = imageProperties {
                        // 複製原始元數據但移除一些敏感資訊
                        var metadata = imageProperties
                        metadata.removeValue(forKey: kCGImagePropertyGPSDictionary as String)

                        for (key, value) in metadata {
                            if let cfKey = key as CFString? {
                                outputProperties[cfKey] = value
                            }
                        }
                    }

                    // 添加圖片到目標
                    CGImageDestinationAddImage(imageDestination, cgImage, outputProperties as CFDictionary)

                    progressHandler(0.9)

                    // 完成寫入
                    guard CGImageDestinationFinalize(imageDestination) else {
                        throw ConversionError.saveFailed
                    }

                    progressHandler(1.0)

                    continuation.resume(returning: (outputData as Data, originalSize))

                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func saveConvertedFile(
        data: Data,
        originalFileName: String,
        format: ConversionFormat
    ) async throws -> URL {
        // 創建輸出目錄
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let outputDirectory = documentsPath.appendingPathComponent("HeicMaster/Converted", isDirectory: true)

        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

        // 生成檔案名稱
        let baseName = (originalFileName as NSString).deletingPathExtension
        let timestamp = DateFormatter.fileNameFormatter.string(from: Date())
        let fileName = "\(baseName)_\(timestamp).\(format.fileExtension)"

        let outputURL = outputDirectory.appendingPathComponent(fileName)

        // 寫入檔案
        try data.write(to: outputURL)

        return outputURL
    }

    // MARK: - 輔助方法

    func checkHEICSupport() -> Bool {
        // iOS 11+ 支援 HEIC
        if #available(iOS 11.0, *) {
            return true
        }
        return false
    }

    func estimateOutputSize(
        originalSize: Int64,
        format: ConversionFormat,
        quality: Double
    ) -> Int64 {
        // 粗略估算輸出大小
        switch format {
        case .jpeg:
            // JPEG 通常比 HEIC 大 2-3 倍，但會根據品質調整
            let factor = 2.5 * quality
            return Int64(Double(originalSize) * factor)
        case .png:
            // PNG 通常比 HEIC 大 4-5 倍
            return originalSize * 4
        }
    }
}

