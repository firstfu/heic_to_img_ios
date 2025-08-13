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

/// 簡化的 ZIP 壓縮服務
class SimpleZipService {
    
    /// ZIP 相關錯誤
    enum ZipError: Error, LocalizedError {
        case fileNotFound(String)
        case compressionFailed
        case invalidData
        
        var errorDescription: String? {
            switch self {
            case .fileNotFound(let filename):
                return "找不到檔案：\(filename)"
            case .compressionFailed:
                return "壓縮失敗"
            case .invalidData:
                return "無效的檔案資料"
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
    
    /// 建立 ZIP 檔案資料
    private static func createZipData(from urls: [URL]) throws -> Data {
        var zipData = Data()
        var centralDirectory = Data()
        var centralDirectoryOffset: UInt32 = 0
        var fileCount: UInt16 = 0
        
        // 處理每個檔案
        for url in urls {
            // 檢查檔案是否存在
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw ZipError.fileNotFound(url.lastPathComponent)
            }
            
            // 讀取檔案資料
            let fileData = try Data(contentsOf: url)
            let fileName = url.lastPathComponent
            let fileNameData = fileName.data(using: .utf8) ?? Data()
            
            // 計算正確的 CRC32
            let crc32 = calculateCRC32(data: fileData)
            
            // 獲取 DOS 格式的時間和日期
            let dosDateTime = getDOSDateTime()
            
            // 記錄當前位置作為本地檔案頭部偏移
            var localHeaderOffset = UInt32(zipData.count)
            
            // 建立本地檔案頭部 (30 bytes + filename length)
            zipData.append(contentsOf: [0x50, 0x4B, 0x03, 0x04]) // 本地檔案頭簽名
            zipData.append(contentsOf: [0x14, 0x00]) // 版本
            zipData.append(contentsOf: [0x00, 0x00]) // 標誌
            zipData.append(contentsOf: [0x00, 0x00]) // 壓縮方法 (0 = 存儲)
            
            // 時間和日期（DOS 格式）
            var dosTime = dosDateTime.time
            zipData.append(Data(bytes: &dosTime, count: 2))
            var dosDate = dosDateTime.date  
            zipData.append(Data(bytes: &dosDate, count: 2))
            
            // CRC32 校驗碼
            var mutableCRC32 = crc32
            zipData.append(Data(bytes: &mutableCRC32, count: 4))
            
            // 檔案大小 (壓縮後)
            var compressedSize = UInt32(fileData.count)
            zipData.append(Data(bytes: &compressedSize, count: 4))
            
            // 檔案大小 (原始)
            var uncompressedSize = UInt32(fileData.count)
            zipData.append(Data(bytes: &uncompressedSize, count: 4))
            
            // 檔案名長度
            var fileNameLength = UInt16(fileNameData.count)
            zipData.append(Data(bytes: &fileNameLength, count: 2))
            
            // 額外欄位長度
            zipData.append(contentsOf: [0x00, 0x00])
            
            // 檔案名
            zipData.append(fileNameData)
            
            // 檔案資料
            zipData.append(fileData)
            
            // 建立中央目錄項目
            centralDirectory.append(contentsOf: [0x50, 0x4B, 0x01, 0x02]) // 中央目錄簽名
            centralDirectory.append(contentsOf: [0x14, 0x00]) // 製作版本
            centralDirectory.append(contentsOf: [0x14, 0x00]) // 解壓版本
            centralDirectory.append(contentsOf: [0x00, 0x00]) // 標誌
            centralDirectory.append(contentsOf: [0x00, 0x00]) // 壓縮方法
            
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
    
    // MARK: - 輔助函數
    
    /// 計算 CRC32 校驗碼
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
}