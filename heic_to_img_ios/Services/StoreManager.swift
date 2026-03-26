/*
 * 功能：StoreKit 2 購買管理服務
 *
 * 描述：管理 In-App Purchase 的購買、驗證、恢復流程
 * - 使用 StoreKit 2 modern async/await API
 * - 支援一次性買斷（Non-Consumable）
 * - 自動監聽交易更新
 * - 從 Transaction.currentEntitlements 驗證購買狀態
 *
 * 創建時間：2026/3/24
 * 作者：firstfu
 */

import StoreKit
import Combine

// MARK: - StoreKit 購買管理
/// 管理 In-App Purchase 的核心服務類別
/// 使用 StoreKit 2 API，支援一次性買斷模式
class StoreManager: ObservableObject {

    // MARK: - 單例
    static let shared = StoreManager()

    // MARK: - 產品 ID
    /// 專業版一次性買斷的產品 ID
    static let proProductID = "com.heicmaster.pro.lifetime"

    // MARK: - Published 狀態
    /// 可購買的產品清單
    @Published private(set) var products: [Product] = []
    /// 已購買的產品 ID 集合
    @Published private(set) var purchasedProductIDs: Set<String> = []
    /// 是否正在載入或處理中
    @Published private(set) var isLoading = false
    /// 錯誤訊息
    @Published var errorMessage: String?

    // MARK: - 計算屬性
    /// 是否為專業版用戶
    var isPro: Bool {
        purchasedProductIDs.contains(Self.proProductID)
    }

    /// 專業版產品資訊
    var proProduct: Product? {
        products.first { $0.id == Self.proProductID }
    }

    // MARK: - 私有屬性
    /// 交易監聽任務
    private var transactionListener: Task<Void, Error>?

    // MARK: - 初始化
    private init() {
        // 啟動交易監聽（處理來自其他裝置或家庭共享的交易）
        transactionListener = listenForTransactions()

        // 載入產品和驗證購買狀態
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - 載入產品
    /// 從 App Store 載入可購買的產品資訊
    @MainActor
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let storeProducts = try await Product.products(for: [Self.proProductID])
            products = storeProducts

            if storeProducts.isEmpty {
                print("⚠️ StoreManager: 未找到任何產品，請確認 Product ID 設定")
            } else {
                print("✅ StoreManager: 成功載入 \(storeProducts.count) 個產品")
            }
        } catch {
            print("❌ StoreManager: 載入產品失敗 - \(error.localizedDescription)")
            errorMessage = "無法載入產品資訊，請檢查網路連線後重試"
        }
    }

    // MARK: - 購買
    /// 執行專業版購買流程
    /// - Returns: 購買是否成功
    @MainActor
    @discardableResult
    func purchase() async -> Bool {
        // 如果產品尚未載入，嘗試重新載入一次
        if proProduct == nil {
            await loadProducts()
        }

        guard let product = proProduct else {
            errorMessage = "無法取得產品資訊，請檢查網路連線後重試"
            return false
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                // 驗證交易
                let transaction = try checkVerified(verification)

                // 更新購買狀態
                await updatePurchasedProducts()

                // 完成交易
                await transaction.finish()

                print("✅ StoreManager: 購買成功")
                return true

            case .userCancelled:
                print("ℹ️ StoreManager: 用戶取消購買")
                return false

            case .pending:
                print("ℹ️ StoreManager: 購買等待中（家長控制等）")
                errorMessage = "購買正在等待核准"
                return false

            @unknown default:
                return false
            }
        } catch StoreKitError.userCancelled {
            print("ℹ️ StoreManager: 用戶取消購買")
            return false
        } catch {
            print("❌ StoreManager: 購買失敗 - \(error.localizedDescription)")
            errorMessage = "購買失敗：\(error.localizedDescription)"
            return false
        }
    }

    // MARK: - 恢復購買
    /// 恢復之前的購買紀錄
    @MainActor
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // 同步交易紀錄
            try await AppStore.sync()

            // 重新驗證購買狀態
            await updatePurchasedProducts()

            if isPro {
                print("✅ StoreManager: 成功恢復購買")
            } else {
                print("ℹ️ StoreManager: 未找到之前的購買紀錄")
                errorMessage = "未找到之前的購買紀錄"
            }
        } catch {
            print("❌ StoreManager: 恢復購買失敗 - \(error.localizedDescription)")
            errorMessage = "恢復購買失敗，請稍後再試"
        }
    }

    // MARK: - 更新購買狀態
    /// 從 Transaction.currentEntitlements 驗證當前的購買狀態
    /// 這是判斷 isPro 的權威來源
    @MainActor
    func updatePurchasedProducts() async {
        var purchasedIDs: Set<String> = []

        // 迭代所有當前的權益
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                // 只處理未撤銷的交易
                if transaction.revocationDate == nil {
                    purchasedIDs.insert(transaction.productID)
                }
            } catch {
                print("⚠️ StoreManager: 交易驗證失敗 - \(error.localizedDescription)")
            }
        }

        purchasedProductIDs = purchasedIDs
    }

    // MARK: - 交易監聽
    /// 監聽來自其他裝置、家庭共享等的交易更新
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    let transaction = try self?.checkVerified(result)

                    // 更新購買狀態
                    await self?.updatePurchasedProducts()

                    // 完成交易
                    await transaction?.finish()
                } catch {
                    print("⚠️ StoreManager: 交易更新處理失敗 - \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - 交易驗證
    /// 驗證 StoreKit 交易的有效性
    /// - Parameter result: StoreKit 驗證結果
    /// - Returns: 驗證通過的交易
    /// - Throws: 驗證失敗時拋出錯誤
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
}
