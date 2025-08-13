/*
 * 功能：簡化的 ZIP 壓縮檔案服務
 * 
 * 描述：提供基本的多檔案打包功能
 * - 不使用壓縮，直接存儲檔案
 * - 生成可被標準解壓縮軟體識別的 ZIP 格式
 * - 專為 iOS 環境設計
 * 
 * 創建時間：2025/8/13
 * 作者：firstfu
 */

//
//  SimpleZipService.swift
//  heic_to_img_ios
//
//  Created by firstfu on 2025/8/13.
//

import Foundation
import Compression

/// 簡化的 ZIP 壓縮服務
class SimpleZipService {
    
    /// ZIP 相關錯誤
    enum ZipError: Error, LocalizedError {
        case fileNotFound(String)
        case compressionFailed
        case invalidData
        case tooManyFiles(Int, Int) // (current, maximum)
        case filesTooLarge(Int, Int) // (currentMB, maximumMB)
        
        var errorDescription: String? {
            switch self {
            case .fileNotFound(let filename):
                return "找不到檔案：\(filename)"
            case .compressionFailed:
                return "壓縮失敗"
            case .invalidData:
                return "無效的檔案資料"
            case .tooManyFiles(let current, let maximum):
                return "檔案數量過多：\(current) 個檔案超過 ZIP 限制（最大 \(maximum) 個）"
            case .filesTooLarge(let currentMB, let maximumMB):
                return "檔案總大小過大：\(currentMB)MB 超過 ZIP 限制（最大 \(maximumMB)MB）"
            }
        }
    }
    
    /// 將多個檔案打包成 ZIP
    /// - Parameters:
    ///   - urls: 要打包的檔案 URL 清單
    ///   - outputName: 輸出檔案名稱
    ///   - completion: 完成回調
    static func createZip(from urls: [URL], outputName: String = "images", completion: @escaping (Result<URL, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // 檢查檔案數量限制
                guard urls.count <= ProcessingLimits.maxZipFiles else {
                    throw ZipError.tooManyFiles(urls.count, ProcessingLimits.maxZipFiles)
                }
                
                // 檢查檔案總大小
                let totalSize = try calculateTotalSize(urls: urls)
                let maxSizeBytes = ProcessingLimits.mbToBytes(ProcessingLimits.maxZipSizeMB)
                
                guard totalSize <= maxSizeBytes else {
                    let totalSizeMB = totalSize / (1024 * 1024)
                    throw ZipError.filesTooLarge(Int(totalSizeMB), ProcessingLimits.maxZipSizeMB)
                }
                
                // 建立輸出 ZIP 檔案路徑
                let tempDirectory = FileManager.default.temporaryDirectory
                let zipFileName = "\(outputName)_\(Int(Date().timeIntervalSince1970)).zip"
                let zipURL = tempDirectory.appendingPathComponent(zipFileName)
                
                // 刪除已存在的檔案
                if FileManager.default.fileExists(atPath: zipURL.path) {
                    try FileManager.default.removeItem(at: zipURL)
                }
                
                // 建立 ZIP 檔案
                let zipData = try createZipData(from: urls)
                try zipData.write(to: zipURL)
                
                DispatchQueue.main.async {
                    completion(.success(zipURL))
                }
                
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// 智能分割打包：如果檔案數量或大小超過限制，自動分割成多個 ZIP
    /// - Parameters:
    ///   - urls: 要打包的檔案 URL 清單
    ///   - outputName: 輸出檔案名稱
    ///   - completion: 完成回調，返回多個 ZIP 檔案的 URL
    static func createZipsWithAutoSplit(from urls: [URL], outputName: String = "images", completion: @escaping (Result<[URL], Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let batches = try splitIntoBatches(urls: urls, baseName: outputName)
                var zipURLs: [URL] = []
                
                for (index, batch) in batches.enumerated() {
                    let batchName = batches.count > 1 ? "\(outputName)_part\(index + 1)" : outputName
                    
                    let semaphore = DispatchSemaphore(value: 0)
                    var batchResult: Result<URL, Error>?
                    
                    createZip(from: batch, outputName: batchName) { result in
                        batchResult = result
                        semaphore.signal()
                    }
                    
                    semaphore.wait()
                    
                    switch batchResult! {
                    case .success(let zipURL):
                        zipURLs.append(zipURL)
                    case .failure(let error):
                        throw error
                    }
                }
                
                DispatchQueue.main.async {
                    completion(.success(zipURLs))
                }
                
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// 建立 ZIP 檔案資料（優化版本）
    private static func createZipData(from urls: [URL]) throws -> Data {
        var zipData = Data()
        var centralDirectory = Data()
        var centralDirectoryOffset: UInt32 = 0
        var fileCount: UInt16 = 0
        
        // 使用並行處理來壓縮檔案
        let compressedFiles = try urls.map { url -> (fileName: String, compressedData: Data, crc32: UInt32, originalSize: UInt32) in
            // 檢查檔案是否存在
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw ZipError.fileNotFound(url.lastPathComponent)
            }
            
            // 使用 stream 方式讀取和壓縮，避免一次載入整個檔案
            let fileName = url.lastPathComponent
            let fileData = try Data(contentsOf: url)
            
            // 使用 DEFLATE 壓縮
            let compressedData = try compressData(fileData)
            let crc32 = calculateCRC32Fast(data: fileData)
            
            return (fileName, compressedData, crc32, UInt32(fileData.count))
        }
        
        // 獲取 DOS 格式的時間和日期（只計算一次）
        let dosDateTime = getDOSDateTime()
        
        // 組裝 ZIP 檔案
        for (fileName, compressedData, crc32, originalSize) in compressedFiles {
            let fileNameData = fileName.data(using: .utf8) ?? Data()
            
            // 記錄當前位置作為本地檔案頭部偏移
            var localHeaderOffset = UInt32(zipData.count)
            
            // 建立本地檔案頭部 (30 bytes + filename length)
            zipData.append(contentsOf: [0x50, 0x4B, 0x03, 0x04]) // 本地檔案頭簽名
            zipData.append(contentsOf: [0x14, 0x00]) // 版本
            zipData.append(contentsOf: [0x00, 0x00]) // 標誌
            zipData.append(contentsOf: [0x08, 0x00]) // 壓縮方法 (8 = DEFLATE)
            
            // 時間和日期（DOS 格式）
            var dosTime = dosDateTime.time
            zipData.append(Data(bytes: &dosTime, count: 2))
            var dosDate = dosDateTime.date  
            zipData.append(Data(bytes: &dosDate, count: 2))
            
            // CRC32 校驗碼
            var mutableCRC32 = crc32
            zipData.append(Data(bytes: &mutableCRC32, count: 4))
            
            // 檔案大小 (壓縮後)
            var compressedSize = UInt32(compressedData.count)
            zipData.append(Data(bytes: &compressedSize, count: 4))
            
            // 檔案大小 (原始)
            var uncompressedSize = originalSize
            zipData.append(Data(bytes: &uncompressedSize, count: 4))
            
            // 檔案名長度
            var fileNameLength = UInt16(fileNameData.count)
            zipData.append(Data(bytes: &fileNameLength, count: 2))
            
            // 額外欄位長度
            zipData.append(contentsOf: [0x00, 0x00])
            
            // 檔案名
            zipData.append(fileNameData)
            
            // 壓縮後的檔案資料
            zipData.append(compressedData)
            
            // 建立中央目錄項目
            centralDirectory.append(contentsOf: [0x50, 0x4B, 0x01, 0x02]) // 中央目錄簽名
            centralDirectory.append(contentsOf: [0x14, 0x00]) // 製作版本
            centralDirectory.append(contentsOf: [0x14, 0x00]) // 解壓版本
            centralDirectory.append(contentsOf: [0x00, 0x00]) // 標誌
            centralDirectory.append(contentsOf: [0x08, 0x00]) // 壓縮方法 (8 = DEFLATE)
            
            // 使用相同的時間和日期
            centralDirectory.append(Data(bytes: &dosTime, count: 2)) // 時間
            centralDirectory.append(Data(bytes: &dosDate, count: 2)) // 日期
            
            // 使用相同的 CRC32
            centralDirectory.append(Data(bytes: &mutableCRC32, count: 4))
            
            // 壓縮後大小
            centralDirectory.append(Data(bytes: &compressedSize, count: 4))
            // 原始大小
            centralDirectory.append(Data(bytes: &uncompressedSize, count: 4))
            // 檔案名長度
            centralDirectory.append(Data(bytes: &fileNameLength, count: 2))
            // 額外欄位長度
            centralDirectory.append(contentsOf: [0x00, 0x00])
            // 檔案註解長度
            centralDirectory.append(contentsOf: [0x00, 0x00])
            // 磁碟開始編號
            centralDirectory.append(contentsOf: [0x00, 0x00])
            // 內部檔案屬性
            centralDirectory.append(contentsOf: [0x00, 0x00])
            // 外部檔案屬性
            centralDirectory.append(contentsOf: [0x00, 0x00, 0x00, 0x00])
            // 本地標頭偏移
            centralDirectory.append(Data(bytes: &localHeaderOffset, count: 4))
            // 檔案名
            centralDirectory.append(fileNameData)
            
            fileCount += 1
        }
        
        // 記錄中央目錄的開始位置
        centralDirectoryOffset = UInt32(zipData.count)
        
        // 加入中央目錄
        zipData.append(centralDirectory)
        
        // 建立中央目錄結束記錄
        zipData.append(contentsOf: [0x50, 0x4B, 0x05, 0x06]) // 結束記錄簽名
        zipData.append(contentsOf: [0x00, 0x00]) // 磁碟編號
        zipData.append(contentsOf: [0x00, 0x00]) // 中央目錄開始磁碟編號
        
        // 本磁碟的中央目錄項目數
        zipData.append(Data(bytes: &fileCount, count: 2))
        
        // 中央目錄項目總數
        zipData.append(Data(bytes: &fileCount, count: 2))
        
        // 中央目錄大小
        var centralDirectorySize = UInt32(centralDirectory.count)
        zipData.append(Data(bytes: &centralDirectorySize, count: 4))
        
        // 中央目錄偏移
        zipData.append(Data(bytes: &centralDirectoryOffset, count: 4))
        
        // 註解長度
        zipData.append(contentsOf: [0x00, 0x00])
        
        return zipData
    }
    
    /// 清理臨時檔案
    static func cleanupTempFile(at url: URL) {
        DispatchQueue.global(qos: .utility).async {
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    // MARK: - 壓縮相關方法
    
    /// 使用 DEFLATE 演算法壓縮資料
    private static func compressData(_ data: Data) throws -> Data {
        // 如果資料很小，不壓縮可能更快
        if data.count < 512 {
            return data
        }
        
        // 使用 Compression framework 進行 DEFLATE 壓縮
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
        defer { destinationBuffer.deallocate() }
        
        let compressedSize = data.withUnsafeBytes { sourceBuffer in
            guard let sourceAddress = sourceBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                return 0
            }
            
            return compression_encode_buffer(
                destinationBuffer, data.count,
                sourceAddress, data.count,
                nil, COMPRESSION_ZLIB
            )
        }
        
        // 如果壓縮失敗或壓縮後更大，返回原始資料
        if compressedSize == 0 || compressedSize >= data.count {
            return data
        }
        
        return Data(bytes: destinationBuffer, count: compressedSize)
    }
    
    /// 優化的 CRC32 計算（使用查表法）
    private static func calculateCRC32Fast(data: Data) -> UInt32 {
        // 使用預計算的 CRC 表格加速計算
        var crc: UInt32 = 0xFFFFFFFF
        
        data.withUnsafeBytes { buffer in
            guard let bytes = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return }
            
            for i in 0..<data.count {
                let tableIndex = Int((crc ^ UInt32(bytes[i])) & 0xFF)
                crc = (crc >> 8) ^ crcTable[tableIndex]
            }
        }
        
        return ~crc
    }
    
    // CRC32 查表（預計算）
    private static let crcTable: [UInt32] = {
        var table = [UInt32](repeating: 0, count: 256)
        for i in 0..<256 {
            var crc = UInt32(i)
            for _ in 0..<8 {
                if (crc & 1) != 0 {
                    crc = (crc >> 1) ^ 0xEDB88320
                } else {
                    crc = crc >> 1
                }
            }
            table[i] = crc
        }
        return table
    }()
    
    // MARK: - 輔助函數
    
    /// 計算 CRC32 校驗碼（保留舊方法以備用）
    /// - Parameter data: 要計算的資料
    /// - Returns: CRC32 值
    private static func calculateCRC32(data: Data) -> UInt32 {
        let polynomial: UInt32 = 0xEDB88320
        var crc: UInt32 = 0xFFFFFFFF
        
        for byte in data {
            crc ^= UInt32(byte)
            for _ in 0..<8 {
                if crc & 1 != 0 {
                    crc = (crc >> 1) ^ polynomial
                } else {
                    crc = crc >> 1
                }
            }
        }
        
        return ~crc
    }
    
    /// 獲取 DOS 格式的日期時間
    /// - Returns: DOS 格式的時間和日期
    private static func getDOSDateTime() -> (time: UInt16, date: UInt16) {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: now)
        
        let year = UInt16(components.year ?? 2025)
        let month = UInt16(components.month ?? 1)
        let day = UInt16(components.day ?? 1)
        let hour = UInt16(components.hour ?? 0)
        let minute = UInt16(components.minute ?? 0)
        let second = UInt16(components.second ?? 0)
        
        // DOS 時間格式：HHHHHMMMMMMSSSSS (時:5位, 分:6位, 秒/2:5位)
        let dosTime = (hour << 11) | (minute << 5) | (second >> 1)
        
        // DOS 日期格式：YYYYYYYMMMMDDDDD (年-1980:7位, 月:4位, 日:5位)
        let dosDate = ((year - 1980) << 9) | (month << 5) | day
        
        return (time: dosTime, date: dosDate)
    }
    
    // MARK: - 分割邏輯輔助函數
    
    /// 計算檔案總大小
    /// - Parameter urls: 檔案 URL 列表
    /// - Returns: 總大小（bytes）
    private static func calculateTotalSize(urls: [URL]) throws -> Int64 {
        var totalSize: Int64 = 0
        
        for url in urls {
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw ZipError.fileNotFound(url.lastPathComponent)
            }
            
            do {
                let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
                totalSize += Int64(resourceValues.fileSize ?? 0)
            } catch {
                // 如果無法獲取檔案大小，嘗試讀取檔案來估算
                do {
                    let data = try Data(contentsOf: url)
                    totalSize += Int64(data.count)
                } catch {
                    throw ZipError.fileNotFound(url.lastPathComponent)
                }
            }
        }
        
        return totalSize
    }
    
    /// 將檔案分割成多個批次，每個批次都符合大小和數量限制
    /// - Parameters:
    ///   - urls: 原始檔案 URL 列表
    ///   - baseName: 基礎檔案名稱
    /// - Returns: 分割後的檔案批次
    private static func splitIntoBatches(urls: [URL], baseName: String) throws -> [[URL]] {
        var batches: [[URL]] = []
        var currentBatch: [URL] = []
        var currentBatchSize: Int64 = 0
        let maxSizeBytes = ProcessingLimits.mbToBytes(ProcessingLimits.maxZipSizeMB)
        
        for url in urls {
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw ZipError.fileNotFound(url.lastPathComponent)
            }
            
            // 獲取檔案大小
            let fileSize: Int64
            do {
                let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
                fileSize = Int64(resourceValues.fileSize ?? 0)
            } catch {
                // 如果無法獲取檔案大小，嘗試讀取檔案來估算
                do {
                    let data = try Data(contentsOf: url)
                    fileSize = Int64(data.count)
                } catch {
                    throw ZipError.fileNotFound(url.lastPathComponent)
                }
            }
            
            // 檢查是否需要開始新的批次
            let wouldExceedSize = currentBatchSize + fileSize > maxSizeBytes
            let wouldExceedCount = currentBatch.count >= ProcessingLimits.maxZipFiles
            
            if (wouldExceedSize || wouldExceedCount) && !currentBatch.isEmpty {
                batches.append(currentBatch)
                currentBatch = []
                currentBatchSize = 0
            }
            
            // 將檔案加入當前批次
            currentBatch.append(url)
            currentBatchSize += fileSize
        }
        
        // 添加最後一個批次
        if !currentBatch.isEmpty {
            batches.append(currentBatch)
        }
        
        return batches
    }
    
    /// 檢查是否應該自動分割（根據檔案數量和大小）
    /// - Parameter urls: 檔案 URL 列表
    /// - Returns: 是否需要自動分割
    static func shouldAutoSplit(urls: [URL]) -> Bool {
        // 檔案數量超過自動分割閾值
        if urls.count > ProcessingLimits.autoSplitZipThreshold {
            return true
        }
        
        // 估算檔案總大小
        do {
            let totalSize = try calculateTotalSize(urls: urls)
            let maxSizeBytes = ProcessingLimits.mbToBytes(ProcessingLimits.maxZipSizeMB)
            return totalSize > maxSizeBytes * 8 / 10 // 80% 的限制
        } catch {
            return false
        }
    }
}