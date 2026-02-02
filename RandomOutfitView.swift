import SwiftUI
import Photos

// MARK: - Outfit Model
struct GeneratedOutfit {
    var topOrDress: ClothingItem?
    var bottom: ClothingItem?
    var shoes: ClothingItem?
    var bag: ClothingItem?
    var accessories: [ClothingItem] = []
    
    var totalPrice: Double {
        var total = 0.0
        if let top = topOrDress { total += top.price }
        if let bottom = bottom { total += bottom.price }
        if let shoes = shoes { total += shoes.price }
        if let bag = bag { total += bag.price }
        total += accessories.reduce(0.0) { $0 + $1.price }
        return total
    }
    
    var allItems: [ClothingItem] {
        var items: [ClothingItem] = []
        if let top = topOrDress { items.append(top) }
        if let bottom = bottom { items.append(bottom) }
        if let shoes = shoes { items.append(shoes) }
        if let bag = bag { items.append(bag) }
        items.append(contentsOf: accessories)
        return items
    }
    
    var isEmpty: Bool {
        return topOrDress == nil && bottom == nil && shoes == nil && bag == nil && accessories.isEmpty
    }
}

// MARK: - Random Outfit Generator View
struct RandomOutfitView: View {
    @EnvironmentObject var wardrobeStore: WardrobeStore
    @Environment(\.dismiss) var dismiss
    
    @State private var maxBudget: Double = 1000
    @State private var budgetText: String = "1000"
    @State private var currentOutfit: GeneratedOutfit?
    @State private var isGenerating = false
    @State private var generationFailed = false
    @State private var showSaveAlert = false
    @State private var showInsufficientItemsAlert = false
    @State private var renderedOutfitImage: UIImage?
    @State private var isSavingToPhotos = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Header
                        VStack(spacing: 12) {
                            HStack {
                                Text("🎲").font(.system(size: 40))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("一键不理性穿搭")
                                        .font(.system(size: 26, weight: .bold))
                                    Text("本功能不考虑季节、温度及路人眼光")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.top)
                        }
                        
                        // Budget Input
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "dollarsign.circle.fill")
                                    .foregroundColor(.indigo)
                                Text("预算上限")
                                    .font(.system(size: 16, weight: .semibold))
                                Spacer()
                            }
                            
                            HStack(spacing: 12) {
                                Text("¥")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.indigo)
                                
                                TextField("输入预算", text: $budgetText)
                                    .keyboardType(.numberPad)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.indigo)
                                    .multilineTextAlignment(.leading)
                                    .onChange(of: budgetText) { _, newValue in
                                        // Update maxBudget from text
                                        if let value = Double(newValue), value > 0 {
                                            maxBudget = value
                                        }
                                    }
                                
                                Button {
                                    generateOutfit()
                                } label: {
                                    Text("生成")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(
                                            LinearGradient(
                                                colors: [.indigo, .purple],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .cornerRadius(10)
                                }
                                .disabled(isGenerating || budgetText.isEmpty || Double(budgetText) == nil)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.tertiarySystemGroupedBackground))
                            )
                            
                            Text("支持输入任意金额，不限上限")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.indigo.opacity(0.3), lineWidth: 1.5)
                        )
                        .padding(.horizontal)
                        
                        // Outfit Display
                        if let outfit = currentOutfit, !outfit.isEmpty {
                            OutfitMoodboardView(outfit: outfit)
                                .transition(.opacity.combined(with: .scale))
                        } else if generationFailed {
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.orange)
                                Text("生成失败")
                                    .font(.title3.bold())
                                Text("预算内没有足够的物品组合\n试试提高预算或添加更多衣物吧！")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(40)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.orange.opacity(0.1))
                            )
                            .padding(.horizontal)
                        } else {
                            VStack(spacing: 16) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 50))
                                    .foregroundColor(.purple.opacity(0.5))
                                Text("点击下方按钮")
                                    .font(.title3.bold())
                                Text("让理性小猫为你搭配今日穿搭")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(40)
                            .frame(maxWidth: .infinity)
                        }
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            Button {
                                generateOutfit()
                            } label: {
                                HStack(spacing: 12) {
                                    if isGenerating {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Image(systemName: currentOutfit == nil ? "wand.and.stars" : "arrow.triangle.2.circlepath")
                                            .font(.system(size: 18, weight: .semibold))
                                    }
                                    Text(currentOutfit == nil ? "随机换一套" : "再换一套")
                                        .font(.system(size: 18, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [.indigo, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(14)
                            }
                            .disabled(isGenerating)
                            
                            if currentOutfit != nil && !currentOutfit!.isEmpty {
                                // Real Share Button using ShareLink
                                if let image = renderedOutfitImage {
                                    ShareLink(
                                        item: Image(uiImage: image),
                                        preview: SharePreview("我的不理性穿搭", image: Image(uiImage: image))
                                    ) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "square.and.arrow.up")
                                            Text("分享穿搭")
                                        }
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(
                                            LinearGradient(
                                                colors: [.purple, .pink],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .cornerRadius(12)
                                    }
                                }
                                
                                Button {
                                    saveOutfitToPhotos()
                                } label: {
                                    HStack(spacing: 8) {
                                        if isSavingToPhotos {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .indigo))
                                        } else {
                                            Image(systemName: "photo.on.rectangle.angled")
                                        }
                                        Text(isSavingToPhotos ? "保存中..." : "保存到相册")
                                    }
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.indigo)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.indigo.opacity(0.1))
                                    .cornerRadius(12)
                                }
                                .disabled(isSavingToPhotos)
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .alert("保存成功", isPresented: $showSaveAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text("穿搭灵感卡片已保存到相册 📸")
            }
            .alert("巧妇难为无米之炊", isPresented: $showInsufficientItemsAlert) {
                Button("知道了", role: .cancel) { }
            } message: {
                Text("你的衣橱物品太少，无法生成完整搭配\n\n至少需要：\n• 1件上装或裙装\n• 1件鞋履\n\n建议先添加更多衣物再试试吧！")
            }
        }
    }
    
    // MARK: - Outfit Generation Logic
    private func generateOutfit() {
        // Pre-flight check: Ensure minimum items exist
        let activeItems = wardrobeStore.items.filter { $0.status == .active }
        let tops = activeItems.filter { $0.category == "上装" || $0.category == "外套" }
        let dresses = activeItems.filter { $0.category == "裙装" }
        let shoes = activeItems.filter { $0.category == "鞋履" }
        
        // Need at least: (1 top OR 1 dress) AND 1 shoe
        let hasMainPiece = !tops.isEmpty || !dresses.isEmpty
        let hasShoes = !shoes.isEmpty
        
        if !hasMainPiece || !hasShoes {
            showInsufficientItemsAlert = true
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            return
        }
        
        isGenerating = true
        generationFailed = false
        
        // Add haptic feedback
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        // Simulate generation delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                let result = tryGenerateOutfit(maxAttempts: 50)
                currentOutfit = result
                generationFailed = result == nil || result!.isEmpty
                isGenerating = false
                
                if !generationFailed {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    // Render image for sharing after generation
                    renderOutfitImage()
                }
            }
        }
    }
    
    private func tryGenerateOutfit(maxAttempts: Int) -> GeneratedOutfit? {
        let activeItems = wardrobeStore.items.filter { $0.status == .active }
        
        // Categorize items
        let tops = activeItems.filter { $0.category == "上装" || $0.category == "外套" }
        let bottoms = activeItems.filter { $0.category == "下装" || $0.category == "裙装" } // Skirts are bottoms!
        let dresses = activeItems.filter { $0.category == "裙装" } // Full dresses/suits
        let shoes = activeItems.filter { $0.category == "鞋履" }
        let bags = activeItems.filter { $0.category == "包包" }
        let accessories = activeItems.filter { $0.category == "配饰" }
        
        // Try multiple times to find a valid combination
        for _ in 0..<maxAttempts {
            var outfit = GeneratedOutfit()
            
            // Step 1: Randomly choose Structure Type
            // Type A: Top + Bottom OR Type B: Dress (standalone piece)
            let useDress = !dresses.isEmpty && Bool.random()
            
            if useDress {
                // Type B: Dress/Suit - NO Top or Bottom
                outfit.topOrDress = dresses.randomElement()
                outfit.bottom = nil // Explicitly no bottom with dress
            } else {
                // Type A: Separates - Top + Bottom
                outfit.topOrDress = tops.randomElement()
                outfit.bottom = bottoms.randomElement()
            }
            
            // Essential items (always included regardless of type)
            outfit.shoes = shoes.randomElement()
            outfit.bag = bags.randomElement()
            
            // Random accessories (0-2 items)
            let accessoryCount = Int.random(in: 0...min(2, accessories.count))
            outfit.accessories = Array(accessories.shuffled().prefix(accessoryCount))
            
            // Check budget
            if outfit.totalPrice <= maxBudget && !outfit.isEmpty {
                return outfit
            }
        }
        
        // If we couldn't generate within budget, return nil
        return nil
    }
    
    // MARK: - Render Outfit Image for Sharing
    @MainActor
    private func renderOutfitImage() {
        guard let outfit = currentOutfit, !outfit.isEmpty else { return }
        let renderer = ImageRenderer(content: OutfitMoodboardView(outfit: outfit))
        renderer.scale = 3.0
        renderedOutfitImage = renderer.uiImage
    }
    
    // MARK: - Save to Photos
    @MainActor
    private func saveOutfitToPhotos() {
        guard let outfit = currentOutfit, !outfit.isEmpty else { return }
        
        isSavingToPhotos = true
        
        // FIX: Enforce Main Thread for Photo Saving (Critical - prevents abort_with_payload crash)
        Task { @MainActor in
            // 1. Request photo library permission
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            
            guard status == .authorized || status == .limited else {
                isSavingToPhotos = false
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                print("❌ Photo library access denied")
                return
            }
            
            // 2. Create renderer on main thread
            let renderer = ImageRenderer(content: OutfitMoodboardView(outfit: outfit))
            renderer.scale = UIScreen.main.scale
            
            // 3. Render and save
            if let renderedImage = renderer.uiImage {
                UIImageWriteToSavedPhotosAlbum(renderedImage, nil, nil, nil)
                
                // Show success feedback
                try? await Task.sleep(nanoseconds: 500_000_000)
                isSavingToPhotos = false
                showSaveAlert = true
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                print("✅ Outfit saved to Photos")
            } else {
                isSavingToPhotos = false
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                print("❌ Failed to render outfit image")
            }
        }
    }
}

// MARK: - Outfit Moodboard View
struct OutfitMoodboardView: View {
    var outfit: GeneratedOutfit
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("今日搭配")
                    .font(.system(size: 18, weight: .bold))
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
            }
            .padding(.top, 10)
            
            // Main Outfit Grid
            VStack(spacing: 16) {
                // Top Row: Accessories (if any)
                if !outfit.accessories.isEmpty {
                    HStack(spacing: 12) {
                        ForEach(outfit.accessories) { item in
                            OutfitItemCard(item: item, size: .small)
                        }
                    }
                }
                
                // Center Row: Main Clothing
                HStack(spacing: 12) {
                    if let topOrDress = outfit.topOrDress {
                        OutfitItemCard(item: topOrDress, size: .large)
                    }
                    
                    if let bottom = outfit.bottom {
                        OutfitItemCard(item: bottom, size: .large)
                    }
                }
                
                // Bottom Row: Shoes and Bag
                HStack(spacing: 12) {
                    if let shoes = outfit.shoes {
                        OutfitItemCard(item: shoes, size: .medium)
                    }
                    
                    if let bag = outfit.bag {
                        OutfitItemCard(item: bag, size: .medium)
                    }
                }
            }
            
            // Total Price Banner
            VStack(spacing: 8) {
                HStack {
                    Text("总价值")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("¥\(String(format: "%.0f", outfit.totalPrice))")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.indigo)
                }
                
                Text("\(outfit.allItems.count) 件单品")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.indigo.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.indigo.opacity(0.3), lineWidth: 2)
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.purple.opacity(0.2), lineWidth: 2)
        )
        .padding(.horizontal)
    }
}

// MARK: - Outfit Item Card
struct OutfitItemCard: View {
    var item: ClothingItem
    var size: CardSize
    
    enum CardSize {
        case small, medium, large
        
        var dimension: CGFloat {
            switch self {
            case .small: return 80
            case .medium: return 120
            case .large: return 150
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Image
            if let uiImage = item.firstImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.dimension, height: size.dimension)
                    .clipped()
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.separator).opacity(0.3), lineWidth: 2)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: size.dimension, height: size.dimension)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: size.dimension * 0.3))
                            .foregroundColor(.gray)
                    )
            }
            
            // Item Info
            VStack(spacing: 3) {
                Text(item.category)
                    .font(.system(size: size == .small ? 10 : 12, weight: .semibold))
                    .lineLimit(1)
                
                Text("¥\(String(format: "%.0f", item.price))")
                    .font(.system(size: size == .small ? 11 : 13, weight: .bold))
                    .foregroundColor(.indigo)
            }
        }
        .frame(width: size.dimension)
    }
}
