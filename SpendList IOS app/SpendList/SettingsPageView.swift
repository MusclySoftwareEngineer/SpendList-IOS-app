//
//  SettingsPageView.swift
//  SpendList
//
//  Created by Seunghu Kim on 12/05/2026.
//

import SwiftUI

struct SettingsPageView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("appLanguage") private var selectedLanguage = "en"

    @State private var showLanguageDialog = false
    @State private var showFirstDeleteWarning = false
    @State private var showSecondDeleteWarning = false
    @State private var showDeleteCompleteMessage = false

    var body: some View {
        ZStack {
            Color("MainColor")
                .ignoresSafeArea()
//arrow
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.black)
                    }

                    Spacer()
                }
                .padding(.top, 70)
                .padding(.leading, 28)

                Spacer()
            }
//language button
            VStack(spacing: 90) {
                Button {
                    showLanguageDialog = true
                } label: {
                    Text(languageButtonText)
                        .fontWeight(.semibold)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 10)
                        .background(Color.gray)
                        .cornerRadius(8)
                }
//delete buton
                Button {
                    showFirstDeleteWarning = true
                } label: {
                    Text(deleteAllSavedDataText)
                        .fontWeight(.semibold)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 10)
                        .background(Color.gray)
                        .cornerRadius(8)
                }
            }
            .offset(y: -120)
            .zIndex(1)

            VStack {
                Spacer()

                Image("basket_money")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 350, height: 370)
                    .padding(.bottom, 80)
            }
            .zIndex(0)
            
        }
        .navigationBarBackButtonHidden(true)

        .confirmationDialog(
            selectLanguageText,
            isPresented: $showLanguageDialog,
            titleVisibility: .visible
        ) {
            Button(englishText) {
                selectedLanguage = "en"
            }

            Button(japaneseText) {
                selectedLanguage = "ja"
            }

            Button(koreanText) {
                selectedLanguage = "ko"
            }

            Button(cancelText, role: .cancel) {}
        }

        .alert(deleteWarningMessageText, isPresented: $showFirstDeleteWarning) {
            Button(noText, role: .cancel) {}

            Button(yesText, role: .destructive) {
                showSecondDeleteWarning = true
            }
        }

        .alert(deleteConfirmMessageText, isPresented: $showSecondDeleteWarning) {
            Button(noText, role: .cancel) {}

            Button(yesText, role: .destructive) {
                deleteAllSavedData()
                showDeleteCompleteMessage = true
            }
        }

        .alert(deleteCompleteMessageText, isPresented: $showDeleteCompleteMessage) {
            Button("OK") {}
        }
    }

    private var languageButtonText: String {
        switch selectedLanguage {
        case "ja":
            return "言語"
        case "ko":
            return "언어"
        default:
            return "Language"
        }
    }

    private var deleteAllSavedDataText: String {
        switch selectedLanguage {
        case "ja":
            return "保存データをすべて削除"
        case "ko":
            return "저장된 데이터 모두 삭제"
        default:
            return "Delete All Saved Data"
        }
    }
        

    private var selectLanguageText: String {
        switch selectedLanguage {
        case "ja":
            return "言語を選択"
        case "ko":
            return "언어를 선택하세요"
        default:
            return "Select your language"
        }
    }

    private var englishText: String {
        switch selectedLanguage {
        case "ja":
            return "英語"
        case "ko":
            return "영어"
        default:
            return "English"
        }
    }

    private var japaneseText: String {
        switch selectedLanguage {
        case "ja":
            return "日本語"
        case "ko":
            return "일본어"
        default:
            return "Japanese"
        }
    }

    private var koreanText: String {
        switch selectedLanguage {
        case "ja":
            return "韓国語"
        case "ko":
            return "한국어"
        default:
            return "Korean"
        }
    }

    private var cancelText: String {
        switch selectedLanguage {
        case "ja":
            return "キャンセル"
        case "ko":
            return "취소"
        default:
            return "Cancel"
        }
    }

    private var yesText: String {
        switch selectedLanguage {
        case "ja":
            return "はい"
        case "ko":
            return "예"
        default:
            return "Yes"
        }
    }

    private var noText: String {
        switch selectedLanguage {
        case "ja":
            return "いいえ"
        case "ko":
            return "아니요"
        default:
            return "No"
        }
    }

    private var deleteWarningMessageText: String {
        switch selectedLanguage {
        case "ja":
            return "「はい」を押すと、保存されたリストと合計金額がすべて完全に削除されます。"
        case "ko":
            return "“예”를 누르면 저장된 목록과 총액이 모두 영구적으로 삭제됩니다."
        default:
            return "If you tap Yes, all your saved item lists and total bills will be permanently deleted."
        }
    }

    private var deleteConfirmMessageText: String {
        switch selectedLanguage {
        case "ja":
            return "本当にすべての保存データを削除しますか？"
        case "ko":
            return "정말로 모든 저장 데이터를 삭제하시겠습니까?"
        default:
            return "Are you sure you want to delete all saved data?"
        }
    }

    private var deleteCompleteMessageText: String {
        switch selectedLanguage {
        case "ja":
            return "すべての保存データが削除されました。"
        case "ko":
            return "모든 저장 데이터가 삭제되었습니다."
        default:
            return "All saved data has been deleted."
        }
    }

    private func deleteAllSavedData() {
        // Later, connect this to your real SwiftData/CoreData/UserDefaults data.
        // For now, this is only the button logic.
        print("Delete all saved data")
    }
}

#Preview {
    SettingsPageView()
}
