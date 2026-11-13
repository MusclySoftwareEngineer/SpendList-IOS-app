//
//  ShoppingDatabase.swift
//  SpendList
//
//  Created by Hunter on 12/05/2026.
//

import Foundation
import SwiftData

@Model
final class ShoppingSession {
    var savedDate: String
    var savedTime: String
    var currency: String
    var totalBill: Double
    var hasTotalBill: Bool

    @Relationship(deleteRule: .cascade)
    var items: [ShoppingSessionItem]

    init(
        savedDate: String,
        savedTime: String,
        currency: String,
        totalBill: Double,
        hasTotalBill: Bool,
        items: [ShoppingSessionItem] = []
    ) {
        self.savedDate = savedDate
        self.savedTime = savedTime
        self.currency = currency
        self.totalBill = totalBill
        self.hasTotalBill = hasTotalBill
        self.items = items
    }
}

@Model
final class ShoppingSessionItem {
    var name: String
    var quantity: Int?
    var type: String
    var order: Int
    var isDone: Bool
    var priceText: String

    init(
        name: String,
        quantity: Int?,
        type: String = "Uncategorized",
        order: Int = 0,
        isDone: Bool,
        priceText: String = ""
    ) {
        self.name = name
        self.quantity = quantity
        self.type = type
        self.order = order
        self.isDone = isDone
        self.priceText = priceText
    }
}

@Model
final class ShoppingDraft {
    var currency: String
    var totalBillText: String

    @Relationship(deleteRule: .cascade)
    var items: [ShoppingDraftItem]

    init(
        currency: String,
        totalBillText: String,
        items: [ShoppingDraftItem] = []
    ) {
        self.currency = currency
        self.totalBillText = totalBillText
        self.items = items
    }
}

@Model
final class ShoppingDraftItem {
    var name: String
    var quantity: Int?
    var type: String
    var order: Int
    var isDone: Bool
    var priceText: String

    init(
        name: String,
        quantity: Int?,
        type: String = "Uncategorized",
        order: Int = 0,
        isDone: Bool,
        priceText: String = ""
    ) {
        self.name = name
        self.quantity = quantity
        self.type = type
        self.order = order
        self.isDone = isDone
        self.priceText = priceText
    }
}
