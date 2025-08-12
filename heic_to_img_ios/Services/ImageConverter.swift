//
//  ImageConverter.swift
//  heic_to_img_ios
//
//  Created by firstfu on 2025/8/10.
//

import Foundation
import Combine

// MARK: - 圖像轉換服務（使用本地轉換）
class ImageConverter: ObservableObject {
    static let shared = ImageConverter()
    
    // 轉換進度追蹤
    @Published var currentProgress: Double = 0.0
    @Published var isConverting: Bool = false
    
    // 使用本地轉換服務而非 API
    private let localConverter = LocalImageConverterService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - 單檔案轉換（透過本地轉換）
    func convertSingleFile(
        _ fileItem: FileItem,
        settings: ConversionSettings,
        progressHandler: @escaping (Double) -> Void,
        completion: @escaping (Result<ConversionResult, Error>) -> Void
    ) {
        Task {
            do {
                let result = try await localConverter.convertFile(
                    fileItem,
                    settings: settings,
                    progressHandler: progressHandler
                )
                
                DispatchQueue.main.async {
                    completion(.success(result))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - 批次轉換（透過本地轉換）
    func convertBatchFiles(
        _ files: [FileItem],
        settings: ConversionSettings,
        progressHandler: @escaping (Double, Int, Int) -> Void,
        completion: @escaping (Result<[ConversionResult], Error>) -> Void
    ) {
        isConverting = true
        
        Task {
            do {
                let results = try await localConverter.convertBatchFiles(
                    files,
                    settings: settings,
                    progressHandler: progressHandler
                )
                
                DispatchQueue.main.async { [weak self] in
                    self?.isConverting = false
                    completion(.success(results))
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.isConverting = false
                    completion(.failure(error))
                }
            }
        }
    }
}

// MARK: - 轉換錯誤
enum ConversionError: LocalizedError {
    case invalidImageFormat
    case unsupportedFormat
    case fileAccessDenied
    case imageTooLarge
    case insufficientMemory
    case saveFailed
    case networkError(String)
    case apiError(String)
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .invalidImageFormat:
            return "無效的圖像格式"
        case .unsupportedFormat:
            return "不支援的檔案格式"
        case .fileAccessDenied:
            return "無法存取檔案"
        case .imageTooLarge:
            return "圖像尺寸過大"
        case .insufficientMemory:
            return "記憶體不足"
        case .saveFailed:
            return "保存檔案失敗"
        case .networkError(let message):
            return "網路錯誤: \(message)"
        case .apiError(let message):
            return "API 錯誤: \(message)"
        case .unknownError:
            return "未知錯誤"
        }
    }
}