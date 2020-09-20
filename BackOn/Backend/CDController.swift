//
//  CoreDataController.swift
//  BackOn
//
//  Created by Vincenzo Riccio on 05/08/2020.
//

import Foundation
import CoreData
import SwiftUI
import Combine

let expiredPredicate = NSPredicate(format: "date < %@", NSDate())
let activePredicate = NSPredicate(format: "date >= %@", NSDate())

class CD: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
    static var controller = CD()
    let context: NSManagedObjectContext
    let activeTasksController: NSFetchedResultsController<Task>
    let expiredTasksController: NSFetchedResultsController<Task>
    let activeRequestsController: NSFetchedResultsController<Request>
    let expiredRequestsController: NSFetchedResultsController<Request>
    let usersController: NSFetchedResultsController<User>
    let loggedUserController: NSFetchedResultsController<LoggedUser>
    @Published var loggedUser: LoggedUser?
    @Published var pendingRequests: [Request] = []
    
    private var pendingJobs: Int = 0 {
        didSet {
            if pendingJobs == 0 && context.hasChanges {
                safeSave()
            }
            if pendingJobs < 0 {pendingJobs = 0}
        }
    }
    func hasPendingJob() -> Bool {return pendingJobs != 0}
    func addPendingJob() {DispatchQueue.main.async {self.pendingJobs += 1}}
    func removePendingJob() {DispatchQueue.main.async {self.pendingJobs -= 1}}
    
    //Serve a fare una publish quando uno dei NSFetchedResultsController rileva una modifica
//    @Published var objectWillChange = PassthroughSubject<Void, Never>()
    
    override private init() {
        let modelURL = Bundle.main.url(forResource: "BackOn", withExtension: "momd")!
        let model = NSManagedObjectModel(contentsOf: modelURL)!
        let psc = NSPersistentStoreCoordinator(managedObjectModel: model)
        let dirURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last
        let fileURL = URL(string: "BackOn.sql", relativeTo: dirURL)!
        try! psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: fileURL, options: nil)
        context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = psc
        
        activeTasksController = NSFetchedResultsController(fetchRequest: Task.requestActive(), managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        expiredTasksController = NSFetchedResultsController(fetchRequest: Task.requestExpired(), managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        activeRequestsController = NSFetchedResultsController(fetchRequest: Request.requestActive(), managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        expiredRequestsController = NSFetchedResultsController(fetchRequest: Request.requestExpired(), managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        usersController = NSFetchedResultsController(fetchRequest: User.fetchRequest(), managedObjectContext: context, sectionNameKeyPath: nil, cacheName: "users")
        loggedUserController = NSFetchedResultsController(fetchRequest: LoggedUser.fetchRequest(), managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        super.init()
        activeTasksController.delegate = self
        expiredTasksController.delegate = self
        activeRequestsController.delegate = self
        expiredRequestsController.delegate = self
        usersController.delegate = self
        loggedUserController.delegate = self
        
        try! activeTasksController.performFetch()
        try! expiredTasksController.performFetch()
        try! activeRequestsController.performFetch()
        try! expiredRequestsController.performFetch()
        try! usersController.performFetch()
        try! loggedUserController.performFetch()
        
        loggedUser = loggedUserController.fetchedObjects!.first
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        DispatchQueue.main.async { self.objectWillChange.send() }
    }
    
    func safeSave() {
        if context.hasChanges {
//            context.performAndWait {
            DispatchQueue.main.async { try? self.context.save() }
//            }
        }
    }
    
    func safeDelete(_ object: NSManagedObject?, save: Bool = true) {
        if object != nil {
//            context.performAndWait {
                self.context.delete(object!)
//            }
            if save {self.safeSave()}
        }
    }
    
    func insertIfNotPresent(_ object: NSManagedObject?, save: Bool = true) {
        if object != nil && !object!.isInserted {
//            context.performAndWait {
                self.context.insert(object!)
//            }
            if save {self.safeSave()}
        }
    }
    
    func deleteAll() {
        for elem in activeTasksController.fetchedObjects! {
            safeDelete(elem, save: false)
        }
        for elem in expiredTasksController.fetchedObjects! {
            safeDelete(elem, save: false)
        }
        for elem in activeRequestsController.fetchedObjects! {
            safeDelete(elem, save: false)
        }
        for elem in expiredRequestsController.fetchedObjects! {
            safeDelete(elem, save: false)
        }
        for elem in usersController.fetchedObjects! {
            safeDelete(elem, save: false)
        }
        for elem in loggedUserController.fetchedObjects! {
            safeDelete(elem, save: false)
        }
        safeSave()
    }
    
}
