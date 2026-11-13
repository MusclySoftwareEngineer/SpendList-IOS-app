//
//  KeyboardDismissHelper.swift
//  SpendList
//
//  Created by hunter on 18/05/2026.
//

import SwiftUI
import UIKit

extension View {
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            hideKeyboard()
        }
    }
}

func hideKeyboard() {
    UIApplication.shared.sendAction(
        #selector(UIResponder.resignFirstResponder),
        to: nil,
        from: nil,
        for: nil
    )
}
