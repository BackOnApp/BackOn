//
//  Certificates.swift
//  BackOn
//
//  Created by Riccio Vincenzo, Sorrentino Giancarlo, Triuzzi Emanuele, Zanfardino Gennaro on 11/02/2020.
//  Copyright © 2020 Riccio Vincenzo, Sorrentino Giancarlo, Triuzzi Emanuele, Zanfardino Gennaro. All rights reserved.
//

import SwiftUI
import MapKit

struct DetailedView<Element:Need, GenericUser:BaseUser>: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var need: Element
    @ObservedObject var user: GenericUser
    @State var showBusyDetail = false
    let isDiscoverSheet: Bool

    var body: some View {
        if (need is Discoverable || need is Task) && need.etaText == nil {
            need.requestETA()
        }
        let isExpired = need.isExpired()
        let isBusy = Calendar.controller.isBusy(when: need.date)
        return VStack(alignment: .leading, spacing: 0) {
            HStack (spacing: 0) {
                user.avatar(size: 50)
                VStack(alignment: .leading, spacing: 0) {
                    Text(user.identity)
                    Text(need.title).font(.body)
                }.font(.title).tint(.white).padding(.horizontal)
                Spacer()
                CloseButton()
            }
            .frame(height: 55)
            .padding()
            .backgroundIf(isExpired, .expiredNeed, .detailedTaskHeaderBG)
            if !isDiscoverSheet {MapView(need: need)}
            VStack(alignment: .leading, spacing: 20) {
                Divider().hidden()
                if need.descr != nil {
                    Text(need.descr!)
                        .fixedSize(horizontal: false, vertical: true)
                        .font(.system(size: 19))
                }
                UserActionRow(need: need)
//                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 5) { //Address section
                    Text("Address")
                        .foregroundColor(.secondary)
                        .font(.body)
                    Divider()
                    Text(need.address)
                }

                VStack(alignment: .leading, spacing: 5) { //Scheduled date section
                    Text("Scheduled Date")
                        .foregroundColor(.secondary)
                        .font(.body)
                    Divider()
                    HStack {
                        if showBusyDetail {
                            Text("You seem busy, check the calendar").tint(.yellow).onTapGesture{self.showBusyDetail.toggle()}
                        } else {
                            Text("\(self.need.date, formatter: customDateFormat)")
                        }
                        if (need is Discoverable) && isBusy && !showBusyDetail {
                            Image(systemName: "exclamationmark.triangle").tint(.yellow).onTapGesture{self.showBusyDetail.toggle()}
                        }
                        Spacer()
                    }
                }
                if !isExpired && !(need is Discoverable) {
                    HStack {
                        Spacer()
                        CallButton(phoneNumber: user.phoneNumber, date: need.date)
                        Spacer()
                    }
                }

            }.padding(.horizontal, 20)
        }
        .animation(.easeOut(duration: 0))
        .background(.systemBG)
    }
}
