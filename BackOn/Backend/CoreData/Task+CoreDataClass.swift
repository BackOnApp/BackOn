//
//  PTasks+CoreDataClass.swift
//  BackOn
//
//  Created by Vincenzo Riccio on 05/08/2020.
//
//

import Foundation
import CoreData
import CoreLocation
import SwiftUI

@objc(Task)
public class Task: NSManagedObject, Need {
    public override var description: String {return "    Request  #\(id)\n         of  #\(needer.id)\naccepted by me\n"}
    
    static var entity: NSEntityDescription = {
        NSEntityDescription.entity(forEntityName: "Task", in: CD.controller.context)!
    }()
    
    static var sortingDescriptor = {NSSortDescriptor(keyPath: \Task.date, ascending: true)}()
    
    var etaText: String? = nil {
        didSet {
            self.objectWillChange.send()
        }
    }
    
    //Published non funziona se la proprietà è definita in un protocollo
    var waitingForServerResponse: Bool = false {
        didSet {
            self.objectWillChange.send()
        }
    }
    
    var helperReport: String?
    var neederReport: String?
    
    var user: User? {return needer}
    
    lazy var position: CLLocationCoordinate2D = {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }()
    
    lazy var city: String = {
        let splitted = address.split(separator: ",")
        var city: String?
        if splitted.count == 2 { city = "\(splitted[1])"} //+2 se riaggiungi CAP e Stato
        if splitted.count == 3 { city = "\(splitted[2])"}
        if city == nil { city = "Incorrect city" }
        return city!
    }()
    
    func matchingSnap(colorScheme: ColorScheme, width: CGFloat = 320, height: CGFloat = 350) -> some View {
        if colorScheme == .dark {
            return Image(mapSnapData: darkMapSnapData).resizable().frame(width: width, height: height).scaledToFill()
        } else {
            return Image(mapSnapData: lightMapSnapData).resizable().frame(width: width, height: height).scaledToFill()
        }
    }
    
    func requestSnaps() {
        CD.controller.addPendingJob()
        Geo.controller.getSnapshot(location: position, style: .dark){ snapshot, error in
            if error == nil, let data = snapshot?.image.pngData() {
                self.darkMapSnapData = data
            } else {print("Error while requesting dark snapshot")}
            CD.controller.removePendingJob()
        }
        CD.controller.addPendingJob()
        Geo.controller.getSnapshot(location: position, style: .light){ snapshot, error in
            if error == nil, let data = snapshot?.image.pngData() {
                self.lightMapSnapData = data
            } else {print("Error while requesting light snapshot")}
            CD.controller.removePendingJob()
        }
    }
}
