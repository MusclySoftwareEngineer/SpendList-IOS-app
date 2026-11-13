//
//  SavedItemsView.swift
//  SpendList
//
//  Created by hunter on 13/05/2026.
//

import SwiftUI
import SwiftData

struct EditableSavedShoppingItem: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var quantityText: String
    var type: String
    var order: Int
    var priceText: String
}

struct SavedItemsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.locale) private var locale

    let selectedDate: String

    @State private var savedSession: ShoppingSession?
    @State private var savedItems: [ShoppingSessionItem] = []
    
    @State private var showDeleteSessionAlert = false
    @State private var showSaveChangesAlert = false
    @State private var originalEditableItems: [EditableSavedShoppingItem] = []
    @State private var originalEditableTotalBillText = ""
    @State private var originalEditableCurrencyDisplay = ""
    
    @State private var itemToDeleteIndex: Int?
    @State private var showDeleteItemAlert = false
    
    @State private var stableScreenWidth: CGFloat = 0
    @State private var stableScreenHeight: CGFloat = 0

    
    
    enum MoneyField: Hashable {
        case totalCost
        case itemPrice(UUID)
    }

    @FocusState private var focusedMoneyField: MoneyField?

    @State private var isEditableTotalBillManuallyEdited = false


    @State private var isEditMode = false
    @State private var editableItems: [EditableSavedShoppingItem] = []
    @State private var editableTotalBillText = ""
    @State private var editableCurrencyDisplay = "🇺🇸 US $"

    @State private var activeAlertMessage: String?
//currencies
    private let itemTypes = [
        "Uncategorized",
        "Food",
        "Clothes",
        "Household",
        "Personal Use"
    ]

    private let currencies = [
        "🇰🇷 Korean ₩",
        "🇬🇧 British £",
        "🇺🇸 US $",
        "🇯🇵 Japanese ¥"
    ]
    
    private func currencySymbolOnly(from currencyCode: String) -> String {
        switch currencyCode {
        case "USD":
            return "$"
        case "JPY":
            return "¥"
        case "GBP":
            return "£"
        case "KRW":
            return "₩"
        default:
            return currencyCode
        }
    }

    private var mainTextColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    // MARK: - Text Size Controls

    private let savedTitleTextSizeRatio: CGFloat = 0.050
    private let savedDateTextSizeRatio: CGFloat = 0.035

    private let savedItemNumberTextSizeRatio: CGFloat = 0.035
    private let savedItemNameTextSizeRatio: CGFloat = 0.035
    private let savedItemTypeTextSizeRatio: CGFloat = 0.025
    private let savedItemPriceTextSizeRatio: CGFloat = 0.035
    private let savedItemQtyTextSizeRatio: CGFloat = 0.033

    private let editItemNumberTextSizeRatio: CGFloat = 0.040
    private let editTypeTextSizeRatio: CGFloat = 0.035
    private let addItemButtonTextSizeRatio: CGFloat = 0.045

    private let deleteButtonTextSizeRatio: CGFloat = 0.035
    private let editSaveButtonTextSizeRatio: CGFloat = 0.035
    private let totalCostTextSizeRatio: CGFloat = 0.045

    // MARK: - Icon Size Controls

    private let backIconSizeRatio: CGFloat = 0.070
    private let editTrashIconSizeRatio: CGFloat = 0.045
    
    // MARK: - Edit Mode Input Bar Controls

    private let editInputTextSizeRatio: CGFloat = 0.030

    private let editTypeBarWidthRatio: CGFloat = 0.34
    private let editTypeBarHeightRatio: CGFloat = 0.035

    private let editQtyBarWidthRatio: CGFloat = 0.15
    private let editQtyBarHeightRatio: CGFloat = 0.035

    private let editItemBarHeightRatio: CGFloat = 0.035

    private let editPriceLabelTextSizeRatio: CGFloat = 0.030
    private let editPriceBarWidthRatio: CGFloat = 0.24
    private let editPriceBarHeightRatio: CGFloat = 0.032

    private let editCurrencyBarWidthRatio: CGFloat = 0.34
    private let editCurrencyBarHeightRatio: CGFloat = 0.040

    private let editTotalCostBarWidthRatio: CGFloat = 0.46
    private let editTotalCostBarHeightRatio: CGFloat = 0.040

    var body: some View {
        GeometryReader { geometry in
            let screenWidth = stableScreenWidth == 0 ? geometry.size.width : stableScreenWidth
            let screenHeight = stableScreenHeight == 0 ? geometry.size.height : stableScreenHeight
            
            ZStack {
                Color("MainColor")
                    .ignoresSafeArea()
                    .dismissKeyboardOnTap()

                VStack(spacing: 0) {
                    topRow(screenWidth: screenWidth, screenHeight: screenHeight)

                    dateTitleRow(screenWidth: screenWidth, screenHeight: screenHeight)

                    if isEditMode {
                        editItemsArea(screenWidth: screenWidth, screenHeight: screenHeight)
                    } else {
                        savedItemsArea(screenWidth: screenWidth, screenHeight: screenHeight)
                    }

                    if isEditMode {
                        editTotalCostRow(screenWidth: screenWidth, screenHeight: screenHeight)
                    } else {
                        totalCostRow(screenWidth: screenWidth, screenHeight: screenHeight)
                    }
                }
                
            }
            .ignoresSafeArea(.keyboard)
                       .dismissKeyboardOnTap()
                       .toolbar {
                           KeyboardTotalCostToolbar(
                               text: activeEditableMoneyTextBinding,
                               isVisible: focusedMoneyField != nil,
                               onOK: {
                                   switch focusedMoneyField {
                                   case .totalCost:
                                       validateEditableTotalBillAfterEditing()

                                   case .itemPrice:
                                       updateEditableTotalFromItemPricesIfNeeded()

                                   case nil:
                                       break
                                   }
                               }
                           )
                       }
                       .navigationBarBackButtonHidden(true)
                       .task {
                           loadSavedData()
            }
            
                       .onChange(of: focusedMoneyField) { oldValue, newValue in
                           if oldValue == .totalCost && newValue != .totalCost {
                               validateEditableTotalBillAfterEditing()
                           }
                       }
            
            .onAppear {
                if stableScreenWidth == 0 {
                    stableScreenWidth = geometry.size.width
                }

                if stableScreenHeight == 0 {
                    stableScreenHeight = geometry.size.height
                }
            }
            
            .alert(
                "Message",
                isPresented: Binding(
                    get: { activeAlertMessage != nil },
                    set: { newValue in
                        if !newValue {
                            activeAlertMessage = nil
                        }
                    }
                )
            )
            {
                Button("OK") {
                    activeAlertMessage = nil
                }
            } message: {
                Text(activeAlertMessage ?? "")
            }
            .alert("Delete this item?", isPresented: $showDeleteItemAlert) {
                Button("No", role: .cancel) {
                    itemToDeleteIndex = nil
                }

                Button("Yes", role: .destructive) {
                    deleteEditableItem()
                }
            } message: {
                if let itemToDeleteIndex {
                    Text("Delete item \(itemToDeleteIndex + 1)?")
                } else {
                    Text("Delete this item?")
                }
            }
            
            .alert("Delete this saved list?", isPresented: $showDeleteSessionAlert) {
                Button("No", role: .cancel) { }

                Button("Yes", role: .destructive) {
                    deleteSelectedDateSession()
                }
            } message: {
                Text("This will delete the saved list for \(formatDateForDisplay(selectedDate)).")
            }
            
            .alert("Save changes?", isPresented: $showSaveChangesAlert) {
                Button("No", role: .cancel) { }

                Button("Yes") {
                    saveEditedData()
                }
            } message: {
                Text("Do you want to save your changes?")
            }
        }
    }

    private func topRow(screenWidth: CGFloat, screenHeight: CGFloat) -> some View {
        ZStack {
            Button {
                if isEditMode {
                    if hasEmptyItemWithQtyOrPrice() {
                        showEmptyItemMessage()
                        return
                    }

                    isEditMode = false
                    loadSavedData()
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: screenWidth * backIconSizeRatio, weight: .bold))
                    .foregroundStyle(mainTextColor)
            }
            .position(
                x: screenWidth * 0.10,
                y: screenHeight * 0.04
            )
            
            if !isEditMode {
                Button {
                    if savedSession == nil {
                        activeAlertMessage = "There is no saved list to delete."
                    } else {
                        showDeleteSessionAlert = true
                    }
                } label: {
                    Text("Delete")
                        .font(.system(size: screenWidth * deleteButtonTextSizeRatio, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(
                            width: screenWidth * 0.22,
                            height: screenHeight * 0.040
                        )
                        .background(Color.red.opacity(0.85))
                        .cornerRadius(10)
                }
                .position(
                    x: screenWidth * 0.62,
                    y: screenHeight * 0.04
                )
            }

            Button {
                if isEditMode {
                    if hasEmptyItemWithQtyOrPrice() {
                        showEmptyItemMessage()
                        return
                    }

                    validateEditableTotalBillAfterEditing()

                    let itemTotal = editableItemPriceTotal
                    let cleanEditableTotal = editableTotalBillText
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: ",", with: "")

                    if itemTotal > 0 {
                        guard let enteredTotal = Double(cleanEditableTotal), enteredTotal >= itemTotal else {
                            editableTotalBillText = formattedMoneyText(itemTotal)
                            isEditableTotalBillManuallyEdited = false
                            activeAlertMessage = "Total cost must be at least the entered prices."
                            return
                        }
                    }

                    if hasUnsavedEditChanges {
                        showSaveChangesAlert = true
                    } else {
                        isEditMode = false
                        loadSavedData()
                    }
                } else {
                    enterEditMode()
                }
            } label: {
                Text(isEditMode ? "Save" : "Edit")
                    .font(.system(size: screenWidth * editSaveButtonTextSizeRatio, weight: .bold))
                    .foregroundStyle(.black)
                //edit button size
                    .frame(
                        width: screenWidth * 0.18,
                        height: screenHeight * 0.040
                    )
                    .background(Color.green)
                    .cornerRadius(10)
            }
            .position(
                x: screenWidth * 0.84,
                y: screenHeight * 0.04
            )
        }
        .frame(height: screenHeight * 0.10)
    }

    private func dateTitleRow(screenWidth: CGFloat, screenHeight: CGFloat) -> some View {
        ZStack {
            
            //saved items
            Text("Saved Items")
                .font(.system(size: screenWidth * savedTitleTextSizeRatio, weight: .bold))
                .foregroundStyle(mainTextColor)
                .position(
                    x: screenWidth * 0.50,
                    y: screenHeight * -0.015
                )

            Text(formatDateForDisplay(selectedDate))
                .font(.system(size: screenWidth * savedDateTextSizeRatio, weight: .semibold))
                .foregroundStyle(mainTextColor.opacity(0.85))
                .position(
                    x: screenWidth * 0.50,
                    y: screenHeight * 0.02
                )
        }
        .frame(maxWidth: .infinity)
        .frame(height: screenHeight * 0.045)
    }

    private func savedItemsArea(screenWidth: CGFloat, screenHeight: CGFloat) -> some View {
        Group {
            if savedItems.isEmpty {
                VStack {
                    Spacer()

                    Text("Empty")
                        .font(.system(size: screenWidth * 0.065, weight: .bold))
                        .foregroundStyle(mainTextColor)

                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(savedItems.enumerated()), id: \.element.id) { index, item in
                            savedItemRow(
                                number: index + 1,
                                item: item,
                                screenWidth: screenWidth
                            )

                            Divider()
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, screenWidth * 0.05)
    }

    private func savedItemRow(
        number: Int,
        item: ShoppingSessionItem,
        screenWidth: CGFloat
    ) -> some View {
        HStack(spacing: screenWidth * 0.02) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text("\(number).")
                        .font(.system(size: screenWidth * savedItemNumberTextSizeRatio))
                        .foregroundStyle(mainTextColor)

                    if item.type != "Uncategorized" {
                        Text(LocalizedStringKey(item.type))
                            .font(.system(size: screenWidth * savedItemTypeTextSizeRatio))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(typeBackgroundColor(item.type))
                            .cornerRadius(5)
                    }
                }

                Text(item.name)
                    .font(.system(size: screenWidth * savedItemNameTextSizeRatio))
                    .foregroundStyle(mainTextColor)
                    .fixedSize(horizontal: false, vertical: true)
                
                if !item.priceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    HStack(spacing: 4) {
                        Text(LocalizedStringKey("Price:"))

                        Text(item.priceText)
                    }
                    .font(.system(size: screenWidth * savedItemPriceTextSizeRatio))
                    .foregroundStyle(mainTextColor.opacity(0.75))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)

            if let quantity = item.quantity {
                Text("Qty: \(quantity)")
                    .font(.system(size: screenWidth * savedItemQtyTextSizeRatio))
                    .foregroundStyle(mainTextColor)
                    .frame(width: screenWidth * 0.20, alignment: .leading)
            }
        }
        .padding(.vertical, 10)
    }

    private func editItemsArea(screenWidth: CGFloat, screenHeight: CGFloat) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: screenHeight * 0.012) {
                    ForEach(Array(editableItems.enumerated()), id: \.element.id) { index, item in
                        editItemRow(
                            index: index,
                            item: item,
                            screenWidth: screenWidth,
                            screenHeight: screenHeight
                        )
                    }

                    Button {
                        addEditableItem()
                    } label: {
                        Text("+ Add Item")
                            .font(.system(size: screenWidth * addItemButtonTextSizeRatio, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(
                                width: screenWidth * 0.45,
                                height: screenHeight * 0.055
                            )
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                    .padding(.top, screenHeight * 0.015)
                }
                .padding(.horizontal, screenWidth * 0.05)
                .padding(.top, screenHeight * 0.02)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func editItemRow(
        index: Int,
        item: EditableSavedShoppingItem,
        screenWidth: CGFloat,
        screenHeight: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: screenHeight * 0.008) {
            HStack(spacing: screenWidth * 0.02) {
                Text("\(index + 1).")
                    .font(.system(size: screenWidth * editItemNumberTextSizeRatio, weight: .semibold))
                    .foregroundStyle(mainTextColor)
                    .frame(width: screenWidth * 0.07, alignment: .leading)

                Menu {
                    ForEach(itemTypes, id: \.self) { type in
                        Button {
                            editableItems[index].type = type
                        } label: {
                            Text(LocalizedStringKey(type))
                        }
                    }
                } label: {
                    HStack {
                        Text(LocalizedStringKey(item.type))
                            .font(.system(size: screenWidth * editTypeTextSizeRatio))
                            .foregroundStyle(.black)

                        Spacer()

                        Image(systemName: "chevron.down")
                            .font(.system(size: screenWidth * 0.03))
                            .foregroundStyle(.black)
                    }
                    .padding(.horizontal, screenWidth * 0.02)
                    .frame(
                        width: screenWidth * editTypeBarWidthRatio,
                        height: screenHeight * editTypeBarHeightRatio
                    )
                    .background(Color.white.opacity(0.85))
                    .cornerRadius(8)
                }

                TextField("Qty", text: Binding(
                    get: { editableItems[index].quantityText },
                    set: { newValue in
                        let filtered = newValue.filter { $0.isNumber }
                        editableItems[index].quantityText = String(filtered.prefix(3))
                    }
                ))
                .font(.system(size: screenWidth * editInputTextSizeRatio))
                .tint(.black)
                .foregroundStyle(.black)
                .keyboardType(.numberPad)
                .padding(.horizontal, 6)
                .frame(
                    width: screenWidth * editQtyBarWidthRatio,
                    height: screenHeight * editQtyBarHeightRatio
                )
                .background(Color.white)
                .cornerRadius(6)

                Button {
                    itemToDeleteIndex = index
                    showDeleteItemAlert = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: screenWidth * editTrashIconSizeRatio))
                        .foregroundStyle(.red)
                }
                .frame(width: screenWidth * 0.08)
            }

            TextField("Item", text: Binding(
                get: { editableItems[index].name },
                set: { newValue in
                    if newValue.count > 65 {
                        editableItems[index].name = String(newValue.prefix(65))
                    } else {
                        editableItems[index].name = newValue
                    }
                }
            ), axis: .vertical)
            
            .font(.system(size: screenWidth * editInputTextSizeRatio))
            .tint(.black)
            .foregroundStyle(.black)
            .lineLimit(1...4)
            .padding(.horizontal, 8)
            .frame(height: screenHeight * editItemBarHeightRatio)
            .background(Color.white)
            .cornerRadius(6)
            
            HStack(spacing: screenWidth * 0.02) {
                Text(LocalizedStringKey("Price:"))
                    .font(.system(size: screenWidth * editPriceLabelTextSizeRatio))
                    .foregroundStyle(mainTextColor.opacity(0.75))

                TextField("0.00", text: Binding(
                    get: { editableItems[index].priceText },
                    set: { newValue in
                        updateEditableItemPrice(editableItems[index].id, text: newValue)
                    }
                ))
                .font(.system(size: screenWidth * editInputTextSizeRatio))
                .tint(.black)
                .foregroundStyle(.black)
                .keyboardType(.decimalPad)
                .padding(.horizontal, 6)
                .frame(
                    width: screenWidth * editPriceBarWidthRatio,
                    height: screenHeight * editPriceBarHeightRatio
                )
                .background(Color.white)
                .cornerRadius(6)
                .focused($focusedMoneyField, equals: .itemPrice(editableItems[index].id))
    
            }
        }
        .padding(.vertical, screenHeight * 0.008)
    }

    
    //total cost view
    
    private let categoryTypeTextSizeRatio: CGFloat = 0.027
    private let categoryPriceTextSizeRatio: CGFloat = 0.033
    private let totalCostSectionHeightRatio: CGFloat = 0.15
    
    private let categoryTypeXRatio: CGFloat = 0.18
    private let categoryPriceXRatio: CGFloat = 0.38
    private let categoryRowHeightRatio: CGFloat = 0.028
    
    private func totalCostRow(screenWidth: CGFloat, screenHeight: CGFloat) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: screenHeight * 0.006) {
                if let session = savedSession, session.hasTotalBill {
                    HStack(spacing: 0) {
                        Text(LocalizedStringKey("Total Cost"))

                        Text(": \(currencyDisplay(from: session.currency)) \(formatMoney(session.totalBill, currencyCode: session.currency))")
                    }
                    .font(.system(size: screenWidth * totalCostTextSizeRatio, weight: .bold))
                    .foregroundStyle(mainTextColor)
                }

                let categoryTotals: [CategoryTotal] = {
                    if let session = savedSession {
                        return CategorySummary.nonZeroTotals(
                            from: savedItems,
                            sessionTotal: session.totalBill,
                            hasSessionTotal: session.hasTotalBill
                        )
                    } else {
                        return CategorySummary.nonZeroTotals(from: savedItems)
                    }
                }()

                ForEach(categoryTotals) { category in
                    VStack(spacing: 3) {
                        ZStack {
                            Text(LocalizedStringKey(category.type))
                                .font(.system(size: screenWidth * categoryTypeTextSizeRatio, weight: .semibold))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(typeBackgroundColor(category.type))
                                .cornerRadius(5)
                                .position(
                                    x: screenWidth * categoryTypeXRatio,
                                    y: screenHeight * categoryRowHeightRatio / 2
                                )

                            Text("\(currencySymbolOnly(from: savedSession?.currency ?? "USD")) \(formatMoney(category.total, currencyCode: savedSession?.currency ?? "USD"))")
                                .font(.system(size: screenWidth * categoryPriceTextSizeRatio, weight: .semibold))
                                .foregroundStyle(mainTextColor.opacity(0.85))
                                .position(
                                    x: screenWidth * categoryPriceXRatio,
                                    y: screenHeight * categoryRowHeightRatio / 2
                                )
                        }
                        .frame(height: screenHeight * categoryRowHeightRatio)

                        Rectangle()
                            .fill(Color.black)
                            .frame(height: 1)
                    }
                }
            }
            .padding(.horizontal, screenWidth * 0.07)
            .padding(.vertical, screenHeight * 0.008)
        }
        .frame(height: screenHeight * totalCostSectionHeightRatio)
    }


    private func editTotalCostRow(screenWidth: CGFloat, screenHeight: CGFloat) -> some View {
        HStack(spacing: screenWidth * 0.02) {
            Menu {
                ForEach(currencies, id: \.self) { currency in
                    Button(currency) {
                        editableCurrencyDisplay = currency
                    }
                }
            } label: {
                HStack {
                    Text(editableCurrencyDisplay)
                        .font(.system(size: screenWidth * editInputTextSizeRatio))
                        .foregroundStyle(.black)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: screenWidth * 0.025))
                        .foregroundStyle(.black)
                }
                .padding(.horizontal, screenWidth * 0.025)
                .frame(
                    width: screenWidth * editCurrencyBarWidthRatio,
                    height: screenHeight * editCurrencyBarHeightRatio
                )
                .background(Color.white.opacity(0.85))
                .cornerRadius(6)
            }

            TextField("Total Cost", text: Binding(
                get: { editableTotalBillText },
                set: { newValue in
                    editableTotalBillText = formatMoneyInput(
                        newValue,
                        previousValue: editableTotalBillText
                    )
                    isEditableTotalBillManuallyEdited = !editableTotalBillText.isEmpty
                }
            ))
            .font(.system(size: screenWidth * editInputTextSizeRatio))
            .tint(.black)
            .foregroundStyle(.black)
            .keyboardType(.decimalPad)
            .padding(.horizontal, 8)
            .frame(
                width: screenWidth * editTotalCostBarWidthRatio,
                height: screenHeight * editTotalCostBarHeightRatio
            )
            .background(Color.white)
            .cornerRadius(6)
            .focused($focusedMoneyField, equals: .totalCost)
        }
        .frame(height: screenHeight * 0.10)
        .padding(.horizontal, screenWidth * 0.04)
    }
    
    private func enterEditMode() {
        editableItems = savedItems.sorted {
            let leftRank = typeSortRank($0.type)
            let rightRank = typeSortRank($1.type)

            if leftRank == rightRank {
                return $0.order < $1.order
            } else {
                return leftRank < rightRank
            }
        }.map { item in
            
            EditableSavedShoppingItem(
                name: item.name,
                quantityText: item.quantity?.description ?? "",
                type: item.type,
                order: item.order,
                priceText: item.priceText
            )
        }

        if editableItems.isEmpty {
            addEditableItem()
        }

        if let session = savedSession {
            editableCurrencyDisplay = fullCurrencyDisplay(from: session.currency)

            if session.hasTotalBill {
                editableTotalBillText = formatMoney(session.totalBill, currencyCode: session.currency)
            } else {
                editableTotalBillText = ""
            }
        } else {
            editableCurrencyDisplay = "🇺🇸 US $"
            editableTotalBillText = ""
        }
        
        isEditableTotalBillManuallyEdited = false

        if let session = savedSession {
            editableCurrencyDisplay = fullCurrencyDisplay(from: session.currency)

            if session.hasTotalBill {
                editableTotalBillText = formatMoney(session.totalBill, currencyCode: session.currency)

                let itemTotal = editableItemPriceTotal
                isEditableTotalBillManuallyEdited = session.totalBill > itemTotal
            } else {
                editableTotalBillText = ""
                isEditableTotalBillManuallyEdited = false
            }
        } else {
            editableCurrencyDisplay = "🇺🇸 US $"
            editableTotalBillText = ""
            isEditableTotalBillManuallyEdited = false
        }
        originalEditableItems = editableItems
        originalEditableTotalBillText = editableTotalBillText
        originalEditableCurrencyDisplay = editableCurrencyDisplay

        isEditMode = true
    }
    
    private var hasUnsavedEditChanges: Bool {
        editableItems != originalEditableItems ||
        editableTotalBillText != originalEditableTotalBillText ||
        editableCurrencyDisplay != originalEditableCurrencyDisplay
    }

    private func addEditableItem() {
        let nextOrder = (editableItems.map { $0.order }.max() ?? 0) + 1

        editableItems.append(
            EditableSavedShoppingItem(
                name: "",
                quantityText: "",
                type: "Uncategorized",
                order: nextOrder,
                priceText: ""
            )
        )
    }
    
    private func deleteEditableItem() {
        guard let index = itemToDeleteIndex else {
            return
        }

        guard editableItems.indices.contains(index) else {
            itemToDeleteIndex = nil
            return
        }

        editableItems.remove(at: index)

        if editableItems.isEmpty {
            addEditableItem()
        }

        itemToDeleteIndex = nil
    }
    
    private func hasEmptyItemWithQtyOrPrice() -> Bool {
        editableItems.contains { item in
            let name = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
            let quantity = item.quantityText.trimmingCharacters(in: .whitespacesAndNewlines)
            let price = item.priceText.trimmingCharacters(in: .whitespacesAndNewlines)

            return name.isEmpty && (!quantity.isEmpty || !price.isEmpty)
        }
    }

    private func showEmptyItemMessage() {
        activeAlertMessage = "There's an empty item in your list. You can't save it without adding an item name."
    }
    
    private func deleteSelectedDateSession() {
        do {
            let descriptor = FetchDescriptor<ShoppingSession>(
                predicate: #Predicate { session in
                    session.savedDate == selectedDate
                }
            )

            let sessions = try modelContext.fetch(descriptor)

            for session in sessions {
                modelContext.delete(session)
            }

            try modelContext.save()

            savedSession = nil
            savedItems = []
            editableItems = []
            editableTotalBillText = ""
            editableCurrencyDisplay = "🇺🇸 US $"
            isEditMode = false

            dismiss()
        } catch {
            activeAlertMessage = "Failed to delete this saved list."
            print("Failed to delete saved session: \(error)")
        }
    }

        
    private func saveEditedData() {
        if hasEmptyItemWithQtyOrPrice() {
            showEmptyItemMessage()
            return
        }
            validateEditableTotalBillAfterEditing()

            let itemTotal = editableItemPriceTotal
            let cleanEditableTotal = editableTotalBillText
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: ",", with: "")

            if itemTotal > 0 {
                guard let enteredTotal = Double(cleanEditableTotal), enteredTotal >= itemTotal else {
                    editableTotalBillText = formattedMoneyText(itemTotal)
                    isEditableTotalBillManuallyEdited = false
                    activeAlertMessage = "Total cost must be equal to or higher than the current item cost."
                    return
                }
            }

            let cleanedItems = editableItems
                .enumerated()
                .compactMap { index, editableItem -> ShoppingSessionItem? in
                    let name = editableItem.name.trimmingCharacters(in: .whitespacesAndNewlines)
                    let quantityText = editableItem.quantityText.trimmingCharacters(in: .whitespacesAndNewlines)

                    if name.isEmpty {
                        return nil
                    }

                    return ShoppingSessionItem(
                        name: name,
                        quantity: quantityText.isEmpty ? nil : Int(quantityText),
                        type: editableItem.type,
                        order: index + 1,
                        isDone: true,
                        priceText: editableItem.priceText
                    )
                }

            let cleanTotalText = editableTotalBillText
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: ",", with: "")

            let hasTotalBill = !cleanTotalText.isEmpty
            let parsedTotalBill = Double(cleanTotalText) ?? 0.0

            if hasTotalBill && Double(cleanTotalText) == nil {
                activeAlertMessage = "Enter a valid total cost."
                return
            }

            if cleanedItems.isEmpty && !hasTotalBill {
                activeAlertMessage = "Enter at least one item or total cost."
                return
            }

            let currencyCode = currencyCode(from: editableCurrencyDisplay)

            do {
                if let session = savedSession {
                    session.currency = currencyCode
                    session.totalBill = parsedTotalBill
                    session.hasTotalBill = hasTotalBill
                    session.items = cleanedItems
                } else {
                    let newSession = ShoppingSession(
                        savedDate: selectedDate,
                        savedTime: currentTimeString(),
                        currency: currencyCode,
                        totalBill: parsedTotalBill,
                        hasTotalBill: hasTotalBill
                    )

                    newSession.items = cleanedItems
                    modelContext.insert(newSession)
                }

                try modelContext.save()

                isEditMode = false
                loadSavedData()
            } catch {
                activeAlertMessage = "Failed to save."
                print("Failed to save edited data: \(error)")
            }
        }
    // saved items order
    private func typeSortRank(_ type: String) -> Int {
        switch type {
        case "Food":
            return 0
        case "Household":
            return 1
        case "Clothes":
            return 2
        case "Personal Use":
            return 3
        case "Uncategorized":
            return 4
        default:
            return 99
        }
    }

    private func loadSavedData() {
        do {
            let descriptor = FetchDescriptor<ShoppingSession>(
                predicate: #Predicate { session in
                    session.savedDate == selectedDate
                },
                sortBy: [
                    SortDescriptor(\.savedTime, order: .reverse)
                ]
            )

            let sessions = try modelContext.fetch(descriptor)

            guard let latestSession = sessions.first else {
                savedSession = nil
                savedItems = []
                return
            }

            savedSession = latestSession
          //saved items order
            savedItems = latestSession.items.sorted {
                let leftRank = typeSortRank($0.type)
                let rightRank = typeSortRank($1.type)

                if leftRank == rightRank {
                    return $0.order < $1.order
                } else {
                    return leftRank < rightRank
                }
            }
        } catch {
            print("Failed to load saved items: \(error)")
            savedSession = nil
            savedItems = []
        }
    }

    private func formatDateForDisplay(_ dateText: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"

        guard let date = inputFormatter.date(from: dateText) else {
            return dateText
        }

        let monthFormatter = DateFormatter()
        monthFormatter.locale = Locale(identifier: locale.identifier)
        monthFormatter.dateFormat = "MMMM"

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "d"

        let yearFormatter = DateFormatter()
        yearFormatter.dateFormat = "yyyy"

        let month = monthFormatter.string(from: date)
        let day = dayFormatter.string(from: date)
        let year = yearFormatter.string(from: date)

        return "\(month) \(day), \(year)"
    }

    private func currencyDisplay(from currencyCode: String) -> String {
        switch currencyCode {
        case "USD":
            return "🇺🇸 $"
        case "JPY":
            return "🇯🇵 ¥"
        case "GBP":
            return "🇬🇧 £"
        case "KRW":
            return "🇰🇷 ₩"
        default:
            return currencyCode
        }
    }

    private func fullCurrencyDisplay(from currencyCode: String) -> String {
        switch currencyCode {
        case "USD":
            return "🇺🇸 US $"
        case "JPY":
            return "🇯🇵 Japanese ¥"
        case "GBP":
            return "🇬🇧 British £"
        case "KRW":
            return "🇰🇷 Korean ₩"
        default:
            return currencyCode
        }
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

    private func formatMoney(_ amount: Double, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal

        if currencyCode == "JPY" || currencyCode == "KRW" {
            formatter.maximumFractionDigits = 0
            formatter.minimumFractionDigits = 0
        } else {
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 0
        }

        return formatter.string(from: NSNumber(value: amount)) ?? String(amount)
    }

    private func formatTotalBillInput(_ input: String) -> String {
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
            return editableTotalBillText
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
            return editableTotalBillText
        }

        if cleanText.hasSuffix(".") {
            return "\(formattedInteger)."
        } else if let decimalPart {
            return "\(formattedInteger).\(decimalPart)"
        } else {
            return formattedInteger
        }
    }

    private func currentTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }
    
    private var editableItemPriceTotal: Double {
        editableItems.reduce(0) { total, item in
            total + moneyValue(from: item.priceText)
        }
    }

    private var activeEditableMoneyTextBinding: Binding<String> {
        Binding(
            get: {
                switch focusedMoneyField {
                case .totalCost:
                    return editableTotalBillText

                case .itemPrice(let id):
                    return editableItems.first(where: { $0.id == id })?.priceText ?? ""

                case nil:
                    return ""
                }
            },
            set: { newValue in
                switch focusedMoneyField {
                case .totalCost:
                    editableTotalBillText = formatMoneyInput(
                        newValue,
                        previousValue: editableTotalBillText
                    )
                    isEditableTotalBillManuallyEdited = !editableTotalBillText.isEmpty

                case .itemPrice(let id):
                    updateEditableItemPrice(id, text: newValue)

                case nil:
                    break
                }
            }
        )
    }

    private func updateEditableItemPrice(_ itemID: UUID, text: String) {
        guard let index = editableItems.firstIndex(where: { $0.id == itemID }) else {
            return
        }

        let previousValue = editableItems[index].priceText

        editableItems[index].priceText = formatMoneyInput(
            text,
            previousValue: previousValue
        )
    }
    
    private func updateEditableTotalFromItemPricesIfNeeded() {
        let itemTotal = editableItemPriceTotal
        let currentTotal = moneyValue(from: editableTotalBillText)

        guard itemTotal > 0 else {
            return
        }

        if currentTotal < itemTotal {
            editableTotalBillText = formattedMoneyText(itemTotal)
            isEditableTotalBillManuallyEdited = false
        }
    }

    private func validateEditableTotalBillAfterEditing() {
        let itemTotal = editableItemPriceTotal

        guard itemTotal > 0 else {
            isEditableTotalBillManuallyEdited = !editableTotalBillText.isEmpty
            return
        }

        let cleanTotalText = editableTotalBillText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: "")

        let enteredTotal = Double(cleanTotalText)

        guard let enteredTotal, enteredTotal >= itemTotal else {
            editableTotalBillText = formattedMoneyText(itemTotal)
            isEditableTotalBillManuallyEdited = false

            activeAlertMessage = "Total cost must be equal to or higher than the current item cost."
            return
        }

        isEditableTotalBillManuallyEdited = true
    }

    private func moneyValue(from text: String) -> Double {
        let cleanText = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: "")

        return Double(cleanText) ?? 0
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
}

#Preview {
    NavigationStack {
        SavedItemsView(selectedDate: "2026-05-13")
    }
    .modelContainer(for: [
        ShoppingSession.self,
        ShoppingSessionItem.self,
        ShoppingDraft.self,
        ShoppingDraftItem.self
    ], inMemory: true)
}
