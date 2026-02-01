import SwiftUI

struct MainDashboardView: View {
    @EnvironmentObject var wardrobeStore: WardrobeStore
    @Environment(\.horizontalSizeClass) var sizeClass
    var gridColumns: [GridItem] { if sizeClass == .compact { return [GridItem(.flexible()), GridItem(.flexible())] } else { return [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())] } }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 25) {
                    HStack {
                        Spacer()
                        HStack(spacing: 12) {
                            Image(systemName: "sparkles").font(.system(size: 28)).foregroundStyle(LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            VStack(alignment: .center, spacing: 2) { Text("我的理性衣橱").font(.system(size: 34, weight: .bold, design: .rounded)) }
                            Image(systemName: "sparkles").font(.system(size: 28)).foregroundStyle(LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        }
                        Spacer()
                    }.padding(.horizontal).padding(.top)
                    
                    NavigationLink(destination: AllItemsView().environmentObject(wardrobeStore)) {
                        HStack { Image(systemName: "tshirt.fill").font(.title2).foregroundColor(.white); VStack(alignment: .leading, spacing: 4) { Text("我的全部衣物").font(.headline).foregroundColor(.white); Text("\(wardrobeStore.items.count) 件 · \(wardrobeStore.getActiveItems().count) 件在用").font(.caption).foregroundColor(.white.opacity(0.8)) }; Spacer(); Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.7)) }.padding().background(LinearGradient(colors: [.indigo, .purple], startPoint: .leading, endPoint: .trailing)).cornerRadius(16)
                    }.padding(.horizontal)
                    
                    let coldPalaceItems = wardrobeStore.getColdPalaceItems()
                    if !coldPalaceItems.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            HStack(spacing: 8) { Text("🕸️").font(.system(size: 20)); Text("衣橱冷宫 (Dusty Corner)").font(.title3).bold(); Spacer(); Text("\(coldPalaceItems.count)件").font(.caption).foregroundColor(.white).padding(.horizontal, 10).padding(.vertical, 4).background(Color.orange).cornerRadius(10) }.padding(.horizontal)
                            Text("购买超过30天从未穿过，该动起来了！").font(.caption).foregroundColor(.orange).padding(.horizontal)
                            ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 15) { ForEach(coldPalaceItems) { item in NavigationLink(destination: ItemDetailView(item: item).environmentObject(wardrobeStore)) { ColdPalaceItemCard(item: item) }.buttonStyle(.plain) } }.padding(.horizontal) }
                        }.padding(.vertical, 15).background(Color.orange.opacity(0.05)).cornerRadius(16).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.orange.opacity(0.3), lineWidth: 2)).padding(.horizontal)
                    }
                    
                    VStack(alignment: .leading, spacing: 15) {
                        HStack(spacing: 8) { Image(systemName: "square.grid.3x3.fill").font(.system(size: 16, weight: .semibold)).foregroundColor(.indigo); Text("分类").font(.title3).bold() }.padding(.horizontal)
                        LazyVGrid(columns: gridColumns, spacing: 12) { ForEach(CategoryConfig.categories, id: \.name) { item in NavigationLink(destination: CategoryDetailView(categoryName: item.name).environmentObject(wardrobeStore)) { CategoryCardView(name: item.name, icon: item.icon, description: item.description, count: wardrobeStore.getItemsForCategory(categoryName: item.name).filter { $0.status == .active }.count) }.buttonStyle(CategoryCardButtonStyle()) } }.padding(.horizontal)
                    }
                    
                    if !wardrobeStore.getRecentlyAddedItems().isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            HStack(spacing: 8) { Image(systemName: "clock.arrow.circlepath").font(.system(size: 16, weight: .semibold)).foregroundColor(.indigo); Text("最近添加").font(.title3).bold() }.padding(.horizontal)
                            ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 15) { ForEach(wardrobeStore.getRecentlyAddedItems()) { item in NavigationLink(destination: ItemDetailView(item: item).environmentObject(wardrobeStore)) { RecentItemCardView(item: item) }.buttonStyle(.plain) } }.padding(.horizontal) }
                        }
                    }
                    RationalityAnalysisBlock().environmentObject(wardrobeStore).padding(.horizontal)
                    Spacer(minLength: 50)
                }
            }
        }
    }
}

struct AllItemsView: View {
    @EnvironmentObject var wardrobeStore: WardrobeStore
    @State private var searchText = ""; @State private var showingSoldItems = true; @State private var itemToDelete: ClothingItem?; @State private var showDeleteConfirmation = false; @State private var itemToMarkSold: ClothingItem?; @State private var showSoldPriceAlert = false; @State private var soldPriceText = ""; @State private var recentlySoldIds: Set<UUID> = []; @State private var recentlyWornIds: Set<UUID> = []
    var monthlyGroups: [MonthlyGroup] { wardrobeStore.getItemsGroupedByMonth(includeSold: showingSoldItems, searchQuery: searchText) }
    var totalDisplayedCount: Int { monthlyGroups.reduce(0) { $0 + $1.itemCount } }
    
    var body: some View {
        List {
            Section { Toggle("显示已出物品", isOn: $showingSoldItems).tint(.indigo) }
            if monthlyGroups.isEmpty { Section { VStack(spacing: 12) { Image(systemName: searchText.isEmpty ? "tshirt" : "magnifyingglass").font(.system(size: 40)).foregroundColor(.gray.opacity(0.5)); Text(searchText.isEmpty ? "暂无衣物记录" : "未找到匹配的衣物").font(.subheadline).foregroundColor(.secondary) }.frame(maxWidth: .infinity).padding(.vertical, 40) } }
            else { ForEach(monthlyGroups) { group in Section { ForEach(group.items) { item in NavigationLink(destination: ItemDetailView(item: item).environmentObject(wardrobeStore)) { AllItemRow(item: item, isRecentlySold: recentlySoldIds.contains(item.id), isRecentlyWorn: recentlyWornIds.contains(item.id), onWear: { wearItem(item) }) }.swipeActions(edge: .trailing, allowsFullSwipe: false) { Button(role: .destructive) { itemToDelete = item; showDeleteConfirmation = true } label: { Label("删除", systemImage: "trash.fill") }; if item.status == .active { Button { itemToMarkSold = item; soldPriceText = ""; showSoldPriceAlert = true } label: { Label("已出", systemImage: "tag.fill") }.tint(.orange) } } } } header: { HStack { Image(systemName: "calendar").font(.system(size: 12)).foregroundColor(.indigo); Text(group.monthKey).font(.system(size: 14, weight: .semibold)); Spacer(); Text("本月购入 \(group.itemCount) 件").font(.system(size: 12)).foregroundColor(.secondary) } } } }
        }
        .listStyle(.insetGrouped).navigationTitle("我的全部衣物").searchable(text: $searchText, prompt: "搜索分类、平台、理由...").toolbar { ToolbarItem(placement: .navigationBarTrailing) { Text("共 \(totalDisplayedCount) 件").font(.caption).foregroundColor(.secondary) } }
        .alert("确认删除", isPresented: $showDeleteConfirmation) { Button("取消", role: .cancel) { itemToDelete = nil }; Button("删除", role: .destructive) { if let item = itemToDelete { wardrobeStore.deleteItemById(id: item.id); itemToDelete = nil } } } message: { Text("删除后将无法恢复，确定要删除这件衣物吗？") }
        .alert("输入卖出金额", isPresented: $showSoldPriceAlert) { TextField("卖出价格", text: $soldPriceText).keyboardType(.decimalPad); Button("取消", role: .cancel) { itemToMarkSold = nil; soldPriceText = "" }; Button("确认卖出") { markItemAsSold() } } message: { if let item = itemToMarkSold { Text("原价 ¥\(String(format: "%.0f", item.price))，请输入实际卖出金额（可选）") } }
    }
    private func wearItem(_ item: ClothingItem) { UIImpactFeedbackGenerator(style: .medium).impactOccurred(); recentlyWornIds.insert(item.id); withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { wardrobeStore.addWearDate(id: item.id) }; DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { recentlyWornIds.remove(item.id) } }
    private func markItemAsSold() { guard let item = itemToMarkSold else { return }; UINotificationFeedbackGenerator().notificationOccurred(.success); recentlySoldIds.insert(item.id); withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { wardrobeStore.markAsSoldById(id: item.id, soldPrice: Double(soldPriceText)) }; itemToMarkSold = nil; soldPriceText = ""; DispatchQueue.main.asyncAfter(deadline: .now() + 2) { recentlySoldIds.remove(item.id) } }
}

struct CategoryDetailView: View {
    @EnvironmentObject var store: WardrobeStore; var categoryName: String; @State private var recentlyWornIds: Set<UUID> = []
    var items: [ClothingItem] { store.getItemsForCategory(categoryName: categoryName) }
    var body: some View {
        Group {
            if items.isEmpty { VStack(spacing: 20) { Image(systemName: "tshirt").font(.system(size: 60)).foregroundColor(.gray.opacity(0.5)); Text("还没有\(categoryName)记录").font(.title3).foregroundColor(.secondary); NavigationLink(destination: AddItemView(categoryName: categoryName).environmentObject(store)) { HStack { Image(systemName: "plus.circle.fill"); Text("添加第一件\(categoryName)") }.font(.headline).foregroundColor(.white).padding(.horizontal, 30).padding(.vertical, 15).background(Color.accentColor).cornerRadius(12) } }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(.systemGroupedBackground)) }
            else { List { ForEach(items) { item in ItemCardRow(item: item, isRecentlyWorn: recentlyWornIds.contains(item.id), onWear: { wearItem(item) }) } }.listStyle(.insetGrouped) }
        }
        .navigationTitle(categoryName).toolbar { ToolbarItem(placement: .navigationBarTrailing) { NavigationLink(destination: AddItemView(categoryName: categoryName).environmentObject(store)) { Image(systemName: "plus").font(.system(size: 16, weight: .semibold)) } } }
    }
    private func wearItem(_ item: ClothingItem) { UIImpactFeedbackGenerator(style: .medium).impactOccurred(); recentlyWornIds.insert(item.id); withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { store.addWearDate(id: item.id) }; DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { recentlyWornIds.remove(item.id) } }
}

struct ContentView: View {
    @StateObject var wardrobeStore = WardrobeStore()
    var body: some View {
        NavigationStack {
            MainDashboardView().environmentObject(wardrobeStore)
        }
    }
}