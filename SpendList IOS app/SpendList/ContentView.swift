//
//  ContentView.swift
//  SpendList
//
//  Created by hunter on 11/05/2026.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("dark_mode") private var isDarkMode = false

    var body: some View {
        NavigationStack {
            ZStack {
                // main page color
                Color("MainColor")
                    .ignoresSafeArea()

                VStack {
                    // Top area: dark mode switch
                    HStack {
                        Spacer()

                        Toggle(isOn: $isDarkMode) {
                            Text(isDarkMode ? "Light Mode" : "Dark Mode")
                                .fontWeight(.bold)
                        }
                        .toggleStyle(SwitchToggleStyle())
                        .fixedSize()
                    }
                    .padding(.top, 50)
                    .padding(.trailing, 25)

                    Spacer()
                }

                VStack(spacing: 45) {
                    Spacer()
                        .frame(height: 130)

                    NavigationLink {
                        InputListPageView()
                    } label: {
                        Text("Create Shopping List")
                            .fontWeight(.semibold)
                            .foregroundStyle(.black)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 10)
                            .background(Color.green)
                            .cornerRadius(8)
                    }

                    NavigationLink {
                        ShoppingCalendarView()
                    } label: {
                        Text("Shopping Calendar")
                            .fontWeight(.semibold)
                            .foregroundStyle(.black)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 10)
                            .background(Color.green)
                            .cornerRadius(8)
                    }

                    Spacer()
                }
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

                VStack {
                    Spacer()

                    NavigationLink {
                        SettingsPageView()
                    } label: {
                        Text("Settings")
                            .fontWeight(.semibold)
                            .foregroundStyle(.black)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 10)
                            .background(Color.gray)
                            .cornerRadius(8)
                    }
                    .padding(.bottom, 80)
                }
            }
            .navigationBarHidden(true)
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}



#Preview {
    ContentView()
}
