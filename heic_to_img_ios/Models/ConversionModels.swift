/*
 * 功能：圖片轉換相關的資料模型
 * 
 * 描述：定義圖片轉換功能所需的各種資料結構
 * - 轉換格式的枚舉和相關屬性
 * - 轉換設定的管理類別
 * - 檔案項目的結構體
 * - 轉換狀態和作業的管理
 * - 轉換結果和統計資料
 * 
 * 創建時間：2025/8/10
 * 作者：firstfu
 */

//
//  ConversionModels.swift
//  heic_to_img_ios
//
//  Created by firstfu on 2025/8/10.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import UIKit

// MARK: - 轉換格式
/// 支援的圖片轉換格式列舉
/// 定義了 HEIC 可以轉換的目標格式
enum ConversionFormat: String, CaseIterable {
    case png = "png"
    case jpeg = "jpeg"
    
    /// 在 UI 中顯示的格式名稱
    var displayName: String {
        switch self {
        case .png: return "PNG"
        case .jpeg: return "JPEG"
        }
    }
    
    /// 檔案副檔名
    var fileExtension: String {
        return rawValue
    }
    
    /// 系統識別的檔案類型
    var utType: UTType {
        switch self {
        case .png: return .png
        case .jpeg: return .jpeg
        }
    }
    
    /// 格式對應的 SF Symbol 圖示
    var icon: String {
        switch self {
        case .png: return "doc.richtext"
        case .jpeg: return "photo"
        }
    }
}

// MARK: - 轉換設定
/// 轉換參數設定的管理類別
/// 管理所有與圖片轉換相關的參數和選項
class ConversionSettings: ObservableObject {
    /// 輸出格式
    @Published var outputFormat: ConversionFormat = .jpeg
    /// JPEG 品質（0.0 - 1.0）
    @Published var jpegQuality: Double = 0.9
    /// 是否保留元數據
    @Published var preserveMetadata: Bool = true
    /// 自訂縮放比例
    @Published var customScale: Double = 1.0
    /// 是否需要調整大小
    @Published var shouldResize: Bool = false
    /// 最大尺寸限制
    @Published var maxDimension: CGFloat = 2048
    
    // 批次處理設定
    /// 一次處理的檔案數量
    @Published var batchSize: Int = 10
    /// 是否啟用並行處理
    @Published var enableParallelProcessing: Bool = true
    
    /// 重設所有設定為預設值
    func reset() {
        outputFormat = .jpeg
        jpegQuality = 0.9
        preserveMetadata = true
        customScale = 1.0
        shouldResize = false
        maxDimension = 2048
        batchSize = 10
        enableParallelProcessing = true
    }
}

// MARK: - 檔案項目
/// 代表一個檔案項目的結構體
/// 包含檔案的基本資訊和屬性
struct FileItem: Identifiable, Hashable {
    /// 唯一識別符
    let id = UUID()
    /// 檔案的 URL 位置（可選，記憶體資料時為 nil）
    let url: URL?
    /// 檔案的記憶體資料（用於實機上處理 PHAsset）
    let data: Data?
    /// 檔案名稱
    let name: String
    /// 檔案大小（位元組）
    let size: Int64
    /// 縮圖數據（目前未使用）
    let thumbnailData: Data?
    /// 檔案建立日期
    let creationDate: Date?
    
    /// 格式化後的檔案大小字串
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    /// 判斷是否為 HEIC 格式檔案
    var isHEIC: Bool {
        if let url = url {
            return url.pathExtension.lowercased() == "heic" || url.pathExtension.lowercased() == "heif"
        } else {
            // 對於記憶體資料，根據檔案名稱判斷
            return name.lowercased().hasSuffix(".heic") || name.lowercased().hasSuffix(".heif")
        }
    }
    
    
    /// 初始化檔案項目（從 URL）
    /// - Parameter url: 檔案的 URL 位置
    init(url: URL) {
        self.url = url
        self.data = nil
        self.name = url.lastPathComponent
        
        // 獲取檔案大小
        do {
            let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey, .creationDateKey])
            self.size = Int64(resourceValues.fileSize ?? 0)
            self.creationDate = resourceValues.creationDate
        } catch {
            self.size = 0
            self.creationDate = nil
        }
        
        self.thumbnailData = nil
    }
    
    /// 初始化檔案項目（從記憶體資料）
    /// - Parameters:
    ///   - data: 檔案的記憶體資料
    ///   - name: 檔案名稱
    ///   - creationDate: 建立日期
    init(data: Data, name: String, creationDate: Date? = nil) {
        self.url = nil
        self.data = data
        self.name = name
        self.size = Int64(data.count)
        self.creationDate = creationDate
        self.thumbnailData = nil
    }
}

// MARK: - 轉換狀態
/// 轉換作業的各種狀態
/// 用於追蹤轉換進度和結果
enum ConversionStatus: Equatable {
    case pending
    case processing
    case completed
    case failed(Error)
    
    static func == (lhs: ConversionStatus, rhs: ConversionStatus) -> Bool {
        switch (lhs, rhs) {
        case (.pending, .pending), (.processing, .processing), (.completed, .completed):
            return true
        case (.failed, .failed):
            return true
        default:
            return false
        }
    }
    
    /// 狀態在 UI 中的顯示文字
    var displayText: String {
        switch self {
        case .pending: return "等待中"
        case .processing: return "轉換中..."
        case .completed: return "完成"
        case .failed: return "失敗"
        }
    }
    
    /// 狀態對應的顏色
    var color: Color {
        switch self {
        case .pending: return .secondary
        case .processing: return .blue
        case .completed: return .green
        case .failed: return .red
        }
    }
}

// MARK: - 轉換任務
/// 單一轉換作業的管理類別
/// 追蹤一個檔案的轉換進度和狀態
class ConversionJob: ObservableObject, Identifiable {
    /// 唯一識別符
    let id = UUID()
    /// 要轉換的檔案項目
    @Published var fileItem: FileItem
    /// 轉換狀態
    @Published var status: ConversionStatus = .pending
    /// 轉換進度（0.0 - 1.0）
    @Published var progress: Double = 0.0
    /// 輸出檔案的 URL
    @Published var outputURL: URL?
    /// 轉換錯誤（如有）
    @Published var error: Error?
    
    /// 轉換設定參數
    let settings: ConversionSettings
    /// 開始轉換的時間
    let startTime: Date
    
    /// 初始化轉換作業
    /// - Parameters:
    ///   - fileItem: 要轉換的檔案
    ///   - settings: 轉換設定
    init(fileItem: FileItem, settings: ConversionSettings) {
        self.fileItem = fileItem
        self.settings = settings
        self.startTime = Date()
    }
    
    /// 輸出檔案名稱
    var outputFileName: String {
        let baseName: String
        if let url = fileItem.url {
            baseName = url.deletingPathExtension().lastPathComponent
        } else {
            // 對於記憶體資料，從檔案名稱中取得基本名稱
            let nameWithoutExtension = (fileItem.name as NSString).deletingPathExtension
            baseName = nameWithoutExtension
        }
        return "\(baseName).\(settings.outputFormat.fileExtension)"
    }
}

// MARK: - 轉換結果
/// 單一檔案轉換的結果資料
/// 包含轉換前後的詳細資訊
struct ConversionResult: Identifiable {
    /// 唯一識別符
    let id = UUID()
    /// 原始檔案項目
    let originalFile: FileItem
    /// 輸出檔案的 URL
    let outputURL: URL
    /// 轉換處理時間
    let processingTime: TimeInterval
    /// 原始檔案大小
    let originalSize: Int64
    /// 輸出檔案大小
    let outputSize: Int64
    
    /// 壓縮比率（輸出/原始）
    var compressionRatio: Double {
        guard originalSize > 0 else { return 0 }
        return Double(outputSize) / Double(originalSize)
    }
    
    /// 節省的空間（正值表示節省，負值表示增加）
    var savedSpace: Int64 {
        return originalSize - outputSize
    }
    
    /// 格式化後的空間節省說明
    var savedSpaceString: String {
        if savedSpace > 0 {
            return "節省 \(ByteCountFormatter.string(fromByteCount: savedSpace, countStyle: .file))"
        } else {
            let increased = -savedSpace
            return "增加 \(ByteCountFormatter.string(fromByteCount: increased, countStyle: .file))"
        }
    }
}

// MARK: - 批次轉換統計
/// 批次轉換的統計資料類別
/// 提供整批轉換作業的統計資訊
class BatchConversionStats: ObservableObject {
    /// 總檔案數
    var totalFiles: Int = 0
    /// 完成轉換的檔案數
    var completedFiles: Int = 0
    /// 失敗的檔案數
    var failedFiles: Int = 0
    /// 總原始檔案大小
    var totalOriginalSize: Int64 = 0
    /// 總輸出檔案大小
    var totalOutputSize: Int64 = 0
    /// 總處理時間
    var totalProcessingTime: TimeInterval = 0
    
    /// 轉換成功率
    var successRate: Double {
        guard totalFiles > 0 else { return 0 }
        return Double(completedFiles) / Double(totalFiles)
    }
    
    /// 平均處理時間
    var averageProcessingTime: TimeInterval {
        guard completedFiles > 0 else { return 0 }
        return totalProcessingTime / Double(completedFiles)
    }
    
    /// 總節省空間
    var totalSavedSpace: Int64 {
        return totalOriginalSize - totalOutputSize
    }
}