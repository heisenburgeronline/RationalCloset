import SwiftUI
import Foundation

// MARK: - 基础枚举与结构
enum ItemStatus: String, Codable, CaseIterable {
    case active = "在用"
    case sold = "已出"
}

enum StatisticsPeriod: String, CaseIterable {
    case week = "本周"
    case month = "本月"
    case year = "本年"
}

struct CategorySpending: Identifiable {
    var id: String { category }
    var category: String
    var amount: Double
}

struct MonthlyGroup: Identifiable {
    var id: String { monthKey }
    var monthKey: String
    var sortDate: Date
    var items: [ClothingItem]
    
    var itemCount: Int { items.count }
}

// MARK: - 核心物品模型
struct ClothingItem: Identifiable, Codable {
    var id: UUID
    var category: String
    var price: Double
    var originalPrice: Double
    var soldPrice: Double?
    var soldDate: Date?
    var date: Date
    var platform: String
    var reason: String
    var size: String
    var status: ItemStatus
    
    var wearDates: [Date] = []
    
    var imagesData: [Data] = []
    
    // 详细平铺尺寸 (选填, cm)
    var shoulderWidth: String?        // 肩宽
    var chestCircumference: String?   // 胸围
    var sleeveLength: String?         // 袖长
    var clothingLength: String?       // 衣长
    var waistline: String?            // 腰围
    
    // 计算属性
    var wearCount: Int { wearDates.count }
    var lastWornDate: Date? { wearDates.max() }
    var purchaseDate: Date { date }
    
    init(id: UUID = UUID(), category: String, price: Double, originalPrice: Double = 0, soldPrice: Double? = nil, soldDate: Date? = nil, date: Date = Date(), platform: String = "", reason: String = "", size: String = "", status: ItemStatus = .active, wearDates: [Date] = [], imagesData: [Data] = [], shoulderWidth: String? = nil, chestCircumference: String? = nil, sleeveLength: String? = nil, clothingLength: String? = nil, waistline: String? = nil) {
        self.id = id
        self.category = category
        self.price = price
        self.originalPrice = originalPrice > 0 ? originalPrice : price
        self.soldPrice = soldPrice
        self.soldDate = soldDate
        self.date = date
        self.platform = platform
        self.reason = reason
        self.size = size
        self.status = status
        self.wearDates = wearDates
        self.imagesData = imagesData
        self.shoulderWidth = shoulderWidth
        self.chestCircumference = chestCircumference
        self.sleeveLength = sleeveLength
        self.clothingLength = clothingLength
        self.waistline = waistline
    }
    
    var monthYearKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    var sortableMonthYear: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }
    
    var costPerWear: Double {
        if wearCount <= 0 { return price }
        return price / Double(wearCount)
    }
}