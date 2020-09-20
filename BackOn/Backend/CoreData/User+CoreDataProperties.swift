//
//  User+CoreDataProperties.swift
//  BackOn
//
//  Created by Vincenzo Riccio on 05/08/2020.
//
//

import Foundation
import CoreData
import UIKit

extension User {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        let req = NSFetchRequest<User>(entityName: "User")
        req.sortDescriptors = [User.sortingDescriptor]
        return req
    }
    
    @nonobjc public class func requestUseless() -> NSFetchRequest<User> {
        let req = NSFetchRequest<User>(entityName: "User")
        req.predicate = NSPredicate(format: "accepted.@count == 0 AND requested.@count == 0")
        req.sortDescriptors = [User.sortingDescriptor]
        return req
    }

    @NSManaged public var email: String
    @NSManaged public var id: String
    @NSManaged public var name: String
    @NSManaged public var surname: String?
    @NSManaged public var phoneNumber: String?
    @NSManaged public var photoData: Data
    @NSManaged public var lastModified: Date
    @NSManaged public var accepted: NSSet
    @NSManaged public var requested: NSSet
    
    func populate(email: String, id: String, name: String, surname: String?, phoneNumber: String?, photoData: Data = Data(), lastModified: Date) -> User {
        self.email = email
        self.id = id
        self.name = name
        self.surname = surname
        self.phoneNumber = phoneNumber
        self.photoData = photoData
        self.lastModified = lastModified
        return self
    }
}

// MARK: Generated accessors for accepted
extension User {

    @objc(addAcceptedObject:)
    @NSManaged public func addToAccepted(_ value: Task)

    @objc(removeAcceptedObject:)
    @NSManaged public func removeFromAccepted(_ value: Task)

    @objc(addAccepted:)
    @NSManaged public func addToAccepted(_ values: NSSet)

    @objc(removeAccepted:)
    @NSManaged public func removeFromAccepted(_ values: NSSet)

}

// MARK: Generated accessors for requested
extension User {

    @objc(addRequestedObject:)
    @NSManaged public func addToRequested(_ value: Request)

    @objc(removeRequestedObject:)
    @NSManaged public func removeFromRequested(_ value: Request)

    @objc(addRequested:)
    @NSManaged public func addToRequested(_ values: NSSet)

    @objc(removeRequested:)
    @NSManaged public func removeFromRequested(_ values: NSSet)

}

extension User : Identifiable {
}

extension User {
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
    
    func updateIfOld(comparedTo newer: User) {
        guard lastModified != newer.lastModified else {return}
        print("devo aggiornare \(self)")
        lastModified = newer.lastModified
        if name != newer.name {name = newer.name}
        if surname != newer.surname {surname = newer.surname}
        if phoneNumber != newer.phoneNumber {phoneNumber = newer.phoneNumber}
        if let photoURL = newer.photoURL {
            CD.controller.addPendingJob()
            self.downloadPhoto(photoURL) {_ in CD.controller.removePendingJob()}
        }
    }
}
