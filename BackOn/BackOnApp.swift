//
//  BackOnApp.swift
//  BackOn
//
//  Created by Vincenzo Riccio on 05/08/2020.
//

import SwiftUI
import GoogleSignIn

typealias ErrorString = String
typealias RequestCategory = String

@main
struct BackOnApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("isUserLogged") var isUserLogged: Bool = false
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            if isUserLogged {
                TabViewController().environment(\.managedObjectContext, CD.controller.context)
            } else {
                LoginPage().environment(\.managedObjectContext, CD.controller.context)
            }
        }
        .onChange(of: scenePhase) { newScenePhase in
            if scenePhase == .background && newScenePhase == .inactive {
                UIApplication.shared.applicationIconBadgeNumber = 0
                guard isUserLogged /*&& Shared.instance.openingMaps == nil*/ else {return}
                DB.controller.loadCommitments()
                //se la posizione è già precisa quando torna attiva
                if Geo.controller.isLocationAccurated() {DB.controller.discover()}
            }
        }
        .onChange(of: scenePhase) { newScenePhase in
            if scenePhase == .inactive && newScenePhase == .background {
                UIApplication.shared.applicationIconBadgeNumber = 0
                //guard isUserLogged && Shared.instance.openingMaps == nil else {return}
                Discover.controller.discoverables = [:]
                Discover.controller.discUsers = [:]
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    @AppStorage("deviceToken") var devToken: String = ""
    @AppStorage("isUserLogged") var isUserLogged: Bool = false
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge, .provisional]) { granted, error in
            guard error == nil else {return}
            DispatchQueue.main.sync { UIApplication.shared.registerForRemoteNotifications() }
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in return String(format: "%02.2hhx", data) }
        devToken = tokenParts.joined()
        print("Registered for remote notifications")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        GIDSignIn.sharedInstance().clientID = "571455866380-8d58drp1d8ap0bkh3tc1c7b29arrfr5c.apps.googleusercontent.com"
        GIDSignIn.sharedInstance().delegate = self
        let _ = Calendar.controller
        let _ = CD.controller
        let _ = DB.controller
        let _ = Geo.controller
        if isUserLogged {
            DB.controller.loadCommitments()
            //se la posizione è già precisa quando torna attiva
            if Geo.controller.isLocationAccurated() {DB.controller.discover()}
        }
        return true
    }

}

extension AppDelegate: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        let alert = defaultAlert(title: "Something wrong with sign-in", message: "It seems there is a problem with Google Sign-In.\nPlease try again.")
        guard error == nil else {print("Error with Google sign-in"); DispatchQueue.main.async {UIViewController.foremost.present(alert)}; return}
        DB.controller.signUp(
            name: user.profile.givenName!,
            surname: user.profile.familyName,
            email: user.profile.email!,
            photoURL: user.profile.imageURL(withDimension: 200)!
        ){ error in
            guard error == nil else {
                GIDSignIn.sharedInstance()?.disconnect()
                print("Error while signing-up on the DB\n",error!)
                DispatchQueue.main.async {UIViewController.foremost.present(alert)}
                return
            }
            print("Signed-up")
            self.isUserLogged = true
            Calendar.controller.requestPermission()
            DB.controller.loadCommitments()
            //se la posizione è già precisa quando si fa l'accesso
            if Geo.controller.isLocationAccurated() {DB.controller.discover()}
        }
    }

    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        print("\n*** User signed out from Google ***\n")
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return GIDSignIn.sharedInstance().handle(url)
    }
}

