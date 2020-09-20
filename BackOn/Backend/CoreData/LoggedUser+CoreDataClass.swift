//
//  LoggedUser+CoreDataClass.swift
//  BackOn
//
//  Created by Vincenzo Riccio on 05/08/2020.
//
//

import Foundation
import CoreData
import UIKit

@objc(LoggedUser)
public class LoggedUser: NSManagedObject, BaseUser {
    
    override public var description: String {return "\(identity) - #\(id)\n"}
    
    static var entity: NSEntityDescription = {
        NSEntityDescription.entity(forEntityName: "LoggedUser", in: CD.controller.context)!
    }()
    
    lazy var identity: String = { return "\(name) \(surname ?? "")" }()
    
    lazy var photo: UIImage? = {return UIImage(data: photoData)}()
}
