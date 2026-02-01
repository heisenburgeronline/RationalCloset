import SwiftUI
import Foundation

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