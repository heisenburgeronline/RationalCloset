import SwiftUI

struct MainDashboardView: View {
    @EnvironmentObject var wardrobeStore: WardrobeStore
    @Environment(\.horizontalSizeClass) var sizeClass
    @State private var showSettings = false
    @State private var showCopySuccess = false
    @State private var showUndoSuccess = false
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
                    
                    NavigationLink(destination: RandomOutfitView().environmentObject(wardrobeStore)) {
                        HStack { Text("🎲").font(.title2); VStack(alignment: .leading, spacing: 4) { Text("一键不理性穿搭").font(.headline).foregroundColor(.white); Text("本功能不考虑季节、温度及路人眼光").font(.caption).foregroundColor(.white.opacity(0.8)) }; Spacer(); Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.7)) }.padding().background(LinearGradient(colors: [Color(red: 0.7, green: 0.6, blue: 0.75), Color(red: 0.8, green: 0.65, blue: 0.75)], startPoint: .leading, endPoint: .trailing)).cornerRadius(16)
                    }.padding(.horizontal)
                    
                    // Copy Yesterday's Outfit - Quick Action
                    if wardrobeStore.hasYesterdayOutfit() {
                        VStack(spacing: 0) {
                            Button {
                                wardrobeStore.copyYesterdayOutfit()
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                showCopySuccess = true
                                showUndoSuccess = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    showCopySuccess = false
                                }
                            } label: {
                                HStack {
                                    Text(showUndoSuccess ? "↺" : "⚡️").font(.title2)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(showUndoSuccess ? "已撤销" : "复制昨日穿搭").font(.headline).foregroundColor(.white)
                                        Text(showCopySuccess ? "✅ 已复制昨日穿搭" : (showUndoSuccess ? "穿搭记录已移除" : "快速记录今天的OOTD")).font(.caption).foregroundColor(.white.opacity(0.8))
                                    }
                                    Spacer()
                                    
                                    // Undo button (only show after successful copy)
                                    if showCopySuccess && wardrobeStore.canUndoCopyYesterday() {
                                        Button {
                                            wardrobeStore.undoCopyYesterday()
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            showCopySuccess = false
                                            showUndoSuccess = true
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                                showUndoSuccess = false
                                            }
                                        } label: {
                                            HStack(spacing: 4) {
                                                Image(systemName: "arrow.uturn.backward.circle.fill")
                                                Text("撤销")
                                            }
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                Capsule()
                                                    .fill(Color.white.opacity(0.2))
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    } else {
                                        Image(systemName: showCopySuccess ? "checkmark.circle.fill" : (showUndoSuccess ? "arrow.uturn.backward.circle.fill" : "doc.on.doc.fill"))
                                            .foregroundColor(.white.opacity(0.7))
                                            .font(.title3)
                                    }
                                }
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: showUndoSuccess ? [Color(red: 0.5, green: 0.5, blue: 0.5), Color(red: 0.6, green: 0.6, blue: 0.6)] : (showCopySuccess ? [Color(red: 0.5, green: 0.7, blue: 0.6), Color(red: 0.6, green: 0.75, blue: 0.65)] : [Color(red: 0.5, green: 0.6, blue: 0.7), Color(red: 0.6, green: 0.65, blue: 0.75)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .scaleEffect(showCopySuccess || showUndoSuccess ? 1.02 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showCopySuccess)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showUndoSuccess)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal)
                    }
                    
                    NavigationLink(destination: CalendarView().environmentObject(wardrobeStore)) {
                        HStack { Image(systemName: "calendar").font(.title2).foregroundColor(.white); VStack(alignment: .leading, spacing: 4) { Text("OOTD 穿搭日历").font(.headline).foregroundColor(.white); Text("查看你的每日穿搭记录").font(.caption).foregroundColor(.white.opacity(0.8)) }; Spacer(); Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.7)) }.padding().background(LinearGradient(colors: [Color(red: 0.7, green: 0.65, blue: 0.55), Color(red: 0.75, green: 0.7, blue: 0.6)], startPoint: .leading, endPoint: .trailing)).cornerRadius(16)
                    }.padding(.horizontal)
                    
                    let coldPalaceItems = wardrobeStore.getColdPalaceItems()
                    if !coldPalaceItems.isEmpty {
                        NavigationLink(destination: ColdPalaceListView().environmentObject(wardrobeStore)) {
                            VStack(alignment: .leading, spacing: 15) {
                                HStack(spacing: 8) { 
                                    Text("🕸️").font(.system(size: 20))
                                    Text("吃灰角落 (Dusty Corner)").font(.title3).bold().foregroundColor(.primary)
                                    Spacer()
                                    Text("\(coldPalaceItems.count)件").font(.caption).foregroundColor(.white).padding(.horizontal, 10).padding(.vertical, 4).background(Color.orange).cornerRadius(10)
                                    Image(systemName: "chevron.right").font(.system(size: 14)).foregroundColor(.orange)
                                }
                                Text("购买超过30天从未穿过，该动起来了！").font(.caption).foregroundColor(.orange)
                                ScrollView(.horizontal, showsIndicators: false) { 
                                    HStack(spacing: 15) { 
                                        ForEach(coldPalaceItems.prefix(5)) { item in 
                                            ColdPalaceItemCard(item: item)
                                        } 
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 15)
                        }
                        .buttonStyle(.plain)
                        .background(Color.orange.opacity(0.05))
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.orange.opacity(0.3), lineWidth: 2))
                        .padding(.horizontal)
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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView().environmentObject(wardrobeStore)
        }
    }
}

struct AllItemsView: View {
    @EnvironmentObject var wardrobeStore: WardrobeStore
    @State private var searchText = ""; @State private var showingSoldItems = true; @State private var itemToDelete: ClothingItem?; @State private var showDeleteConfirmation = false; @State private var itemToMarkSold: ClothingItem?; @State private var showSoldSheet = false
    @State private var isGridMode = false; @State private var recentlySoldIds: Set<UUID> = []; @State private var recentlyWornIds: Set<UUID> = []
    var monthlyGroups: [MonthlyGroup] { wardrobeStore.getItemsGroupedByMonth(includeSold: showingSoldItems, searchQuery: searchText) }
    var totalDisplayedCount: Int { monthlyGroups.reduce(0) { $0 + $1.itemCount } }
    var gridColumns: [GridItem] { [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())] }
    
    var body: some View {
        Group {
            if isGridMode {
                ScrollView {
                    VStack(spacing: 20) {
                        Toggle("显示已出物品", isOn: $showingSoldItems)
                            .tint(.indigo)
                            .padding(.horizontal)
                            .padding(.top)
                        
                        if monthlyGroups.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: searchText.isEmpty ? "tshirt" : "magnifyingglass")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray.opacity(0.5))
                                Text(searchText.isEmpty ? "衣橱空空如也，去进货吧！🛍️" : "咦，没找到匹配的衣物 🔍")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            ForEach(monthlyGroups) { group in
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "calendar")
                                            .font(.system(size: 12))
                                            .foregroundColor(.indigo)
                                        Text(group.monthKey)
                                            .font(.system(size: 14, weight: .semibold))
                                        Spacer()
                                        Text("本月购入 \(group.itemCount) 件")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal)
                                    
                                    LazyVGrid(columns: gridColumns, spacing: 12) {
                                        ForEach(group.items) { item in
                                            NavigationLink(destination: ItemDetailView(item: item).environmentObject(wardrobeStore)) {
                                                GridItemCard(item: item)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
            } else {
                List {
                    Section { Toggle("显示已出物品", isOn: $showingSoldItems).tint(.indigo) }
                    if monthlyGroups.isEmpty { Section { VStack(spacing: 12) { Image(systemName: searchText.isEmpty ? "tshirt" : "magnifyingglass").font(.system(size: 40)).foregroundColor(.gray.opacity(0.5)); Text(searchText.isEmpty ? "衣橱空空如也，去进货吧！🛍️" : "咦，没找到匹配的衣物 🔍").font(.subheadline).foregroundColor(.secondary) }.frame(maxWidth: .infinity).padding(.vertical, 40) } }
                    else { ForEach(monthlyGroups) { group in Section { ForEach(group.items) { item in NavigationLink(destination: ItemDetailView(item: item).environmentObject(wardrobeStore)) { AllItemRow(item: item, isRecentlySold: recentlySoldIds.contains(item.id), isRecentlyWorn: recentlyWornIds.contains(item.id), onWear: { wearItem(item) }) }.swipeActions(edge: .trailing, allowsFullSwipe: false) { Button(role: .destructive) { itemToDelete = item; showDeleteConfirmation = true } label: { Label("删除", systemImage: "trash.fill") }; if item.status == .active { Button { itemToMarkSold = item; showSoldSheet = true } label: { Label("已出", systemImage: "tag.fill") }.tint(.orange) } } } } header: { HStack { Image(systemName: "calendar").font(.system(size: 12)).foregroundColor(.indigo); Text(group.monthKey).font(.system(size: 14, weight: .semibold)); Spacer(); Text("本月购入 \(group.itemCount) 件").font(.system(size: 12)).foregroundColor(.secondary) } } } }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("我的全部衣物").searchable(text: $searchText, prompt: "搜索分类、平台、理由...").toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 15) {
                    Text("共 \(totalDisplayedCount) 件")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button {
                        withAnimation {
                            isGridMode.toggle()
                        }
                    } label: {
                        Image(systemName: isGridMode ? "list.bullet" : "square.grid.3x3")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
        }
        .alert("确认删除", isPresented: $showDeleteConfirmation) { Button("取消", role: .cancel) { itemToDelete = nil }; Button("删除", role: .destructive) { if let item = itemToDelete { wardrobeStore.deleteItemById(id: item.id); itemToDelete = nil } } } message: { Text("删除后将无法恢复，确定要删除这件衣物吗？") }
        .sheet(isPresented: $showSoldSheet) {
            if let item = itemToMarkSold {
                MarkAsSoldView(item: item).environmentObject(wardrobeStore)
            }
        }
    }
    private func wearItem(_ item: ClothingItem) { UIImpactFeedbackGenerator(style: .medium).impactOccurred(); recentlyWornIds.insert(item.id); withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { wardrobeStore.addWearDate(id: item.id) }; DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { recentlyWornIds.remove(item.id) } }
}

struct CategoryDetailView: View {
    @EnvironmentObject var store: WardrobeStore
    var categoryName: String
    @State private var recentlyWornIds: Set<UUID> = []
    @State private var sortOption: SortOption = .dateNewest
    
    var items: [ClothingItem] {
        let categoryItems = store.getItemsForCategory(categoryName: categoryName)
        switch sortOption {
        case .dateNewest:
            return categoryItems.sorted { $0.purchaseDate > $1.purchaseDate }
        case .priceHigh:
            return categoryItems.sorted { $0.price > $1.price }
        case .priceLow:
            return categoryItems.sorted { $0.price < $1.price }
        case .wearMost:
            return categoryItems.sorted { $0.wearCount > $1.wearCount }
        case .wearLeast:
            return categoryItems.sorted { $0.wearCount < $1.wearCount }
        case .cpwLow:
            // CPW Low to High (物尽其用) - treat wearCount=0 as infinity (goes last)
            return categoryItems.sorted { item1, item2 in
                if item1.wearCount == 0 && item2.wearCount == 0 { return false }
                if item1.wearCount == 0 { return false }
                if item2.wearCount == 0 { return true }
                return item1.costPerWear < item2.costPerWear
            }
        case .cpwHigh:
            // CPW High to Low (需多穿) - treat wearCount=0 as infinity (goes first)
            return categoryItems.sorted { item1, item2 in
                if item1.wearCount == 0 && item2.wearCount == 0 { return false }
                if item1.wearCount == 0 { return true }
                if item2.wearCount == 0 { return false }
                return item1.costPerWear > item2.costPerWear
            }
        }
    }
    
    // FIX: Get the actual icon for this category
    private var categoryIcon: String {
        CategoryConfig.categories.first(where: { $0.name == categoryName })?.icon ?? "tshirt"
    }
    
    var body: some View {
        Group {
            if items.isEmpty { 
                VStack(spacing: 20) { 
                    Image(systemName: categoryIcon).font(.system(size: 60)).foregroundColor(.gray.opacity(0.5))
                    Text("这里还是空的呢~").font(.title3).foregroundColor(.secondary)
                    NavigationLink(destination: AddItemView(categoryName: categoryName).environmentObject(store)) { 
                        HStack { 
                            Image(systemName: "plus.circle.fill")
                            Text("添加你的第一件好物 ✨") 
                        }.font(.headline).foregroundColor(.white).padding(.horizontal, 30).padding(.vertical, 15).background(LinearGradient(colors: [Color(red: 0.5, green: 0.6, blue: 0.7), Color(red: 0.6, green: 0.65, blue: 0.75)], startPoint: .leading, endPoint: .trailing)).cornerRadius(12) 
                    } 
                }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(.systemGroupedBackground)) 
            }
            else { 
                List { 
                    ForEach(items) { item in 
                        ItemCardRow(item: item, isRecentlyWorn: recentlyWornIds.contains(item.id), onWear: { wearItem(item) }) 
                    } 
                }.listStyle(.insetGrouped) 
            }
        }
        .navigationTitle(categoryName)
        .toolbar { 
            ToolbarItem(placement: .navigationBarTrailing) { 
                HStack(spacing: 12) {
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button {
                                sortOption = option
                            } label: {
                                HStack {
                                    Text(option.rawValue)
                                    if sortOption == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    
                    NavigationLink(destination: AddItemView(categoryName: categoryName).environmentObject(store)) { 
                        Image(systemName: "plus").font(.system(size: 16, weight: .semibold)) 
                    } 
                }
            } 
        }
    }
    
    private func wearItem(_ item: ClothingItem) { 
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        recentlyWornIds.insert(item.id)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { 
            store.addWearDate(id: item.id) 
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { 
            recentlyWornIds.remove(item.id) 
        } 
    }
}

struct ContentView: View {
    @StateObject var wardrobeStore = WardrobeStore()
    var body: some View {
        NavigationStack {
            MainDashboardView().environmentObject(wardrobeStore)
        }
    }
}

struct ColdPalaceListView: View {
    @EnvironmentObject var store: WardrobeStore
    @State private var recentlyWornIds: Set<UUID> = []
    @State private var sortOption: SortOption = .dateNewest
    
    var coldPalaceItems: [ClothingItem] {
        let items = store.getColdPalaceItems()
        switch sortOption {
        case .dateNewest:
            return items.sorted { $0.purchaseDate > $1.purchaseDate }
        case .priceHigh:
            return items.sorted { $0.price > $1.price }
        case .priceLow:
            return items.sorted { $0.price < $1.price }
        case .wearMost:
            return items.sorted { $0.wearCount > $1.wearCount }
        case .wearLeast:
            return items.sorted { $0.wearCount < $1.wearCount }
        case .cpwLow:
            // CPW Low to High (物尽其用) - treat wearCount=0 as infinity (goes last)
            return items.sorted { item1, item2 in
                if item1.wearCount == 0 && item2.wearCount == 0 { return false }
                if item1.wearCount == 0 { return false }
                if item2.wearCount == 0 { return true }
                return item1.costPerWear < item2.costPerWear
            }
        case .cpwHigh:
            // CPW High to Low (需多穿) - treat wearCount=0 as infinity (goes first)
            return items.sorted { item1, item2 in
                if item1.wearCount == 0 && item2.wearCount == 0 { return false }
                if item1.wearCount == 0 { return true }
                if item2.wearCount == 0 { return false }
                return item1.costPerWear > item2.costPerWear
            }
        }
    }
    
    var body: some View {
        Group {
            if coldPalaceItems.isEmpty {
                VStack(spacing: 20) {
                    Text("🎉").font(.system(size: 80))
                    Text("太棒了！").font(.title.bold())
                    Text("没有吃灰的衣物呢~").font(.title3).foregroundColor(.secondary)
                    Text("你的衣橱利用率超高！继续保持 💪").font(.subheadline).foregroundColor(.secondary)
                }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(.systemGroupedBackground))
            } else {
                List {
                    Section {
                        Text("这些物品已经超过\(store.coldThresholdDays)天未穿着了，是时候让它们重新发光，或者考虑出售吧！")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                            .padding(.vertical, 8)
                    }
                    
                    ForEach(coldPalaceItems) { item in
                        NavigationLink(destination: ItemDetailView(item: item).environmentObject(store)) {
                            ItemCardRow(item: item, isRecentlyWorn: recentlyWornIds.contains(item.id), onWear: { wearItem(item) })
                        }
                    }
                }.listStyle(.insetGrouped)
            }
        }
        .navigationTitle("吃灰角落 🕸️")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button {
                            sortOption = option
                        } label: {
                            HStack {
                                Text(option.rawValue)
                                if sortOption == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
    }
    
    private func wearItem(_ item: ClothingItem) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        recentlyWornIds.insert(item.id)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            store.addWearDate(id: item.id)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            recentlyWornIds.remove(item.id)
        }
    }
}

struct GridItemCard: View {
    @EnvironmentObject var wardrobeStore: WardrobeStore
    var item: ClothingItem
    var isCold: Bool { item.isCold(threshold: wardrobeStore.coldThresholdDays) }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topLeading) {
                // FIX: Use item.firstImage which loads from filesystem via ImageManager
                if let uiImage = item.firstImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .clipped()
                        .cornerRadius(12)
                        .id("\(item.id)-grid-image")
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 120)
                        .cornerRadius(12)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 30))
                                .foregroundColor(.gray)
                        )
                        .id("\(item.id)-grid-placeholder")
                }
                
                if isCold {
                    Text("🕸️")
                        .font(.system(size: 20))
                        .padding(4)
                        .background(Circle().fill(Color(.systemBackground)))
                        .padding(6)
                }
            }
            
            VStack(spacing: 4) {
                Text(item.category)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text("¥\(String(format: "%.0f", item.price))")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.indigo)
                    
                    if item.status == .sold {
                        Text("SOLD")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .cornerRadius(4)
                    }
                }
                
                if item.wearCount > 0 {
                    Text("\(item.wearCount)次")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .id("\(item.id)-grid-card")
    }
}

struct SettingsView: View {
    @EnvironmentObject var wardrobeStore: WardrobeStore
    @Environment(\.dismiss) var dismiss
    @State private var coldThreshold: Double = 60
    @State private var showExportSuccess = false
    @State private var exportedData: String?
    @State private var showEmptyDataAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("吃灰阈值")
                                .font(.headline)
                            Spacer()
                            Text("\(Int(coldThreshold)) 天")
                                .font(.headline)
                                .foregroundColor(.indigo)
                        }
                        
                        Slider(value: $coldThreshold, in: 7...180, step: 1)
                            .tint(.indigo)
                        
                        Text("物品超过此天数未穿着，将被标记为🕸️")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("吃灰设置")
                }
                
                Section {
                    HStack {
                        Text("月度预算")
                        Spacer()
                        Text("¥\(String(format: "%.0f", wardrobeStore.monthlyBudget))")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("预算设置")
                } footer: {
                    Text("在分析视图中可以调整预算")
                }
                
                // Data Management Section
                Section {
                    Button {
                        exportData()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "square.and.arrow.up.on.square")
                                .font(.system(size: 20))
                                .foregroundColor(.indigo)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("导出记账数据 (JSON)")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text("导出衣物信息与消费记录")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Label("数据管理", systemImage: "externaldrive")
                } footer: {
                    Text("此功能用于将您的衣物录入信息与消费记录导出为 JSON 文件，便于在电脑上进行二次统计。此文件仅包含文本数据。")
                }
                
                Section {
                    HStack {
                        Text("总物品数")
                        Spacer()
                        Text("\(wardrobeStore.items.count)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("在用物品")
                        Spacer()
                        Text("\(wardrobeStore.getActiveItems().count)")
                            .foregroundColor(.green)
                    }
                    HStack {
                        Text("吃灰物品")
                        Spacer()
                        Text("\(wardrobeStore.getColdItemsCount())")
                            .foregroundColor(.cyan)
                    }
                } header: {
                    Text("统计信息")
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        wardrobeStore.updateColdThreshold(days: Int(coldThreshold))
                        dismiss()
                    }
                    .bold()
                }
            }
            .onAppear {
                coldThreshold = Double(wardrobeStore.coldThresholdDays)
            }
            .sheet(item: Binding(
                get: { exportedData.map { ExportData(content: $0, fileName: wardrobeStore.getExportFileName()) } },
                set: { exportedData = $0?.content }
            )) { exportData in
                ExportShareSheet(data: exportData)
            }
            .alert("哎呀~", isPresented: $showEmptyDataAlert) {
                Button("好的", role: .cancel) { }
            } message: {
                Text("衣橱还是空的呢，添加一些衣物后再来导出吧！📦")
            }
        }
    }
    
    private func exportData() {
        // Validate: Check if there's any data to export
        if wardrobeStore.items.isEmpty {
            showEmptyDataAlert = true
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            return
        }
        
        // Proceed with export
        if let jsonString = wardrobeStore.exportDataAsJSON() {
            exportedData = jsonString
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}

// Helper struct for export data
struct ExportData: Identifiable {
    let id = UUID()
    let content: String
    let fileName: String
}

// Export Share Sheet
struct ExportShareSheet: View {
    @Environment(\.dismiss) var dismiss
    var data: ExportData
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("数据导出成功")
                        .font(.title2.bold())
                    
                    Text("文件名: \(data.fileName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                VStack(alignment: .leading, spacing: 12) {
                    Label("包含 \(dataItemCount()) 件物品记录", systemImage: "tshirt.fill")
                    Label("完整穿着历史", systemImage: "calendar")
                    Label("预算与设置", systemImage: "gearshape")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .padding(.horizontal)
                
                Spacer()
                
                // Data Export Section
                VStack(spacing: 12) {
                    if let url = saveToTemporaryFile() {
                        ShareLink(item: url) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("导出记账数据 (JSON)")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(colors: [.indigo, .purple], startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(14)
                        }
                        .padding(.horizontal)
                        
                        Text("此功能用于将您的衣物录入信息与消费记录导出为 JSON 文件，便于在电脑上进行二次统计或留存。此文件仅包含文本数据。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                
                Button {
                    dismiss()
                } label: {
                    Text("完成")
                        .font(.headline)
                        .foregroundColor(.indigo)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.indigo.opacity(0.1))
                        .cornerRadius(14)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func dataItemCount() -> Int {
        // Parse JSON to count items
        if let jsonData = data.content.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
           let items = json["items"] as? [[String: Any]] {
            return items.count
        }
        return 0
    }
    
    private func saveToTemporaryFile() -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(data.fileName)
        
        do {
            try data.content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Failed to save temp file: \(error)")
            return nil
        }
    }
}