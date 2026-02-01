import SwiftUI
import PhotosUI
import Vision

struct ItemDetailView: View {
    @EnvironmentObject var wardrobeStore: WardrobeStore
    @Environment(\.dismiss) var dismiss
    var item: ClothingItem
    @State private var showEditSheet = false
    @State private var showSoldSheet = false
    @State private var justWore = false
    
    private var hasDetailedSizes: Bool { 
        (item.shoulderWidth != nil && !item.shoulderWidth!.isEmpty) || 
        (item.chestCircumference != nil && !item.chestCircumference!.isEmpty) || 
        (item.sleeveLength != nil && !item.sleeveLength!.isEmpty) || 
        (item.clothingLength != nil && !item.clothingLength!.isEmpty) || 
        (item.waistline != nil && !item.waistline!.isEmpty) ||
        (item.pantsLength != nil && !item.pantsLength!.isEmpty) ||
        (item.hips != nil && !item.hips!.isEmpty) ||
        (item.legOpening != nil && !item.legOpening!.isEmpty) ||
        (item.centerBackLength != nil && !item.centerBackLength!.isEmpty) ||
        (item.frontLength != nil && !item.frontLength!.isEmpty) ||
        (item.hem != nil && !item.hem!.isEmpty) ||
        (item.bagType != nil && !item.bagType!.isEmpty) ||
        (item.brand != nil && !item.brand!.isEmpty)
    }
    private func formatDate(_ date: Date) -> String { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.locale = Locale(identifier: "zh_CN"); return f.string(from: date) }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    if !item.imagesData.isEmpty {
                        TabView {
                            ForEach(Array(item.imagesData.enumerated()), id: \.offset) { index, data in
                                if let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 350)
                                        .clipped()
                                }
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .always))
                        .frame(height: 350)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 350)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                            )
                    }
                    if item.status == .sold { Text("SOLD").font(.system(size: 24, weight: .black)).foregroundColor(.white).padding(.horizontal, 20).padding(.vertical, 10).background(Color.red).cornerRadius(8).rotationEffect(.degrees(-20)).padding(20) }
                }
                VStack(spacing: 25) {
                    VStack(spacing: 10) {
                        Text(item.category).font(.system(size: 34, weight: .bold, design: .rounded))
                        HStack(spacing: 12) {
                            if !item.size.isEmpty { Text(item.size).font(.subheadline).padding(.horizontal, 12).padding(.vertical, 6).background(Color.accentColor.opacity(0.15)).cornerRadius(8) }
                            if !item.platform.isEmpty { Text(item.platform).font(.subheadline).padding(.horizontal, 12).padding(.vertical, 6).background(Color.indigo.opacity(0.15)).cornerRadius(8) }
                            Text(item.status == .sold ? "已出" : "在用").font(.caption.weight(.bold)).padding(.horizontal, 10).padding(.vertical, 4).background(item.status == .sold ? Color.red : Color.green).foregroundColor(.white).cornerRadius(6)
                        }
                    }.padding(.top, 20)
                    
                    HStack(spacing: 15) {
                        VStack(spacing: 8) { Text("价格").font(.caption).foregroundColor(.secondary); Text("¥\(String(format: "%.0f", item.price))").font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(.indigo) }.frame(maxWidth: .infinity).padding(.vertical, 16).background(RoundedRectangle(cornerRadius: 12).fill(Color.indigo.opacity(0.1)))
                        VStack(spacing: 8) { Text("CPW").font(.caption).foregroundColor(.secondary); Text("¥\(String(format: "%.0f", item.costPerWear))").font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(.purple) }.frame(maxWidth: .infinity).padding(.vertical, 16).background(RoundedRectangle(cornerRadius: 12).fill(Color.purple.opacity(0.1)))
                        VStack(spacing: 8) { Text("穿着次数").font(.caption).foregroundColor(.secondary); Text("\(item.wearCount)").font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(.green) }.frame(maxWidth: .infinity).padding(.vertical, 16).background(RoundedRectangle(cornerRadius: 12).fill(Color.green.opacity(0.1)))
                    }.padding(.horizontal)
                    
                    if !item.wearDates.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            HStack { Image(systemName: "calendar.badge.clock").font(.system(size: 16, weight: .semibold)).foregroundColor(.indigo); Text("穿着记录").font(.headline); Spacer() }.padding(.horizontal)
                            ScrollView {
                                VStack(spacing: 10) {
                                    ForEach(item.wearDates.sorted(by: >), id: \.self) { date in
                                        HStack {
                                            Image(systemName: "figure.walk").foregroundColor(.green)
                                            Text(formatDate(date)).font(.system(size: 15, design: .monospaced))
                                            Spacer()
                                            if let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day, days > 0 { Text("\(days)天前").font(.caption).foregroundColor(.secondary) }
                                            else if let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day, days == 0 { Text("今天").font(.caption.weight(.bold)).foregroundColor(.green) }
                                        }.padding(.horizontal, 16).padding(.vertical, 12).background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemGroupedBackground)))
                                    }
                                }.padding(.horizontal)
                            }.frame(maxHeight: 250)
                        }.padding(.vertical, 15).background(Color(.systemGroupedBackground)).cornerRadius(16).padding(.horizontal)
                    } else {
                        VStack(spacing: 12) { Image(systemName: "calendar.badge.exclamationmark").font(.system(size: 40)).foregroundColor(.orange.opacity(0.6)); Text("还没有穿着记录").font(.subheadline).foregroundColor(.secondary); if item.status == .active { Text("点击下方“今天穿了”按钮开始记录").font(.caption).foregroundColor(.secondary) } }.frame(maxWidth: .infinity).padding(.vertical, 40).background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemGroupedBackground))).padding(.horizontal)
                    }
                    
                    if hasDetailedSizes {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack { Image(systemName: "ruler").font(.system(size: 16, weight: .semibold)).foregroundColor(.indigo); Text("详细尺寸").font(.headline) }
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                if let s = item.shoulderWidth, !s.isEmpty { SizeInfoCard(label: "肩宽", value: "\(s)cm") }
                                if let c = item.chestCircumference, !c.isEmpty { SizeInfoCard(label: "胸围", value: "\(c)cm") }
                                if let sl = item.sleeveLength, !sl.isEmpty { SizeInfoCard(label: "袖长", value: "\(sl)cm") }
                                if let l = item.clothingLength, !l.isEmpty { SizeInfoCard(label: "衣长", value: "\(l)cm") }
                                if let w = item.waistline, !w.isEmpty { SizeInfoCard(label: "腰围", value: "\(w)cm") }
                                if let pl = item.pantsLength, !pl.isEmpty { SizeInfoCard(label: "裤长", value: "\(pl)cm") }
                                if let h = item.hips, !h.isEmpty { SizeInfoCard(label: "臀围", value: "\(h)cm") }
                                if let lo = item.legOpening, !lo.isEmpty { SizeInfoCard(label: "脚阔", value: "\(lo)cm") }
                                if let cbl = item.centerBackLength, !cbl.isEmpty { SizeInfoCard(label: "后中长", value: "\(cbl)cm") }
                                if let fl = item.frontLength, !fl.isEmpty { SizeInfoCard(label: "前衣长", value: "\(fl)cm") }
                                if let hm = item.hem, !hm.isEmpty { SizeInfoCard(label: "下摆", value: "\(hm)cm") }
                                if let bt = item.bagType, !bt.isEmpty { SizeInfoCard(label: "类型", value: bt) }
                                if let br = item.brand, !br.isEmpty { SizeInfoCard(label: "品牌", value: br) }
                            }
                        }.padding().background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemGroupedBackground))).padding(.horizontal)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack { Image(systemName: "info.circle").font(.system(size: 16, weight: .semibold)).foregroundColor(.indigo); Text("购买信息").font(.headline) }
                        VStack(spacing: 10) {
                            InfoRow(label: "购买日期", value: formatDate(item.purchaseDate))
                            if item.originalPrice != item.price { InfoRow(label: "原价", value: "¥\(String(format: "%.0f", item.originalPrice))") }
                            if !item.reason.isEmpty { VStack(alignment: .leading, spacing: 6) { Text("购买理由").font(.caption).foregroundColor(.secondary); Text(item.reason).font(.subheadline).foregroundColor(.primary) }.frame(maxWidth: .infinity, alignment: .leading) }
                            if let notes = item.notes, !notes.isEmpty { VStack(alignment: .leading, spacing: 6) { Text("备注").font(.caption).foregroundColor(.secondary); Text(notes).font(.subheadline).foregroundColor(.primary) }.frame(maxWidth: .infinity, alignment: .leading) }
                        }
                    }.padding().background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemGroupedBackground))).padding(.horizontal)
                    
                    if item.status == .sold {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack { Image(systemName: "tag.fill").font(.system(size: 16, weight: .semibold)).foregroundColor(.orange); Text("出售信息").font(.headline) }
                            VStack(spacing: 10) {
                                if let soldDate = item.soldDate { InfoRow(label: "出售日期", value: formatDate(soldDate)) }
                                if let soldPrice = item.soldPrice { InfoRow(label: "出售价格", value: "¥\(String(format: "%.0f", soldPrice))") }
                                if let soldNotes = item.soldNotes, !soldNotes.isEmpty { VStack(alignment: .leading, spacing: 6) { Text("出售备注").font(.caption).foregroundColor(.secondary); Text(soldNotes).font(.subheadline).foregroundColor(.primary) }.frame(maxWidth: .infinity, alignment: .leading) }
                            }
                        }.padding().background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemGroupedBackground))).padding(.horizontal)
                    }
                    
                    if item.status == .active {
                        VStack(spacing: 12) {
                            Button { wardrobeStore.addWearDate(id: item.id); UIImpactFeedbackGenerator(style: .medium).impactOccurred(); justWore = true; DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { justWore = false } } label: { HStack { Image(systemName: "figure.walk"); Text("今天穿了").font(.headline) }.frame(maxWidth: .infinity).padding().background(LinearGradient(colors: [.green, .teal], startPoint: .leading, endPoint: .trailing)).foregroundColor(.white).cornerRadius(14) }.scaleEffect(justWore ? 1.1 : 1.0).animation(.spring(response: 0.3, dampingFraction: 0.5), value: justWore)
                            HStack(spacing: 12) {
                                Button { showEditSheet = true } label: { HStack { Image(systemName: "pencil"); Text("编辑") }.font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity).padding().background(Color.indigo.opacity(0.1)).foregroundColor(.indigo).cornerRadius(12) }
                                Button { showSoldSheet = true } label: { HStack { Image(systemName: "tag"); Text("已出") }.font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity).padding().background(Color.orange.opacity(0.1)).foregroundColor(.orange).cornerRadius(12) }
                            }
                        }.padding(.horizontal)
                    }
                    Spacer(minLength: 30)
                }
            }
        }
        .navigationTitle("物品详情").navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditSheet) { EditItemView(item: item).environmentObject(wardrobeStore) }
        .sheet(isPresented: $showSoldSheet) { MarkAsSoldView(item: item).environmentObject(wardrobeStore) }
    }
}

struct EditItemView: View {
    @EnvironmentObject var wardrobeStore: WardrobeStore
    @Environment(\.dismiss) var dismiss
    var item: ClothingItem
    @State private var priceText: String = ""
    @State private var platformText: String = ""
    @State private var reasonText: String = ""
    @State private var sizeText: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("价格") { TextField("价格", text: $priceText).keyboardType(.decimalPad) }
                Section("基本信息") { TextField("平台", text: $platformText); TextField("尺码", text: $sizeText) }
                Section("购买理由") { TextEditor(text: $reasonText).frame(minHeight: 100) }
            }
            .navigationTitle("编辑物品").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("取消") { dismiss() } }; ToolbarItem(placement: .navigationBarTrailing) { Button("保存") { saveChanges() }.bold() } }
            .onAppear { priceText = String(format: "%.0f", item.price); platformText = item.platform; reasonText = item.reason; sizeText = item.size }
        }
    }
    private func saveChanges() {
        var updatedItem = item
        if let price = Double(priceText) { updatedItem.price = price }
        updatedItem.platform = platformText; updatedItem.reason = reasonText; updatedItem.size = sizeText
        wardrobeStore.updateItem(updatedItem: updatedItem); dismiss()
    }
}

struct AddItemView: View {
    @EnvironmentObject var store: WardrobeStore
    @Environment(\.dismiss) var dismiss
    var categoryName: String
    @State private var photoPickerItems: [PhotosPickerItem] = []
    @State private var imagesData: [Data] = []
    @State private var purchaseDate = Date()
    @State private var priceText = ""; @State private var originalPriceText = ""; @State private var platformText = ""; @State private var reasonText = ""; @State private var sizeText = ""; @State private var notesText = ""
    @State private var showExpensiveWarning = false; @State private var showScenarioWarning = false; @State private var currentWarningMessage = ""
    @State private var shoulderWidthText = ""; @State private var chestCircumferenceText = ""; @State private var sleeveLengthText = ""; @State private var clothingLengthText = ""; @State private var waistlineText = ""
    @State private var pantsLengthText = ""; @State private var hipsText = ""; @State private var legOpeningText = ""
    @State private var centerBackLengthText = ""; @State private var frontLengthText = ""; @State private var hemText = ""
    @State private var bagTypeText = ""; @State private var brandText = ""
    @State private var isProcessingBackground = false
    @State private var selectedImageIndexForBG: Int?
    
    var isClothingCategory: Bool {
        let clothingCategories = ["上装", "下装", "外套", "内衣", "运动服", "连衣裙", "套装"]
        return clothingCategories.contains(categoryName)
    }
    
    var isFormValid: Bool { !priceText.isEmpty && Double(priceText) != nil && !reasonText.isEmpty && !imagesData.isEmpty }
    var isExpensive: Bool { Double(priceText).map { $0 > 1000 } ?? false }
    var isScenarioExpensive: Bool { categoryName == "场景功能" && (Double(priceText).map { $0 > 500 } ?? false) }
    
    var body: some View {
        Form {
            Section {
                VStack(spacing: 15) {
                    HStack {
                        Text("照片 (\(imagesData.count)/5)").font(.headline)
                        Spacer()
                        if imagesData.isEmpty {
                            Text("至少添加1张").font(.caption).foregroundColor(.orange)
                        }
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(imagesData.enumerated()), id: \.offset) { index, data in
                                VStack(spacing: 8) {
                                    ZStack(alignment: .topTrailing) {
                                        if let uiImage = UIImage(data: data) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 110, height: 110)
                                                .cornerRadius(12)
                                                .clipped()
                                        }
                                        Button {
                                            imagesData.remove(at: index)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 22))
                                                .foregroundColor(.white)
                                                .background(Circle().fill(Color.red))
                                        }
                                        .padding(4)
                                    }
                                    
                                    // Background Removal Button
                                    Button {
                                        selectedImageIndexForBG = index
                                        removeBackground(at: index)
                                    } label: {
                                        HStack(spacing: 4) {
                                            if isProcessingBackground && selectedImageIndexForBG == index {
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle())
                                                    .scaleEffect(0.7)
                                            } else {
                                                Text("✂️")
                                                    .font(.system(size: 12))
                                            }
                                            Text("抠图")
                                                .font(.system(size: 10, weight: .semibold))
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing))
                                        )
                                    }
                                    .disabled(isProcessingBackground)
                                }
                            }
                            
                            if imagesData.count < 5 {
                                PhotosPicker(selection: $photoPickerItems, maxSelectionCount: 5 - imagesData.count, matching: .images) {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.15))
                                        .frame(width: 110, height: 110)
                                        .overlay(
                                            VStack(spacing: 5) {
                                                Image(systemName: "plus.circle.fill")
                                                    .font(.title2)
                                                Text("添加照片").font(.caption)
                                            }
                                            .foregroundColor(.gray)
                                        )
                                }
                            }
                        }
                    }
                }
            }
            Section("价格信息") {
                VStack(spacing: 12) {
                    HStack { Text("实付价格"); Spacer(); TextField("0.00", text: $priceText).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 100).onChange(of: priceText) { _, _ in updateWarnings() } }
                    if showExpensiveWarning { HStack(spacing: 8) { Image(systemName: "exclamationmark.bubble.fill").font(.system(size: 20)).foregroundColor(.orange); Text(currentWarningMessage).font(.system(size: 13)).foregroundColor(.orange).lineLimit(2).fixedSize(horizontal: false, vertical: true) }.padding(12).frame(maxWidth: .infinity, alignment: .leading).background(RoundedRectangle(cornerRadius: 10).fill(Color.orange.opacity(0.1))).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.orange.opacity(0.3), lineWidth: 1)).transition(.asymmetric(insertion: .scale(scale: 0.8).combined(with: .opacity), removal: .scale(scale: 0.8).combined(with: .opacity))) }
                    if showScenarioWarning { HStack(spacing: 8) { Image(systemName: "theatermasks.fill").font(.system(size: 20)).foregroundColor(.purple); Text(RationalityCatMessages.scenarioWarning).font(.system(size: 13)).foregroundColor(.purple).lineLimit(2).fixedSize(horizontal: false, vertical: true) }.padding(12).frame(maxWidth: .infinity, alignment: .leading).background(RoundedRectangle(cornerRadius: 10).fill(Color.purple.opacity(0.1))).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.purple.opacity(0.3), lineWidth: 1)).transition(.asymmetric(insertion: .scale(scale: 0.8).combined(with: .opacity), removal: .scale(scale: 0.8).combined(with: .opacity))) }
                    HStack { Text("原价"); Spacer(); TextField("可选", text: $originalPriceText).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 100) }
                }
            }
            Section("基本信息") { 
                DatePicker("购买日期", selection: $purchaseDate, displayedComponents: .date)
                HStack { Text("购买平台"); Spacer(); TextField("淘宝、京东...", text: $platformText).multilineTextAlignment(.trailing) }
                if categoryName != "包包" {
                    HStack { Text("尺码"); Spacer(); TextField("M / L / XL...", text: $sizeText).multilineTextAlignment(.trailing).frame(width: 100) }
                }
                if categoryName == "包包" {
                    HStack { Text("品牌"); Spacer(); TextField("例: LV / Gucci...", text: $brandText).multilineTextAlignment(.trailing) }
                }
            }
            
            // 分类专属测量字段
            if categoryName == "上装" {
                Section("详细平铺尺寸 (选填, cm)") {
                    HStack { Text("肩宽"); Spacer(); TextField("例: 48", text: $shoulderWidthText).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 100) }
                    HStack { Text("胸围"); Spacer(); TextField("例: 110", text: $chestCircumferenceText).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 100) }
                    HStack { Text("袖长"); Spacer(); TextField("例: 62", text: $sleeveLengthText).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 100) }
                    HStack { Text("衣长"); Spacer(); TextField("例: 72", text: $clothingLengthText).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 100) }
                    HStack { Text("腰围"); Spacer(); TextField("例: 90", text: $waistlineText).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 100) }
                }
            }
            
            if categoryName == "下装" {
                Section("详细平铺尺寸 (选填, cm)") {
                    HStack { Text("裤长"); Spacer(); TextField("例: 105", text: $pantsLengthText).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 100) }
                    HStack { Text("腰围"); Spacer(); TextField("例: 78", text: $waistlineText).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 100) }
                    HStack { Text("臀围"); Spacer(); TextField("例: 100", text: $hipsText).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 100) }
                    HStack { Text("脚阔"); Spacer(); TextField("例: 35", text: $legOpeningText).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 100) }
                }
            }
            
            if categoryName == "裙装" {
                Section("详细平铺尺寸 (选填, cm)") {
                    HStack { Text("后中长"); Spacer(); TextField("例: 95", text: $centerBackLengthText).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 100) }
                    HStack { Text("前衣长"); Spacer(); TextField("例: 90", text: $frontLengthText).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 100) }
                    HStack { Text("胸围"); Spacer(); TextField("例: 88", text: $chestCircumferenceText).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 100) }
                    HStack { Text("腰围"); Spacer(); TextField("例: 68", text: $waistlineText).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 100) }
                    HStack { Text("下摆"); Spacer(); TextField("例: 120", text: $hemText).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 100) }
                }
            }
            
            if categoryName == "包包" {
                Section("包包信息 (选填)") {
                    HStack { Text("类型"); Spacer(); TextField("例: Tote / 单肩包...", text: $bagTypeText).multilineTextAlignment(.trailing) }
                }
            }
            
            if isClothingCategory && categoryName != "下装" && categoryName != "裙装" {
                Section("详细平铺尺寸 (选填, cm)") {
                    HStack { Text("肩宽"); Spacer(); TextField("例: 48", text: $shoulderWidthText).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 100) }
                    HStack { Text("胸围"); Spacer(); TextField("例: 110", text: $chestCircumferenceText).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 100) }
                    HStack { Text("袖长"); Spacer(); TextField("例: 62", text: $sleeveLengthText).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 100) }
                    HStack { Text("衣长"); Spacer(); TextField("例: 72", text: $clothingLengthText).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 100) }
                    HStack { Text("腰围"); Spacer(); TextField("例: 90", text: $waistlineText).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 100) }
                }
            }
            
            Section("购买理由（必填）") { TextEditor(text: $reasonText).frame(minHeight: 100).overlay(alignment: .topLeading) { if reasonText.isEmpty { Text("为什么我一定要买这件衣服？").foregroundColor(.gray.opacity(0.5)).padding(.top, 8).padding(.leading, 4).allowsHitTesting(false) } } }
            
            Section("备注（选填）") { TextEditor(text: $notesText).frame(minHeight: 80).overlay(alignment: .topLeading) { if notesText.isEmpty { Text("其他备注信息...").foregroundColor(.gray.opacity(0.5)).padding(.top, 8).padding(.leading, 4).allowsHitTesting(false) } } }
        }
        .navigationTitle("记录 \(categoryName)").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("保存") { saveItem() }.disabled(!isFormValid).bold() } }
        .onChange(of: photoPickerItems) { _, newItems in loadPhotos(from: newItems) }
        .onAppear { currentWarningMessage = RationalityCatMessages.randomWarning() }
    }
    
    private func updateWarnings() { if isExpensive && !showExpensiveWarning { currentWarningMessage = RationalityCatMessages.randomWarning() }; withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { showExpensiveWarning = isExpensive; showScenarioWarning = isScenarioExpensive } }
    
    private func loadPhotos(from items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        Task {
            var loadedData: [Data] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    loadedData.append(data)
                }
            }
            await MainActor.run {
                imagesData.append(contentsOf: loadedData)
                photoPickerItems = []
            }
        }
    }
    
    private func saveItem() { 
        guard let priceValue = Double(priceText) else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let newItem = ClothingItem(
            id: UUID(), 
            category: categoryName, 
            price: priceValue, 
            originalPrice: Double(originalPriceText) ?? priceValue, 
            soldPrice: nil, 
            soldDate: nil, 
            date: purchaseDate, 
            platform: platformText, 
            reason: reasonText, 
            size: sizeText, 
            status: .active, 
            wearDates: [], 
            imagesData: imagesData, 
            notes: notesText.isEmpty ? nil : notesText, 
            soldNotes: nil, 
            shoulderWidth: shoulderWidthText.isEmpty ? nil : shoulderWidthText, 
            chestCircumference: chestCircumferenceText.isEmpty ? nil : chestCircumferenceText, 
            sleeveLength: sleeveLengthText.isEmpty ? nil : sleeveLengthText, 
            clothingLength: clothingLengthText.isEmpty ? nil : clothingLengthText, 
            waistline: waistlineText.isEmpty ? nil : waistlineText,
            pantsLength: pantsLengthText.isEmpty ? nil : pantsLengthText,
            hips: hipsText.isEmpty ? nil : hipsText,
            legOpening: legOpeningText.isEmpty ? nil : legOpeningText,
            centerBackLength: centerBackLengthText.isEmpty ? nil : centerBackLengthText,
            frontLength: frontLengthText.isEmpty ? nil : frontLengthText,
            hem: hemText.isEmpty ? nil : hemText,
            bagType: bagTypeText.isEmpty ? nil : bagTypeText,
            brand: brandText.isEmpty ? nil : brandText
        )
        store.addNewItem(newItem: newItem)
        dismiss() 
    }
    
    // MARK: - AI Background Removal
    private func removeBackground(at index: Int) {
        guard index < imagesData.count,
              let inputImage = UIImage(data: imagesData[index]) else { return }
        
        isProcessingBackground = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        Task {
            do {
                let processedImage = try await processBackgroundRemoval(image: inputImage)
                
                await MainActor.run {
                    if let pngData = processedImage.pngData() {
                        imagesData[index] = pngData
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                    isProcessingBackground = false
                    selectedImageIndexForBG = nil
                }
            } catch {
                await MainActor.run {
                    isProcessingBackground = false
                    selectedImageIndexForBG = nil
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }
        }
    }
    
    private func processBackgroundRemoval(image: UIImage) async throws -> UIImage {
        guard let inputImage = CIImage(image: image) else {
            throw NSError(domain: "BackgroundRemoval", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create CIImage"])
        }
        
        // Create Vision request for subject masking (iOS 17+)
        if #available(iOS 17.0, *) {
            let request = VNGenerateForegroundInstanceMaskRequest()
            
            return try await withCheckedThrowingContinuation { continuation in
                let handler = VNImageRequestHandler(ciImage: inputImage, options: [:])
                
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        try handler.perform([request])
                        
                        guard let result = request.results?.first else {
                            continuation.resume(throwing: NSError(domain: "BackgroundRemoval", code: -2, userInfo: [NSLocalizedDescriptionKey: "No mask generated"]))
                            return
                        }
                        
                        // Generate mask
                        let mask = try result.generateScaledMaskForImage(forInstances: result.allInstances, from: handler)
                        
                        // Apply mask to create transparent background
                        let maskCIImage = CIImage(cvPixelBuffer: mask)
                        let filter = CIFilter.blendWithMask()
                        filter.inputImage = inputImage
                        filter.backgroundImage = CIImage.empty()
                        filter.maskImage = maskCIImage
                        
                        guard let outputImage = filter.outputImage else {
                            continuation.resume(throwing: NSError(domain: "BackgroundRemoval", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to apply mask"]))
                            return
                        }
                        
                        let context = CIContext()
                        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
                            continuation.resume(throwing: NSError(domain: "BackgroundRemoval", code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to create CGImage"]))
                            return
                        }
                        
                        let resultImage = UIImage(cgImage: cgImage)
                        continuation.resume(returning: resultImage)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        } else {
            // Fallback for iOS 16 - return original image
            return image
        }
    }
}

struct MarkAsSoldView: View {
    @EnvironmentObject var wardrobeStore: WardrobeStore
    @Environment(\.dismiss) var dismiss
    var item: ClothingItem
    
    @State private var soldPriceText: String = ""
    @State private var soldDate: Date = Date()
    @State private var soldNotes: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("出售价格") {
                    HStack {
                        Text("原价")
                        Spacer()
                        Text("¥\(String(format: "%.0f", item.price))")
                            .foregroundColor(.secondary)
                    }
                    TextField("出售价格（可选）", text: $soldPriceText)
                        .keyboardType(.decimalPad)
                }
                
                Section("出售日期") {
                    DatePicker("日期", selection: $soldDate, displayedComponents: .date)
                }
                
                Section("备注（可选）") {
                    TextEditor(text: $soldNotes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("标记为已出")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("确认") {
                        let price = soldPriceText.isEmpty ? nil : Double(soldPriceText)
                        let notes = soldNotes.isEmpty ? nil : soldNotes
                        wardrobeStore.markAsSoldById(id: item.id, soldPrice: price, soldDate: soldDate, soldNotes: notes)
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }
}