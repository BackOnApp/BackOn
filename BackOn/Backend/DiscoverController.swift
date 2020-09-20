//
//  DiscoverTabController.swift
//  BackOn
//
//  Created by Vincenzo Riccio on 31/08/2020.
//

import MapKit

class Discover: ObservableObject {
    static let controller = Discover()
    @Published var discoverables: [String:Discoverable] = [:]
    @Published var discUsers: [String:DiscoverableUser] = [:]
    @Published var canLoadAroundYouMap = false
    @Published var showSheet = false
    @Published var showModal = false
    @Published var selectedDiscoverable: Discoverable?
    @Published var baseMKMap: MKMapView?
    @Published var mapMode = true {
        didSet {
            if oldValue == true && self.mapMode == false {
                self.closeSheet()
            }
        }
    }
    
    private init() {}
    
    func discoverablesArray() -> [Discoverable] {
        return Array(discoverables.values)
    }
    
    func showModal(discoverable: Discoverable) {
        self.selectedDiscoverable = discoverable
        showModal = true
    }
    
    func closeModal() {
        showModal = false
        selectedDiscoverable = nil
    }
    
    func showSheet(discoverable: Discoverable) {
        self.selectedDiscoverable = discoverable
        showSheet = true
    }
    
    func closeSheet() {
        showSheet = false
        selectedDiscoverable = nil
        deselectAnnotation()
    }
    
    func deselectAnnotation() {
        baseMKMap?.deselectAnnotation(baseMKMap?.selectedAnnotations.first, animated: true)
    }
}
