import SwiftUI
import Combine
import MapKit

struct AddRequestView: View {
    @State var isEditing = false
    @State var busy = false
    @State var showTitlePicker = false
    @State var titlePickerValue = -1
    @State var requestDescription = ""
    @State var showDatePicker = false
    @State var selectedDate = Date(timeIntervalSinceReferenceDate: 0)
    @State var locationNeeded = false
    @State var titleNeeded = false
    @State var descriptionNeeded = false
    @State var dateNeeded = false
    @State var showAddressCompleter = false
    @ObservedObject var addressCompleter = AddressCompleterHandler()
    
    private let referenceDate = Date(timeIntervalSinceReferenceDate: 0)
    private var toAppendDescription: String { return titlePickerValue != -1 && Souls.categories[titlePickerValue] == "Other..." ? "(required)" : "(optional)" }
    
    private func addRequest(request: Request) {
        DB.controller.addRequest(request: request) { id, error in
            if error == nil, let id = id {
                DispatchQueue.main.async {
                    request.id = id
                    request.waitingForServerResponse = false
                    CD.controller.pendingRequests.removeFirst()
                    CD.controller.safeSave()
                    Calendar.controller.addRequest(request)
                }
           } else {
                let alert = UIAlertController(title: "Oh no!", message: "It seems we had a problem adding your request.\nDo you want to try again?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { _ in
                    request.waitingForServerResponse = false
                    CD.controller.pendingRequests.removeFirst()
                }))
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
                    addRequest(request: request)
                }))
                DispatchQueue.main.async { UIViewController.foremost.present(alert) }
           }
       }
    }

    var confirmButton: some View {
        Button(action: {
            locationNeeded = addressCompleter.selectedAddress == nil
            titleNeeded = titlePickerValue == -1
            descriptionNeeded = titlePickerValue != -1 && Souls.categories[titlePickerValue] == "Other..." && requestDescription == ""
            dateNeeded = selectedDate < Date()
            if !(locationNeeded || titleNeeded || dateNeeded || descriptionNeeded) {
                DispatchQueue.main.async { UIViewController.foremost.dismiss() }
                let request = Request(entity: Request.entity, insertInto: CD.controller.context).populate(id: "waitingForServerResponse", title: Souls.categories[titlePickerValue], descr: requestDescription == "" ? nil : requestDescription, latitude: addressCompleter.selectedCoordinates!.latitude, longitude: addressCompleter.selectedCoordinates!.longitude, date: selectedDate, address: addressCompleter.selectedAddress!)
                DispatchQueue.main.async { request.waitingForServerResponse = true; CD.controller.pendingRequests.append(request) }
                addRequest(request: request)
            }
        }) {
            Text("Confirm").orange().bold()
        }
    }
    
    
    var body: some View {
        UITableView.appearance().backgroundColor = .systemGray6
        UIViewController.foremost.presentationController?.delegate = PresentationDelegate.shared
        return NavigationView {
            Form {
                Section(header: Text("Need information")) {
                    HStack {
                        Text("Title: ").orange()
                        Spacer()
                        Text(titlePickerValue == -1 ? "Click to select your need" : Souls.categories[titlePickerValue])
                            .tintIf(titleNeeded, .red, titlePickerValue == -1 ? .gray3 : .primary)
                            .onTapGesture {withAnimation{
                                if titlePickerValue == -1 {titlePickerValue = 0}
                                showTitlePicker.toggle()
                                titleNeeded = false
                                UIViewController.foremost.setEditMode(observedVar: $isEditing, value: true)
                            }}
                    }
                    HStack {
                        Text("Description: ").orange()
                        SuperTextField(
                            placeholder: "Insert a description \(toAppendDescription)",
                            text: $requestDescription, required: $descriptionNeeded)
                    }
                }
                Section(header: Text("Time")) {
                    HStack {
                        Text("Date: ").orange()
                        Spacer()
                        if busy {
                            Image(systemName: "exclamationmark.triangle").tint(.yellow)
                                .onTapGesture{withAnimation{showDatePicker.toggle()}}
                        }
                        Text(selectedDate == referenceDate ? "Click to insert a date" : "\(selectedDate, formatter: customDateFormat)")
                            .tintIf(dateNeeded, .red, selectedDate == referenceDate ? .gray3 : .primary)
                            .onTapGesture {withAnimation{
                                showDatePicker.toggle()
                                dateNeeded = false
                                UIViewController.foremost.setEditMode(observedVar: $isEditing, value: true)
                            }}
                    }
                }
                Section(header: Text("Location")) {
                    HStack{
                        Text("Place: ").orange()
                        Spacer()
                        Text(addressCompleter.selectedAddress ?? "Click to insert the location")
                            .tintIf(locationNeeded, .red, addressCompleter.selectedAddress == nil ? .gray3 : .primary)
                            .onTapGesture {withAnimation{
                                showAddressCompleter = true
                                locationNeeded = false
                                UIViewController.foremost.setEditMode(observedVar: $isEditing, value: true)
                            }}
                    }
                }
            }
            .onTapGesture {UIViewController.foremost.view.endEditing(true)}
            .frame(width: UIScreen.main.bounds.width, alignment: .leading)
            .sheet(isPresented: $showAddressCompleter){SearchLocation(addressCompleter: addressCompleter)}
            .navigationBarTitle(Text("Add a request"), displayMode: .inline)
            .navigationBarItems(leading: Button(action: {UIViewController.foremost.dismiss()}){Text("Cancel").orange()}, trailing: confirmButton)
        }
        .opaqueOverlay(isPresented: $showTitlePicker, toOverlay: ElementPickerGUI(pickerElements: Souls.categories, selectedValue: $titlePickerValue))
        .opaqueOverlay(isPresented: $showDatePicker, toOverlay: DatePickerGUI(selectedDate: $selectedDate, showBusyWarning: $busy))
    }
}

struct SuperTextField: View {
    var placeholder: String
    @Binding var text: String
    @Binding var required: Bool
    
    var body: some View {
        ZStack(alignment: .trailing) {
            if text.isEmpty {Text(placeholder).tintIf(required, .red, .gray3)}
            TextField("", text: $text).multilineTextAlignment(.trailing).offset(y: 1).onTapGesture {
                required = false
            }
        }
    }
}

class AddressCompleterHandler: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    var completer = MKLocalSearchCompleter()
    @Published var selectedAddress: String? = nil
    @Published var selectedCoordinates: CLLocationCoordinate2D? = nil
    @Published var results: [MKLocalSearchCompletion] = []
    
    override init() {
        super.init()
        completer.delegate = self
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = Array(completer.results.prefix(3))
    }
    
    func clear() {
        selectedAddress = nil
        selectedCoordinates = nil
        results = []
        completer.cancel()
    }
}

extension MKLocalSearchCompletion: Identifiable {}

struct SearchLocation: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var addressCompleter: AddressCompleterHandler
    @State var userLocationAddress: String = "Processing your current location..."
    
    struct Map: UIViewRepresentable {
        let coordinate: Binding<CLLocationCoordinate2D?>
        let addressCompleter: AddressCompleterHandler
        let mapView: MKMapView = MKMapView(frame: UIScreen.main.bounds)
        
        class MapCoordinator: NSObject, MKMapViewDelegate {
            let parent: Binding<Map>
            
            init(parent: Binding<Map>) {
                self.parent = parent
            }
            
            @objc func handleTap(sender: UIGestureRecognizer) {
                if sender.state == UIGestureRecognizer.State.ended {
                    let mapView = parent.wrappedValue.mapView
                    let touchPoint = sender.location(in: mapView)
                    let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
                    Geo.controller.coordinatesToAddress(touchCoordinate) { result, error in
                        guard error == nil, let result = result else {print("Error while getting the address");return}
                        let annotation = MKPointAnnotation()
                        annotation.coordinate = touchCoordinate
                        annotation.title = String(result.split(separator: ",").first ?? "Unknown address")
                        mapView.removeAnnotations(mapView.annotations)
                        if Geo.controller.lastLocation != nil {
                            mapView.addAnnotation(LastLocationAnnotation())
                        }
                        mapView.addAnnotation(annotation)
                        self.parent.wrappedValue.addressCompleter.selectedAddress = result
                        self.parent.wrappedValue.addressCompleter.selectedCoordinates = touchCoordinate
                    }
                }
            }
            
            func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
                if annotation.isKind(of: LastLocationAnnotation.self) {
                    let view = MKAnnotationView(annotation: annotation, reuseIdentifier: nil)
                    view.canShowCallout = false
                    view.displayPriority = .required
                    view.image = UIImage(named: "Marker")
                    return view
                } else {
                    let view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: nil)
                    view.canShowCallout = false
                    view.displayPriority = .required
                    view.isSelected = true
                    return view
                }
            }
            
        }
        
        func makeCoordinator() -> MapCoordinator { return MapCoordinator(parent: .constant(self)) }
        
        func makeUIView(context: Context) -> MKMapView {
            mapView.delegate = context.coordinator
            mapView.showsCompass = false
            mapView.showsUserLocation = false
            mapView.userTrackingMode = .none
            let longPressGesture = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(MapCoordinator.handleTap(sender:)))
            longPressGesture.minimumPressDuration = 0.7
            mapView.addGestureRecognizer(longPressGesture)
            return mapView
        }

        func updateUIView(_ uiView: MKMapView, context: Context) {
            let mapSpan = coordinate.wrappedValue == nil && Geo.controller.lastLocation == nil ? MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5) : MKCoordinateSpan(latitudeDelta: 0.007, longitudeDelta: 0.007)
            let center = coordinate.wrappedValue ?? (Geo.controller.lastLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0))
            uiView.removeAnnotations(uiView.annotations)
            if Geo.controller.lastLocation != nil {
                uiView.addAnnotation(LastLocationAnnotation())
            }
            if coordinate.wrappedValue != nil {
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate.wrappedValue!
                uiView.addAnnotation(annotation)
            }
            uiView.setRegion(MKCoordinateRegion(center: center, span: mapSpan), animated: true)
        }
    }

    var body: some View {
        UITableView.appearance().sectionFooterHeight = 0
        UITableView.appearance().sectionHeaderHeight = 26
        return NavigationView {
            VStack(spacing: 0) {
                SearchBar(text: $addressCompleter.completer.queryFragment, onDelete: {
                    addressCompleter.clear()
                }).padding([.top,.horizontal], 10)
                Form {
                    if Geo.controller.lastLocation != nil {
                        Section (header: Text("Your position")) {
                            Text(userLocationAddress)
                                .onTapGesture {
                                    addressCompleter.selectedAddress = userLocationAddress
                                    addressCompleter.selectedCoordinates = Geo.controller.lastLocation!.coordinate
                                    presentationMode.dismiss()
                                }
                        }
                    }
                    if addressCompleter.selectedAddress == nil {
                        ForEach(addressCompleter.results) { currentItem in
                            let title = currentItem.title
                            let subtitle = currentItem.subtitle
                            let address = "\(title) (\(subtitle))"
                            VStack(alignment: .leading, spacing: 2) {
                                Text(title)
                                if subtitle != "" {Text(subtitle).font(.footnote).tint(.gray)}
                            }.onTapGesture {
                                Geo.controller.addressToCoordinates(address) { result, error in
                                    guard error == nil, let result = result else {
                                        UIViewController.foremost.present(defaultAlert(title: "Error while getting the coordinate", message: "The Geocoder failed to get the coordinate of the selected address"))
                                        return
                                    }
                                    addressCompleter.completer.cancel()
                                    addressCompleter.results = []
                                    addressCompleter.selectedAddress = address
                                    addressCompleter.selectedCoordinates = result
                                }
                            }
                        }
                    } else {
                        Section (header: EmptyView()) {}
                        Section (header: Text("Your selection")) {
                            Text(addressCompleter.selectedAddress!)
                        }
                    }
                }.frame(height: 310)
                Text("LONG PRESS TO SELECT A POINT ON THE MAP").font(.footnote).foregroundColor(Color(.systemGray)).offset(y: -5)
                Map(coordinate: $addressCompleter.selectedCoordinates, addressCompleter: addressCompleter)
            }
            .navigationBarTitle(Text("Select a location"), displayMode: .inline)
            .navigationBarItems(
                leading: Button(action: {addressCompleter.clear(); presentationMode.dismiss()}){Text("Cancel").orange()},
                trailing: Button(action: {presentationMode.dismiss()}){Text("Done").tintIf(addressCompleter.selectedAddress == nil, .gray3)}
                            .disabled(addressCompleter.selectedAddress == nil)
            )
            .background(.gray6)
            .edgesIgnoringSafeArea(.bottom)
            .onAppear() {
                if let lastLocation = Geo.controller.lastLocation {
                    Geo.controller.coordinatesToAddress(lastLocation.coordinate) { result, error in
                        guard error == nil, let result = result else {return}
                        userLocationAddress = result
                    }
                } else {
                    userLocationAddress = "Current location not available"
                }
            }
        }
    }
}
