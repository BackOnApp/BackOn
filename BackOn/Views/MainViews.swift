//
//  ContentView.swift
//  BackOn
//
//  Created by Riccio Vincenzo, Sorrentino Giancarlo, Triuzzi Emanuele, Zanfardino Gennaro on 14/02/2020.
//  Copyright © 2020 Riccio Vincenzo, Sorrentino Giancarlo, Triuzzi Emanuele, Zanfardino Gennaro. All rights reserved.
//

import SwiftUI

struct TabViewController: View {
    let dashboardTab = DashboardTab()
    let discoverTab = DiscoverTab()
    @State var selectedIndex = 0
    var body: some View {
        VStack(spacing: 0) {
            if selectedIndex == 0 {
                dashboardTab
            } else if selectedIndex == 1 {
                discoverTab.accentColor(Color(.systemBlue))
            }
            VStack(spacing: 0) {
                SizedDivider(height: 4, width: UIScreen.main.bounds.width)
                HStack {
                    HStack {
                        Spacer()
                        VStack(spacing: 2) {
                            Image(systemName: "rectangle.stack.fill.badge.person.crop").resizable().scaledToFit()
                            Text("About you").font(.caption)
                        }.tintIf(selectedIndex == 0, .orange, .gray)
                        .onTapGesture {self.selectedIndex = 0}
                        Spacer()
                    }
                    HStack {
                        Spacer()
                        VStack(spacing: 2) {
                            Image("DiscoverSymbol").resizable().scaledToFit()
                            Text("Discover").font(.caption)
                        }.tintIf(selectedIndex == 1, .orange, .gray)
                        .onTapGesture {self.selectedIndex = 1}
                        Spacer()
                    }
                }
                SizedDivider(height: 22, width: UIScreen.main.bounds.width)
            }.frame(width: UIScreen.main.bounds.width, height: 75).background(getColor(.expiredNeed).shadow(radius: 2))
        }.edgesIgnoringSafeArea(.bottom)
        .accentColor(Color(.systemOrange))
        .overlay(DiscoverSheetView())
    }
}

struct LoginPage: View {
    var body: some View {
        VStack {
            Text("BackOn")
                .fontWeight(.bold)
                .foregroundColor(.white)
                .font(.system(size: 40, weight: .bold, design: .default))
                .padding([.top, .bottom], 40)
            Image("Icon")
                .resizable()
                .frame(width: 250, height: 250)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                .shadow(radius: 10)
            Spacer()
            GoogleButton()
            Spacer()
        }
        .frame(width: UIScreen.main.bounds.width)
        .offset(y: 50)
        .background(Color(#colorLiteral(red: 0.9502732158, green: 0.6147753596, blue: 0.2734006643, alpha: 1)))
        .edgesIgnoringSafeArea(.all)
    }
}

struct Login_Previews: PreviewProvider {
    static var previews: some View {
        LoginPage()
    }
}
