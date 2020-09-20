//
//  ProfileView.swift
//  BackOn
//
//  Created by Riccio Vincenzo, Sorrentino Giancarlo, Triuzzi Emanuele, Zanfardino Gennaro on 10/03/2020.
//  Copyright © 2020 Riccio Vincenzo, Sorrentino Giancarlo, Triuzzi Emanuele, Zanfardino Gennaro. All rights reserved.
//

import SwiftUI
import GoogleSignIn
import PhotosUI

struct ProfileView: View {
    @AppStorage("isUserLogged") var isUserLogged: Bool = false
    @ObservedObject var loggedUser = CD.controller.loggedUser!
    @State var nameNeeded = false
    @State var alertUpdateFailed = false
    @State var alertPhotoUploadFailed = false
    @State var alertWrongPNFormat = false
    @State var alertEmptyName = false
    @State var showPicker = false
    @State var isEditing = false
    @State var source = UIImagePickerController.SourceType.photoLibrary
    
    var body: some View {
        let name = Binding(get: {loggedUser.name}, set: {new in loggedUser.name = new})
        let surname = Binding(get: {loggedUser.surname ?? ""}, set: {new in loggedUser.surname = new})
        let phoneNumber = Binding(get: {loggedUser.phoneNumber ?? ""}, set: {new in loggedUser.phoneNumber = new})
        let profilePic = Binding(get: {loggedUser.photo ?? UIImage(systemName: "person")!}, set: {new in loggedUser.photo = new; loggedUser.photoData = new.pngData()!; loggedUser.objectWillChange.send()})
        let editPhotoOverlay = Text("Edit").font(.subheadline).frame(width: 150, height: 30).tint(.white).background(Color.black.opacity(0.7))
        UITableView.appearance().backgroundColor = .systemGray6
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = .systemOrange
        UIViewController.foremost.presentationController?.delegate = PresentationDelegate.shared
        
        return NavigationView {
            VStack (spacing: 0){
                SizedDivider(height: 20)
                HStack {
                    Spacer()
                    ZStack {
                        Image(uiImage: profilePic.wrappedValue)
                            .avatar(size: 150)
                            .overlayIf($isEditing, toOverlay: editPhotoOverlay, alignment: .bottom)
                            .clipShape(Circle()).overlay(Circle().stroke(Color.white, lineWidth: 1))
                        Menu(content: {
                            Button(action: {profilePic.wrappedValue = UIImage(data: Data())!}) {
                                Label("Delete picture", systemImage: "trash")
                            }
                            Button(action: {source = .photoLibrary; showPicker.toggle()}) {
                                Label("Choose from library", systemImage: "photo")
                            }
                        }) {
                            Circle().frame(width: 150, height: 150).foregroundColor(.clear)
                        }.disabled(!isEditing)
                    }
                    Spacer()
                }
                Form {
                    Section(header: Text("Personal information")) {
                        HStack {
                            Text("Name: ")
                                .orange()
                            TextField("Name field is requred!", text: name)
                                .disabled(!isEditing)
                                .multilineTextAlignment(.trailing)
                                .alert(isPresented: $alertEmptyName) {
                                    Alert(title: Text("The name field must not be empty"), message: Text("Insert a valid name"), dismissButton: .default(Text("Got it!")))
                                }
                        }
                        HStack {
                            Text("Surname: ")
                                .orange()
                            TextField("", text: surname)
                                .disabled(!isEditing)
                                .multilineTextAlignment(.trailing)
                        }
                        HStack {
                            Text("Phone: ")
                                .orange()
                            TextField("Type your prefix and phone number", text: phoneNumber)
                                .disabled(!isEditing)
                                .keyboardType(.phonePad)
                                .multilineTextAlignment(.trailing)
                                .alert(isPresented: $alertWrongPNFormat) {
                                    Alert(title: Text("Wrong format for the phone number"), message: Text("The phone number should have the prefix followed by the phone number itself (e.g. +39 0123456789)"), dismissButton: .default(Text("Got it!")))
                                }
                        }
                        HStack {
                            Text("Mail: ").orange()
                            Spacer()
                            Text(loggedUser.email)
                        }
                    }
                    HStack {
                        Text("Logout").orange()
                        Spacer()
                        Image(systemName: "chevron.right").tint(.primary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        UIViewController.foremost.dismiss()
                        print("Logging out from Google!")
                        DB.controller.logout(){ error in
                            guard error == nil else {print(error!); return}
                            GIDSignIn.sharedInstance()?.disconnect()
                            CD.controller.deleteAll()
                            DispatchQueue.main.async {
                                Discover.controller.discoverables = [:]
                                Discover.controller.discUsers = [:]
                                isUserLogged = false
                            }
                        }
                    }
                }
                
            }
            .background(.gray6)
            .onTapGesture {UIViewController.foremost.view.endEditing(true)}
            .navigationBarTitle(Text("Your profile"), displayMode: .inline)
            .fullScreenCover(isPresented: $showPicker){PhotoPicker(imageBinding: profilePic, isPresented: $showPicker).edgesIgnoringSafeArea(.all)}
            .alert(isPresented: $alertUpdateFailed) {
                Alert(title: Text("Error while updating profile"), message: Text("Check your connection and try again later"), dismissButton: .default(Text("Got it!")))
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        UIViewController.foremost.view.endEditing(true)
                        UIViewController.foremost.dismiss()
                        CD.controller.context.rollback();
                        loggedUser.photo = UIImage(data: loggedUser.photoData)
                    }){Text("Cancel").orange()}
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        UIViewController.foremost.view.endEditing(true)
                        if isEditing {
                            //Se sono in edit mode e qualche parametro è cambiato...
                            name.wrappedValue = name.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines)
                            surname.wrappedValue = surname.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines)
                            phoneNumber.wrappedValue = phoneNumber.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard name.wrappedValue != "" else {self.alertEmptyName = true; print("Name field must not be empty"); return}
                            if phoneNumber.wrappedValue != "" {
                                let regex = try! NSRegularExpression(pattern: "(\\+\\d{2}\\s*)?(\\s*(\\d{7,15}))")
                                let result = regex.firstMatch(in: phoneNumber.wrappedValue, options: [], range: NSRange(location: 0, length: phoneNumber.wrappedValue.count))
                                guard result != nil && phoneNumber.wrappedValue.count <= 15 else {self.alertWrongPNFormat = true; print("Wrong format for phone number"); return}
                            }
                            if CD.controller.context.hasChanges {
                                DB.controller.updateProfile(
                                    newName: name.wrappedValue,
                                    newSurname: surname.wrappedValue,
                                    newPhoneNumber: phoneNumber.wrappedValue,
                                    newImageEncoded: loggedUser.photo?.jpegData(compressionQuality: 0.25)?.base64EncodedString(options: .lineLength64Characters)
                                ){ responseCode, error in
                                    guard error == nil, ((try? CD.controller.context.save()) != nil) else {self.alertUpdateFailed = true; print("Error while updating profile"); CD.controller.context.rollback(); return}
                                }
                            }
                        }
                        UIViewController.foremost.toggleEditMode(observedVar: $isEditing)
                    })
                    {Text.ofEditButton(isEditing)}
                }
            }
        }
    }
}
