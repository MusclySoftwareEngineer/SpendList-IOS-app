//
//  KeyboardTotalCostTool.bar.swift
//  SpendList
//
//  Created by Seunghu Kim on 18/05/2026.
//

import SwiftUI

struct KeyboardTotalCostToolbar: ToolbarContent {
    @Binding var text: String

    let isVisible: Bool
    var onOK: () -> Void = {}

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            if isVisible {
                Text(text.isEmpty ? "Total Cost" : text)
                    .foregroundStyle(text.isEmpty ? .gray : .black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.white)
                    .cornerRadius(8)

                Button("OK") {
                    onOK()
                    hideKeyboard()
                }
                .fontWeight(.bold)
            }
        }
    }
}
