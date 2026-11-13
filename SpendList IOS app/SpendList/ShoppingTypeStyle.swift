//
//  ShoppingTypeStyle.swift
//  SpendList
//
//  Created by hunteron 15/05/2026.
//

//input item type color
import SwiftUI

func typeBackgroundColor(_ type: String) -> Color {
    switch type {
    case "Food":
        return Color.white.opacity(1)
    case "Clothes":
        return Color.yellow.opacity(0.8)
    case "Household":
        return Color.pink.opacity(0.8)
    case "Personal Use":
        return Color.blue.opacity(0.8)
    case "Uncategorized":
        return Color.gray.opacity(0.8)
    default:
        return Color.white.opacity(0.8)
        
    }
}
