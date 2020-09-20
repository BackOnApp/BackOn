//
//  Souls.swift
//  BackOn
//
//  Created by Riccio Vincenzo, Sorrentino Giancarlo, Triuzzi Emanuele, Zanfardino Gennaro on 13/04/2020.
//  Copyright © 2020 Riccio Vincenzo, Sorrentino Giancarlo, Triuzzi Emanuele, Zanfardino Gennaro. All rights reserved.
//

import Foundation

typealias CareGiverWeight = Double
typealias HouseKeeperWeight = Double
typealias RunnerWeight = Double
typealias SmartAssistant = Double

class Souls {
    static var soulsDict: [RequestCategory:Double] = [:]
    static let weights: [RequestCategory:(CareGiverWeight, HouseKeeperWeight, RunnerWeight, SmartAssistant)] = [
        "Disabled Assistance" : (7.5, 2.5, 0, 0),
        "Elder Care" : (6.5, 3.5, 0, 0),
        "Generic Errands" : (3.5, 0, 6.5, 0),
        "Going to the Pharmacy" : (3, 0, 7, 0),
        "Grocery Shopping" : (2.5, 0, 7.5, 0),
        "Houseworks" : (2.5, 7.5, 0, 0),
        "Pet Caring" : (2.5, 5.5, 2, 0),
        "Ride to the Doctor" : (4.5, 0, 3.5, 2),
        "Sharing Time" : (5, 0, 0, 5),
        "Study Support" : (3, 0, 0, 7),
        "Tech Assistance" : (2, 0, 0, 8),
        "Wheelchair Transport" : (6.5, 0, 3.5, 0)
    ]
    static var categories = {Array<String>(Souls.weights.keys.sorted() + ["Other..."])}()
    static func setValue(category: RequestCategory, newValue: Double) {
        Souls.soulsDict[category] = newValue
    }
    
    static func calculateSuitability(discoverable: Discoverable) -> Double {
        if let currentLocation = Geo.controller.lastLocation {
            return (soulsDict[discoverable.title]!+1)/(atan(0.3 * currentLocation.distance(from: discoverable.position)/1000 + 0.45))*(0.5 + 1/sqrt(-0.5 * discoverable.date.distance(to: Date())/86400 + 0.25))
        } else{
            return soulsDict[discoverable.title]!
        }
    }
}

/*enum RequestCategories: String{
 case disabledAssistance = "Disabled Assistance"
 case elderCare = "Elder Care"
 case genericErrands = "Generic Errands"
 case goingToThePharmacy = "Going to the Pharmacy"
 case groceryShopping = "Grocery Shopping"
 case houseworks = "Houseworks"
 case petCaring = "Pet Caring"
 case rideToDoctorAppointment = "Ride to a Doctor's Appointment"
 case sharingTime = "Sharing Time"
 case studySupport = "Study Support"
 case techAssistance = "Tech Assistance"
 case wheelchairTransport = "Wheelchair Transport"
 }*/
