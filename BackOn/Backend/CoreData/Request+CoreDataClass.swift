//
//  Requests+CoreDataClass.swift
//  BackOn
//
//  Created by Vincenzo Riccio on 05/08/2020.
//
//

import Foundation
import CoreData

@objc(Request)
public class Request: NSManagedObject, Need {
    public override var description: String {return "    My request  #\(id)\n         \naccepted by  #\(helper?.id ?? "nobody")\n"}
    
    static var entity: NSEntityDescription = {
        NSEntityDescription.entity(forEntityName: "Request", in: CD.controller.context)!
    }()
    
    static var sortingDescriptor = {NSSortDescriptor(keyPath: \Request.date, ascending: true)}()
    
    //Published non funziona se la proprietà è definita in un protocollo
    var waitingForServerResponse: Bool = false {
        didSet {
            self.objectWillChange.send()
        }
    }
    
    var etaText: String? = nil {
        didSet {
            self.objectWillChange.send()
        }
    }
    
    var user: User? {return helper}
    
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
}
