//
//  DiscoverDetailedView.swift
//  BackOn
//
//  Created by Riccio Vincenzo, Sorrentino Giancarlo, Triuzzi Emanuele, Zanfardino Gennaro on 04/03/2020.
//  Copyright © 2020 Riccio Vincenzo, Sorrentino Giancarlo, Triuzzi Emanuele, Zanfardino Gennaro. All rights reserved.
//

import SwiftUI
import Combine

struct DashboardTab: View {
    @ObservedObject var cdc = CD.controller
    var body: some View {
        return NavigationView {
            VStack {
                SizedDivider(height: 5)
                TaskRow()
                RequestRow()
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .transparentNavBar()
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    HStack(alignment: .center, spacing: 0) {
                        Text("Hi \(cdc.loggedUser!.name)!").font(.title).fontWeight(.medium)
                        Spacer()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        ProfileButton()
                        AddNeedButton()
//                        Button(action: {print(CD.controller.hasPendingJob())}, label: {Text("hPJ")})
//                        Button(action: {CD.controller.activeRequestsController.fetchedObjects?.first?.waitingForServerResponse.toggle()}, label: {Text("t")})
                    }
                }
            }
        }
    }
}

struct DiscoverTab: View {
    @ObservedObject var dtc = Discover.controller
    
    var body: some View {
        VStack(alignment: .center) {
//            HStack {
//                Text("Around you")
//                    .fontWeight(.bold)
//                    .font(.title)
//                    .frame(alignment: .leading)
//                    .padding(.leading)
//                    .offset(y: 2)
//                Spacer()
//            }
            Picker(selection: $dtc.mapMode, label: Text("Select")) {
                Text("List").tag(false)
                Text("Map").tag(true)
            }.pickerStyle(SegmentedPickerStyle()).labelsHidden().padding(.horizontal).offset(y: -5)
            if Geo.controller.isLocationAccurated() && dtc.canLoadAroundYouMap && !dtc.discoverables.isEmpty {
                if dtc.mapMode {
                    MapView<Discoverable>()
                } else {
                    NeedList<Discoverable>()
                }
            } else {
                NoDiscoverablesAroundYou().offset(y: -30) //Pin barrato
            }
        }
    }
}

struct DiscoverSheetView: View {
    @ObservedObject var discoverTabController = Discover.controller
    
    var body: some View {
        SheetView(isOpen: $discoverTabController.showSheet, onClose: {discoverTabController.closeSheet()}) {
            if discoverTabController.selectedDiscoverable != nil {
                DetailedView(need: discoverTabController.selectedDiscoverable!, user: discoverTabController.selectedDiscoverable!.needer, isDiscoverSheet: true)
                    .transition(.move(edge: .bottom))
            } else {
                EmptyView()
            }
        }
    }
}

