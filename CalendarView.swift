import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var wardrobeStore: WardrobeStore
    @State private var selectedDate: Date? = nil
    @State private var currentMonth: Date = Date()
    @State private var showOutfitSheet = false
    
    private var calendar: Calendar {
        Calendar.current
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: currentMonth)
    }
    
    private var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }
        
        var days: [Date?] = []
        var date = monthFirstWeek.start
        
        while date < monthInterval.end || days.count % 7 != 0 {
            if calendar.isDate(date, equalTo: currentMonth, toGranularity: .month) {
                days.append(date)
            } else {
                days.append(nil)
            }
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }
        
        return days
    }
    
    private func itemsWorn(on date: Date) -> [ClothingItem] {
        wardrobeStore.getOutfit(for: date)
    }
    
    private func hasOutfit(on date: Date?) -> Bool {
        guard let date = date else { return false }
        return !wardrobeStore.getOutfit(for: date).isEmpty
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Month Navigation Header
                HStack {
                    Button {
                        withAnimation {
                            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.indigo)
                            .padding(12)
                            .background(Circle().fill(Color.indigo.opacity(0.1)))
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .foregroundColor(.indigo)
                            Text(monthYearString)
                                .font(.system(size: 24, weight: .bold))
                        }
                        Text("OOTD 穿搭日历")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        withAnimation {
                            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.indigo)
                            .padding(12)
                            .background(Circle().fill(Color.indigo.opacity(0.1)))
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                
                // Weekday Headers
                HStack(spacing: 0) {
                    ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { day in
                        Text(day)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 8)
                
                // Calendar Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                    ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                        if let date = date {
                            CalendarDayCell(
                                date: date,
                                isToday: calendar.isDateInToday(date),
                                isSelected: selectedDate != nil && calendar.isDate(date, inSameDayAs: selectedDate!),
                                hasOutfit: hasOutfit(on: date),
                                items: itemsWorn(on: date)
                            )
                            .onTapGesture {
                                if hasOutfit(on: date) {
                                    selectedDate = date
                                    showOutfitSheet = true
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                            }
                        } else {
                            Color.clear
                                .frame(height: 70)
                        }
                    }
                }
                .padding(.horizontal, 8)
                
                Spacer()
                
                // Legend
                HStack(spacing: 20) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("有穿搭记录")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.indigo)
                            .frame(width: 8, height: 8)
                        Text("今天")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .padding()
            }
        }
        .navigationTitle("穿搭日历")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showOutfitSheet) {
            if let date = selectedDate {
                OutfitDetailSheet(date: date, items: itemsWorn(on: date))
                    .environmentObject(wardrobeStore)
            }
        }
    }
}

// MARK: - Calendar Day Cell
struct CalendarDayCell: View {
    var date: Date
    var isToday: Bool
    var isSelected: Bool
    var hasOutfit: Bool
    var items: [ClothingItem]
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 2) {
            // Day Number
            Text(dayNumber)
                .font(.system(size: 14, weight: isToday ? .bold : .medium))
                .foregroundColor(isToday ? .white : (hasOutfit ? .primary : .secondary))
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(isToday ? Color.indigo : Color.clear)
                )
            
            // Thumbnail or Indicator - FIX: Handle multiple items without overlap
            if hasOutfit {
                ZStack(alignment: .bottomTrailing) {
                    if items.count == 1 {
                        // Single item: show full thumbnail
                        if let uiImage = items.first?.firstImage {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 32, height: 32)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.green.opacity(0.6), lineWidth: 1.5)
                                )
                        } else {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.green.opacity(0.2))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: "tshirt.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.green)
                                )
                        }
                    } else {
                        // Multiple items: show 2x2 mini grid with first item + badge
                        if let uiImage = items.first?.firstImage {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 32, height: 32)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.green.opacity(0.6), lineWidth: 1.5)
                                )
                        } else {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.green.opacity(0.2))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: "tshirt.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.green)
                                )
                        }
                    }
                    
                    // Badge for multiple items - positioned in bottom-right corner
                    if items.count > 1 {
                        Text("+\(items.count - 1)")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 3)
                            .padding(.vertical, 1)
                            .background(
                                Capsule()
                                    .fill(Color.orange)
                            )
                            .offset(x: 4, y: 4)
                    }
                }
                .frame(width: 36, height: 36)
            } else {
                // No outfit - empty space
                Color.clear
                    .frame(width: 32, height: 32)
            }
            
            Spacer(minLength: 0)
        }
        .frame(height: 70)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(hasOutfit ? Color.green.opacity(0.05) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.indigo : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Outfit Detail Sheet
struct OutfitDetailSheet: View {
    @EnvironmentObject var wardrobeStore: WardrobeStore
    @Environment(\.dismiss) var dismiss
    var date: Date
    var items: [ClothingItem]
    @State private var dailyNote: String = ""
    @FocusState private var isNoteFieldFocused: Bool
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    private var weekdayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Date Header
                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.title2)
                                    .foregroundColor(.indigo)
                                Text(dateString)
                                    .font(.title2.bold())
                            }
                            Text(weekdayString)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top)
                        
                        // Items Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(items) { item in
                                NavigationLink(destination: ItemDetailView(item: item).environmentObject(wardrobeStore)) {
                                    VStack(spacing: 10) {
                                        // Image
                                        if let uiImage = item.firstImage {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(height: 150)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color.indigo.opacity(0.3), lineWidth: 1)
                                                )
                                        } else {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.gray.opacity(0.2))
                                                .frame(height: 150)
                                                .overlay(
                                                    Image(systemName: "photo")
                                                        .font(.title)
                                                        .foregroundColor(.gray)
                                                )
                                        }
                                        
                                        // Info
                                        VStack(spacing: 4) {
                                            Text(item.category)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundColor(.primary)
                                            
                                            HStack(spacing: 4) {
                                                Text("¥\(String(format: "%.0f", item.price))")
                                                    .font(.caption)
                                                    .foregroundColor(.indigo)
                                                
                                                if !item.size.isEmpty {
                                                    Text("•")
                                                        .foregroundColor(.secondary)
                                                    Text(item.size)
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Stats
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("当天共穿了 \(items.count) 件单品")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            let totalValue = items.reduce(0.0) { $0 + $1.price }
                            HStack {
                                Image(systemName: "dollarsign.circle.fill")
                                    .foregroundColor(.indigo)
                                Text("总价值 ¥\(String(format: "%.0f", totalValue))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                        .padding(.horizontal)
                        
                        // Daily Notes Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "note.text")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.indigo)
                                Text("今日心得")
                                    .font(.headline)
                                Spacer()
                            }
                            
                            TextEditor(text: $dailyNote)
                                .frame(minHeight: 100)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.tertiarySystemGroupedBackground))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(isNoteFieldFocused ? Color.indigo : Color.clear, lineWidth: 1.5)
                                )
                                .overlay(alignment: .topLeading) {
                                    if dailyNote.isEmpty && !isNoteFieldFocused {
                                        Text("记录今天的穿搭心得...\n例如: 鞋子有点磨脚、今天被夸了、搭配很舒适...")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary.opacity(0.6))
                                            .padding(.top, 16)
                                            .padding(.leading, 12)
                                            .allowsHitTesting(false)
                                    }
                                }
                                .focused($isNoteFieldFocused)
                                .onChange(of: dailyNote) { _, newValue in
                                    // Auto-save when note changes
                                    wardrobeStore.setNote(for: date, note: newValue)
                                }
                            
                            if !dailyNote.isEmpty {
                                HStack {
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("已自动保存 ✓")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                        .padding(.horizontal)
                        
                        Spacer(minLength: 20)
                    }
                }
            }
            .navigationTitle("\(dateString)的穿搭")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        // Save note before dismissing (already auto-saved, but just in case)
                        wardrobeStore.setNote(for: date, note: dailyNote)
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .keyboard) {
                    Button("完成") {
                        isNoteFieldFocused = false
                    }
                    .font(.headline)
                }
            }
            .onAppear {
                // Load existing note when sheet appears
                if let existingNote = wardrobeStore.getNote(for: date) {
                    dailyNote = existingNote
                }
            }
        }
    }
}
