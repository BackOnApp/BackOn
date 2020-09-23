//
//  DiscoverDetailedView.swift
//  BackOn
//
//  Created by Emanuele Triuzzi on 04/03/2020.
//  Copyright © 2020 Riccio Vincenzo, Sorrentino Giancarlo, Triuzzi Emanuele, Zanfardino Gennaro. All rights reserved.
//

import SwiftUI

struct NeedPreview<Content:Need,GenericUser:BaseUser>: View {
    let need: Content
    let user: GenericUser
    @State var showLoadingOverlay = false
    
    var body: some View {
        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                user.avatar(size: 50)
                VStack(alignment: .leading) {
                    Text(user.identity)
                    Text(need.title).font(.subheadline).fontWeight(.light)
                }
                .font(.title) //c'era 26 di grandezza invece di 28
                .lineLimit(1)
                .tint(.white)
                .padding(.leading, 5)
                .offset(y: -1)
                Spacer()
            }
            Spacer()
            HStack {
                Text(need.city)
                Spacer()
                Text("\(need.date, formatter: customDateFormat)")
            }.font(.body).tint(.secondary).offset(y: 1)
        }
        .padding(12)
        .backgroundIf(need.isExpired(), .expiredNeed, .need)
        .loadingOverlayIf(.constant(showLoadingOverlay))
        .cornerRadius(10)
        .onReceive(need.objectWillChange) {_ in self.showLoadingOverlay = need.waitingForServerResponse}
    }
}

struct NeedList<Content:Need>: View {
    @ObservedObject var cdc = CD.controller
    @ObservedObject var dtc = Discover.controller
    @State var selectedNeed: Content?
    @State var showModal = false
    
    var body: some View {
        let activeNeeds: [Content]!
        let expiredNeeds: [Content]!
        var navTitle = ""
        switch type(of: selectedNeed) {
        case is Task?.Type:
            activeNeeds = cdc.activeTasksController.fetchedObjects as? [Content] ?? []
            expiredNeeds = cdc.expiredTasksController.fetchedObjects as? [Content] ?? []
            navTitle = "Your tasks"
        case is Request?.Type:
            activeNeeds = cdc.activeRequestsController.fetchedObjects as? [Content] ?? []
            expiredNeeds = cdc.expiredRequestsController.fetchedObjects as? [Content] ?? []
            navTitle = "Your requests"
        case is Discoverable?.Type:
            activeNeeds = dtc.discoverablesArray() as? [Content] ?? []
            expiredNeeds = []
            navTitle = "Your discoverables"
        default:
            print("Error! Default case in NeedList")
            activeNeeds = []
            expiredNeeds = []
        }
        return ScrollView(.vertical) {
            VStack(alignment: .leading) {
                ForEach(activeNeeds) { current in
                    Button(action: {
                        self.selectedNeed = current
                        self.showModal = true
                    }) {
                        if let user = current.user {
                            NeedPreview(need: current, user: user)
                        } else {
                            NeedPreview(need: current, user: NobodyAccepted.instance)
                        }
                    }
                    .customButtonStyle()
                }
                if !activeNeeds.isEmpty && !expiredNeeds.isEmpty {
                    Divider()
                }
                ForEach(expiredNeeds) { current in
                    Button(action: {
                        self.selectedNeed = current
                        self.showModal = true
                    }) {
                        if let user = current.user {
                            NeedPreview(need: current, user: user)
                        } else {
                            NeedPreview(need: current, user: NobodyAccepted.instance)
                        }
                    }
                    .customButtonStyle()
                }
            }
            .navigationTitle(navTitle)
            .padding(10)
        }
        .sheet(isPresented: self.$showModal) {
            if selectedNeed!.user == nil {
                DetailedView(need: selectedNeed!, user: NobodyAccepted.instance, isDiscoverSheet: false)
            } else {
                DetailedView(need: selectedNeed!, user: selectedNeed!.user!, isDiscoverSheet: false)
            }
        }
    }
}
