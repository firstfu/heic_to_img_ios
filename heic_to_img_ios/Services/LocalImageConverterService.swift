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
import os.log

// MARK: - 本地圖像轉換服務
class LocalImageConverterService {
    static let shared = LocalImageConverterService()

    // 使用 CIContext 進行 GPU 加速圖片處理
    private let ciContext: CIContext

    // 用於處理的並發佇列
    private let processingQueue = DispatchQueue(label: "com.heicmaster.imageProcessing", attributes: .concurrent)
    
    // 記憶體監控
    private let memoryLogger = Logger(subsystem: "com.heicmaster", category: "memory")
    private var isLowMemoryMode = false
    
    // 批次處理控制
    private let maxConcurrentOperations: Int

    private init() {
        // 根據設備性能設置併發操作數
        if ProcessInfo.processInfo.physicalMemory > 4 * 1024 * 1024 * 1024 { // > 4GB
            self.maxConcurrentOperations = ProcessingLimits.maxConcurrentJobs
        } else if ProcessInfo.processInfo.physicalMemory > 2 * 1024 * 1024 * 1024 { // > 2GB
            self.maxConcurrentOperations = ProcessingLimits.maxConcurrentJobs / 2
        } else {
            self.maxConcurrentOperations = 1 // 低記憶體設備使用串行處理
        }
        
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
        
        // 設置記憶體警告監聽
        setupMemoryWarning()
    }
    
    // MARK: - 記憶體管理
    
    private func setupMemoryWarning() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }
    }
    
    private func handleMemoryWarning() {
        isLowMemoryMode = true
        memoryLogger.warning("收到記憶體警告，切換到低記憶體模式")
        
        // 清理記憶體
        autoreleasepool {
            // 強制垃圾回收
        }
        
        // 5秒後恢復正常模式
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.isLowMemoryMode = false
        }
    }
    
    private func getCurrentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
        }
        return 0
    }
    
    private func checkMemoryStatus() -> Bool {
        let currentMemory = getCurrentMemoryUsage()
        let memoryMB = currentMemory / (1024 * 1024)
        
        if memoryMB > ProcessingLimits.memoryWarningThresholdMB {
            memoryLogger.info("記憶體使用量: \(memoryMB)MB，接近警告閾值")
            return true
        }
        return false
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
        
        // 檢查檔案數量限制
        guard files.count <= ProcessingLimits.maxBatchFiles else {
            throw ConversionError.tooManyFiles(files.count, ProcessingLimits.maxBatchFiles)
        }
        
        // 檢查檔案大小限制
        guard !ProcessingLimits.exceedsSizeLimit(files) else {
            let totalSizeMB = ProcessingLimits.totalSizeInMB(files)
            throw ConversionError.fileTooLarge("總大小 \(Int(totalSizeMB))MB 超過 \(ProcessingLimits.maxTotalSizeMB)MB 限制")
        }
        
        let totalFiles = files.count
        let batchSize = determineBatchSize(files.count)
        var results: [ConversionResult] = []
        var completedFiles = 0
        
        memoryLogger.info("開始批次轉換：\(totalFiles) 個檔案，批次大小：\(batchSize)")
        
        // 分批處理檔案
        let batches = files.chunked(into: batchSize)
        
        for (batchIndex, batch) in batches.enumerated() {
            memoryLogger.info("處理批次 \(batchIndex + 1)/\(batches.count)，包含 \(batch.count) 個檔案")
            
            // 檢查記憶體狀態
            if checkMemoryStatus() || isLowMemoryMode {
                memoryLogger.warning("記憶體使用量過高，使用串行處理")
                // 串行處理以節省記憶體
                for file in batch {
                    let result = try await convertFile(
                        file,
                        settings: settings,
                        progressHandler: { _ in }
                    )
                    results.append(result)
                    completedFiles += 1
                    
                    await MainActor.run {
                        let progress = Double(completedFiles) / Double(totalFiles)
                        progressHandler(progress, completedFiles, totalFiles)
                    }
                }
            } else {
                // 並行處理以提高速度
                let batchResults = try await withThrowingTaskGroup(of: ConversionResult.self) { group in
                    let concurrency = min(maxConcurrentOperations, batch.count)
                    var batchResults: [ConversionResult] = []
                    
                    // 添加轉換任務到群組
                    for file in batch {
                        group.addTask {
                            return try await self.convertFile(
                                file,
                                settings: settings,
                                progressHandler: { _ in }
                            )
                        }
                    }
                    
                    // 收集結果
                    for try await result in group {
                        batchResults.append(result)
                        completedFiles += 1
                        
                        await MainActor.run {
                            let progress = Double(completedFiles) / Double(totalFiles)
                            progressHandler(progress, completedFiles, totalFiles)
                        }
                    }
                    
                    return batchResults
                }
                
                results.append(contentsOf: batchResults)
            }
            
            // 批次間休息，讓系統回收記憶體
            if batchIndex < batches.count - 1 {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
            }
        }
        
        memoryLogger.info("批次轉換完成：\(results.count) 個檔案成功轉換")
        return results
    }
    
    // MARK: - 輔助方法
    
    private func determineBatchSize(_ totalFiles: Int) -> Int {
        if isLowMemoryMode {
            return ProcessingLimits.lowMemoryBatchFiles
        }
        
        let memoryBasedSize = min(totalFiles, maxConcurrentOperations * 2)
        return max(1, memoryBasedSize)
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

// MARK: - Array Extension for Batching
extension Array {
    /// 將陣列分割成指定大小的小批次
    /// - Parameter size: 每個批次的大小
    /// - Returns: 分割後的二維陣列
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

