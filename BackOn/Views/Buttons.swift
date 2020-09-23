//
//  Buttons.swift
//  BackOn
//
//  Created by Vincenzo Riccio on 18/08/2020.
//

import SwiftUI
import CoreData
import GoogleSignIn

struct GoogleButton: View {
    @AppStorage("isUserLogged") var isUserLogged: Bool = false
    var body: some View {
        Button(action: {
            GIDSignIn.sharedInstance()?.presentingViewController = UIViewController.main
            GIDSignIn.sharedInstance()?.signIn()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 30).fill(Color(.white)).frame(width: 280, height: 60, alignment: .center)
                HStack (spacing: 20){
                    Image("GIcon").resizable().renderingMode(.original).scaledToFit()
                    Text("Sign in with Google").foregroundColor(.black)
                }.frame(width: 280, height: 30, alignment: .center)
            }
        }
    }
}

struct AddNeedButton: View {
    @State var showModal = false
    var body: some View {
        Button(action: {self.showModal.toggle()}) {
            Image("AddNeedSymbol").orange().font(.largeTitle).imageScale(.medium)
        }.sheet(isPresented: $showModal){AddRequestView()}
    }
}

struct ProfileButton: View {
    @State var showModal = false
    var body: some View {
        Button(action: {self.showModal.toggle()}) {
            Image(systemName: "person.crop.circle").orange().font(.title)
        }.sheet(isPresented: $showModal){ProfileView()}
    }
}

struct CloseButton: View {
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        Button(action: {
            withAnimation {
                self.presentationMode.wrappedValue.dismiss()
                Discover.controller.closeSheet()
            }
        }){
            Image(systemName: "xmark.circle.fill").font(.largeTitle).tint(.white).opacity(0.9)
        }.customButtonStyle()
    }
}

struct UserActionRow<Element:Need>: View {
    @Environment(\.presentationMode) var presentationMode
    @State var showAlert = false
    let need: Element
    
    var body: some View {
        switch need {
        case is Task: //CantDoItButton
            if need.isExpired() {
                FeedbackButtonsRow(need: need)
            } else {
                HStack {
                    DirectionsButton(need: need)
                    Spacer()
                    GenericButton(
                        isFilled: true,
                        topText: "Can't do it"
                    ) {
                        presentationMode.wrappedValue.dismiss()
                        need.waitingForServerResponse = true
                        DB.controller.removeNeed(toRemove: self.need) { error in
                            DispatchQueue.main.async { self.need.waitingForServerResponse = false}
                            guard error == nil else { print(error!); self.showAlert = true; return }
                            let _ = Calendar.controller.remove(self.need)
                            CD.controller.safeDelete(need as! Task)
                        }
                    }.alert(isPresented: $showAlert) {
                        Alert(title: Text("Something wrong with your task"), message: Text("The system encountered a problem removing your task.\nPlease try again."), dismissButton: .default(Text("Got it!")))
                    }
                }
            }
        case is Request:
            if need.isExpired() {
                if need.user == nil { //AskAgainButton
                    HStack {
                        Spacer()
                        GenericButton(
                            isFilled: true,
                            isLarge: true,
                            topText: "Ask again"
                        ) {
                            UIViewController.foremost.dismiss(animated: true) {
                                let view = AddRequestView(isEditing: true, titlePickerValue: Souls.categories.firstIndex(of: self.need.title) ?? -1, requestDescription: self.need.descr ?? "", selectedDate: self.need.date)
                                view.addressCompleter.selectedAddress = need.address
                                view.addressCompleter.selectedCoordinates = need.position
                                UIViewController.foremost.present(HostingController(view, modalPresentationStyle: .formSheet, preventModalDismiss: true))
                            }
                        }
                        Spacer()
                    }
                } else {
                    FeedbackButtonsRow(need: need)
                }
            } else { //DontNeedAnymoreButton
                HStack {
                    Spacer()
                    GenericButton(
                        isFilled: true,
                        isLarge: true,
                        topText: "Don't need anymore"
                    ) {
                        presentationMode.wrappedValue.dismiss()
                        need.waitingForServerResponse = true
                        DB.controller.removeNeed(toRemove: self.need) { error in
                            DispatchQueue.main.async { self.need.waitingForServerResponse = false}
                            guard error == nil else { print(error!); self.showAlert = true; return }
                            let _ = Calendar.controller.remove(self.need)
                            DispatchQueue.main.async { CD.controller.safeDelete(need as! Request) }
                        }
                    }.alert(isPresented: $showAlert) {
                        Alert(title: Text("Something wrong with your request"), message: Text("The system encountered a problem removing your request.\nPlease try again."), dismissButton: .default(Text("Got it!")))
                    }
                    Spacer()
                }
            }
        case is Discoverable: //DoItButton
            if need.isExpired() {
                GenericButton(
                    isFilled: true,
                    topText: "Expired"
                ) {}.disabled(true)
            } else {
                HStack {
                    DirectionsButton(need: need)
                    Spacer()
                    GenericButton(
                        isFilled: true,
                        topText: "I'll do it"
                    ) {
                        DispatchQueue.main.async {
                            self.need.waitingForServerResponse = true
                            self.presentationMode.wrappedValue.dismiss()
                            Discover.controller.closeSheet()
                        }
                        DB.controller.acceptDiscoverable(toAccept: self.need as! Discoverable) { error in
                            DispatchQueue.main.async { self.need.waitingForServerResponse = false }
                            guard error == nil else {
                                print(error!)
                                DispatchQueue.main.async {Discover.controller.discoverables.removeValue(forKey: self.need.id)}
                                self.showAlert = true
                                return
                            }
                            let disc = self.need as! Discoverable
                            let discUser = self.need.user! as! DiscoverableUser
                            let cdc = CD.controller
                            let user: User =
                                cdc.usersController.fetchedObjects!.compactMap { fetcheduser in
                                    return fetcheduser.id == discUser.id ? fetcheduser : nil
                                }.first ??
                                User(context: cdc.context).populate(email: discUser.email, id: discUser.id, name: discUser.name, surname: discUser.surname, phoneNumber: discUser.phoneNumber, photoData: discUser.photo?.pngData() ?? Data(), lastModified: discUser.lastModified)
                            let task = Task(context: cdc.context).populate(id: disc.id, needer: user, title: disc.title, descr: disc.descr, latitude: disc.position.latitude, longitude: disc.position.longitude, date: disc.date, address: disc.address, lastModified: Date())
                            task.etaText = disc.etaText
                            user.addToAccepted(task)
                            task.requestSnaps()
                            DispatchQueue.main.async {Discover.controller.discoverables.removeValue(forKey: self.need.id)}
                            Calendar.controller.addTask(task)
                            CD.controller.safeSave()
                        }
                    }.alert(isPresented: $showAlert) {
                        Alert(title: Text("Oh no!"), message: Text("It seems that this request was already accepted by another user.\nThank you anyway for your help and support, we really apreciate it."), dismissButton: .default(Text("Got it!")))
                    }
                }
            }
        default:
            EmptyView()
        }
    }
}

struct FeedbackButtonsRow<Element: Need>: View {
    @Environment(\.presentationMode) var presentationMode
    @State var showActionSheet: Bool = false
    @State var showAlert: Bool = false
    let need: Element
    
    var body: some View {
        var actionSheet: ActionSheet {
            ActionSheet(title: Text("Report a problem"), message: Text("Choose Option"), buttons: [
                .default(Text("The person didn't show up")) {
                    DispatchQueue.main.async { self.presentationMode.wrappedValue.dismiss() }
                    DB.controller.reportTask(need: self.need, report: "Didn't show up") { error in
                        guard error == nil else {print(error!); self.showAlert = true; return}
                        CD.controller.safeDelete((need as! NSManagedObject), save: true)
                    }
                },
                .default(Text("The person had bad manners")) {
                    DispatchQueue.main.async { self.presentationMode.wrappedValue.dismiss() }
                    DB.controller.reportTask(need: self.need, report: "Bad manners") { error in
                        guard error == nil else {print(error!); self.showAlert = true; return}
                        CD.controller.safeDelete((need as! NSManagedObject), save: true)
                    }
                },
                .destructive(Text("Cancel"))
            ])
        }
        
        return HStack {
            GenericButton(
                isFilled: true,
                topText: "Thank you"
            ) {
                DispatchQueue.main.async { self.presentationMode.wrappedValue.dismiss() }
                DB.controller.reportTask(need: self.need, report: "Thank you") { error in
                    guard error == nil else {print(error!); self.showAlert = true; return}
                    CD.controller.safeDelete((need as! NSManagedObject), save: true)
                }
            }
            Spacer()
            GenericButton(
                isFilled: false,
                topText: "Report"
            ){
                self.showActionSheet.toggle()
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Oh no!"), message: Text("It seems that there is a problem processing your request. Try again later"), dismissButton: .default(Text("Got it!")))
            }
            .actionSheet(isPresented: $showActionSheet){actionSheet}
        }
    }
}

struct DirectionsButton<Element:Need>: View {
    let isFilled: Bool = false
    @ObservedObject var need: Element
    
    var body: some View {
        Button(action: {Geo.controller.openInMaps(need: need)}){
            VStack {
                Text("Directions")
                    .fontWeight(.semibold)
                    .font(.body)
                    .tintIf(isFilled, .white, .detailedTaskHeaderBG)
                if need.etaText != nil {
                    Text(need.etaText!)
                        .font(.subheadline)
                        .tintIf(isFilled, .white, .detailedTaskHeaderBG)
                }
            }
            .frame(width: defaultButtonDimensions.width, height: defaultButtonDimensions.height)
            .backgroundIf(isFilled, .detailedTaskHeaderBG, .systemBG)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(!isFilled ? getColor(.detailedTaskHeaderBG) : Color(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)), lineWidth: 1))
        }.customButtonStyle()
    }
}

struct CallButton: View {
    var phoneNumber: String?
    var date: Date
    var body: some View {
        let hoursLeft = (date.timeIntervalSinceNow - 18_000)/3_600
        let daysLeft = Int(hoursLeft/24)
        let dayString: String? = daysLeft > 0 ? "\(daysLeft) " + (daysLeft > 1 ? "days" : "day") : nil
        let hourString: String? = hoursLeft > 1 ? "\(Int(hoursLeft)) " + (hoursLeft > 2 ? "hrs" : "hr") : nil
        let disabledCondition = self.phoneNumber == nil || hoursLeft > 0
        return Button(action: {
            guard let phoneNumber = self.phoneNumber, let number = URL(string: "tel://" + phoneNumber) else { return }
            UIApplication.shared.open(number)
        }) {
            HStack {
                if self.phoneNumber == nil {
                    Image(systemName: "phone.down.fill").tint(.red)
                    Text("Phone number not available")
                        .fontWeight(.semibold)
                        .font(.body)
                        .tint(.red)
                } else {
                    if hoursLeft <= 0 {
                        Image(systemName: "phone.fill").tint(.green)
                        Text("Call")
                            .fontWeight(.semibold)
                            .font(.body)
                            .tint(.green)
                    } else {
                        Image(systemName: "phone.down.fill").tint(.red)
                        if dayString != nil {
                            Text("Available in " + dayString!)
                                .fontWeight(.semibold)
                                .font(.body)
                                .tint(.red)
                        } else if hourString != nil {
                            Text("Available in about " + hourString!)
                            .fontWeight(.semibold)
                            .font(.body)
                            .tint(.red)
                        } else {
                            Text("Available in less than 1 hr")
                                .fontWeight(.semibold)
                                .font(.body)
                                .tint(.red)
                        }
                    }
                }
            }
            .frame(width: defaultButtonDimensions.width*2, height: defaultButtonDimensions.height)
            .background(Color(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0))).cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(disabledCondition ? Color(.systemRed) : Color(.systemGreen), lineWidth: 1))
        }
        .customButtonStyle()
        .disabled(disabledCondition)
    }
}

struct GenericButton: View {
    let dimensions: (width: CGFloat, height: CGFloat) = defaultButtonDimensions
    let isFilled: Bool
    var isLarge: Bool = false
    let color: Color = getColor(.detailedTaskHeaderBG)//Color(#colorLiteral(red: 0.9910104871, green: 0.6643157601, blue: 0.3115140796, alpha: 1)).opacity(0.9)
    let topText: String
    var bottomText: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Text(topText)
                    .fontWeight(.semibold)
                    .font(.body)
                    .foregroundColor(!isFilled ? color : Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)))
                if bottomText != nil {
                    Text(bottomText!)
                        .font(.subheadline)
                        .foregroundColor(!isFilled ? color : Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)))
                }
            }
            .frame(width: isLarge ? dimensions.width*2 : dimensions.width, height: dimensions.height)
            .background(isFilled ? color : Color(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0))).cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(!isFilled ? color : Color(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)), lineWidth: 1))
        }.customButtonStyle()
    }
}
