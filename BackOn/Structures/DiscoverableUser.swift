//
//  UserInfo.swift
//  BackOn
//
//  Created by Riccio Vincenzo, Sorrentino Giancarlo, Triuzzi Emanuele, Zanfardino Gennaro on 11/02/2020.
//  Copyright © 2020 Riccio Vincenzo, Sorrentino Giancarlo, Triuzzi Emanuele, Zanfardino Gennaro. All rights reserved.
//

import SwiftUI

class DiscoverableUser: BaseUser {
    let id: String
    let email: String
    var name: String
    var surname: String?
    lazy var identity: String = { return "\(name) \(surname ?? "")" }()
    var phoneNumber: String?
    var lastModified: Date
    
    @Published var photo: UIImage?
    
    init(id: String, name: String, surname: String?, email: String, phoneNumber: String?, lastModified: Date) {
        self.id = id
        self.name = name
        self.surname = surname
        self.email = email
        self.phoneNumber = phoneNumber
        self.lastModified = lastModified
    }
}
