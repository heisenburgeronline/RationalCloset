import SwiftUI

struct InfoRow: View {
    var label: String
    var value: String
    
    var body: some View {
        HStack {
            Text(label).font(.caption).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.subheadline).foregroundColor(.primary)
        }
    }
}

struct SizeInfoCard: View {
    var label: String
    var value: String
    
    var body: some View {
        VStack(spacing: 6) {
            Text(label).font(.caption).foregroundColor(.secondary)
            Text(value).font(.subheadline.weight(.semibold)).foregroundColor(.blue)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.blue.opacity(0.08)))
    }
}

struct ColdPalaceItemCard: View {
    var item: ClothingItem
    private var daysSincePurchase: Int {
        Calendar.current.dateComponents([.day], from: item.purchaseDate, to: Date()).day ?? 0
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 8) {
                if let data = item.imagesData.first, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage).resizable().scaledToFill().frame(width: 140, height: 140).clipped().cornerRadius(12)
                } else {
                    RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.3)).frame(width: 140, height: 140)
                        .overlay(Image(systemName: "photo").font(.title).foregroundColor(.gray))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.category).font(.caption.weight(.semibold)).lineLimit(1)
                    HStack(spacing: 4) {
                        Image(systemName: "calendar").font(.caption2).foregroundColor(.orange)
                        Text("\(daysSincePurchase)天未穿").font(.caption2).foregroundColor(.orange)
                    }
                    Text("¥\(String(format: "%.0f", item.price))").font(.subheadline.weight(.bold))
                }
            }.frame(width: 140)
            Text("🕸️").font(.system(size: 28)).offset(x: 8, y: -8)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.orange.opacity(0.3), lineWidth: 1.5))
    }
}

struct CategoryCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .rotationEffect(.degrees(configuration.isPressed ? -1 : 0))
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct CategoryCardView: View {
    var name: String
    var icon: String
    var description: String
    var count: Int
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 26)).foregroundColor(.accentColor).frame(width: 40, height: 40)
            Text(name).font(.caption.weight(.medium)).lineLimit(1)
            Text(description).font(.caption2).foregroundColor(.secondary).lineLimit(1).minimumScaleFactor(0.8)
            if count > 0 {
                Text("\(count)件").font(.caption2).foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity).frame(height: 100)
        .background(Color(.secondarySystemGroupedBackground)).cornerRadius(12)
    }
}

struct RecentItemCardView: View {
    var item: ClothingItem
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let data = item.imagesData.first, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage).resizable().scaledToFill().frame(width: 130, height: 130).clipped().cornerRadius(10)
            } else {
                RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.2)).frame(width: 130, height: 130)
                    .overlay(Image(systemName: "photo").font(.title).foregroundColor(.gray))
            }
            Text(item.category).font(.caption).foregroundColor(.secondary)
            HStack {
                Text("¥\(String(format: "%.0f", item.price))").font(.subheadline.weight(.semibold))
                if item.wearCount > 0 { Text("穿\(item.wearCount)次").font(.caption2).foregroundColor(.green) }
            }
        }.frame(width: 130)
    }
}

struct AllItemRow: View {
    var item: ClothingItem
    var isRecentlySold: Bool = false
    var isRecentlyWorn: Bool = false
    var onWear: () -> Void
    
    var isSold: Bool { item.status == .sold }
    
    // 详细尺寸部分代码复用
    var detailSizeString: String? {
        var parts: [String] = []
        if let c = item.chestCircumference, !c.isEmpty { parts.append("胸围:\(c)") }
        if let l = item.clothingLength, !l.isEmpty { parts.append("衣长:\(l)") }
        if let s = item.shoulderWidth, !s.isEmpty { parts.append("肩宽:\(s)") }
        if let sl = item.sleeveLength, !sl.isEmpty { parts.append("袖长:\(sl)") }
        if let w = item.waistline, !w.isEmpty { parts.append("腰围:\(w)") }
        if let pl = item.pantsLength, !pl.isEmpty { parts.append("裤长:\(pl)") }
        if let h = item.hips, !h.isEmpty { parts.append("臀围:\(h)") }
        if let lo = item.legOpening, !lo.isEmpty { parts.append("脚阔:\(lo)") }
        if let cbl = item.centerBackLength, !cbl.isEmpty { parts.append("后中长:\(cbl)") }
        if let fl = item.frontLength, !fl.isEmpty { parts.append("前长:\(fl)") }
        if let hm = item.hem, !hm.isEmpty { parts.append("下摆:\(hm)") }
        if let bt = item.bagType, !bt.isEmpty { parts.append("类型:\(bt)") }
        if let br = item.brand, !br.isEmpty { parts.append("品牌:\(br)") }
        return parts.isEmpty ? nil : parts.joined(separator: " | ")
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                if let data = item.imagesData.first, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage).resizable().scaledToFill().frame(width: 60, height: 60).cornerRadius(10).clipped()
                        .id("\(item.id)-list-image")
                } else {
                    RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.2)).frame(width: 60, height: 60)
                        .overlay(Image(systemName: "photo").foregroundColor(.gray))
                        .id("\(item.id)-list-placeholder")
                }
                if isSold {
                    RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.5)).frame(width: 60, height: 60)
                    Text("SOLD").font(.system(size: 12, weight: .black)).foregroundColor(.white).rotationEffect(.degrees(-20))
                }
            }
            .scaleEffect(isRecentlySold ? 0.95 : (isRecentlyWorn ? 1.1 : 1.0))
            
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(item.category).font(.headline)
                    if isSold { Text("SOLD").font(.caption2.weight(.black)).foregroundColor(.white).padding(.horizontal, 5).padding(.vertical, 2).background(Color.red).cornerRadius(4) }
                }
                if isSold {
                    HStack(spacing: 4) {
                        Text("¥\(String(format: "%.0f", item.price))").font(.subheadline).strikethrough().foregroundColor(.secondary)
                        Image(systemName: "arrow.right").font(.caption2).foregroundColor(.orange)
                        if let soldPrice = item.soldPrice { Text("卖出 ¥\(String(format: "%.0f", soldPrice))").font(.subheadline.weight(.semibold)).foregroundColor(.orange) }
                        else { Text("已出").font(.subheadline).foregroundColor(.orange) }
                    }
                } else {
                    HStack(spacing: 8) {
                        Text("¥\(String(format: "%.0f", item.price))").font(.subheadline.weight(.semibold))
                        Text("CPW: ¥\(String(format: "%.0f", item.costPerWear))").font(.caption2).foregroundColor(.purple).padding(.horizontal, 6).padding(.vertical, 2).background(Color.purple.opacity(0.1)).cornerRadius(4)
                    }
                }
                HStack(spacing: 6) {
                    if !item.platform.isEmpty { Text(item.platform).font(.caption).foregroundColor(.secondary) }
                    Text(item.date, style: .date).font(.caption).foregroundColor(.secondary)
                    if item.wearCount > 0 { Text("穿\(item.wearCount)次").font(.caption).foregroundColor(.green) }
                }
                if let sizeStr = detailSizeString { Text(sizeStr).font(.caption2).foregroundColor(.blue.opacity(0.8)).lineLimit(1).minimumScaleFactor(0.7) }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                if !item.size.isEmpty { Text(item.size).font(.caption).padding(.horizontal, 8).padding(.vertical, 4).background(Color.accentColor.opacity(0.1)).cornerRadius(4).foregroundColor(.accentColor) }
                if !isSold {
                    Button { onWear() } label: { Image(systemName: "figure.walk").font(.system(size: 14, weight: .medium)).foregroundColor(.green).padding(8).background(Circle().fill(Color.green.opacity(0.15))) }.buttonStyle(.plain)
                }
            }
        }.padding(.vertical, 4).opacity(isSold ? 0.5 : 1.0)
    }
}

struct ItemCardRow: View {
    @EnvironmentObject var wardrobeStore: WardrobeStore
    var item: ClothingItem
    var isRecentlyWorn: Bool = false
    var onWear: () -> Void
    var isSold: Bool { item.status == .sold }
    var isCold: Bool { item.isCold(threshold: wardrobeStore.coldThresholdDays) }
    
    // 详细尺寸部分代码复用
    var detailSizeString: String? {
        var parts: [String] = []
        if let c = item.chestCircumference, !c.isEmpty { parts.append("胸围:\(c)") }
        if let l = item.clothingLength, !l.isEmpty { parts.append("衣长:\(l)") }
        if let s = item.shoulderWidth, !s.isEmpty { parts.append("肩宽:\(s)") }
        if let sl = item.sleeveLength, !sl.isEmpty { parts.append("袖长:\(sl)") }
        if let w = item.waistline, !w.isEmpty { parts.append("腰围:\(w)") }
        if let pl = item.pantsLength, !pl.isEmpty { parts.append("裤长:\(pl)") }
        if let h = item.hips, !h.isEmpty { parts.append("臀围:\(h)") }
        if let lo = item.legOpening, !lo.isEmpty { parts.append("脚阔:\(lo)") }
        if let cbl = item.centerBackLength, !cbl.isEmpty { parts.append("后中长:\(cbl)") }
        if let fl = item.frontLength, !fl.isEmpty { parts.append("前长:\(fl)") }
        if let hm = item.hem, !hm.isEmpty { parts.append("下摆:\(hm)") }
        if let bt = item.bagType, !bt.isEmpty { parts.append("类型:\(bt)") }
        if let br = item.brand, !br.isEmpty { parts.append("品牌:\(br)") }
        return parts.isEmpty ? nil : parts.joined(separator: " | ")
    }
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                if let data = item.imagesData.first, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage).resizable().scaledToFill().frame(width: 70, height: 70).cornerRadius(10).clipped()
                        .id("\(item.id)-category-image")
                } else {
                    RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.2)).frame(width: 70, height: 70).overlay(Image(systemName: "photo").foregroundColor(.gray))
                        .id("\(item.id)-category-placeholder")
                }
                if isSold {
                    RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.5)).frame(width: 70, height: 70)
                    Text("SOLD").font(.system(size: 12, weight: .black)).foregroundColor(.white).rotationEffect(.degrees(-20))
                }
            }
            .scaleEffect(isRecentlyWorn ? 1.1 : 1.0)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    if isCold {
                        Text("❄️").font(.system(size: 14))
                    }
                    if isSold {
                        HStack(spacing: 4) {
                            Text("¥\(String(format: "%.0f", item.price))").font(.system(size: 16, weight: .medium)).strikethrough().foregroundColor(.secondary)
                            Image(systemName: "arrow.right").font(.caption).foregroundColor(.orange)
                            if let soldPrice = item.soldPrice { Text("¥\(String(format: "%.0f", soldPrice))").font(.system(size: 18, weight: .bold)).foregroundColor(.orange) }
                            else { Text("已出").font(.system(size: 16)).foregroundColor(.orange) }
                        }
                    } else {
                        HStack(spacing: 8) {
                            Text("¥\(String(format: "%.2f", item.price))").font(.system(size: 18, weight: .bold))
                            Text("CPW: ¥\(String(format: "%.0f", item.costPerWear))").font(.caption2).foregroundColor(.purple).padding(.horizontal, 5).padding(.vertical, 2).background(Color.purple.opacity(0.1)).cornerRadius(4)
                        }
                    }
                    if isSold { Text("SOLD").font(.caption2.weight(.black)).foregroundColor(.white).padding(.horizontal, 5).padding(.vertical, 2).background(Color.red).cornerRadius(3) }
                }
                if !item.platform.isEmpty { Text(item.platform).font(.caption).foregroundColor(.secondary) }
                HStack {
                    if !item.reason.isEmpty { Text(item.reason).font(.caption).foregroundColor(.secondary).lineLimit(1) }
                    if item.wearCount > 0 { Text("穿\(item.wearCount)次").font(.caption).foregroundColor(.green) }
                }
                if let sizeStr = detailSizeString { Text(sizeStr).font(.caption2).foregroundColor(.blue.opacity(0.8)).lineLimit(1).minimumScaleFactor(0.7) }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Text(item.date, style: .date).font(.caption2).foregroundColor(.secondary)
                if !item.size.isEmpty { Text(item.size).font(.caption2).padding(.horizontal, 8).padding(.vertical, 3).background(Color.accentColor.opacity(0.1)).cornerRadius(4) }
                if !isSold {
                    Button { onWear() } label: { Image(systemName: "figure.walk").font(.system(size: 12, weight: .medium)).foregroundColor(.green).padding(6).background(Circle().fill(Color.green.opacity(0.15))) }.buttonStyle(.plain)
                }
            }
        }.padding(.vertical, 8).opacity(isSold ? 0.5 : 1.0)
    }
}