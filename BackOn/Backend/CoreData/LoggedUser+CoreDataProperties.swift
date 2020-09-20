//
//  LoggedUser+CoreDataProperties.swift
//  BackOn
//
//  Created by Vincenzo Riccio on 05/08/2020.
//
//

import Foundation
import CoreData


extension LoggedUser {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LoggedUser> {
        let req = NSFetchRequest<LoggedUser>(entityName: "LoggedUser")
        req.sortDescriptors = [User.sortingDescriptor]
        return req
    }

    @NSManaged public var lastModified: Date
    @NSManaged public var email: String
    @NSManaged public var id: String
    @NSManaged public var name: String
    @NSManaged public var surname: String?
    @NSManaged public var phoneNumber: String?
    @NSManaged public var photoData: Data
    
    func populate(email: String, id: String, name: String, surname: String?, phoneNumber: String?, photoData: Data = Data(), lastModified: Date = Date()) -> LoggedUser {
        self.email = email
        self.id = id
        self.name = name
        self.surname = surname
        self.phoneNumber = phoneNumber
        self.photoData = photoData
        self.lastModified = lastModified
        return self
    }
    
    func populateTest() {
        let rand = "\(Int.random(in: 1..<100))"
        self.email = "email"+rand
        self.id = "id"+rand
        self.name = "name"+rand
        self.surname = "surname"+rand
        self.phoneNumber = "phoneNumber"+rand
        self.photoData = Data()
    }
    
}

extension LoggedUser : Identifiable {

}

extension LoggedUser {
    static func == (lhs: LoggedUser, rhs: LoggedUser) -> Bool {
        return
            lhs.id == rhs.id &&
            lhs.lastModified == rhs.lastModified
    }
}
