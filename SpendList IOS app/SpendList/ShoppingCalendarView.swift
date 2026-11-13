//
//  ShoppingCalendarView.swift
//  SpendList
//
//  Created by hunter on 13/05/2026.
//

import SwiftUI
import SwiftData

struct CalendarDayInput: Identifiable {
    let id = UUID()
    let dayText: String
    let fullDate: String?
    let hasShoppingData: Bool
    let isCurrentMonth: Bool
}

struct ShoppingCalendarView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.locale) private var locale

    @Query private var sessions: [ShoppingSession]

    @State private var currentDate = Date()
    
    @State private var isMonthYearPickerOpen = false
    @State private var selectedPickerMonth = Calendar.current.component(.month, from: Date())
    @State private var selectedPickerYear = Calendar.current.component(.year, from: Date())

    private let weekDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    private let monthNames = [
        "January", "February", "March", "April",
        "May", "June", "July", "August",
        "September", "October", "November", "December"
    ]
    
    private var mainTextColor: Color {
        colorScheme == .dark ? .white : .black
    }

    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height

            ZStack {
                Color("MainColor")
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    topRow(
                        screenWidth: screenWidth,
                        screenHeight: screenHeight
                    )

                    monthControlRow(
                        screenWidth: screenWidth,
                        screenHeight: screenHeight
                    )

                    weekHeaderRow(
                        screenWidth: screenWidth,
                        screenHeight: screenHeight
                    )

                    calendarGrid(
                        screenWidth: screenWidth,
                        screenHeight: screenHeight
                    )

                    monthlyTotalArea(
                        screenWidth: screenWidth,
                        screenHeight: screenHeight
                    )
                }
            }
            .navigationBarBackButtonHidden(true)
            .sheet(isPresented: $isMonthYearPickerOpen) {
                monthYearPickerSheet
            }
        }
    }

    private func topRow(screenWidth: CGFloat, screenHeight: CGFloat) -> some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: screenWidth * 0.07, weight: .bold))
                    .foregroundStyle(mainTextColor)
            }

            Spacer()
        }
        .padding(.leading, screenWidth * 0.07)
        .padding(.top, screenHeight * -0.03)
        .frame(height: screenHeight * 0.13)
    }

    private func monthControlRow(screenWidth: CGFloat, screenHeight: CGFloat) -> some View {
        HStack {
            Button {
                moveMonth(by: -1)
            } label: {
                Image(systemName: "arrow.left.circle")
                    .font(.system(size: screenWidth * 0.095))
                    .foregroundStyle(mainTextColor)
            }

            Spacer()

            Button {
                selectedPickerMonth = currentMonth
                selectedPickerYear = currentYear
                isMonthYearPickerOpen = true
            } label: {
                Text(monthTitle)
                    .font(.system(size: screenWidth * 0.06, weight: .bold))
                    .foregroundStyle(mainTextColor)
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                moveMonth(by: 1)
            } label: {
                Image(systemName: "arrow.right.circle")
                    .font(.system(size: screenWidth * 0.095))
                    .foregroundStyle(mainTextColor)
            }
        }
        .padding(.horizontal, screenWidth * 0.06)
        .frame(height: screenHeight * 0.08)
    }
    
    private func applySelectedMonthYear() {
        var components = DateComponents()
        components.year = selectedPickerYear
        components.month = selectedPickerMonth
        components.day = 1

        if let newDate = Calendar.current.date(from: components) {
            currentDate = newDate
        }
    }
    
    //month code
    private var monthYearPickerSheet: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height

            VStack(spacing: screenHeight * 0.03) {
                Text("Select Month and Year")
                    .font(.system(size: screenWidth * 0.055, weight: .bold))
                    .foregroundStyle(mainTextColor)
                    .padding(.top, screenHeight * 0.04)

                HStack(spacing: screenWidth * 0.04) {
                    Picker("Month", selection: $selectedPickerMonth) {
                        ForEach(1...12, id: \.self) { month in
                            Text(LocalizedStringKey(monthNames[month - 1]))
                                .tag(month)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: screenWidth * 0.50)

                    Picker("Year", selection: $selectedPickerYear) {
                        ForEach(2026...3000, id: \.self) { year in
                            Text(String(year))
                                .tag(year)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: screenWidth * 0.35)
                }
                .frame(height: screenHeight * 0.35)

                HStack(spacing: screenWidth * 0.04) {
                    Button {
                        isMonthYearPickerOpen = false
                    } label: {
                        Text("Cancel")
                            .font(.system(size: screenWidth * 0.045, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(width: screenWidth * 0.35, height: screenHeight * 0.06)
                            .background(Color.gray.opacity(0.4))
                            .cornerRadius(10)
                    }

                    Button {
                        applySelectedMonthYear()
                        isMonthYearPickerOpen = false
                    } label: {
                        Text("OK")
                            .font(.system(size: screenWidth * 0.045, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(width: screenWidth * 0.35, height: screenHeight * 0.06)
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("MainColor"))
        }
        .presentationDetents([.fraction(0.55)])
    }

    private func weekHeaderRow(screenWidth: CGFloat, screenHeight: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(weekDays, id: \.self) { day in
                Text(LocalizedStringKey(day))
                    .font(.system(size: screenWidth * 0.035, weight: .bold))
                    .foregroundStyle(mainTextColor)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, screenWidth * 0.04)
        .frame(height: screenHeight * 0.04)
    }

    private func calendarGrid(screenWidth: CGFloat, screenHeight: CGFloat) -> some View {
        let columns = Array(
            repeating: GridItem(.flexible(), spacing: screenWidth * 0.01),
            count: 7
        )

        return LazyVGrid(columns: columns, spacing: screenHeight * 0.01) {
            ForEach(calendarDays) { day in
                if let fullDate = day.fullDate {
                    NavigationLink {
                        SavedItemsView(selectedDate: fullDate)
                    } label: {
                        calendarDayCell(
                            day: day,
                            screenWidth: screenWidth,
                            screenHeight: screenHeight
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    calendarDayCell(
                        day: day,
                        screenWidth: screenWidth,
                        screenHeight: screenHeight
                    )
                }
            }
        }
        .padding(.horizontal, screenWidth * 0.04)
        .frame(height: screenHeight * 0.50, alignment: .top)
    }

    private func calendarDayCell(
        day: CalendarDayInput,
        screenWidth: CGFloat,
        screenHeight: CGFloat
    ) -> some View {
        Text(day.dayText)
            .font(.system(size: screenWidth * 0.04, weight: .semibold))
            .foregroundStyle(mainTextColor)
            .frame(
                maxWidth: .infinity,
                minHeight: screenHeight * 0.055
            )
            .background(
                day.hasShoppingData
                ? Color.green.opacity(0.65)
                : Color.clear
            )
            .cornerRadius(8)
    }

    private func monthlyTotalArea(screenWidth: CGFloat, screenHeight: CGFloat) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: screenHeight * 0.012) {
                Text("Total cost this month")
                    .font(.system(size: screenWidth * 0.045, weight: .bold))
                    .foregroundStyle(mainTextColor)

                if monthlyCurrencySummaries.isEmpty {
                    Text("Empty")
                        .font(.system(size: screenWidth * 0.043, weight: .bold))
                        .foregroundStyle(mainTextColor)
                } else {
                    ForEach(monthlyCurrencySummaries) { summary in
                        monthlyCurrencyBlock(
                            summary: summary,
                            screenWidth: screenWidth,
                            screenHeight: screenHeight
                        )
                    }
                }
            }
            .padding(.horizontal, screenWidth * 0.07)
            .padding(.vertical, screenHeight * 0.01)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    private func monthlyCurrencyBlock(
        summary: CurrencyCategoryMonthSummary,
        screenWidth: CGFloat,
        screenHeight: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: screenHeight * 0.006) {
            Text("\(currencyFlag(summary.currency)): \(formatMoney(summary.total, currencyCode: summary.currency))")
                .font(.system(size: screenWidth * 0.040, weight: .bold))
                .foregroundStyle(mainTextColor)

            if summary.categoryTotals.isEmpty {
                Text("No item prices entered")
                    .font(.system(size: screenWidth * 0.030, weight: .medium))
                    .foregroundStyle(mainTextColor.opacity(0.75))
                    .padding(.leading, screenWidth * 0.04)
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: screenWidth * 0.02),
                        GridItem(.flexible(), spacing: screenWidth * 0.02)
                    ],
                    spacing: screenHeight * 0.008
                ) {
                    ForEach(summary.categoryTotals) { category in
                        monthlyCategoryCell(
                            category: category,
                            currencyCode: summary.currency,
                            screenWidth: screenWidth
                        )
                    }
                }
                .padding(.leading, screenWidth * 0.10)
            }
        }
        .padding(.bottom, screenHeight * 0.01)
    }
    
    private func monthlyCategoryCell(
        category: CategoryTotal,
        currencyCode: String,
        screenWidth: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(LocalizedStringKey(category.type))
                .font(.system(size: screenWidth * 0.026, weight: .semibold))
                .foregroundStyle(.black)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(typeBackgroundColor(category.type))
                .cornerRadius(5)

            Text("\(currencySymbolOnly(currencyCode)): \(formatMoney(category.total, currencyCode: currencyCode))")
                .font(.system(size: screenWidth * 0.028, weight: .semibold))
                .foregroundStyle(mainTextColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(6)
        .overlay(
            Rectangle()
                .stroke(Color.black.opacity(0.5), lineWidth: 1)
        )
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: locale.identifier)
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentDate)
    }
    
    private var currentYear: Int {
        Calendar.current.component(.year, from: currentDate)
    }

    private var currentMonth: Int {
        Calendar.current.component(.month, from: currentDate)
    }

    private var monthPrefix: String {
        String(format: "%04d-%02d", currentYear, currentMonth)
    }

    private var savedDateSet: Set<String> {
        Set(sessions.map { $0.savedDate })
    }

    private var calendarDays: [CalendarDayInput] {
        var result: [CalendarDayInput] = []

        let calendar = Calendar.current

        var components = DateComponents()
        components.year = currentYear
        components.month = currentMonth
        components.day = 1

        guard let firstDateOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstDateOfMonth)
        else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: firstDateOfMonth)
        let blankCount = firstWeekday - 1

        for _ in 0..<blankCount {
            result.append(
                CalendarDayInput(
                    dayText: "",
                    fullDate: nil,
                    hasShoppingData: false,
                    isCurrentMonth: false
                )
            )
        }

        for day in range {
            let fullDate = String(format: "%04d-%02d-%02d", currentYear, currentMonth, day)

            result.append(
                CalendarDayInput(
                    dayText: "\(day)",
                    fullDate: fullDate,
                    hasShoppingData: savedDateSet.contains(fullDate),
                    isCurrentMonth: true
                )
            )
        }

        while result.count % 7 != 0 {
            result.append(
                CalendarDayInput(
                    dayText: "",
                    fullDate: nil,
                    hasShoppingData: false,
                    isCurrentMonth: false
                )
            )
        }

        return result
    }
    
    private var monthlyCurrencySummaries: [CurrencyCategoryMonthSummary] {
        CategorySummary.monthlyCurrencySummaries(from: monthlySessions)
    }

    private var monthlySessions: [ShoppingSession] {
        sessions.filter { session in
            session.savedDate.hasPrefix(monthPrefix)
        }
    }

    private var monthlyTotalText: String {
        if monthlySessions.isEmpty {
            return "Empty"
        }

        var totals: [String: Double] = [:]

        for session in monthlySessions {
            totals[session.currency, default: 0.0] += session.totalBill
        }

        let currencyOrder: [String] = ["JPY", "USD", "GBP", "KRW"]

        var lines: [String] = []

        for currency in currencyOrder {
            if let amount = totals[currency] {
                let line = "\(currencyFlag(currency)): \(formatMoney(amount, currencyCode: currency))"
                lines.append(line)
            }
        }

        return lines.isEmpty ? "Empty" : lines.joined(separator: "\n")
    }

    private func moveMonth(by value: Int) {
        if let newDate = Calendar.current.date(
            byAdding: .month,
            value: value,
            to: currentDate
        ) {
            currentDate = newDate
        }
    }

    private func currencyFlag(_ currencyCode: String) -> String {
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
    
    private func currencySymbolOnly(_ currencyCode: String) -> String {
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

    private func formatMoney(_ amount: Double, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_US")

        if currencyCode == "JPY" || currencyCode == "KRW" {
            formatter.maximumFractionDigits = 0
            formatter.minimumFractionDigits = 0
        } else {
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 0
        }

        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
}

#Preview {
    NavigationStack {
        ShoppingCalendarView()
    }
    .modelContainer(for: [
        ShoppingSession.self,
        ShoppingSessionItem.self,
        ShoppingDraft.self,
        ShoppingDraftItem.self
    ], inMemory: true)
}
