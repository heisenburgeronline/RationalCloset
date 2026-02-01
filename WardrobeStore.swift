import SwiftUI
import Foundation

// MARK: - Monthly Title Model
struct MonthlyTitle {
    var title: String
    var subtitle: String
    var icon: String
    var color: Color
}

class WardrobeStore: ObservableObject {
    @Published var items: [ClothingItem] = []
    @Published var monthlyBudget: Double = 2000.0
    @Published var coldThresholdDays: Int = 60
    
    private let storageKey: String = "MyWardrobeItems"
    private let budgetKey: String = "MonthlyBudget"
    private let coldThresholdKey: String = "ColdThresholdDays"
    
    init() {
        loadData()
        loadBudget()
        loadColdThreshold()
    }
    
    // MARK: - 基础 CRUD
    func addNewItem(newItem: ClothingItem) {
        items.append(newItem)
        saveData()
    }
    
    func deleteItem(item: ClothingItem) {
        items.removeAll { $0.id == item.id }
        saveData()
    }
    
    func deleteItemById(id: UUID) {
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
    
    func updateItem(updatedItem: ClothingItem) {
        if let index = items.firstIndex(where: { $0.id == updatedItem.id }) {
            items[index] = updatedItem
            saveData()
        }
    }
    
    // MARK: - 查询与筛选
    func getColdPalaceItems() -> [ClothingItem] {
        return items.filter { $0.isCold(threshold: coldThresholdDays) }
            .sorted { $0.purchaseDate < $1.purchaseDate }
    }
    
    func getColdItemsCount() -> Int {
        return items.filter { $0.isCold(threshold: coldThresholdDays) }.count
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
        case .week: return monthlyBudget / 4.0
        case .month: return monthlyBudget
        case .year: return monthlyBudget * 12.0
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
        if currentMonthSpending > monthlyBudget * 1.5 {
            return MonthlyTitle(
                title: "钱包粉碎机",
                subtitle: "再买就要去天桥贴膜了",
                icon: "exclamationmark.triangle.fill",
                color: .red
            )
        }
        
        // 4. Low Spender (< 20% Budget)
        if currentMonthSpending < monthlyBudget * 0.2 && currentMonthSpending > 0 {
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
        if currentMonthSpending >= monthlyBudget * 0.9 && currentMonthSpending <= monthlyBudget * 1.1 {
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
    
    func saveBudget() {
        UserDefaults.standard.set(monthlyBudget, forKey: budgetKey)
        UserDefaults.standard.synchronize()
    }
    
    func loadBudget() {
        let saved = UserDefaults.standard.double(forKey: budgetKey)
        if saved > 0 {
            monthlyBudget = saved
        }
    }
    
    func updateBudget(newBudget: Double) {
        monthlyBudget = newBudget
        saveBudget()
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
}