/*
 * 功能：每日免費轉換次數追蹤服務
 *
 * 描述：追蹤免費版用戶每日的轉換次數
 * - 使用 UserDefaults 儲存當日轉換計數
 * - 每天自動重置計數器
 * - 提供剩餘次數和是否可轉換的查詢
 *
 * 創建時間：2026/3/24
 * 作者：firstfu
 */

import Foundation

// MARK: - 每日使用追蹤
/// 追蹤免費版用戶每日轉換次數的服務
class DailyUsageTracker: ObservableObject {

    // MARK: - 單例
    static let shared = DailyUsageTracker()

    // MARK: - UserDefaults Keys
    private let dailyCountKey = "dailyConversionCount"
    private let lastResetDateKey = "lastConversionResetDate"

    // MARK: - Published 狀態
    /// 當日已使用的轉換次數
    @Published private(set) var todayConversionCount: Int = 0

    // MARK: - 計算屬性
    /// 剩餘免費轉換次數
    var remainingConversions: Int {
        resetIfNewDay()
        return max(0, FreeTierLimits.dailyConversionLimit - todayConversionCount)
    }

    /// 是否還可以進行免費轉換
    var canConvert: Bool {
        return remainingConversions > 0
    }

    // MARK: - 初始化
    private init() {
        loadCurrentCount()
    }

    // MARK: - 記錄轉換
    /// 記錄一次或多次轉換使用
    /// - Parameter count: 本次轉換的檔案數量
    func recordConversion(count: Int = 1) {
        resetIfNewDay()
        todayConversionCount += count
        saveCurrentCount()
        print("📊 DailyUsageTracker: 已記錄 \(count) 次轉換，今日已用 \(todayConversionCount)/\(FreeTierLimits.dailyConversionLimit)")
    }

    // MARK: - 私有方法

    /// 檢查是否為新的一天，若是則重置計數器
    private func resetIfNewDay() {
        let lastDate = UserDefaults.standard.object(forKey: lastResetDateKey) as? Date ?? .distantPast

        if !Calendar.current.isDateInToday(lastDate) {
            todayConversionCount = 0
            UserDefaults.standard.set(0, forKey: dailyCountKey)
            UserDefaults.standard.set(Date(), forKey: lastResetDateKey)
            print("🔄 DailyUsageTracker: 新的一天，重置轉換計數")
        }
    }

    /// 從 UserDefaults 載入當前計數
    private func loadCurrentCount() {
        resetIfNewDay()
        todayConversionCount = UserDefaults.standard.integer(forKey: dailyCountKey)
    }

    /// 儲存當前計數到 UserDefaults
    private func saveCurrentCount() {
        UserDefaults.standard.set(todayConversionCount, forKey: dailyCountKey)
        UserDefaults.standard.set(Date(), forKey: lastResetDateKey)
    }
}
