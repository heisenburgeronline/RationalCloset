import SwiftUI
import Foundation
import Combine

// MARK: - Monthly Title Model
struct MonthlyTitle {
    var title: String
    var subtitle: String
    var icon: String
    var color: Color
}

class WardrobeStore: ObservableObject {
    @Published var items: [ClothingItem] = []
    
    // Smart Budget System - Three separate budgets for different time periods
    @Published var budgetWeekly: Double = 500.0
    @Published var budgetMonthly: Double = 2000.0
    @Published var budgetYearly: Double = 20000.0
    
    @Published var coldThresholdDays: Int = 60
    @Published var dailyNotes: [String: String] = [:] // Key: date string (yyyy-MM-dd), Value: note
    
    // Track items affected by last copy operation for undo
    private var lastCopiedItemIDs: [UUID] = []
    
    private let storageKey: String = "MyWardrobeItems"
    private let budgetWeeklyKey: String = "BudgetWeekly"
    private let budgetMonthlyKey: String = "BudgetMonthly"
    private let budgetYearlyKey: String = "BudgetYearly"
    private let coldThresholdKey: String = "ColdThresholdDays"
    private let dailyNotesKey: String = "DailyOutfitNotes"
    
    init() {
        loadData()
        loadBudgets()
        loadColdThreshold()
        loadDailyNotes()
        migrateImagesToFilesystem()
    }
    
    // MARK: - Migration: Convert Data to Filesystem
    
    /// Migrates existing image Data to filesystem (one-time migration)
    private func migrateImagesToFilesystem() {
        var needsSave = false
        
        for index in items.indices {
            var item = items[index]
            
            // Skip if already migrated (has filenames) or no legacy data
            if !item.imageFilenames.isEmpty || item.imagesData.isEmpty {
                continue
            }
            
            print("🔄 Migrating images for item: \(item.category) (\(item.imagesData.count) images)")
            
            var migratedFilenames: [String] = []
            
            for imageData in item.imagesData {
                if let filename = ImageManager.shared.migrateDataToFile(imageData) {
                    migratedFilenames.append(filename)
                }
            }
            
            // Update item with filenames and clear old data
            item.imageFilenames = migratedFilenames
            item.imagesData = [] // Clear to free memory
            items[index] = item
            needsSave = true
            
            print("✅ Migrated \(migratedFilenames.count) images")
        }
        
        if needsSave {
            saveData()
            print("✅ Migration complete. Saved updated data.")
            
            // Print storage info
            let info = ImageManager.shared.getStorageInfo()
            print("📊 Storage: \(info.count) images, \(info.totalSizeKB)KB total")
        }
    }
    
    // MARK: - 基础 CRUD
    func addNewItem(newItem: ClothingItem) {
        items.append(newItem)
        saveData()
    }
    
    func deleteItem(item: ClothingItem) {
        // Delete associated images from filesystem
        for filename in item.imageFilenames {
            ImageManager.shared.deleteImage(filename: filename)
        }
        items.removeAll { $0.id == item.id }
        saveData()
    }
    
    func deleteItemById(id: UUID) {
        // Find item and delete images
        if let item = items.first(where: { $0.id == id }) {
            for filename in item.imageFilenames {
                ImageManager.shared.deleteImage(filename: filename)
            }
        }
        items.removeAll { $0.id == id }
        saveData()
    }
    
    func markAsSold(item: ClothingItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].status = .sold
            items[index].soldDate = Date()
            saveData()
        }
    }
    
    func markAsSoldById(id: UUID, soldPrice: Double?, soldDate: Date?, soldNotes: String?) {
        if let index = items.firstIndex(where: { $0.id == id }) {
            items[index].status = .sold
            items[index].soldPrice = soldPrice
            items[index].soldDate = soldDate ?? Date()
            items[index].soldNotes = soldNotes
            saveData()
        }
    }
    
    func addWearDate(id: UUID, date: Date = Date()) {
        if let index = items.firstIndex(where: { $0.id == id }) {
            items[index].wearDates.append(date)
            saveData()
        }
    }
    
    func removeWearDate(id: UUID, date: Date) {
        if let index = items.firstIndex(where: { $0.id == id }) {
            // Remove the specific wear date
            items[index].wearDates.removeAll { wearDate in
                Calendar.current.isDate(wearDate, inSameDayAs: date)
            }
            saveData()
        }
    }
    
    func updateItem(updatedItem: ClothingItem) {
        if let index = items.firstIndex(where: { $0.id == updatedItem.id }) {
            items[index] = updatedItem
            saveData()
        }
    }
    
    // MARK: - 查询与筛选
    func getColdPalaceItems() -> [ClothingItem] {
        // Exclude underwear/loungewear and accessories from cold palace tracking
        let excludedCategories = ["内衣居家", "配饰", "场景功能"]
        return items.filter { item in
            !excludedCategories.contains(item.category) && item.isCold(threshold: coldThresholdDays)
        }
        .sorted { $0.purchaseDate < $1.purchaseDate }
    }
    
    func getColdItemsCount() -> Int {
        let excludedCategories = ["内衣居家", "配饰", "场景功能"]
        return items.filter { item in
            !excludedCategories.contains(item.category) && item.isCold(threshold: coldThresholdDays)
        }.count
    }
    
    func getItemsForCategory(categoryName: String) -> [ClothingItem] {
        items.filter { $0.category == categoryName }
             .sorted { $0.date > $1.date }
    }
    
    func getActiveItems() -> [ClothingItem] {
        items.filter { $0.status == .active }.sorted { $0.date > $1.date }
    }
    
    func getAllItemsSorted() -> [ClothingItem] {
        items.sorted { $0.date > $1.date }
    }
    
    func getRecentlyAddedItems() -> [ClothingItem] {
        let sorted = items.filter { $0.status == .active }.sorted { $0.date > $1.date }
        return Array(sorted.prefix(10))
    }
    
    func getItemsGroupedByMonth(includeSold: Bool, searchQuery: String) -> [MonthlyGroup] {
        var filteredItems = includeSold ? getAllItemsSorted() : getActiveItems()
        
        if !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let lowercasedQuery = searchQuery.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            filteredItems = filteredItems.filter { item in
                item.category.lowercased().contains(lowercasedQuery) ||
                item.platform.lowercased().contains(lowercasedQuery) ||
                item.reason.lowercased().contains(lowercasedQuery) ||
                item.size.lowercased().contains(lowercasedQuery)
            }
        }
        
        var groupDict: [String: [ClothingItem]] = [:]
        var sortDateDict: [String: Date] = [:]
        
        for item in filteredItems {
            let key = item.monthYearKey
            if groupDict[key] == nil {
                groupDict[key] = []
                sortDateDict[key] = item.sortableMonthYear
            }
            groupDict[key]?.append(item)
        }
        
        return groupDict.map { key, items in
            MonthlyGroup(monthKey: key, sortDate: sortDateDict[key] ?? Date(), items: items)
        }.sorted { $0.sortDate > $1.sortDate }
    }
    
    func searchItems(query: String, includeSold: Bool) -> [ClothingItem] {
        var result = includeSold ? getAllItemsSorted() : getActiveItems()
        
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return result
        }
        
        let lowercasedQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        result = result.filter { item in
            item.category.lowercased().contains(lowercasedQuery) ||
            item.platform.lowercased().contains(lowercasedQuery) ||
            item.reason.lowercased().contains(lowercasedQuery) ||
            item.size.lowercased().contains(lowercasedQuery)
        }
        
        return result
    }
    
    // MARK: - 统计计算
    func calculateTotalSpending(forPeriod period: StatisticsPeriod) -> Double {
        let filtered = getItemsForPeriod(period: period)
        if filtered.isEmpty { return 0.0 }
        return filtered.reduce(0.0) { $0 + $1.price }
    }
    
    func calculateTotalCount(forPeriod period: StatisticsPeriod) -> Int {
        return getItemsForPeriod(period: period).count
    }
    
    func calculateMoneySaved(forPeriod period: StatisticsPeriod) -> Double {
        let spending = calculateTotalSpending(forPeriod: period)
        let budget = getBudgetForPeriod(period: period)
        return budget - spending
    }
    
    func calculateTotalRecovered(forPeriod period: StatisticsPeriod) -> Double {
        let soldItems = items.filter { $0.status == .sold && $0.soldPrice != nil }
        if soldItems.isEmpty { return 0.0 }
        
        let calendar = Calendar.current
        let now = Date()
        
        let filtered = soldItems.filter { item in
            guard let soldDate = item.soldDate else { return false }
            switch period {
            case .week:
                if let daysAgo = calendar.date(byAdding: .day, value: -7, to: now) {
                    return soldDate >= daysAgo
                }
                return false
            case .month:
                if let daysAgo = calendar.date(byAdding: .day, value: -30, to: now) {
                    return soldDate >= daysAgo
                }
                return false
            case .year:
                if let daysAgo = calendar.date(byAdding: .day, value: -365, to: now) {
                    return soldDate >= daysAgo
                }
                return false
            }
        }
        return filtered.compactMap { $0.soldPrice }.reduce(0.0, +)
    }
    
    func calculateAllTimeRecovered() -> Double {
        return items.filter { $0.status == .sold }
            .compactMap { $0.soldPrice }
            .reduce(0.0, +)
    }
    
    func calculateNetSpending(forPeriod period: StatisticsPeriod) -> Double {
        let spent = calculateTotalSpending(forPeriod: period)
        let recovered = calculateTotalRecovered(forPeriod: period)
        return spent - recovered
    }
    
    func getSpendingByCategory(forPeriod period: StatisticsPeriod) -> [CategorySpending] {
        let filtered = getItemsForPeriod(period: period)
        var categoryDict: [String: Double] = [:]
        
        for item in filtered {
            categoryDict[item.category, default: 0] += item.price
        }
        
        return categoryDict.map { CategorySpending(category: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }
    
    func getItemsForPeriod(period: StatisticsPeriod) -> [ClothingItem] {
        if items.isEmpty { return [] }
        let calendar = Calendar.current
        let now = Date()
        return items.filter { item in
            switch period {
            case .week:
                if let daysAgo = calendar.date(byAdding: .day, value: -7, to: now) {
                    return item.date >= daysAgo
                }
                return false
            case .month:
                if let daysAgo = calendar.date(byAdding: .day, value: -30, to: now) {
                    return item.date >= daysAgo
                }
                return false
            case .year:
                if let daysAgo = calendar.date(byAdding: .day, value: -365, to: now) {
                    return item.date >= daysAgo
                }
                return false
            }
        }
    }
    
    func getBudgetForPeriod(period: StatisticsPeriod) -> Double {
        switch period {
        case .week: return budgetWeekly
        case .month: return budgetMonthly
        case .year: return budgetYearly
        }
    }
    
    // MARK: - Calendar / OOTD Helpers
    func getOutfit(for date: Date) -> [ClothingItem] {
        let calendar = Calendar.current
        
        return items.filter { item in
            item.wearDates.contains { wearDate in
                calendar.isDate(wearDate, inSameDayAs: date)
            }
        }.sorted { $0.category < $1.category }
    }
    
    func getDatesWithOutfits(in month: Date) -> Set<DateComponents> {
        let calendar = Calendar.current
        let monthComponents = calendar.dateComponents([.year, .month], from: month)
        
        var datesWithItems: Set<DateComponents> = []
        
        for item in items {
            for wearDate in item.wearDates {
                let wearComponents = calendar.dateComponents([.year, .month], from: wearDate)
                if wearComponents.year == monthComponents.year && wearComponents.month == monthComponents.month {
                    let dayComponents = calendar.dateComponents([.year, .month, .day], from: wearDate)
                    datesWithItems.insert(dayComponents)
                }
            }
        }
        
        return datesWithItems
    }
    
    // MARK: - Gamification: Monthly Title
    func calculateMonthlyTitle() -> MonthlyTitle {
        let calendar = Calendar.current
        let now = Date()
        
        // Get items from the current calendar month
        let currentMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        let nextMonthStart = calendar.date(byAdding: .month, value: 1, to: currentMonthStart) ?? now
        
        // Filter items purchased in current month
        let currentMonthItems = items.filter { item in
            item.date >= currentMonthStart && item.date < nextMonthStart
        }
        
        // Calculate spending for current month
        let currentMonthSpending = currentMonthItems.reduce(0.0) { $0 + $1.price }
        
        // Calculate sold items in current month
        let currentMonthSold = items.filter { item in
            guard let soldDate = item.soldDate else { return false }
            return soldDate >= currentMonthStart && soldDate < nextMonthStart
        }
        let soldAmount = currentMonthSold.compactMap { $0.soldPrice }.reduce(0.0, +)
        let soldCount = currentMonthSold.count
        
        // Calculate item count
        let itemCount = currentMonthItems.count
        
        // Title Logic (Priority Order)
        
        // 1. Zero Spend
        if currentMonthSpending == 0 && itemCount == 0 {
            return MonthlyTitle(
                title: "清心寡欲仙人",
                subtitle: "施主，您已经跳出三界外了",
                icon: "sparkles",
                color: .purple
            )
        }
        
        // 2. High Resale (> ¥500)
        if soldAmount > 500 {
            return MonthlyTitle(
                title: "回血大师",
                subtitle: "您的衣柜竟然是理财产品",
                icon: "yensign.circle.fill",
                color: .orange
            )
        }
        
        // 3. High Spender (> 150% Budget)
        if currentMonthSpending > budgetMonthly * 1.5 {
            return MonthlyTitle(
                title: "钱包粉碎机",
                subtitle: "再买就要去天桥贴膜了",
                icon: "exclamationmark.triangle.fill",
                color: .red
            )
        }
        
        // 4. Low Spender (< 20% Budget)
        if currentMonthSpending < budgetMonthly * 0.2 && currentMonthSpending > 0 {
            return MonthlyTitle(
                title: "人形存钱罐",
                subtitle: "抠门...哦不，是节俭的艺术",
                icon: "banknote.fill",
                color: .green
            )
        }
        
        // 5. Many Items Added (> 10 items)
        if itemCount > 10 {
            return MonthlyTitle(
                title: "千手观音",
                subtitle: "剁手速度赶不上长手速度",
                icon: "hands.sparkles.fill",
                color: .pink
            )
        }
        
        // 6. Balanced (Spend ≈ Budget, within 90%-110%)
        if currentMonthSpending >= budgetMonthly * 0.9 && currentMonthSpending <= budgetMonthly * 1.1 {
            return MonthlyTitle(
                title: "端水大师",
                subtitle: "居然能精准控制预算，是个狠人",
                icon: "scale.3d",
                color: .blue
            )
        }
        
        // 7. Default/Normal
        return MonthlyTitle(
            title: "理性萌新",
            subtitle: "继续保持，未来可期",
            icon: "leaf.fill",
            color: .teal
        )
    }
    
    // MARK: - 持久化存储
    func saveData() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: storageKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    func loadData() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([ClothingItem].self, from: data) {
            items = decoded
        }
    }
    
    // MARK: - Smart Budget Management
    
    func saveBudgets() {
        UserDefaults.standard.set(budgetWeekly, forKey: budgetWeeklyKey)
        UserDefaults.standard.set(budgetMonthly, forKey: budgetMonthlyKey)
        UserDefaults.standard.set(budgetYearly, forKey: budgetYearlyKey)
        UserDefaults.standard.synchronize()
    }
    
    func loadBudgets() {
        // Load weekly budget
        let savedWeekly = UserDefaults.standard.double(forKey: budgetWeeklyKey)
        if savedWeekly > 0 {
            budgetWeekly = savedWeekly
        }
        
        // Load monthly budget (with migration from old key)
        let savedMonthly = UserDefaults.standard.double(forKey: budgetMonthlyKey)
        if savedMonthly > 0 {
            budgetMonthly = savedMonthly
        } else {
            // Migrate from old "MonthlyBudget" key
            let oldBudget = UserDefaults.standard.double(forKey: "MonthlyBudget")
            if oldBudget > 0 {
                budgetMonthly = oldBudget
            }
        }
        
        // Load yearly budget
        let savedYearly = UserDefaults.standard.double(forKey: budgetYearlyKey)
        if savedYearly > 0 {
            budgetYearly = savedYearly
        }
    }
    
    func updateBudget(forPeriod period: StatisticsPeriod, newBudget: Double) {
        switch period {
        case .week:
            budgetWeekly = newBudget
        case .month:
            budgetMonthly = newBudget
        case .year:
            budgetYearly = newBudget
        }
        saveBudgets()
    }
    
    func updateColdThreshold(days: Int) {
        coldThresholdDays = days
        saveColdThreshold()
    }
    
    func loadColdThreshold() {
        let saved = UserDefaults.standard.integer(forKey: coldThresholdKey)
        if saved > 0 {
            coldThresholdDays = saved
        }
    }
    
    func saveColdThreshold() {
        UserDefaults.standard.set(coldThresholdDays, forKey: coldThresholdKey)
        UserDefaults.standard.synchronize()
    }
    
    // MARK: - Daily Notes Management
    
    /// Generate date key for daily notes (yyyy-MM-dd format)
    private func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    /// Save daily notes to UserDefaults
    func saveDailyNotes() {
        if let data = try? JSONEncoder().encode(dailyNotes) {
            UserDefaults.standard.set(data, forKey: dailyNotesKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    /// Load daily notes from UserDefaults
    func loadDailyNotes() {
        if let data = UserDefaults.standard.data(forKey: dailyNotesKey),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            dailyNotes = decoded
        }
    }
    
    /// Get note for a specific date
    func getNote(for date: Date) -> String? {
        dailyNotes[dateKey(for: date)]
    }
    
    /// Set or update note for a specific date
    func setNote(for date: Date, note: String) {
        let key = dateKey(for: date)
        if note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            dailyNotes.removeValue(forKey: key)
        } else {
            dailyNotes[key] = note
        }
        saveDailyNotes()
    }
    
    // MARK: - Copy Yesterday's Outfit
    
    /// Check if yesterday has any worn items
    func hasYesterdayOutfit() -> Bool {
        let calendar = Calendar.current
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else {
            return false
        }
        
        // Check if any item has a wear date matching yesterday
        return items.contains { item in
            item.wearDates.contains { date in
                calendar.isDate(date, inSameDayAs: yesterday)
            }
        }
    }
    
    /// Copy all items worn yesterday to today (avoids duplicate logging)
    func copyYesterdayOutfit() {
        let calendar = Calendar.current
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else {
            return
        }
        
        let today = Date()
        var updated = false
        lastCopiedItemIDs = [] // Reset tracking
        
        // Iterate through all items and check if they were worn yesterday
        for index in items.indices {
            let wasWornYesterday = items[index].wearDates.contains { date in
                calendar.isDate(date, inSameDayAs: yesterday)
            }
            
            if wasWornYesterday {
                // Avoid duplicate logging for today
                let alreadyWornToday = items[index].wearDates.contains { date in
                    calendar.isDate(date, inSameDayAs: today)
                }
                
                if !alreadyWornToday {
                    items[index].wearDates.append(today)
                    lastCopiedItemIDs.append(items[index].id) // Track for undo
                    updated = true
                }
            }
        }
        
        // Save data if any updates were made
        if updated {
            saveData()
            // Force UI update
            objectWillChange.send()
        }
    }
    
    /// Undo the last copy yesterday operation
    func undoCopyYesterday() {
        guard !lastCopiedItemIDs.isEmpty else { return }
        
        let calendar = Calendar.current
        let today = Date()
        var updated = false
        
        // Remove today's date from all items that were copied
        for itemID in lastCopiedItemIDs {
            if let index = items.firstIndex(where: { $0.id == itemID }) {
                // Remove today's wear date
                items[index].wearDates.removeAll { date in
                    calendar.isDate(date, inSameDayAs: today)
                }
                updated = true
            }
        }
        
        // Clear the tracking list
        lastCopiedItemIDs = []
        
        // Save data if any updates were made
        if updated {
            saveData()
            // Force UI update
            objectWillChange.send()
        }
    }
    
    /// Check if there's a recent copy operation that can be undone
    func canUndoCopyYesterday() -> Bool {
        return !lastCopiedItemIDs.isEmpty
    }
    
    // MARK: - Rational Cat Logic v2.0
    
    /// Categories excluded from average price calculation
    private static let excludedCategoriesForAverage = ["内衣居家", "配饰"]
    
    /// Calculate the adjusted average price, excluding underwear/home and accessories
    /// Used for "Rational Cat" purchase evaluation
    func calculateAdjustedAveragePrice() -> Double {
        let includedItems = items.filter { item in
            item.status == .active && 
            !WardrobeStore.excludedCategoriesForAverage.contains(item.category)
        }
        
        guard !includedItems.isEmpty else { return 0 }
        
        let totalPrice = includedItems.reduce(0.0) { $0 + $1.price }
        return totalPrice / Double(includedItems.count)
    }
    
    /// Evaluate a price against the adjusted average for Rational Cat comments
    /// Returns: (isGoodValue: Bool, isLuxury: Bool, message: String)
    func evaluatePriceForRationalCat(price: Double) -> (isGoodValue: Bool, isLuxury: Bool, message: String) {
        let adjustedAverage = calculateAdjustedAveragePrice()
        
        // If no items yet, can't compare
        guard adjustedAverage > 0 else {
            return (false, false, "这是你的第一件衣物，开启理性衣橱之旅！🐱")
        }
        
        if price < adjustedAverage {
            // Good value: below average
            return (true, false, "理性小猫在呼噜噜！这件性价比超高，比你的平均单价还低！🐱✨")
        } else if price > adjustedAverage * 2 {
            // Luxury: more than 2x average
            return (false, true, "理性小猫正在审判你... 这件是你平均价格的2倍以上，真的需要吗？🐱⚠️")
        } else {
            // Normal range
            return (false, false, "")
        }
    }
    
    // MARK: - Data Export / Backup
    struct BackupData: Codable {
        var items: [ClothingItem]
        var budgetWeekly: Double
        var budgetMonthly: Double
        var budgetYearly: Double
        var coldThresholdDays: Int
        var dailyNotes: [String: String]
        var exportDate: Date
        var appVersion: String
    }
    
    func exportDataAsJSON() -> String? {
        let backup = BackupData(
            items: items,
            budgetWeekly: budgetWeekly,
            budgetMonthly: budgetMonthly,
            budgetYearly: budgetYearly,
            coldThresholdDays: coldThresholdDays,
            dailyNotes: dailyNotes,
            exportDate: Date(),
            appVersion: "11.0"
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let jsonData = try encoder.encode(backup)
            return String(data: jsonData, encoding: .utf8)
        } catch {
            print("Export failed: \(error)")
            return nil
        }
    }
    
    func getExportFileName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let dateString = formatter.string(from: Date())
        return "RationalCloset_Backup_\(dateString).json"
    }
}