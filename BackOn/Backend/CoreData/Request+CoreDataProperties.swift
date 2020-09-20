//
//  Requests+CoreDataProperties.swift
//  BackOn
//
//  Created by Vincenzo Riccio on 05/08/2020.
//
//

import Foundation
import CoreData


extension Request {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Request> {
        return NSFetchRequest<Request>(entityName: "Request")
    }
    
    @nonobjc public class func requestActive() -> NSFetchRequest<Request> {
        let req = NSFetchRequest<Request>(entityName: "Request")
        req.sortDescriptors = [Request.sortingDescriptor]
        req.predicate = activePredicate
        return req
    }
    
    @nonobjc public class func requestExpired() -> NSFetchRequest<Request> {
        let req = NSFetchRequest<Request>(entityName: "Request")
        req.sortDescriptors = [Request.sortingDescriptor]
        req.predicate = expiredPredicate
        return req
    }
    
    @NSManaged public var lastModified: Date
    @NSManaged public var id: String
    @NSManaged public var title: String
    @NSManaged public var descr: String?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var date: Date
    @NSManaged public var address: String
    @NSManaged public var helper: User?
    
    
    func populate(id: String, helper: User? = nil, title: String, descr: String? = nil, latitude: Double, longitude: Double, date: Date, address: String = "", lastModified: Date = Date()) -> Request {
        self.id = id
        self.helper = helper
        self.title = title
        self.descr = descr
        self.latitude = latitude
        self.longitude = longitude
        self.date = date
        self.address = address
        self.lastModified = lastModified
        return self
    }
}

extension Request : Identifiable {

}

extension Request {
    static func == (lhs: Request, rhs: Request) -> Bool {
        return lhs.id == rhs.id
    }
    
    func updateIfOld(comparedTo newer: Request) {
        guard lastModified != newer.lastModified else {return}
        print("devo aggiornare \(self)")
        lastModified = newer.lastModified
        if title != newer.title {title = newer.title}
        if descr != newer.descr {descr = newer.descr}
        if latitude != newer.latitude {latitude = newer.latitude}
        if longitude != newer.longitude {longitude = newer.longitude}
        if date != newer.date {date = newer.date}
        if helper != newer.helper {
            if newer.helper != nil {
                helper = newer.helper!
                newer.helper!.addToRequested(self)
            } else {
                helper = nil
            }
        }
    }
}
