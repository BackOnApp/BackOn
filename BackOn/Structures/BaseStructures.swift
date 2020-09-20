//
//  BaseStructures.swift
//  BackOn
//
//  Created by Vincenzo Riccio on 04/09/2020.
//

import SwiftUI
import CoreLocation
import Combine

enum needType {
    case task
    case request
    case discoverable
}

protocol BaseUser: ObservableObject, CustomStringConvertible {
    var id: String { get }
    var email: String { get }
    var name: String { get set }
    var surname: String? { get set }
    var identity: String { get }
    var phoneNumber: String? { get set }
    var photo: UIImage? { get set }
    var lastModified: Date { get set }
}

extension BaseUser {
    public var description: String {return "\(identity) - #\(id)\n"}
    
    func avatar(size: CGFloat = 75) -> some View {
        Group {
            if photo == nil {
                Image(systemName: "person").resizable().scaleEffect(0.5).offset(y: -2)
                //Image("NobodyIcon").resizable()
            } else {
                Image(uiImage: photo!).resizable()
            }
        }
        .scaledToFit()
        .frame(width: size, height: size)
        .background(Color.white)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white, lineWidth: 1))
        .orange()
    }
    
    func downloadPhoto(_ url: URL?, completion: @escaping (String?) -> Void = {_ in}) {
        if url != nil {
            DispatchQueue(label: "loadProfilePic", qos: .utility).async {
                guard let uiimage = try? UIImage(data: Data(contentsOf: url!)), let data = uiimage.pngData() else { return completion("Error while loading profile pic") }
                if self is DiscoverableUser && self.photo != uiimage {
                    self.photo = uiimage
                } else if self is LoggedUser {
                    let savedData = (self as! LoggedUser).photoData
                    if savedData != data {(self as! LoggedUser).photoData = data}
                } else if self is User {
                    let savedData = (self as! User).photoData
                    if savedData != data {(self as! User).photoData = data}
                } else { return completion("Error while loading profile pic") }
                return completion(nil)
            }
        } else {
            if self is LoggedUser {
                (self as! LoggedUser).photoData = Data()
            } else if self is User {
                (self as! User).photoData = Data()
            }
            return completion(nil)
        }
    }
}

class NobodyAccepted: BaseUser {
    var id: String = "nobodyID"
    var email: String = "nobodyEMAIL"
    var name: String = "Nobody accepted"
    var surname: String? = nil
    var lastModified: Date = Date()
    lazy var identity: String = { return "Nobody accepted" }()
    var phoneNumber: String? = nil
    public var description: String {return "Nobody accepted\n"}
    var photo: UIImage? = UIImage(named: "NobodyIcon")?.withTintColor(.systemOrange)
    static var instance = NobodyAccepted()
}

protocol Need: ObservableObject, CustomStringConvertible, Identifiable {
    associatedtype GenericUser where GenericUser:BaseUser
    var user: GenericUser? { get }
    var title: String { get set }
    var descr: String? { get set }
    var date: Date { get set }
    var id: String { get set }
    var waitingForServerResponse: Bool { get set }
    var address: String { get set }
    var city: String { get set }
    var position: CLLocationCoordinate2D { get set }
    var etaText: String? { get set }
    var lastModified: Date { get set }
}

extension Need {
    func isExpired() -> Bool {
        return date < Date()
    }
    
    func locate(action: @escaping () -> Void = {}) {
        Geo.controller.coordinatesToAddress(self.position) { result, error in
            guard error == nil, let result = result else {action();return}
            self.address = result
            let splitted = result.split(separator: ",")
            if splitted.count == 2 { self.city = "\(splitted[1])"} // +2 se riaggiungi CAP e Paese
            if splitted.count == 3 { self.city = "\(splitted[2])"}
            action()
        }
    }
    
    func requestETA() {
        Geo.controller.requestETA(destination: position) { (eta, error) in
            if error != nil {self.etaText = eta}
        }
    }
}
