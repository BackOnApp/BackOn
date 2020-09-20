//
//  DatabaseController.swift
//  BackOn
//
//  Created by Riccio Vincenzo, Sorrentino Giancarlo, Triuzzi Emanuele, Zanfardino Gennaro on 18/02/2020.
//  Copyright © 2020 Riccio Vincenzo, Sorrentino Giancarlo, Triuzzi Emanuele, Zanfardino Gennaro. All rights reserved.
//

import Foundation
import CoreLocation
import SwiftUI

class DB {
    @AppStorage("deviceToken") var deviceToken: String = ""
    @AppStorage("isUserLogged") var isUserLogged: Bool = false
    static var shared = DB()
    private init(){if isUserLogged{loadFromServer()}}
    
    let cdc = CD.controller
    
    func loadFromServer() {
        print("*** DB - \(#function) ***")
        refreshSignIn(){ name, surname, photoURL, phoneNumber, error in
            guard error == nil else {print(error!); return}
            let loggedUser = CD.controller.loggedUser!
            loggedUser.name = name
            loggedUser.surname = surname
            loggedUser.phoneNumber = phoneNumber
            CD.controller.addPendingJob()
            if let photoURL = photoURL {
                DispatchQueue(label: "loadProfilePic", qos: .utility).async {
                    do {
                        print(photoURL)
                        guard let uiimage = try UIImage(data: Data(contentsOf: photoURL)) else { return }
                        DispatchQueue.main.async { loggedUser.photoData = uiimage.pngData() ?? Data() }
                        CD.controller.removePendingJob()
                    } catch {
                        print("Error while updating profile\n",error)
                        let alert = UIAlertController(title: "Something wrong with signin", message: "It seems there is a problem loading your profile.\nPlease try again later.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Got it!", style: .default))
                        UIViewController.foremost.present(alert)
                        CD.controller.removePendingJob()
                        return
                    }
                }
            }
        }
        getMyCommitments(){ tasks, requests, users, error in
            guard error == nil, var tasks = tasks, var requests = requests, var users = users else {print(error!); return} //FAI L'ALERT!
            let cdc = CD.controller
            //let now = Date()
            for task in cdc.activeTasksController.fetchedObjects! {
                let newer = tasks[task.id]
                if newer == nil { //non c'è nella risposta del server
                    cdc.safeDelete(task, save: false)
                } else {
                    task.updateIfOld(comparedTo: newer!)
                    if task.lightMapSnapData.count == 0 || task.darkMapSnapData.count == 0 {
                        task.requestSnaps()
                    }
                    tasks.removeValue(forKey: task.id)
                }
            }
            for task in cdc.expiredTasksController.fetchedObjects! {
                let newer = tasks[task.id]
                if newer == nil { //non c'è nella risposta del server
                    cdc.safeDelete(task, save: false)
                } else {
                    task.updateIfOld(comparedTo: newer!)
                    tasks.removeValue(forKey: task.id)
                }
            }
            for request in cdc.activeRequestsController.fetchedObjects! {
                let newer = requests[request.id]
                if newer == nil { //non c'è nella risposta del server
                    cdc.safeDelete(request, save: false)
                } else {
                    request.updateIfOld(comparedTo: newer!)
                    requests.removeValue(forKey: request.id)
                }
            }
            for request in cdc.expiredRequestsController.fetchedObjects! {
                let newer = requests[request.id]
                if newer == nil { //non c'è nella risposta del server
                    cdc.safeDelete(request, save: false)
                } else {
                    request.updateIfOld(comparedTo: newer!)
                    requests.removeValue(forKey: request.id)
                }
            }
            for user in cdc.usersController.fetchedObjects! {
                let newer = users[user.id]
                if newer == nil { //non c'è nella risposta del server
                    cdc.safeDelete(user, save: false)
                } else {
                    user.updateIfOld(comparedTo: newer!)
                    users.removeValue(forKey: user.id)
                }
            }
//            if MapController.lastLocation != nil { // serve solo se la posizione precisa è disponibile prima di avere i set popolati
//                shouldRequestETA = MapController.lastLocation!.horizontalAccuracy < MapController.horizontalAccuracy
//            }
            for user in users.values {
                cdc.context.insert(user)
            }
            for task in tasks.values {
                cdc.context.insert(task)
                task.requestETA()
                task.requestSnaps()
                cdc.addPendingJob()
                task.locate() {cdc.removePendingJob()}
            }
            for request in requests.values {
                cdc.context.insert(request)
                cdc.addPendingJob()
                request.locate() {cdc.removePendingJob()}
            }
            if !cdc.hasPendingJob() && cdc.context.hasChanges {cdc.safeSave()}
        }
//        discover()
    }
    
    func refreshSignIn(completion: @escaping (String, String?, URL?, String?, ErrorString?) -> Void) {
        do {
            print("*** DB - \(#function) ***")
            let parameters: [String: String?] = ["deviceToken": deviceToken, "_id": cdc.loggedUser!.id]
            let request = initJSONRequest(urlString: ServerRoutes.signUp, body: try JSONSerialization.data(withJSONObject: parameters))
            URLSession.shared.dataTask(with: request) { data, response, error in
                guard error == nil else {print("Error in " + #function + ". The error is:\n" + error!.localizedDescription); return}
                guard let responseCode = (response as? HTTPURLResponse)?.statusCode else {print("Error in \(#function). The error is:\n \(error!.localizedDescription)"); return}
                guard responseCode == 200 else {print("Bad response code in \(#function): \(responseCode)"); return}
                guard let data = data, let jsonResponse = try? JSON(data: data) else {return}
                let name = jsonResponse["name"].stringValue
                let surname = jsonResponse["surname"].string
                let photoURL = URL(string: jsonResponse["photo"].string)
                let phoneNumber = jsonResponse["phoneNumber"].string
                let caregiver = jsonResponse["caregiver"].doubleValue
                let housekeeper = jsonResponse["housekeeper"].doubleValue
                let runner = jsonResponse["runner"].doubleValue
                let smartAssistant = jsonResponse["smartassistant"].doubleValue
                //CHIEDI CHE COSA FA
                for requestType in Souls.weights.keys {
                    let weights = Souls.weights[requestType]!
                    Souls.setValue(category: requestType, newValue: caregiver * weights.0 + housekeeper * weights.1 + runner * weights.2 + smartAssistant * weights.3)
                }
                Souls.setValue(category: "Other...", newValue: caregiver * 0.25 + housekeeper * 0.25 + runner * 0.25 + smartAssistant * 0.25)
                completion(name, surname, photoURL, phoneNumber, nil)
            }.resume()
        } catch {print("Error in \(#function). The error is:\n\(error.localizedDescription)")}
    }
    
    func signUp(name: String, surname: String?, email: String, photoURL: URL, completion: @escaping (LoggedUser?, ErrorString?) -> Void) {
        do {
            print("*** DB - \(#function) ***")
            let parameters: [String: Any?] = ["name": name, "surname": surname, "email" : email, "photo": "\(photoURL)", "lastModified" : serverDateFormatter(date: Date())]
            let request = initJSONRequest(urlString: ServerRoutes.signUp, body: try JSONSerialization.data(withJSONObject: parameters))
            URLSession.shared.dataTask(with: request) { data, response, error in
                guard error == nil else {return completion(nil, "Error in " + #function + ". The error is:\n\(error!.localizedDescription)")}
                guard let responseCode = (response as? HTTPURLResponse)?.statusCode else {return completion(nil,"Error in \(#function). Invalid response!")}
                guard responseCode == 200 else {return completion(nil, "Bad response code in \(#function): \(responseCode)")}
                guard let data = data, let jsonResponse = try? JSON(data: data) else {return completion(nil, "Error with returned data in \( #function)")}
                let id = jsonResponse["_id"].stringValue
                //NELLA RISPOSTA CI DEVE ESSERE IL NUMERO DI TELEFONO, CONTROLLA
                let loggedUser = LoggedUser(context: self.cdc.context).populate(email: email, id: id, name: name, surname: surname, phoneNumber: nil)
                DispatchQueue(label: "loadProfilePic", qos: .utility).async {
                    do {
                        guard let uiimage = try UIImage(data: Data(contentsOf: photoURL)) else { return }
                        loggedUser.photoData = uiimage.pngData() ?? Data()
                        try self.cdc.context.save()
                    } catch {
                        //FALLA NELLA COMPLETION LA GESTIONE DEGLI ERRORI!
                        self.isUserLogged = false
                        print("Error while updating profile\n",error)
                        let alert = UIAlertController(title: "Something wrong with signin", message: "It seems there is a problem loading your profile picture.\nPlease try again later.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Got it!", style: .default))
                        UIViewController.foremost.present(alert)
                        return
                    }
                }
                completion(loggedUser, nil)
            }.resume()
        } catch let error {completion(nil, "Error in " + #function + ". The error is:\n" + error.localizedDescription)}
    }
    
    func logout(completion: @escaping (ErrorString?) -> Void) {
        do {
            print("*** DB - \(#function) ***")
            let parameters: [String: Any?] = ["_id": cdc.loggedUser!.id, "logoutToken" : deviceToken]
            let request = initJSONRequest(urlString: ServerRoutes.updateProfile, body: try JSONSerialization.data(withJSONObject: parameters))
            URLSession.shared.dataTask(with: request) { data, response, error in
                guard error == nil else {return completion("Error in " + #function + ". The error is:\n \(error!.localizedDescription)")}
                guard let responseCode = (response as? HTTPURLResponse)?.statusCode else {return completion("Error in \(#function). Invalid response!")}
                guard responseCode == 200 else {return completion("Bad response code in \(#function): \(responseCode)")}
                completion(nil)
            }.resume()
        } catch let error {completion("Error in \(#function). The error is:\n \(error.localizedDescription)")}
    }
    
    func getMyCommitments(completion: @escaping ([String:Task]?, [String:Request]?, [String:User]?, ErrorString?) -> Void) {
        do {
            print("*** DB - \(#function) ***")
            let parameters: [String: String] = ["_id": cdc.loggedUser!.id]
            let request = initJSONRequest(urlString: ServerRoutes.getMyBonds, body: try JSONSerialization.data(withJSONObject: parameters))
            URLSession.shared.dataTask(with: request) { data, response, error in
                guard error == nil else {return completion(nil,nil,nil,"Error in \(#function). The error is:\n\(error!.localizedDescription)")}
                guard let responseCode = (response as? HTTPURLResponse)?.statusCode else {return completion(nil,nil,nil,"Error in \(#function). Invalid response!")}
                guard responseCode == 200 else {return completion(nil,nil,nil,"Bad response code in \(#function): \(responseCode)")}
                guard let data = data, let jsonTasksAndRequests = try? JSON(data: data) else {return completion(nil,nil,nil,"Error with returned data in \(#function)")}
                var tasksJSONArray = jsonTasksAndRequests["tasks"].arrayValue
                var requestsJSONArray = jsonTasksAndRequests["requests"].arrayValue
                var taskDict: [String:Task] = [:]
                var requestDict: [String:Request] = [:]
                var userDict: [String:User] = [:]
                self.parseJSONArray(jsonArray: &tasksJSONArray, needDict: &taskDict, userDict: &userDict)
                self.parseJSONArray(jsonArray: &requestsJSONArray, needDict: &requestDict, userDict: &userDict)
                completion(taskDict, requestDict, userDict, nil)
            }.resume()
        } catch let error {completion(nil,nil,nil,"Error in \(#function). The error is:\n\(error.localizedDescription)")}
    }
    
    func discover(/*completion: @escaping ([String:Discoverable]?, [String:DiscoverableUser]?, ErrorString?) -> Void*/) {
        guard let lastLocation = Geo.controller.lastLocation else { print("Location Disabled: no discover"); return }
        do {
            print("*** DB - \(#function) ***")
            DispatchQueue.main.async { Discover.controller.canLoadAroundYouMap = false }
            let parameters: [String: Any?] = ["_id": cdc.loggedUser!.id, "longitude": lastLocation.coordinate.longitude, "latitude": lastLocation.coordinate.latitude]
            let request = initJSONRequest(urlString: ServerRoutes.discover, body: try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted))
            URLSession.shared.dataTask(with: request) { data, response, error in
                guard error == nil else {print(error!); return}
                guard let responseCode = (response as? HTTPURLResponse)?.statusCode else {print("Invalid response in \(#function)!"); return}
                guard responseCode == 200 else {print("Bad response code in \(#function): \(responseCode)"); return}
                guard let data = data, var jsonDiscoverables = try? JSON(data: data).arrayValue else {print("Error with returned data in \(#function)"); return}
                var discoverables: [String:Discoverable] = [:]
                var users: [String:DiscoverableUser] = [:]
                self.parseJSONArray(jsonArray: &jsonDiscoverables, needDict: &discoverables, userDict: &users)
                let now = Date()
                for discoverable in discoverables.values {
                    if discoverable.date > now {
                        DispatchQueue.main.async { Discover.controller.discoverables[discoverable.id] = discoverable }
                    }
                }
                DispatchQueue.main.async { Discover.controller.canLoadAroundYouMap = true }
            }.resume()
        } catch {print(error)}
    }
    
    func addRequest(request: Request, completion: @escaping (String?, ErrorString?) -> Void) { // (id, error)
        do {
            print("*** DB - \(#function) ***")
            let parameters: [String: Any?] = ["title": request.title, "description": request.descr, "neederID" : cdc.loggedUser!.id, "date": serverDateFormatter(date: request.date), "latitude": request.position.latitude, "longitude": request.position.longitude, "lastModified" : serverDateFormatter(date: Date())]
            let request = initJSONRequest(urlString: ServerRoutes.addRequest, body: try JSONSerialization.data(withJSONObject: parameters))
            URLSession.shared.dataTask(with: request) { data, response, error in
                guard error == nil else {return completion(nil, "Error in \(#function). The error is:\n\(error!.localizedDescription)")}
                guard let responseCode = (response as? HTTPURLResponse)?.statusCode else {return completion(nil,"Error in \(#function). Invalid response!")}
                guard responseCode == 200 else {return completion(nil,"Response code != 200 in \(#function): \(responseCode)")}
                guard let data = data, let jsonResponse = try? JSON(data: data) else {return completion(nil, "Error with returned data in \(#function)")}
                let _id = jsonResponse["_id"].stringValue
                completion(_id, nil)
            }.resume()
        } catch let error {completion(nil, "Error in " + #function + ". The error is:\n" + error.localizedDescription)}
    } //Error handling missing, but should work
    
    func acceptDiscoverable(toAccept: Discoverable, completion: @escaping (ErrorString?) -> Void) {
        do {
            print("*** DB - \(#function) ***")
            let parameters: [String: String] = ["_id": toAccept.id, "helperID": cdc.loggedUser!.id, "lastModified" : serverDateFormatter(date: Date())]
            let request = initJSONRequest(urlString: ServerRoutes.addTask, body: try JSONSerialization.data(withJSONObject: parameters), httpMethod: "PUT")
            URLSession.shared.dataTask(with: request) { data, response, error in
                guard error == nil else {return completion("Error in \(#function). The error is:\n\(error!.localizedDescription)")}
                guard let responseCode = (response as? HTTPURLResponse)?.statusCode else {return completion("Error in \(#function). Invalid response!")}
                guard responseCode == 200 else {return completion("Bad response code in \(#function): \(responseCode)")}
                self.sendPushNotification(receiverID: toAccept.needer.id, title: "Good news!", body: "Your \(toAccept.title) request has been accepted!")
                completion(nil)
            }.resume()
        } catch let error {completion("Error in \(#function). The error is:\n\(error.localizedDescription)")}
    } //Error handling missing, but should work
    
    func reportTask<Content:Need>(need: Content, report: String, completion: @escaping (ErrorString?) -> Void) {
        let helperToReport = need is Request ? true : false
        do {
            print("*** DB - \(#function) ***")
            let parameters: [String: Any] = ["_id" : need.id, (helperToReport ? "helperReport" : "neederReport") : report, "lastModified" : serverDateFormatter(date: Date())]
            let request = initJSONRequest(urlString: ServerRoutes.reportTask, body: try JSONSerialization.data(withJSONObject: parameters), httpMethod: "PUT")
            URLSession.shared.dataTask(with: request) { data, response, error in
                guard error == nil else {return completion("Error in \(#function). The error is:\n\(error!.localizedDescription)")}
                guard let responseCode = (response as? HTTPURLResponse)?.statusCode else {return completion("Error in \(#function). Invalid response!")}
                guard responseCode == 200 else {return completion("Bad response code in \(#function): \(responseCode)")}
                completion(nil)
            }.resume()
        } catch let error {completion("Error in \(#function). The error is:\n\(error.localizedDescription)")}
    }
    
    func updateProfile(newName: String, newSurname: String, newPhoneNumber: String, newImageEncoded: String? = nil, completion: @escaping (Int, ErrorString?) -> Void) {
        do {
            print("*** DB - \(#function) ***")
            var parameters: [String: Any] = ["_id" : cdc.loggedUser!.id, "lastModified" : serverDateFormatter(date: Date())]
            if newName != cdc.loggedUser!.name {parameters["name"] = newName}
            if newSurname != cdc.loggedUser!.surname {parameters["surname"] = newSurname}
            if newPhoneNumber != cdc.loggedUser!.phoneNumber {parameters["phoneNumber"] = newPhoneNumber}
            if (newImageEncoded != nil) {parameters["photo"] = newImageEncoded}
            let request = initJSONRequest(urlString: ServerRoutes.updateProfile, body: try JSONSerialization.data(withJSONObject: parameters))
            URLSession.shared.dataTask(with: request) { data, response, error in
                guard error == nil else {return completion(400, "Error in \(#function). The error is:\n\(error!.localizedDescription)")}
                guard let responseCode = (response as? HTTPURLResponse)?.statusCode else {return completion(400, "Error in \(#function). Invalid response!")}
                completion(responseCode, responseCode == 400 ? "Server function returned 400" : nil)
            }.resume()
        } catch let error {completion(400, "Error in \(#function). The error is:\n" + error.localizedDescription)}
    }
    
    func removeNeed<Content:Need>(toRemove: Content, completion: @escaping (ErrorString?) -> Void) {
        var isRequest = true
        if toRemove is Task {isRequest = false}
        do {
            let parameters: [String: String] = ["_id": toRemove.id, "lastModified" : serverDateFormatter(date: Date())]
            let request = initJSONRequest(urlString: isRequest ? ServerRoutes.removeRequest : ServerRoutes.removeTask, body: try JSONSerialization.data(withJSONObject: parameters), httpMethod: isRequest ? "DELETE" : "PUT")
            URLSession.shared.dataTask(with: request) { data, response, error in
                guard error == nil else {return completion("Error in \(#function) opering with a \(isRequest ? "request" : "task"). The error is:\n\(error!.localizedDescription)")}
                guard let responseCode = (response as? HTTPURLResponse)?.statusCode else {return completion("Error in \(#function). Invalid response!")}
                guard responseCode == 200 else {return completion("Bad response code in \(#function): \(responseCode)")}
                self.sendPushNotification(receiverID: toRemove.user?.id, title: isRequest ? "Don't worry!" : "Oh no! \(self.cdc.loggedUser!.name) can't help you anymore", body: isRequest ? "\(self.cdc.loggedUser!.name) doesn't need your help anymore.\nThanks anyway for your care!" : "Wait for someone else to accept your \(toRemove.title) request.")
                completion(nil)
            }.resume()
        } catch let error {completion("Error in \(#function) opering with a \(isRequest ? "request" : "task"). The error is:\n" + error.localizedDescription)}
    }
    
    private func sendPushNotification(receiverID: String?, title: String, body: String) {
        guard let receiverID = receiverID else {return}
        do {
            print("*** DB - \(#function) ***")
            //print ("Receiver ID: \(receiverID)")
            let parameters: [String: String] = ["receiverID": receiverID, "title": title, "body": body]
            let request = initJSONRequest(urlString: ServerRoutes.sendNotification, body: try JSONSerialization.data(withJSONObject: parameters))
            URLSession.shared.dataTask(with: request) { data, response, error in
                guard error == nil else {print("Error in " + #function + ". The error is:\n" + error!.localizedDescription); return}
                guard let responseCode = (response as? HTTPURLResponse)?.statusCode else {print("Error in \(#function). The error is:\n" + error!.localizedDescription); return}
                guard responseCode == 200 else {print("Invalid response code in \(#function): \(responseCode)"); return}
            }.resume()
        } catch {print("Error in \(#function). The error is:\n" + error.localizedDescription)}
    }
    
    private func parseJSONArray<Content:Need, GenericUser:BaseUser>(jsonArray: inout [JSON], needDict: inout [String:Content], userDict: inout [String:GenericUser]) {
        let myID = cdc.loggedUser!.id
        for current: JSON in jsonArray {
            let neederID = current["neederID"].stringValue
            let helperID = current["helperID"].string
            let helperReport = current["helperReport"].string
            let neederReport = current["neederReport"].string
            guard (myID != neederID && myID != helperID) || (myID == neederID && helperReport == nil) || (myID == helperID && neederReport == nil) else {continue}
            let title = current["title"].stringValue
            let descr = current["description"].string
            let date = serverDateFormatter(date: current["date"].stringValue)
            let latitude = current["location"]["coordinates"][1].doubleValue
            let longitude = current["location"]["coordinates"][0].doubleValue
            let id = current["_id"].stringValue
            let user = current["user"].arrayValue.first
            
            var userID: String?
            var userName: String?
            var userSurname: String?
            var userEmail: String?
            var userPhotoURL: URL?
            var userPhoneNumber: String?
            var newUser: User?
            var newDiscoverableUser: DiscoverableUser?
            
            if user != nil {
                userID = user!["_id"].stringValue
                if userDict[userID!] == nil {
                    userName = user!["name"].stringValue
                    userSurname = user!["surname"].string
                    userEmail = user!["email"].stringValue
                    userPhotoURL = URL(string: user!["photo"].stringValue)
                    userPhoneNumber = user!["phoneNumber"].string
                    if type(of: userDict).Value is User.Type {
                        newUser = User(entity: User.entity, insertInto: nil).populate(email: userEmail!, id: userID!, name: userName!, surname: userSurname, phoneNumber: userPhoneNumber)
                        newUser?.loadPhoto(from: userPhotoURL)
                    } else {
                        newDiscoverableUser = DiscoverableUser(id: userID!, name: userName!, surname: userSurname, email: userEmail!, photoURL: userPhotoURL, phoneNumber: userPhoneNumber)
                    }
                } else {
                    if type(of: userDict).Value is User.Type {
                        newUser = (userDict[userID!]! as! User)
                    } else {
                        newDiscoverableUser = (userDict[userID!]! as! DiscoverableUser)
                    }
                }
            }
            if type(of: needDict).Value is Task.Type && newUser != nil {
                let task = Task(entity: Task.entity, insertInto: nil).populate(id: id, needer: newUser!, title: title, descr: descr, latitude: latitude, longitude: longitude, date: date)
                newUser!.addToAccepted(task)
                needDict[id] = (task as! Content)
                userDict[newUser!.id] = (newUser! as! GenericUser)
            } else if type(of: needDict).Value is Request.Type {
                let request = Request(entity: Request.entity, insertInto: nil).populate(id: id, helper: newUser, title: title, descr: descr, latitude: latitude, longitude: longitude, date: date)
                newUser?.addToRequested(request)
                needDict[id] = (request as! Content)
                if newUser != nil { userDict[newUser!.id] = (newUser! as! GenericUser) }
            } else if newDiscoverableUser != nil {
                let discoverable = Discoverable(needer: newDiscoverableUser!, title: title, date: date, latitude: latitude, longitude: longitude, id: id)
                needDict[id] = (discoverable as! Content)
                userDict[newDiscoverableUser!.id] = (newDiscoverableUser as! GenericUser)
            }
        }
    }
    
    private func initJSONRequest(urlString: String, body: Data, httpMethod: String = "POST") -> URLRequest {
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = httpMethod
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = body
        //request.setValue("close", forHTTPHeaderField: "Connection")
        return request
    }
    
    private func serverDateFormatter(date: String) -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        if let parsedDate = formatter.date(from: date) {
            return parsedDate
        }
        return Date()
    }
    
    private func serverDateFormatter(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return formatter.string(from: date)
    }
    
    
}

//static func updateCathegories(lastUpdate: Date) {
//    //Chiede l'ultima data di aggiornamento delle categorie di request al db e, se diversa da quella che ha internamente, richiede al db di inviarle e le aggiorna
//    //Apro la connessione, ottengo la data, se diversa faccio la richiesta altrimenti chiudo
//}
