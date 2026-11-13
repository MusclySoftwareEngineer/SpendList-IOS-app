//
//  CategoryCalculator.swift
//  SpendList
//
//  Created by hunter on 21/05/2026.
//

import Foundation

struct CategoryTotal: Identifiable {
    let id = UUID()
    let type: String
    let total: Double
}

struct CurrencyCategoryMonthSummary: Identifiable {
    let id = UUID()
    let currency: String
    let total: Double
    let categoryTotals: [CategoryTotal]
}

struct CategorySummary {
    static let categoryOrder = [
        "Food",
        "Household",
        "Clothes",
        "Personal Use",
        "Uncategorized"
    ]

    static func moneyValue(from text: String) -> Double {
        let cleanText = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: "")

        return Double(cleanText) ?? 0
    }

    static func totals(from items: [ShoppingSessionItem]) -> [CategoryTotal] {
        var totalsByType: [String: Double] = [:]

        for item in items {
            let type = item.type.isEmpty ? "Uncategorized" : item.type
            let price = moneyValue(from: item.priceText)

            totalsByType[type, default: 0] += price
        }

        return categoryOrder.map { type in
            CategoryTotal(
                type: type,
                total: totalsByType[type, default: 0]
            )
        }
    }

    static func nonZeroTotals(from items: [ShoppingSessionItem]) -> [CategoryTotal] {
        totals(from: items).filter { $0.total > 0 }
    }

    static func monthlyCurrencySummaries(from sessions: [ShoppingSession]) -> [CurrencyCategoryMonthSummary] {
        var totalByCurrency: [String: Double] = [:]
        var categoryTotalsByCurrency: [String: [String: Double]] = [:]

        for session in sessions {
            guard session.hasTotalBill else {
                continue
            }

            totalByCurrency[session.currency, default: 0] += session.totalBill

            let sessionCategoryTotals = totals(
                from: session.items,
                sessionTotal: session.totalBill,
                hasSessionTotal: session.hasTotalBill
            )

            for categoryTotal in sessionCategoryTotals {
                categoryTotalsByCurrency[session.currency, default: [:]][categoryTotal.type, default: 0] += categoryTotal.total
            }
        }

        let summaries = totalByCurrency.map { currency, total in
            let categoryTotals = categoryOrder.map { type in
                CategoryTotal(
                    type: type,
                    total: categoryTotalsByCurrency[currency]?[type] ?? 0
                )
            }
            .filter { $0.total > 0 }

            return CurrencyCategoryMonthSummary(
                currency: currency,
                total: total,
                categoryTotals: categoryTotals
            )
        }

        return summaries.sorted { $0.total > $1.total }
    }
    
    static func totals(
        from items: [ShoppingSessionItem],
        sessionTotal: Double,
        hasSessionTotal: Bool
    ) -> [CategoryTotal] {
        var totalsByType: [String: Double] = [:]

        var itemPriceTotal: Double = 0

        for item in items {
            let type = item.type.isEmpty ? "Uncategorized" : item.type
            let price = moneyValue(from: item.priceText)

            totalsByType[type, default: 0] += price
            itemPriceTotal += price
        }

        if hasSessionTotal {
            let unassignedAmount = sessionTotal - itemPriceTotal

            if unassignedAmount > 0 {
                totalsByType["Uncategorized", default: 0] += unassignedAmount
            }
        }

        return categoryOrder.map { type in
            CategoryTotal(
                type: type,
                total: totalsByType[type, default: 0]
            )
        }
    }
    
    static func nonZeroTotals(
        from items: [ShoppingSessionItem],
        sessionTotal: Double,
        hasSessionTotal: Bool
    ) -> [CategoryTotal] {
        totals(
            from: items,
            sessionTotal: sessionTotal,
            hasSessionTotal: hasSessionTotal
        )
        .filter { $0.total > 0 }
    }
}
