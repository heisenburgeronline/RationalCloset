import SwiftUI

// MARK: - 分类配置
struct CategoryConfig {
    static let categories: [(name: String, icon: String, description: String)] = [
        (name: "上装", icon: "tshirt", description: "T恤 / 卫衣 / 衬衫"),
        (name: "下装", icon: "figure.walk", description: "牛仔裤 / 休闲裤"),
        (name: "外套", icon: "cloud.snow", description: "大衣 / 羽绒 / 夹克"),
        (name: "裙装", icon: "figure.dress.line.vertical.figure", description: "连衣裙 / 半身裙"),
        (name: "内衣居家", icon: "house.fill", description: "睡衣 / 内衣 / 袜子"),
        (name: "鞋履", icon: "shoe.2", description: "运动鞋 / 靴子"),
        (name: "包包", icon: "bag", description: "背包 / 手提 / 钱包"),
        (name: "配饰", icon: "eyeglasses", description: "帽子 / 围巾 / 首饰"),
        (name: "场景功能", icon: "theatermasks.fill", description: "COS服 / 演出 / 滑雪")
    ]
}

// MARK: - 欲望天梯
struct SavingsConversion {
    static func getFunText(for amount: Double) -> String {
        if amount >= 150000 { return "哇！你已经攒出了人生第一桶金！💰" }
        else if amount >= 80000 { return "够装修一间电竞房/衣帽间 🏠" }
        else if amount >= 50000 { return "够支付一辆代步车的首付 🚗" }
        else if amount >= 30000 { return "够买一个香奈儿经典款 🛍️" }
        else if amount >= 20000 { return "够去一趟日本/泰国深度游 🇯🇵" }
        else if amount >= 12000 { return "够买一个奢侈品入门包包 👜" }
        else if amount >= 8000 { return "够买一台 MacBook Air 💻" }
        else if amount >= 5000 { return "够买一台 iPhone 或去一趟三亚 📱" }
        else if amount >= 3000 { return "够买一张周杰伦演唱会内场票 🎤" }
        else if amount >= 2000 { return "够买一台 Nintendo Switch 2 🎮" }
        else if amount >= 1500 { return "够买一副 AirPods Pro 🎧" }
        else if amount >= 800 { return "够买一张迪士尼门票+周边 🏰" }
        else if amount >= 500 { return "够买一双 Nike 运动鞋 👟" }
        else if amount >= 300 { return "够买一支大牌口红 💄" }
        else if amount >= 100 { return "够吃一顿海底捞火锅 🍲" }
        else if amount >= 50 { return "够吃一顿麦当劳全家桶 🍔" }
        else if amount >= 20 { return "够喝一杯星巴克 ☕️" }
        else if amount >= 10 { return "够喝一杯霸王茶姬 🧋" }
        else if amount >= 5 { return "够买一杯蜜雪冰城 🍦" }
        else if amount > 0 { return "积少成多，理性的一小步！✨" }
        else { return "理性小猫：警报！你的钱包正在流泪... 😿" }
    }
    
    static func getIcon(for amount: Double) -> String {
        if amount >= 150000 { return "dollarsign.circle.fill" }
        else if amount >= 50000 { return "car.fill" }
        else if amount >= 20000 { return "airplane" }
        else if amount >= 8000 { return "laptopcomputer" }
        else if amount >= 3000 { return "music.mic" }
        else if amount >= 1500 { return "airpodspro" }
        else if amount >= 500 { return "shoe.fill" }
        else if amount >= 100 { return "flame.fill" }
        else if amount >= 20 { return "cup.and.saucer.fill" }
        else if amount > 0 { return "leaf.fill" }
        else { return "exclamationmark.triangle.fill" }
    }
}

// MARK: - 理性小猫文案
struct RationalityCatMessages {
    static let expensiveWarnings: [String] = [
        "理性小猫：这笔有点贵，不如先放购物车冷处理3天？🐱",
        "理性小猫：哇，这价位！它是你的'梦中情衣'吗？🐱",
        "理性小猫：想想你的预算，它真的值得吗？喵~ 🐱",
        "理性小猫：深呼吸...再看一眼价格...确定吗？🐱",
        "理性小猫：这件衣服很贵呢，是心动还是冲动？🐱",
        "理性小猫：高价物品警报！请三思而后行喵~ 🐱",
        "理性小猫：你的钱包正在瑟瑟发抖...🐱",
        "理性小猫：问问自己：一年后还会穿吗？🐱"
    ]
    
    static let scenarioWarning = "理性小猫：特殊场合衣服利用率很低，租一个会不会更香？🐱"
    static func randomWarning() -> String { expensiveWarnings.randomElement() ?? expensiveWarnings[0] }
}