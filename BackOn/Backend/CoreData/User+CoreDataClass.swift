//
//  User+CoreDataClass.swift
//  BackOn
//
//  Created by Vincenzo Riccio on 05/08/2020.
//
//

import Foundation
import CoreData
import UIKit

@objc(User)
public class User: NSManagedObject, BaseUser {
    override public var description: String {return "\(identity) - #\(id)\n"}
    
    static var sortingDescriptor = { NSSortDescriptor(keyPath: \User.name, ascending: true) }()
    
    static var entity: NSEntityDescription = { NSEntityDescription.entity(forEntityName: "User", in: CD.controller.context)! }()
    
    lazy var identity: String = { return "\(name) \(surname ?? "")" }()
    
    lazy var photo: UIImage? = { return UIImage(data: photoData) }()
    
    var photoURL: URL?
}
