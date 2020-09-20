//
//  Discoverable.swift
//  BackOn
//
//  Created by Riccio Vincenzo, Sorrentino Giancarlo, Triuzzi Emanuele, Zanfardino Gennaro on 11/02/2020.
//  Copyright © 2020 Riccio Vincenzo, Sorrentino Giancarlo, Triuzzi Emanuele, Zanfardino Gennaro. All rights reserved.
//

import CoreLocation
import MapKit

class Discoverable: Need {
    @Published var needer: DiscoverableUser
    var title: String
    var descr: String?
    var date: Date
    var position: CLLocationCoordinate2D
    var id: String
    var suitability: Double {return Souls.calculateSuitability(discoverable: self)}
    var user: DiscoverableUser? {return needer}
    var lastModified: Date
    
    @Published var waitingForServerResponse = false
    var etaText: String? {
        didSet {
            self.objectWillChange.send()
        }
    }
    @Published var address = "Locating..."
    @Published var city = "Locating..."
        
    public var description: String {return "    Request  #\(id)\n         of  #\(needer)\n"}
    
    init(needer: DiscoverableUser, title: String, descr: String? = nil, date: Date, latitude: Double, longitude: Double, id: String, lastModified: Date) {
        self.needer = needer
        self.title = title
        self.descr = descr
        self.date = date
        self.id = id
        self.position = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.lastModified = lastModified
        self.locate()
//        self.requestETA()
    }
    
    func timeRemaining() -> TimeInterval {
        return date.timeIntervalSinceNow
    }
}
