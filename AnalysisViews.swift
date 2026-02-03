import SwiftUI
import Charts
import Photos

struct RationalityAnalysisBlock: View {
    @EnvironmentObject var wardrobeStore: WardrobeStore
    @State private var analysisPeriod: StatisticsPeriod = .month
    @State private var showBudgetEditor = false
    @State private var showShareSheet = false
    
    var totalSpent: Double { wardrobeStore.calculateTotalSpending(forPeriod: analysisPeriod) }
    var moneySaved: Double { wardrobeStore.calculateMoneySaved(forPeriod: analysisPeriod) }
    var itemCount: Int { wardrobeStore.calculateTotalCount(forPeriod: analysisPeriod) }
    var budget: Double { wardrobeStore.getBudgetForPeriod(period: analysisPeriod) }
    var spendingData: [CategorySpending] { wardrobeStore.getSpendingByCategory(forPeriod: analysisPeriod) }
    var isOverBudget: Bool { moneySaved < 0 }
    var periodRecovered: Double { wardrobeStore.calculateTotalRecovered(forPeriod: analysisPeriod) }
    var allTimeRecovered: Double { wardrobeStore.calculateAllTimeRecovered() }
    var netSpending: Double { wardrobeStore.calculateNetSpending(forPeriod: analysisPeriod) }
    
    // Monthly Title
    var monthlyTitle: MonthlyTitle { wardrobeStore.calculateMonthlyTitle() }
    
    // Rational Cat v2.0: Adjusted average price (excluding underwear/home and accessories)
    var adjustedAveragePrice: Double { wardrobeStore.calculateAdjustedAveragePrice() }
    
    // Recycle count for current period
    var recycleCount: Int {
        let calendar = Calendar.current
        let now = Date()
        let items = wardrobeStore.items.filter { item in
            guard let soldDate = item.soldDate, item.status == .sold else { return false }
            switch analysisPeriod {
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
        return items.count
    }
    
    // UI Helpers - New Logic
    var difference: Double { budget - netSpending }
    
    var savingsLabel: String {
        if netSpending < 0 { return "净赚" }
        else if difference >= 0 { return "成功省下" }
        else { return "超出预算" }
    }
    
    var savingsColor: Color {
        if netSpending < 0 { return Color(red: 1.0, green: 0.84, blue: 0.0) } // Gold
        else if difference >= 0 { return .green }
        else { return .red }
    }
    
    var savingsDisplayAmount: Double {
        if netSpending < 0 { return abs(netSpending) }
        else if difference >= 0 { return difference }
        else { return abs(difference) }
    }
    
    var savingsIconName: String {
        if netSpending < 0 { return "trophy.fill" }
        else if difference >= 0 { return "leaf.fill" }
        else { return "exclamationmark.triangle.fill" }
    }
    
    var savingsTitle: String {
        if netSpending < 0 { return "回血大师 🏆" }
        else if difference >= 0 { return "省钱小能手 ✅" }
        else { return "再买剁手 ⚠️" }
    }
    
    var funConversionText: String { 
        // FIX: Don't show positive savings messages when over budget
        if netSpending < 0 {
            // Net profit - show positive message
            return SavingsConversion.getFunText(for: abs(netSpending))
        } else if isOverBudget {
            // Over budget - show warning regardless of recovered amount
            if periodRecovered > 0 {
                return "虽然回血不少，但整体还是超支啦！控制一下剁手冲动吧 🐱"
            } else {
                return "理性小猫：警报！你的钱包正在流泪... 😿"
            }
        } else {
            // Under budget - show positive savings message
            return SavingsConversion.getFunText(for: savingsDisplayAmount)
        }
    }
    var funIcon: String { SavingsConversion.getIcon(for: savingsDisplayAmount) }
    var rationalityIcon: String { netSpending < 0 ? "hand.thumbsup.fill" : (difference < 0 ? "exclamationmark.triangle.fill" : "checkmark.circle.fill") }
    var rationalityColor: Color { netSpending < 0 ? .yellow : (difference < 0 ? .red : .green) }
    var rationalityMessage: String {
        if difference < 0 { return "消费已超出预算，建议控制支出或卖出闲置物品！" }
        else if difference > budget * 0.5 { return "太棒了！你省下了超过一半的预算，继续保持！" }
        else if totalSpent == 0 && itemCount == 0 { return "暂无消费记录，开始记录你的理性衣橱吧！" }
        else { return "消费习惯良好，继续保持记录的好习惯！" }
    }
    func formatCurrency(_ amount: Double) -> String { amount < 0 ? "-¥\(String(format: "%.0f", abs(amount)))" : "¥\(String(format: "%.0f", amount))" }
    
    // Net Spending Display Logic
    var netSpendingLabel: String { netSpending < 0 ? "反向搞钱" : "净支出" }
    var netSpendingColor: Color { netSpending < 0 ? .orange : .purple }
    var netSpendingAmount: String { 
        if netSpending < 0 {
            return "¥\(String(format: "%.0f", abs(netSpending)))"
        } else {
            return "¥\(String(format: "%.0f", netSpending))"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar.doc.horizontal").font(.system(size: 18, weight: .semibold)).foregroundColor(.indigo)
                    Text("理性消费分析").font(.system(size: 18, weight: .bold))
                }
                Spacer()
                Button { showShareSheet = true } label: { Image(systemName: "square.and.arrow.up").font(.system(size: 16, weight: .medium)).foregroundColor(.indigo).padding(8).background(Color.indigo.opacity(0.1)).cornerRadius(8) }
                Menu {
                    ForEach(StatisticsPeriod.allCases, id: \.self) { period in
                        Button { analysisPeriod = period } label: { HStack { Text(period.rawValue); if analysisPeriod == period { Image(systemName: "checkmark") } } }
                    }
                } label: { HStack(spacing: 4) { Text(analysisPeriod.rawValue).font(.system(size: 14, weight: .medium)); Image(systemName: "chevron.down").font(.system(size: 12, weight: .medium)) }.foregroundColor(.indigo).padding(.horizontal, 12).padding(.vertical, 6).background(Color.indigo.opacity(0.1)).cornerRadius(8) }
            }.padding(20)
            Divider().padding(.horizontal, 20)
            
            VStack(spacing: 20) {
                // 🏆 Monthly Title Card (Gamification)
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: monthlyTitle.icon)
                            .font(.system(size: 32))
                            .foregroundColor(monthlyTitle.color)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(monthlyTitle.title)
                                .font(.system(size: 20, weight: .black))
                                .foregroundColor(monthlyTitle.color)
                            Text(monthlyTitle.subtitle)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(monthlyTitle.color.opacity(0.12))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(monthlyTitle.color.opacity(0.4), lineWidth: 2)
                    )
                }
                .padding(.horizontal, 4)
                
                // 预算行
                HStack {
                    Text("月预算").font(.system(size: 14)).foregroundColor(.secondary)
                    Text(String(format: "¥%.0f", wardrobeStore.monthlyBudget)).font(.system(size: 14, weight: .semibold)).foregroundColor(.indigo)
                    Button { showBudgetEditor = true } label: { Image(systemName: "pencil.circle.fill").font(.system(size: 20)).foregroundColor(.indigo) }
                    Spacer()
                    if allTimeRecovered > 0 { HStack(spacing: 4) { Image(systemName: "star.circle.fill").font(.system(size: 14)).foregroundColor(.yellow); Text("回血达人").font(.system(size: 12, weight: .bold)).foregroundColor(.orange) }.padding(.horizontal, 8).padding(.vertical, 4).background(Capsule().fill(Color.orange.opacity(0.15))) }
                }.padding(.horizontal, 4)
                
                // 进度条
                VStack(spacing: 8) {
                    HStack { Text("\(analysisPeriod.rawValue)支出 / 预算").font(.system(size: 13)).foregroundColor(.secondary); Spacer(); Text(String(format: "¥%.0f", budget)).font(.system(size: 13)).foregroundColor(.secondary) }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.2))
                            RoundedRectangle(cornerRadius: 6).fill(LinearGradient(colors: isOverBudget ? [.orange, .red] : [.green, .teal], startPoint: .leading, endPoint: .trailing)).frame(width: budget > 0 ? min(geo.size.width * (totalSpent / budget), geo.size.width) : 0).animation(.easeInOut(duration: 0.3), value: totalSpent)
                        }
                    }.frame(height: 12)
                    Text(String(format: "¥%.2f", totalSpent)).font(.system(size: 28, weight: .bold, design: .rounded)).foregroundColor(isOverBudget ? .red : .primary)
                }.padding(16).background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.08)))
                
                // 欲望天梯 - Updated Display
                VStack(spacing: 10) {
                    HStack(spacing: 6) { 
                        Image(systemName: savingsIconName).font(.system(size: 14)).foregroundColor(savingsColor)
                        Text(savingsLabel).font(.system(size: 13)).foregroundColor(.secondary)
                    }
                    Text("¥\(String(format: "%.0f", savingsDisplayAmount))").font(.system(size: 26, weight: .bold, design: .rounded)).foregroundColor(savingsColor)
                    HStack(spacing: 6) { 
                        Image(systemName: funIcon).font(.system(size: 14))
                        Text(funConversionText).font(.system(size: 12)).lineLimit(1).minimumScaleFactor(0.8) 
                    }.foregroundColor(savingsColor.opacity(0.9)).padding(.horizontal, 14).padding(.vertical, 6).background(Capsule().fill(savingsColor.opacity(0.12)))
                }.frame(maxWidth: .infinity).padding(.vertical, 16).background(RoundedRectangle(cornerRadius: 12).fill(savingsColor.opacity(0.08)))
                
                // 收支明细
                VStack(spacing: 12) {
                    HStack { Text("\(analysisPeriod.rawValue)收支明细").font(.system(size: 14, weight: .semibold)).foregroundColor(.secondary); Spacer() }
                    HStack(spacing: 10) {
                        VStack(spacing: 4) { HStack(spacing: 4) { Image(systemName: "cart.fill").font(.system(size: 11)).foregroundColor(.indigo); Text("购入").font(.system(size: 10)).foregroundColor(.secondary) }; Text(formatCurrency(totalSpent)).font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(.indigo) }.frame(maxWidth: .infinity).padding(.vertical, 10).background(RoundedRectangle(cornerRadius: 8).fill(Color.indigo.opacity(0.08)))
                        
                        VStack(spacing: 4) { 
                            HStack(spacing: 4) { 
                                Image(systemName: "arrow.uturn.backward").font(.system(size: 11)).foregroundColor(.orange)
                                Text("回收").font(.system(size: 10)).foregroundColor(.secondary)
                            }
                            Text(formatCurrency(periodRecovered)).font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(.orange)
                            Text("本月累计回血 \(recycleCount) 件").font(.system(size: 8)).foregroundColor(.orange.opacity(0.8))
                        }.frame(maxWidth: .infinity).padding(.vertical, 10).background(RoundedRectangle(cornerRadius: 8).fill(Color.orange.opacity(0.08)))
                        
                        VStack(spacing: 4) { 
                            HStack(spacing: 4) { 
                                Image(systemName: netSpending < 0 ? "arrow.up.circle.fill" : "equal.circle.fill").font(.system(size: 11)).foregroundColor(netSpendingColor)
                                Text(netSpendingLabel).font(.system(size: 10)).foregroundColor(.secondary)
                            }
                            Text(netSpendingAmount).font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(netSpendingColor)
                        }.frame(maxWidth: .infinity).padding(.vertical, 10).background(RoundedRectangle(cornerRadius: 8).fill(netSpendingColor.opacity(0.08)))
                    }
                }.padding(14).background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.08)))
                
                // Rational Cat v2.0: Adjusted Average Reference
                if adjustedAveragePrice > 0 {
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Text("🐱")
                                .font(.system(size: 14))
                            Text("理性参考价")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("¥\(String(format: "%.0f", adjustedAveragePrice))/件")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.indigo)
                        }
                        Text("基于你的衣橱平均单价（不含内衣配饰），低于此价≈好价，高于2倍≈奢侈")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.indigo.opacity(0.05)))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.indigo.opacity(0.2), lineWidth: 1))
                }
                
                // 双列指标
                HStack(spacing: 10) {
                    VStack(spacing: 6) { HStack(spacing: 4) { Image(systemName: "bag.fill").font(.system(size: 12)).foregroundColor(.blue); Text("购买").font(.system(size: 11)).foregroundColor(.secondary) }; Text("\(itemCount)件").font(.system(size: 18, weight: .bold, design: .rounded)).foregroundColor(.blue) }.frame(maxWidth: .infinity).padding(.vertical, 12).background(RoundedRectangle(cornerRadius: 10).fill(Color.blue.opacity(0.08)))
                    VStack(spacing: 6) { HStack(spacing: 4) { Text("🕸️").font(.system(size: 12)); Text("吃灰").font(.system(size: 11)).foregroundColor(.secondary) }; Text("\(wardrobeStore.getColdItemsCount())件").font(.system(size: 18, weight: .bold, design: .rounded)).foregroundColor(.cyan) }.frame(maxWidth: .infinity).padding(.vertical, 12).background(RoundedRectangle(cornerRadius: 10).fill(Color.cyan.opacity(0.08)))
                }
                
                HStack(spacing: 10) {
                    VStack(spacing: 6) { HStack(spacing: 4) { Image(systemName: "arrow.uturn.backward.circle.fill").font(.system(size: 12)).foregroundColor(.orange); Text("累计回收").font(.system(size: 11)).foregroundColor(.secondary) }; Text(formatCurrency(allTimeRecovered)).font(.system(size: 18, weight: .bold, design: .rounded)).foregroundColor(.orange).minimumScaleFactor(0.8) }.frame(maxWidth: .infinity).padding(.vertical, 12).background(RoundedRectangle(cornerRadius: 10).fill(Color.orange.opacity(0.08)))
                    VStack(spacing: 6) { HStack(spacing: 4) { Image(systemName: "tshirt.fill").font(.system(size: 12)).foregroundColor(.green); Text("在用").font(.system(size: 11)).foregroundColor(.secondary) }; Text("\(wardrobeStore.getActiveItems().count)件").font(.system(size: 18, weight: .bold, design: .rounded)).foregroundColor(.green) }.frame(maxWidth: .infinity).padding(.vertical, 12).background(RoundedRectangle(cornerRadius: 10).fill(Color.green.opacity(0.08)))
                }
                
                // 图表
                if !spendingData.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("分类消费").font(.system(size: 14, weight: .semibold)).foregroundColor(.secondary)
                        Chart(spendingData) { item in BarMark(x: .value("金额", item.amount), y: .value("分类", item.category)).foregroundStyle(LinearGradient(colors: [.indigo, .green], startPoint: .leading, endPoint: .trailing)).cornerRadius(4).annotation(position: .trailing) { Text(String(format: "¥%.0f", item.amount)).font(.system(size: 11)).foregroundColor(.secondary) } }
                            .chartXAxis(.hidden).chartYAxis { AxisMarks { _ in AxisValueLabel().font(.system(size: 12)) } }.frame(height: CGFloat(max(spendingData.count * 40, 80)))
                    }.padding(16).background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.08)))
                }
                
                // 提示
                HStack(spacing: 8) { Image(systemName: rationalityIcon).foregroundColor(rationalityColor); Text(rationalityMessage).font(.system(size: 13)).foregroundColor(.secondary) }.padding(.horizontal, 16).padding(.vertical, 12).frame(maxWidth: .infinity).background(RoundedRectangle(cornerRadius: 10).fill(rationalityColor.opacity(0.1)))
            }.padding(20)
        }
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.indigo.opacity(0.3), lineWidth: 1.5))
        .sheet(isPresented: $showBudgetEditor) { BudgetEditorSheet(isPresented: $showBudgetEditor).environmentObject(wardrobeStore) }
        .sheet(isPresented: $showShareSheet) { ShareReportSheet(moneySaved: moneySaved, totalRecovered: periodRecovered, totalSpent: totalSpent, netSpending: netSpending, itemCount: itemCount, period: analysisPeriod) }
    }
}

struct ShareableReportView: View {
    var moneySaved: Double
    var totalRecovered: Double
    var totalSpent: Double
    var netSpending: Double
    var itemCount: Int
    var period: StatisticsPeriod
    @Environment(\.horizontalSizeClass) var sizeClass
    
    // Fixed Logic for Display - V13.0 Logic
    var budget: Double { totalSpent + moneySaved } // Reverse engineer budget from provided data
    var difference: Double { budget - netSpending }
    
    var savingsDisplayText: String {
        if netSpending < 0 {
            // Scenario A: Profit (Sold more than bought)
            return "净赚"
        } else if difference >= 0 {
            // Scenario B: Under Budget
            return "成功省下"
        } else {
            // Scenario C: Over Budget
            return "超出预算"
        }
    }
    
    var savingsIcon: String {
        if netSpending < 0 {
            return "trophy.fill"
        } else if difference >= 0 {
            return "checkmark.circle.fill"
        } else {
            return "exclamationmark.triangle.fill"
        }
    }
    
    var savingsDisplayAmount: String {
        if netSpending < 0 {
            return "¥\(String(format: "%.0f", abs(netSpending)))"
        } else if difference >= 0 {
            return "¥\(String(format: "%.0f", difference))"
        } else {
            return "¥\(String(format: "%.0f", abs(difference)))"
        }
    }
    
    var savingsColor: Color {
        if netSpending < 0 {
            return Color(red: 1.0, green: 0.84, blue: 0.0) // Gold
        } else if difference >= 0 {
            return .green
        } else {
            return .red
        }
    }
    
    var funText: String { 
        if netSpending < 0 { return SavingsConversion.getFunText(for: abs(netSpending)) }
        else if difference >= 0 { return SavingsConversion.getFunText(for: difference) }
        else { return SavingsConversion.getFunText(for: abs(difference)) }
    }
    func formatCurrency(_ amount: Double) -> String { amount < 0 ? "-¥\(String(format: "%.0f", abs(amount)))" : "¥\(String(format: "%.0f", amount))" }
    
    var body: some View {
        VStack(spacing: 25) {
            HStack { Image(systemName: "sparkles").font(.system(size: 24)); Text("我的理性战绩").font(.system(size: 28, weight: .bold, design: .rounded)); Image(systemName: "sparkles").font(.system(size: 24)) }.foregroundColor(.white)
            Text(period.rawValue).font(.system(size: 16, weight: .medium)).foregroundColor(.white.opacity(0.8)).padding(.horizontal, 16).padding(.vertical, 6).background(Color.white.opacity(0.2)).cornerRadius(20)
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    HStack(spacing: 6) { 
                        Image(systemName: savingsIcon).font(.system(size: 20))
                        Text(savingsDisplayText).font(.system(size: 16, weight: .medium))
                    }.foregroundColor(.white.opacity(0.9))
                    Text(savingsDisplayAmount).font(.system(size: 48, weight: .bold, design: .rounded)).foregroundColor(.white)
                    Text(funText).font(.system(size: 13)).foregroundColor(.white.opacity(0.85)).padding(.horizontal, 12).padding(.vertical, 4).background(Color.white.opacity(0.15)).cornerRadius(12)
                }
                HStack(spacing: 20) {
                    VStack(spacing: 6) { Text("净支出").font(.system(size: 13)).foregroundColor(.white.opacity(0.8)); Text(formatCurrency(netSpending)).font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(.white) }
                    Rectangle().fill(Color.white.opacity(0.3)).frame(width: 1, height: 45)
                    VStack(spacing: 6) { Text("已回收").font(.system(size: 13)).foregroundColor(.white.opacity(0.8)); Text(formatCurrency(totalRecovered)).font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(.white) }
                    Rectangle().fill(Color.white.opacity(0.3)).frame(width: 1, height: 45)
                    VStack(spacing: 6) { Text("购入").font(.system(size: 13)).foregroundColor(.white.opacity(0.8)); Text("\(itemCount)件").font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(.white) }
                }.padding(.horizontal, 25).padding(.vertical, 16).background(Color.white.opacity(0.15)).cornerRadius(14)
                if totalRecovered > 0 { HStack(spacing: 6) { Image(systemName: "star.circle.fill").font(.system(size: 16)); Text("回血达人").font(.system(size: 14, weight: .bold)) }.foregroundColor(.yellow).padding(.horizontal, 16).padding(.vertical, 8).background(Color.yellow.opacity(0.2)).cornerRadius(20) }
            }
            Spacer().frame(height: 10)
            VStack(spacing: 12) { Text("理性消费，精致生活 ✨").font(.system(size: 14, weight: .medium)).foregroundColor(.white.opacity(0.9)); HStack(spacing: 6) { Image(systemName: "hanger").font(.system(size: 12)); Text("Powered by 理性衣橱").font(.system(size: 11, weight: .medium)) }.foregroundColor(.white.opacity(0.5)) }
        }
        .padding(sizeClass == .compact ? 25 : 35).frame(maxWidth: 400).background(LinearGradient(colors: getGradientColors(), startPoint: .topLeading, endPoint: .bottomTrailing)).cornerRadius(24).shadow(color: savingsColor.opacity(0.4), radius: 20, x: 0, y: 10)
    }
    
    // Dynamic gradient based on savings status - V13.0 Logic
    private func getGradientColors() -> [Color] {
        if netSpending < 0 {
            // Profit: Gold/Yellow gradient
            return [Color(red: 0.9, green: 0.7, blue: 0.2), Color(red: 0.8, green: 0.5, blue: 0.3), Color(red: 0.7, green: 0.4, blue: 0.5)]
        } else if difference < 0 {
            // Over budget: Red/Pink gradient
            return [Color(red: 0.8, green: 0.3, blue: 0.3), Color(red: 0.7, green: 0.3, blue: 0.5), Color(red: 0.6, green: 0.3, blue: 0.6)]
        } else {
            // Under budget: Green/Blue gradient
            return [Color(red: 0.2, green: 0.6, blue: 0.4), Color(red: 0.3, green: 0.5, blue: 0.7), Color(red: 0.4, green: 0.4, blue: 0.8)]
        }
    }
}

struct ShareReportSheet: View {
    var moneySaved: Double
    var totalRecovered: Double
    var totalSpent: Double
    var netSpending: Double
    var itemCount: Int
    var period: StatisticsPeriod
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) var sizeClass
    @State private var renderedImage: UIImage?
    @State private var showSaveSuccessAlert = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("分享你的理性战绩").font(.title2.bold()).padding(.top)
                ShareableReportView(moneySaved: moneySaved, totalRecovered: totalRecovered, totalSpent: totalSpent, netSpending: netSpending, itemCount: itemCount, period: period)
                if let image = renderedImage {
                    // Primary Action: Save to Photos
                    Button { saveToPhotos() } label: { 
                        HStack { 
                            Image(systemName: "photo.on.rectangle.angled")
                            Text("保存到相册") 
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient(colors: [.indigo, .purple], startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(14) 
                    }
                    .padding(.horizontal, sizeClass == .compact ? 30 : 40)
                    
                    // Secondary Action: System Share
                    ShareLink(item: Image(uiImage: image), preview: SharePreview("我的理性战绩", image: Image(uiImage: image))) { 
                        HStack { 
                            Image(systemName: "square.and.arrow.up")
                            Text("分享") 
                        }
                        .font(.headline)
                        .foregroundColor(.indigo)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.indigo.opacity(0.1))
                        .cornerRadius(14) 
                    }
                    .padding(.horizontal, sizeClass == .compact ? 30 : 40)
                }
                Spacer()
            }
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("完成") { dismiss() } } }
            .onAppear { renderImage() }
            .alert("保存成功", isPresented: $showSaveSuccessAlert) {
                Button("好的", role: .cancel) { }
            } message: {
                Text("理性战绩已保存到相册，快去分享吧！✨")
            }
        }
    }
    
    @MainActor private func renderImage() {
        let renderer = ImageRenderer(content: ShareableReportView(moneySaved: moneySaved, totalRecovered: totalRecovered, totalSpent: totalSpent, netSpending: netSpending, itemCount: itemCount, period: period))
        renderer.scale = 3.0
        renderedImage = renderer.uiImage
    }
    
    private func saveToPhotos() {
        // FIX: Enforce Main Thread for Photo Saving (Critical - prevents abort_with_payload crash)
        Task { @MainActor in
            // 1. Request photo library permission
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            
            guard status == .authorized || status == .limited else {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                print("❌ Photo library access denied")
                return
            }
            
            // 2. Create fresh renderer on main thread
            let renderer = ImageRenderer(content: ShareableReportView(
                moneySaved: moneySaved, 
                totalRecovered: totalRecovered, 
                totalSpent: totalSpent, 
                netSpending: netSpending, 
                itemCount: itemCount, 
                period: period
            ))
            renderer.scale = UIScreen.main.scale
            
            // 3. Render and save
            if let image = renderer.uiImage {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                showSaveSuccessAlert = true
                print("✅ Image saved to Photos")
            } else {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                print("❌ Failed to render image")
            }
        }
    }
}

struct BudgetEditorSheet: View {
    @EnvironmentObject var wardrobeStore: WardrobeStore
    @Binding var isPresented: Bool
    @State private var budgetText: String = ""
    var isValidBudget: Bool { Double(budgetText).map { $0 > 0 } ?? false }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                VStack(spacing: 12) { Image(systemName: "dollarsign.circle.fill").font(.system(size: 60)).foregroundColor(.indigo); Text("设置月预算").font(.title2.bold()); Text("合理的预算有助于理性消费").font(.subheadline).foregroundColor(.secondary) }.padding(.top, 30)
                VStack(spacing: 16) { TextField("输入预算金额", text: $budgetText).font(.system(size: 24, weight: .semibold, design: .rounded)).keyboardType(.decimalPad).multilineTextAlignment(.center).padding().background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6))).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.indigo.opacity(0.3), lineWidth: 1)).padding(.horizontal, 40); Text("当前预算: ¥\(String(format: "%.0f", wardrobeStore.monthlyBudget))").font(.caption).foregroundColor(.secondary) }
                VStack(spacing: 12) {
                    Text("快捷设置").font(.subheadline).foregroundColor(.secondary)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach([1000, 2000, 3000, 5000], id: \.self) { amount in Button { budgetText = "\(amount)" } label: { Text("¥\(amount)").font(.subheadline.weight(.medium)).foregroundColor(budgetText == "\(amount)" ? .white : .indigo).frame(maxWidth: .infinity).padding(.vertical, 12).background(RoundedRectangle(cornerRadius: 10).fill(budgetText == "\(amount)" ? Color.indigo : Color.indigo.opacity(0.1))) } }
                    }.padding(.horizontal, 40)
                }
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("取消") { isPresented = false } }; ToolbarItem(placement: .navigationBarTrailing) { Button("保存") { saveBudgetAction() }.fontWeight(.semibold).disabled(!isValidBudget) } }
            .onAppear { budgetText = String(format: "%.0f", wardrobeStore.monthlyBudget) }
        }.presentationDetents([.medium])
    }
    
    private func saveBudgetAction() {
        if let value = Double(budgetText), value > 0 { wardrobeStore.updateBudget(newBudget: value) }
        isPresented = false
    }
}