//
//  APIService.swift
//  heic_to_img_ios
//
//  Created by firstfu on 2025/8/10.
//

import Foundation
import UIKit
import Combine

// MARK: - API 配置
struct APIConfig {
    static var baseURL: String {
        // 可以根據環境切換
        #if DEBUG
        // 開發環境 - 本地 API
//        return "http://localhost:8000/api/v1"
        return "http://192.168.23.103:8000/api/v1"
        #else
        // 生產環境 - 實際 API 伺服器
        return "https://api.heicmaster.com/api/v1"
        #endif
    }
}

// MARK: - API 服務
class APIService: ObservableObject {
    static let shared = APIService()

    // API 基礎 URL
    private var baseURL: String { APIConfig.baseURL }

    // URLSession 配置
    private let session: URLSession

    // 發佈者
    @Published var uploadProgress: Double = 0.0
    @Published var downloadProgress: Double = 0.0
    @Published var isUploading: Bool = false
    @Published var isDownloading: Bool = false

    private var cancellables = Set<AnyCancellable>()

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60.0
        configuration.timeoutIntervalForResource = 300.0
        self.session = URLSession(configuration: configuration)
    }

    // MARK: - 轉換單個檔案
    func convertFile(
        _ fileItem: FileItem,
        settings: ConversionSettings,
        progressHandler: @escaping (Double) -> Void,
        completion: @escaping (Result<ConversionResult, Error>) -> Void
    ) {
        Task {
            do {
                progressHandler(0.1)

                // 準備檔案資料
                let fileData: Data
                if let data = fileItem.data {
                    fileData = data
                } else if let url = fileItem.url {
                    fileData = try Data(contentsOf: url)
                } else {
                    throw APIError.invalidFileData
                }

                progressHandler(0.2)

                // 上傳並轉換
                let convertedData = try await uploadAndConvert(
                    fileData: fileData,
                    fileName: fileItem.name,
                    settings: settings,
                    progressHandler: { uploadProgress in
                        // 上傳進度佔 20%-70%
                        progressHandler(0.2 + uploadProgress * 0.5)
                    }
                )

                progressHandler(0.8)

                // 儲存轉換後的檔案
                let outputURL = try await saveConvertedFile(
                    data: convertedData.data,
                    originalFileName: fileItem.name,
                    format: settings.outputFormat
                )

                progressHandler(0.9)

                // 創建轉換結果
                let result = ConversionResult(
                    originalFile: fileItem,
                    outputURL: outputURL,
                    processingTime: convertedData.processingTime,
                    originalSize: fileItem.size,
                    outputSize: Int64(convertedData.data.count)
                )

                progressHandler(1.0)

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

    // MARK: - 批次轉換
    func convertBatchFiles(
        _ files: [FileItem],
        settings: ConversionSettings,
        progressHandler: @escaping (Double, Int, Int) -> Void,
        completion: @escaping (Result<[ConversionResult], Error>) -> Void
    ) {
        Task {
            var results: [ConversionResult] = []
            var errors: [Error] = []
            let totalFiles = files.count

            for (index, file) in files.enumerated() {
                do {
                    // 轉換單個檔案
                    let result = try await withCheckedThrowingContinuation { continuation in
                        convertFile(
                            file,
                            settings: settings,
                            progressHandler: { _ in
                                // 個別檔案進度暫不處理
                            },
                            completion: { result in
                                continuation.resume(with: result)
                            }
                        )
                    }

                    results.append(result)

                } catch {
                    errors.append(error)
                }

                // 更新整體進度
                let completedFiles = results.count + errors.count
                let progress = Double(completedFiles) / Double(totalFiles)

                DispatchQueue.main.async {
                    progressHandler(progress, completedFiles, totalFiles)
                }
            }

            DispatchQueue.main.async {
                if errors.isEmpty {
                    completion(.success(results))
                } else if results.isEmpty {
                    completion(.failure(errors.first ?? APIError.unknownError))
                } else {
                    // 部分成功
                    completion(.success(results))
                }
            }
        }
    }

    // MARK: - 私有方法

    private func uploadAndConvert(
        fileData: Data,
        fileName: String,
        settings: ConversionSettings,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> (data: Data, processingTime: TimeInterval) {

        let startTime = Date()

        // 創建請求
        guard let url = URL(string: "\(baseURL)/convert") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // 創建 multipart/form-data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // 添加檔案
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/heic\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)

        // 添加格式參數
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"format\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(settings.outputFormat.rawValue)\r\n".data(using: .utf8)!)

        // 添加品質參數（JPEG）
        if settings.outputFormat == .jpeg {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"quality\"\r\n\r\n".data(using: .utf8)!)
            let quality = Int(settings.jpegQuality * 100)
            body.append("\(quality)\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        // 執行請求
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }

        // 解析響應
        let apiResponse = try JSONDecoder().decode(APIConversionResponse.self, from: data)

        guard apiResponse.success,
              let dataURL = apiResponse.dataURL else {
            throw APIError.conversionFailed(apiResponse.message ?? "Unknown error")
        }

        // 從 data URL 提取圖片資料
        guard let imageData = Data(base64Encoded: dataURL.replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
                                                     .replacingOccurrences(of: "data:image/png;base64,", with: "")) else {
            throw APIError.invalidImageData
        }

        let processingTime = Date().timeIntervalSince(startTime)

        return (data: imageData, processingTime: processingTime)
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
}

// MARK: - API 錯誤
enum APIError: LocalizedError {
    case invalidURL
    case invalidFileData
    case invalidResponse
    case invalidImageData
    case serverError(statusCode: Int)
    case conversionFailed(String)
    case networkError(Error)
    case unknownError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無效的 API URL"
        case .invalidFileData:
            return "無法讀取檔案資料"
        case .invalidResponse:
            return "伺服器回應無效"
        case .invalidImageData:
            return "無效的圖片資料"
        case .serverError(let statusCode):
            return "伺服器錯誤 (狀態碼: \(statusCode))"
        case .conversionFailed(let message):
            return "轉換失敗: \(message)"
        case .networkError(let error):
            return "網路錯誤: \(error.localizedDescription)"
        case .unknownError:
            return "未知錯誤"
        }
    }
}

// MARK: - API 響應模型
struct APIConversionResponse: Codable {
    let success: Bool
    let message: String?
    let filename: String?
    let originalSize: Int?
    let convertedSize: Int?
    let dataURL: String?

    enum CodingKeys: String, CodingKey {
        case success
        case message
        case filename
        case originalSize = "original_size"
        case convertedSize = "converted_size"
        case dataURL = "data_url"
    }
}

// MARK: - DateFormatter 擴展
extension DateFormatter {
    static let fileNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter
    }()
}
