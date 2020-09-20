//
//  PTasks+CoreDataProperties.swift
//  BackOn
//
//  Created by Vincenzo Riccio on 05/08/2020.
//
//

import Foundation
import CoreData


extension Task {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Task> {
        return NSFetchRequest<Task>(entityName: "Task")
    }
    
    @nonobjc public class func requestActive() -> NSFetchRequest<Task> {
        let req = NSFetchRequest<Task>(entityName: "Task")
        req.sortDescriptors = [Task.sortingDescriptor]
        req.predicate = activePredicate
        return req
    }
    
    @nonobjc public class func requestExpired() -> NSFetchRequest<Task> {
        let req = NSFetchRequest<Task>(entityName: "Task")
        req.sortDescriptors = [Task.sortingDescriptor]
        req.predicate = expiredPredicate
        return req
    }
    
    @NSManaged public var id: String
    @NSManaged public var title: String
    @NSManaged public var descr: String?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var date: Date
    @NSManaged public var lastModified: Date
    @NSManaged public var address: String
    @NSManaged public var lightMapSnapData: Data
    @NSManaged public var darkMapSnapData: Data
    @NSManaged public var needer: User
    
    func populate(id: String, needer: User, title: String, descr: String? = nil, latitude: Double, longitude: Double, date: Date, address: String = "", lightMapSnapData: Data = Data(), darkMapSnapData: Data = Data(), lastModified: Date) -> Task {
        self.id = id
        self.needer = needer
        self.title = title
        self.descr = descr
        self.latitude = latitude
        self.longitude = longitude
        self.date = date
        self.address = address
        self.lightMapSnapData = lightMapSnapData
        self.darkMapSnapData = darkMapSnapData
        self.lastModified = lastModified
        return self
    }
}

extension Task : Identifiable {

}

extension Task {
    static func == (lhs: Task, rhs: Task) -> Bool {
        return lhs.id == rhs.id
    }
    
    func updateIfOld(comparedTo newer: Task) {
        guard lastModified != newer.lastModified else {return}
        print("devo aggiornare \(self)")
        lastModified = newer.lastModified
        if title != newer.title {title = newer.title}
        if descr != newer.descr {descr = newer.descr}
        if latitude != newer.latitude {latitude = newer.latitude}
        if longitude != newer.longitude {longitude = newer.longitude}
        if date != newer.date {date = newer.date}
//        needer.updateIfOld(comparedTo: newer.needer)
    }
}
