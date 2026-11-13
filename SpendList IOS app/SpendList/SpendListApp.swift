//
//  SpendListApp.swift
//  SpendList
//
//  Created by hunter on 11/05/2026.
//

import SwiftUI
import SwiftData

@main
struct SpendListApp: App {
    @AppStorage("appLanguage") private var appLanguage = "en"

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, Locale(identifier: appLanguage))
                .id(appLanguage)
        }
        .modelContainer(for: [
            ShoppingSession.self,
            ShoppingSessionItem.self,
            ShoppingDraft.self,
            ShoppingDraftItem.self
        ])
    }
}
