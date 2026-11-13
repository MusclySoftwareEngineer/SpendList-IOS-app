//
//  InputListPageView.swift
//  SpendList
//
//  Created by hunter on 12/05/2026.
//

import SwiftUI
import SwiftData

struct ShoppingItemInput: Identifiable {
    let id = UUID()
    var name: String
    var quantity: Int?
    var type: String
    var order: Int
    var isDone: Bool = false
    var priceText: String = ""
}


struct InputListPageView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    
    enum MoneyField: Hashable {
        case totalCost
        case itemPrice(UUID)
    }

    @FocusState private var focusedMoneyField: MoneyField?
    
    @State private var isTotalBillManuallyEdited = false
    @State private var pendingUncategorizedCost: Double = 0.0
    @AppStorage("inputListSelectedFilterType") private var selectedFilterType = "All"
    @State private var isItemTypeDropdownOpen = false
    @State private var isSortDropdownOpen = false
    @State private var itemText = ""
    @State private var qtyText = ""
    @State private var totalBillText = ""
    @State private var selectedCurrencyDisplay = "🇺🇸 US $"
    //type selection bar
    @State private var selectedItemType = "Uncategorized"

    @State private var items: [ShoppingItemInput] = []

    @State private var activeAlert: ActiveAlert?
    @State private var pendingTotalBill: Double = 0.0
    @State private var pendingHasTotalBill = false
    
    // dark mode: white light mode: black
    private var mainTextColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private let currencies = [
        "🇰🇷 Korean ₩",
            "🇬🇧 British £",
            "🇺🇸 US $",
            "🇯🇵 Japanese ¥"
    ]
    //type selection bar
    private let itemTypes = [
        "Uncategorized",
        "Food",
        "Clothes",
        "Household",
        "Personal Use"
        
    ]
    
    private func itemTypeRow(barHeight: CGFloat, dropdownRowHeight: CGFloat) -> some View {
        Button {
            isSortDropdownOpen = false
            isItemTypeDropdownOpen.toggle()
        } label: {
            HStack {
                Text(LocalizedStringKey(selectedItemType))
                    .foregroundStyle(.black)

                Spacer()

                Image(systemName: isItemTypeDropdownOpen ? "chevron.up" : "chevron.down")
                    .foregroundStyle(.black)
            }
            //closed type bar
            .padding(.horizontal, 12)
            .frame(height: barHeight)
            .background(typeBackgroundColor(selectedItemType).opacity(0.85))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .top) {
            if isItemTypeDropdownOpen {
                VStack(spacing: 0) {
                    ForEach(itemTypes, id: \.self) { type in
                        Button {
                            selectedItemType = type
                            isItemTypeDropdownOpen = false
                            saveDraft()
                        } label: {
                            HStack {
                                Text(LocalizedStringKey(type))
                                    .foregroundStyle(.black)

                                Spacer()

                                if selectedItemType == type {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.black)
                                }
                            }
                            //opened dropdown row
                            .padding(.horizontal, 12)
                            .frame(height: dropdownRowHeight)
                            .background(typeBackgroundColor(type).opacity(0.95))
                        }
                        .buttonStyle(.plain)

                        if type != itemTypes.last {
                            Divider()
                        }
                    }
                }
                .cornerRadius(8)
                .padding(.top, barHeight + 4)
            }
        }
    }
//end of type selection bar
    
    
    //sort selection bar
    private let filterOptions = [
        "All",
        "Food",
        "Uncategorized",
        "Clothes",
        "Household",
        "Personal Use"
    ]
    
    private func filterRow(barHeight: CGFloat, dropdownRowHeight: CGFloat) -> some View {
        Button {
            isItemTypeDropdownOpen = false
            isSortDropdownOpen.toggle()
        } label: {
            HStack {
                Text("View")
                    .foregroundStyle(.black)
                    .font(.system(size: 13.5))

                Spacer()

                Text(LocalizedStringKey(selectedFilterType))
                    .font(.system(size: 12))
                    .foregroundStyle(.black.opacity(0.7))

                Image(systemName: isSortDropdownOpen ? "chevron.up" : "chevron.down")
                    .foregroundStyle(.black)
            }
            .padding(.horizontal, 15)
            .frame(height: barHeight)
            .background(Color.white.opacity(0.85))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .top) {
            if isSortDropdownOpen {
                VStack(spacing: 0) {
                    ForEach(filterOptions, id: \.self) { option in
                        Button {
                            selectedFilterType = option
                            isSortDropdownOpen = false
                        } label: {
                            HStack {
                                Text(LocalizedStringKey(option))
                                    .foregroundStyle(.black)
                                    .font(.system(size: 12))

                                Spacer()

                                if selectedFilterType == option {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.black)
                                }
                            }
                            .padding(.horizontal, 12)
                            .frame(height: dropdownRowHeight)
                            .background(
                                option == "All"
                                ? Color.white.opacity(0.95)
                                : typeBackgroundColor(option).opacity(0.95)
                            )
                        }
                        .buttonStyle(.plain)

                        if option != filterOptions.last {
                            Divider()
                        }
                    }
                }
                .background(Color.white.opacity(0.95))
                .cornerRadius(8)
                .padding(.top, barHeight + 4)
            }
        }
    }
    
    enum ActiveAlert: Identifiable {
        case message(String)
        case deleteItem(UUID, Int)
        case clearAll
        case selectAll(Bool)
        case saveWithoutTotal
        case confirmSave
        case replaceExisting

        var id: String {
            switch self {
            case .message(let text):
                return "message-\(text)"
            case .deleteItem(let itemId, _):
                return "delete-\(itemId)"
            case .clearAll:
                return "clearAll"
            case .selectAll(let allSelected):
                return "selectAll-\(allSelected)"
            case .saveWithoutTotal:
                return "saveWithoutTotal"
            case .confirmSave:
                return "confirmSave"
            case .replaceExisting:
                return "replaceExisting"
            }
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let screenHeight = geometry.size.height
            let bottomHeight = min(max(screenHeight * 0.12, 105), 120)
            let topBackButtonHeight = min(max(screenHeight * 0.075, 56), 72)

            ZStack {
                Color("MainColor")
                    .ignoresSafeArea()
                    .dismissKeyboardOnTap()

                VStack(spacing: 0) {
                    topBackButton
                        .frame(height: topBackButtonHeight)

                    topControlRow
                        .padding(.bottom, screenHeight * 0.015)
                        .zIndex(10)

                    inputRow

                    shoppingListArea
                }
                .dismissKeyboardOnTap()
            }
            .safeAreaInset(edge: .bottom) {
                bottomInputArea
                    .frame(height: bottomHeight)
                    .background(Color("MainColor"))
            }
            .ignoresSafeArea(.keyboard)
            .toolbar {
                KeyboardTotalCostToolbar(
                    text: activeMoneyTextBinding,
                    isVisible: focusedMoneyField != nil,
                    onOK: {
                        if focusedMoneyField == .totalCost {
                            validateTotalBillAfterEditing()
                        }
                    }
                )
            }
            .navigationBarBackButtonHidden(true)
            .task {
                loadDraft()
            }
            .onDisappear {
                saveDraft()
            }
            .alert(item: $activeAlert) { alert in
                makeAlert(alert)
            }
            
            .onChange(of: focusedMoneyField) { oldValue, newValue in
                if oldValue == .totalCost && newValue != .totalCost {
                    validateTotalBillAfterEditing()
                }
            }
        }
    }
    
    private var topControlRow: some View {
        HStack(spacing: 16) {
            filterRow(barHeight: 22, dropdownRowHeight: 30)
                .frame(width: 140)

            itemTypeRow(barHeight: 22, dropdownRowHeight: 30)
                .frame(width: 170)
                .font(.system(size: 13.5))
        }
        .padding(.horizontal, 16)
    }

    private var topBackButton: some View {
        HStack {
            Button {
                saveDraft()
                dismiss()
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(mainTextColor)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 64)
    }
    
    private var bottomInputArea: some View {
        GeometryReader { geometry in
            let rowWidth = geometry.size.width

            let billRowSlotHeight: CGFloat = 34
            let billRowXOffset: CGFloat = 0
            let billRowYOffset: CGFloat = 48

            let buttonRowHeight: CGFloat = 29
            let buttonRowXOffset: CGFloat = 0
            let buttonRowYOffset: CGFloat = 48

            let gapBetweenRows: CGFloat = 6

            VStack(spacing: gapBetweenRows) {
                billInputRow(rowWidth: rowWidth)
                    .frame(height: billRowSlotHeight)
                    .offset(x: billRowXOffset, y: billRowYOffset)

                bottomButtonRow(
                    rowWidth: rowWidth,
                    rowHeight: buttonRowHeight
                )
                .offset(x: buttonRowXOffset, y: buttonRowYOffset)
            }
            .frame(width: rowWidth, alignment: .top)
        }
    }
    // inputrow size control
    private let inputHeight: CGFloat = 22

    private var inputRow: some View {

        HStack(spacing: 8) {
            TextField("Item", text: $itemText)
                .font(.system(size: 14))
                .tint(mainTextColor)
                .padding(.horizontal, 8)
                .frame(height: inputHeight)
                .background(Color.white)
                .cornerRadius(6)
                .onChange(of: itemText) { _, newValue in
                    if newValue.count > 65 {
                        itemText = String(newValue.prefix(65))
                    }
                }

            TextField("Qty", text: $qtyText)
                .font(.system(size: 14))
                .tint(mainTextColor)
                .keyboardType(.numberPad)
                .padding(.horizontal, 8)
                .frame(width: 55, height: inputHeight)
                .background(Color.white)
                .cornerRadius(6)
                .onChange(of: qtyText) { _, newValue in
                    let filtered = newValue.filter { $0.isNumber }
                    qtyText = String(filtered.prefix(3))
                }

            Button {
                addItem()
            } label: {
                Text("Add")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(width: 48, height: inputHeight)
                    .background(Color.green)
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private var shoppingListArea: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(displayedItems.enumerated()), id: \.element.id) { index, item in
                    ShoppingItemRowView(
                        number: index + 1,
                        item: item,
                        priceText: priceBinding(for: item.id),
                        focusedMoneyField: $focusedMoneyField,
                        onToggle: { isDone in
                            if let itemIndex = items.firstIndex(where: { $0.id == item.id }) {
                                items[itemIndex].isDone = isDone
                                saveDraft()
                            }
                        },
                        onDelete: {
                            activeAlert = .deleteItem(item.id, index + 1)
                        }
                    )

                    Divider()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func billInputRow(rowWidth: CGFloat) -> some View {
        let currencyWidth = rowWidth * 0.35
        let totalCostWidth = rowWidth * 0.30
        let currencyHeight: CGFloat = 27
        let totalCostHeight: CGFloat = 27
        let rowSpacing = rowWidth * 0.07
        let currencyOffsetY: CGFloat = -20
        let totalCostOffsetY: CGFloat = -20

        HStack(spacing: rowSpacing) {
            Menu {
                ForEach(currencies, id: \.self) { currency in
                    Button(currency) {
                        selectedCurrencyDisplay = currency
                        saveDraft()
                    }
                }
            } label: {
                HStack {
                    Text(selectedCurrencyDisplay)
                        .font(.system(size: 13))
                        .foregroundStyle(.black)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 11))
                        .foregroundStyle(.black)
                }
                .padding(.horizontal, 10)
                .frame(width: currencyWidth, height: currencyHeight)
                .background(Color.white.opacity(0.78))
                .cornerRadius(8)
            }
            .offset(y: currencyOffsetY)

            TextField("Total Cost", text: totalBillBinding)
                .font(.system(size: 13))
                .tint(mainTextColor)
                .keyboardType(.decimalPad)
                .padding(.horizontal, 8)
                .frame(width: totalCostWidth, height: totalCostHeight)
                .background(Color.white)
                .cornerRadius(6)
                .focused($focusedMoneyField, equals: .totalCost)
                .offset(y: totalCostOffsetY)
                
        }
    
    }

    private func bottomButtonRow(rowWidth: CGFloat, rowHeight: CGFloat) -> some View {
        HStack(spacing: rowWidth * 0.05) {
            Button {
                startSaveFlow()
            } label: {
                Text("Save")
                    .font(.system(size: rowWidth * 0.045, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(
                        width: rowWidth * 0.20,
                        height: rowHeight * 1.2
                    )
                    .background(Color.green)
                    .cornerRadius(rowHeight * 0.20)
            }

            Button {
                handleSelectAllButton()
            } label: {
                Text(LocalizedStringKey(areAllItemsSelected ? "Deselect All" : "Select All"))
                    .font(.system(size: rowWidth * 0.045, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(
                        width: rowWidth * 0.31,
                        height: rowHeight * 1.2
                    )
                    .background(Color.green)
                    .cornerRadius(rowHeight * 0.20)
            }

            Button {
                handleClearAllButton()
            } label: {
                Text("Clear All")
                    .font(.system(size: rowWidth * 0.045, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(
                        width: rowWidth * 0.25,
                        height: rowHeight * 1.2
                    )
                    .background(Color.green)
                    .cornerRadius(rowHeight * 0.20)
            }
        }
        .frame(width: rowWidth, height: rowHeight)
    }

    private var areAllItemsSelected: Bool {
        !items.isEmpty && items.allSatisfy { $0.isDone }
    }
    
    private func applyCurrentSort() {
        items.sort {
            let leftTypeRank = typeSortRank($0.type)
            let rightTypeRank = typeSortRank($1.type)

            if leftTypeRank == rightTypeRank {
                return $0.order < $1.order
            } else {
                return leftTypeRank < rightTypeRank
            }
        }
    }
    
    private var displayedItems: [ShoppingItemInput] {
        let sortedItems = items.sorted {
            let leftTypeRank = typeSortRank($0.type)
            let rightTypeRank = typeSortRank($1.type)

            if leftTypeRank == rightTypeRank {
                return $0.order < $1.order
            } else {
                return leftTypeRank < rightTypeRank
            }
        }

        if selectedFilterType == "All" {
            return sortedItems
        } else {
            return sortedItems.filter { $0.type == selectedFilterType }
        }
    }
    
    private func nextItemOrder() -> Int {
        let maxOrder = items.map { $0.order }.max() ?? 0
        return maxOrder + 1
    }

    private func typeSortRank(_ type: String) -> Int {
        switch type {
        case "Food":
            return 0
        case "Clothes":
            return 1
        case "Household":
            return 2
        case "Personal Use":
            return 3
        case "Uncategorized":
            return 4
        default:
            return 99
        }
    }

    private func addItem() {
        let name = itemText.trimmingCharacters(in: .whitespacesAndNewlines)
        let qtyString = qtyText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !name.isEmpty else {
            activeAlert = .message("Enter an item.")
            return
        }

        let quantity: Int?

        if qtyString.isEmpty {
            quantity = nil
        } else if let parsedQuantity = Int(qtyString) {
            quantity = parsedQuantity
        } else {
            activeAlert = .message("Enter a valid quantity.")
            return
        }

        items.append(
            ShoppingItemInput(
                name: name,
                quantity: quantity,
                type: selectedItemType,
                order: nextItemOrder(),
                isDone: false
            )
        )
        
        applyCurrentSort()

        itemText = ""
        qtyText = ""

        saveDraft()
    }

    private func handleSelectAllButton() {
        guard !items.isEmpty else {
            activeAlert = .message("There are no items to select.")
            return
        }

        activeAlert = .selectAll(areAllItemsSelected)
    }

    private func handleClearAllButton() {
        guard !items.isEmpty else {
            activeAlert = .message("There are no items to clear.")
            return
        }

        activeAlert = .clearAll
    }

    private func startSaveFlow() {
        guard !items.isEmpty else {
            activeAlert = .message("Add at least one item.")
            return
        }

        guard areAllItemsSelected else {
            activeAlert = .message("Select all items before saving.")
            return
        }

        let cleanTotal = totalBillText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: "")

        let currentItemTotal = itemPriceTotal

        if cleanTotal.isEmpty {
            if currentItemTotal > 0 {
                totalBillText = formattedMoneyText(currentItemTotal)
                pendingUncategorizedCost = 0
                isTotalBillManuallyEdited = false

                activeAlert = .message(
                    "Total cost must be at least the entered prices."
                )

                saveDraft()
                return
            }

            pendingTotalBill = 0.0
            pendingHasTotalBill = false
            activeAlert = .saveWithoutTotal
            return
        }

        guard let parsedTotal = Double(cleanTotal) else {
            activeAlert = .message("Enter a valid total cost.")
            return
        }

        guard parsedTotal >= currentItemTotal else {
            totalBillText = formattedMoneyText(currentItemTotal)
            pendingUncategorizedCost = 0
            isTotalBillManuallyEdited = false

            activeAlert = .message(
                "Total cost must be at least the entered prices."
            )

            saveDraft()
            return
        }
        

        guard parsedTotal >= currentItemTotal else {
            activeAlert = .message("Total cost must be at least the entered prices.")
            return
        }

        pendingTotalBill = parsedTotal
        pendingHasTotalBill = true
        pendingUncategorizedCost = parsedTotal - currentItemTotal

        checkExistingSessionBeforeSaving()
    }

    private func checkExistingSessionBeforeSaving() {
        let today = todayDateString()

        do {
            let descriptor = FetchDescriptor<ShoppingSession>(
                predicate: #Predicate { session in
                    session.savedDate == today
                }
            )

            let existingSessions = try modelContext.fetch(descriptor)

            if existingSessions.isEmpty {
                activeAlert = .confirmSave
            } else {
                activeAlert = .replaceExisting
            }
        } catch {
            activeAlert = .message("Failed to check saved data.")
        }
    }

    private func saveToCalendar(replaceExisting: Bool) {
        let today = todayDateString()
        let nowTime = currentTimeString()
        let currencyCode = currencyCode(from: selectedCurrencyDisplay)

        do {
            if replaceExisting {
                let descriptor = FetchDescriptor<ShoppingSession>(
                    predicate: #Predicate { session in
                        session.savedDate == today
                    }
                )

                let existingSessions = try modelContext.fetch(descriptor)

                for session in existingSessions {
                    modelContext.delete(session)
                }
            }

            let session = ShoppingSession(
                savedDate: today,
                savedTime: nowTime,
                currency: currencyCode,
                totalBill: pendingTotalBill,
                hasTotalBill: pendingHasTotalBill
            )

            session.items = items.map { item in
                ShoppingSessionItem(
                    name: item.name,
                    quantity: item.quantity,
                    type: item.type,
                    order: item.order,
                    isDone: item.isDone,
                    priceText: item.priceText
                )
            }
            
            modelContext.insert(session)

            clearDraft()

            try modelContext.save()

            items.removeAll()
            itemText = ""
            qtyText = ""
            totalBillText = ""
            selectedCurrencyDisplay = "🇺🇸 US $"

            activeAlert = .message("Saved to the calendar.")
        } catch {
            activeAlert = .message("Failed to save the list.")
        }
    }

    private func saveDraft() {
        do {
            let descriptor = FetchDescriptor<ShoppingDraft>()
            let drafts = try modelContext.fetch(descriptor)

            let draft: ShoppingDraft

            if let existingDraft = drafts.first {
                draft = existingDraft
            } else {
                draft = ShoppingDraft(
                    currency: selectedCurrencyDisplay,
                    totalBillText: totalBillText
                )
                modelContext.insert(draft)
            }

            draft.currency = selectedCurrencyDisplay
            draft.totalBillText = totalBillText

            draft.items.removeAll()

            draft.items = items.map { item in
                ShoppingDraftItem(
                    name: item.name,
                    quantity: item.quantity,
                    type: item.type,
                    order: item.order,
                    isDone: item.isDone,
                    priceText: item.priceText
                )
            }

            try modelContext.save()
        } catch {
            print("Failed to save draft: \(error)")
        }
    }

    private func loadDraft() {
        do {
            let descriptor = FetchDescriptor<ShoppingDraft>()
            let drafts = try modelContext.fetch(descriptor)

            guard let draft = drafts.first else {
                return
            }

            selectedCurrencyDisplay = draft.currency.isEmpty ? "🇺🇸 US $" : draft.currency
            totalBillText = draft.totalBillText

            let sortedDraftItems = draft.items.sorted {
                let leftOrder = $0.order == 0 ? Int.max : $0.order
                let rightOrder = $1.order == 0 ? Int.max : $1.order

                if leftOrder == rightOrder {
                    return $0.name < $1.name
                } else {
                    return leftOrder < rightOrder
                }
            }

            items = sortedDraftItems.enumerated().map { index, draftItem in
                ShoppingItemInput(
                    name: draftItem.name,
                    quantity: draftItem.quantity,
                    type: draftItem.type,
                    order: draftItem.order == 0 ? index + 1 : draftItem.order,
                    isDone: draftItem.isDone,
                    priceText: draftItem.priceText
                )
            }

            applyCurrentSort()

        } catch {
            print("Failed to load draft: \(error)")
        }
    }

    private func clearDraft() {
        do {
            try clearDraftWithoutSavingContext()
            try modelContext.save()
        } catch {
            print("Failed to clear draft: \(error)")
        }
    }

    private func clearDraftWithoutSavingContext() throws {
        let draftDescriptor = FetchDescriptor<ShoppingDraft>()
        let drafts = try modelContext.fetch(draftDescriptor)

        for draft in drafts {
            modelContext.delete(draft)
        }
    }

    private func makeAlert(_ alert: ActiveAlert) -> Alert {
        switch alert {
        case .message(let message):
            return Alert(
                title: Text(message),
                dismissButton: .default(Text("OK"))
            )

        case .deleteItem(let itemId, let number):
            return Alert(
                title: Text("Delete this item?"),
                message: Text("Delete item \(number)?"),
                primaryButton: .destructive(Text("Yes")) {
                    items.removeAll { $0.id == itemId }
                    saveDraft()
                },
                secondaryButton: .cancel(Text("No"))
            )

        case .clearAll:
            return Alert(
                title: Text("Clear all items?"),
                primaryButton: .destructive(Text("Yes")) {
                    items.removeAll()
                    totalBillText = ""
                    selectedCurrencyDisplay = "🇺🇸 US $"
                    clearDraft()
                },
                secondaryButton: .cancel(Text("No"))
            )

        case .selectAll(let allSelected):
            return Alert(
                title: Text(allSelected ? "Deselect all?" : "Select all?"),
                primaryButton: .default(Text("Yes")) {
                    for index in items.indices {
                        items[index].isDone = !allSelected
                    }
                    saveDraft()
                },
                secondaryButton: .cancel(Text("No"))
            )

        case .saveWithoutTotal:
            return Alert(
                title: Text("You didn’t enter the total cost."),
                message: Text("You can edit it later in the calendar. Save anyway?"),
                primaryButton: .default(Text("Yes")) {
                    checkExistingSessionBeforeSaving()
                },
                secondaryButton: .cancel(Text("No"))
            )

        case .confirmSave:
            return Alert(
                title: Text("Save this list?"),
                primaryButton: .default(Text("Yes")) {
                    saveToCalendar(replaceExisting: false)
                },
                secondaryButton: .cancel(Text("No"))
            )

        case .replaceExisting:
            return Alert(
                title: Text("Saved list already exists"),
                message: Text("A saved list already exists for today. Replace it?"),
                primaryButton: .destructive(Text("Yes")) {
                    saveToCalendar(replaceExisting: true)
                },
                secondaryButton: .cancel(Text("No"))
            )
        }
    }

    private func formatMoneyInput(_ input: String, previousValue: String) -> String {
        let allowedCharacters = input.filter { character in
            character.isNumber || character == "." || character == ","
        }

        let cleanText = allowedCharacters.replacingOccurrences(of: ",", with: "")

        if cleanText.isEmpty {
            return ""
        }

        if cleanText == "." {
            return "."
        }

        let parts = cleanText.split(separator: ".", omittingEmptySubsequences: false)

        if parts.count > 2 {
            return previousValue
        }

        let integerPart = String(parts[0])
        let decimalPart = parts.count == 2 ? String(parts[1]) : nil

        let formattedInteger: String

        if integerPart.isEmpty {
            formattedInteger = ""
        } else if let number = Int(integerPart) {
            formattedInteger = NumberFormatter.localizedString(
                from: NSNumber(value: number),
                number: .decimal
            )
        } else {
            return previousValue
        }

        if cleanText.hasSuffix(".") {
            return "\(formattedInteger)."
        } else if let decimalPart {
            return "\(formattedInteger).\(decimalPart)"
        } else {
            return formattedInteger
        }
    }
    
    private var activeMoneyTextBinding: Binding<String> {
        Binding(
            get: {
                switch focusedMoneyField {
                case .totalCost:
                    return totalBillText
                case .itemPrice(let id):
                    return items.first(where: { $0.id == id })?.priceText ?? ""
                case nil:
                    return ""
                }
            },
            set: { newValue in
                switch focusedMoneyField {
                case .totalCost:
                    totalBillText = formatMoneyInput(newValue, previousValue: totalBillText)
                    isTotalBillManuallyEdited = !totalBillText.isEmpty
                    saveDraft()

                case .itemPrice(let id):
                    updateItemPrice(id, text: newValue)

                case nil:
                    break
                }
            }
        )
    }
    
    private var itemPriceTotal: Double {
        items.reduce(0) { total, item in
            total + moneyValue(from: item.priceText)
        }
    }

    private var totalBillBinding: Binding<String> {
        Binding(
            get: { totalBillText },
            set: { newValue in
                totalBillText = formatMoneyInput(newValue, previousValue: totalBillText)
                isTotalBillManuallyEdited = !totalBillText.isEmpty
                saveDraft()
            }
        )
    }
    
    private func priceBinding(for itemID: UUID) -> Binding<String> {
        Binding(
            get: {
                items.first(where: { $0.id == itemID })?.priceText ?? ""
            },
            set: { newValue in
                updateItemPrice(itemID, text: newValue)
            }
        )
    }

    private func updateItemPrice(_ itemID: UUID, text: String) {
        guard let index = items.firstIndex(where: { $0.id == itemID }) else {
            return
        }

        let previousValue = items[index].priceText
        items[index].priceText = formatMoneyInput(text, previousValue: previousValue)

        if !isTotalBillManuallyEdited {
            totalBillText = formattedMoneyText(itemPriceTotal)
        }

        saveDraft()
    }

    private func moneyValue(from text: String) -> Double {
        let cleanText = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: "")

        return Double(cleanText) ?? 0
    }
    
    private func validateTotalBillAfterEditing() {
        let itemTotal = itemPriceTotal

        // If there are no item prices, empty total cost is allowed.
        guard itemTotal > 0 else {
            isTotalBillManuallyEdited = !totalBillText.isEmpty
            saveDraft()
            return
        }

        let cleanTotalText = totalBillText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: "")

        let enteredTotal = Double(cleanTotalText)

        guard let enteredTotal, enteredTotal >= itemTotal else {
            totalBillText = formattedMoneyText(itemTotal)
            isTotalBillManuallyEdited = false
            pendingUncategorizedCost = 0

            activeAlert = .message(
                "Total cost must be at least the entered prices."
            )

            saveDraft()
            return
        }

        pendingUncategorizedCost = enteredTotal - itemTotal
        isTotalBillManuallyEdited = true
        saveDraft()
    }
    

    private func formattedMoneyText(_ value: Double) -> String {
        if value == 0 {
            return ""
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = value.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2

        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private func todayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func currentTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }

    private func currencyCode(from display: String) -> String {
        switch display {
        case "🇺🇸 US $":
            return "USD"
        case "🇯🇵 Japanese ¥":
            return "JPY"
        case "🇬🇧 British £":
            return "GBP"
        case "🇰🇷 Korean ₩":
            return "KRW"
        default:
            return display
        }
    }
    
}


//Shopping item row view
struct ShoppingItemRowView: View {
    let number: Int
    let item: ShoppingItemInput
    @Binding var priceText: String
    var focusedMoneyField: FocusState<InputListPageView.MoneyField?>.Binding
    let onToggle: (Bool) -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text("\(number).")
                        .font(.system(size: 17))
                        .strikethrough(item.isDone)

                    if item.type != "Uncategorized" {
                        Text(LocalizedStringKey(item.type))
                            .font(.system(size: 12))
                            .foregroundStyle(.black)
                            .strikethrough(item.isDone)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(typeBackgroundColor(item.type))
                            .cornerRadius(5)
                    }
                }

                Text(item.name)
                    .font(.system(size: 13))
                    .strikethrough(item.isDone)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    Text("Price:")
                        .font(.system(size: 10))
                        .foregroundStyle(.black.opacity(0.75))
                        .strikethrough(item.isDone)

                    TextField("0.00", text: $priceText)
                        .font(.system(size: 12))
                        .keyboardType(.decimalPad)
                        .padding(.horizontal, 6)
                        .focused(focusedMoneyField, equals: .itemPrice(item.id))
                        .frame(width: 70, height: 15)
                        .background(Color.white)
                        .cornerRadius(5)
                        .disabled(item.isDone)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)

            if let quantity = item.quantity {
                Text("Qty: \(quantity)")
                    .font(.system(size: 12))
                    .strikethrough(item.isDone)
                    .frame(width: 58, alignment: .leading)
            } else {
                Spacer()
                    .frame(width: 58)
            }

            Button {
                onToggle(!item.isDone)
            } label: {
                Image(systemName: item.isDone ? "checkmark.square.fill" : "square")
                    .font(.system(size: 18))
                    .foregroundStyle(.black)
            }
            .buttonStyle(.plain)

            Spacer()
                .frame(width: 12)

            Button {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 15))
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 10)
    }
}
#Preview {
    NavigationStack {
        InputListPageView()
    }
    .modelContainer(for: [
        ShoppingSession.self,
        ShoppingSessionItem.self,
        ShoppingDraft.self,
        ShoppingDraftItem.self
    ], inMemory: true)
}
