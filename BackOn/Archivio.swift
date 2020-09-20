////
////  Archivio.swift
////  BackOn
////
////  Created by Vincenzo Riccio on 04/09/2020.
////
//
//import Foundation
//
//struct TasksKey: EnvironmentKey {
//    static let defaultValue: FetchedResults<Task>? = nil
//}
//struct RequestsKey: EnvironmentKey {
//    static let defaultValue: FetchedResults<Request>? = nil
//}
//struct UsersKey: EnvironmentKey {
//    static let defaultValue: FetchedResults<User>? = nil
//}
//struct LoggedUserKey: EnvironmentKey {
//    static let defaultValue: FetchedResults<LoggedUser>? = nil
//}
//

//static var customSortingDescriptor: NSSortDescriptor = {NSSortDescriptor(keyPath: \Request.date, ascending: true, comparator: {(req1, req2) in
//    let now = Date()
//    let date1 = (req1 as! Request).date
//    let date2 = (req2 as! Request).date
//    if date1 < now && date2 >= now {
//        return .orderedDescending
//    }
//    if date2 < now && date1 >= now {
//        return .orderedAscending
//    }
//    return date1 < date2 ? .orderedAscending : .orderedDescending
//})}()

//class CalendarControllerOLD {
//    static var eventStore = EKEventStore()
//    static var destCalendar: EKCalendar?
//    static var authorized = false
//    
//    static func initController() {
//        switch EKEventStore.authorizationStatus(for: .event) {
//        case .authorized:
//            authorized = true
//            initCalendar()
//        case .denied:
//            print("Calendar access denied")
//            authorized = false
//        case .notDetermined, .restricted:
//            eventStore.requestAccess(to: .event) { granted, error in
//                if granted {
//                    print("Calendar access granted")
//                    self.authorized = true
//                    initCalendar()
//                } else {
//                    print("Calendar access denied")
//                    self.authorized = false
//                }
//            }
//        default:
//            print("Case Default")
//            authorized = false
//        }
//    }
//    
//    static private func initCalendar() {
//        let calendars = eventStore.calendars(for: .event)
//        for calendar in calendars {
//            if calendar.title == "BackOn Tasks" {
//                destCalendar = calendar
//            }
//        }
//        if destCalendar == nil {
//            destCalendar = EKCalendar(for: .event, eventStore: eventStore)
//            destCalendar!.title = "BackOn Tasks"
//            destCalendar!.source = eventStore.defaultCalendarForNewEvents?.source
//            do {
//                try eventStore.saveCalendar(destCalendar!, commit: true)
//            } catch {print("Error adding calendar!\n", error.localizedDescription)}
//        }
//    }
//    
//    static func addTask(task: Task) -> Bool {
//        return addEvent(title: "Help \(task.needer.name) with \(task.title)", startDate: task.date, notes: task.id)
//    }
//    
//    static func addRequest(request: Request) -> Bool {
//        return addEvent(title: "You requested help with \(request.title)", startDate: request.date, notes: request.id)
//    }
//    
//    static func remove<Element:Need>(_ need: Element) -> Bool {
//        let predicate = eventStore.predicateForEvents(withStart: need.date, end: need.date.addingTimeInterval(120), calendars: [destCalendar!])
//        let events = eventStore.events(matching: predicate)
//        for event in events {
//            print(event)
//            if let note = event.notes, note == need.id {
//                do {
//                    try eventStore.remove(event, span: .thisEvent)
//                    return true
//                } catch {print("Error while removing the event from the calendar"); return false}
//            }
//        }
//        print("No event matching the needID")
//        return false
//    }
//    
//    static func addEvent(title: String, startDate: Date, endDate: Date? = nil, relativeAlarmTime: TimeInterval = -60, notes: String? = nil) -> Bool {
//        guard authorized else {print("You don't have the permission to add an event"); return false}
//        let event = EKEvent(eventStore: eventStore)
//        event.title = title
//        event.startDate = startDate
//        event.endDate = endDate ?? startDate
//        event.notes = notes
//        event.addAlarm(EKAlarm(relativeOffset: relativeAlarmTime))
//        event.calendar = destCalendar!
//        do {
//            try eventStore.save(event, span: .thisEvent)
//            return true
//        } catch {print(error.localizedDescription); return false}
//    }
//    
//    static func isBusy(when date: Date) -> Bool { //controlla che non ho impegni in [data-10min:data+10min]
//        let predicate = eventStore.predicateForEvents(withStart: date.addingTimeInterval(-600), end: date.addingTimeInterval(600), calendars: nil)
//        let events = eventStore.events(matching: predicate)
//        guard !events.isEmpty else { return false }
//        for event in events {
//            if !event.isAllDay {
//                return true
//            }
//        }
//        return false
//    }
//}


//extension EnvironmentValues {
//    var activeTasks: FetchedResults<Task>? {
//        get {
//            return self[TasksKey]
//        }
//        set {
//            self[TasksKey] = newValue
//        }
//    }
//    var expiredTasks: FetchedResults<Task>? {
//        get {
//            return self[TasksKey]
//        }
//        set {
//            self[TasksKey] = newValue
//        }
//    }
//    var activeRequests: FetchedResults<Request>? {
//        get {
//            return self[RequestsKey]
//        }
//        set {
//            self[RequestsKey] = newValue
//        }
//    }
//    var expiredRequests: FetchedResults<Request>? {
//        get {
//            return self[RequestsKey]
//        }
//        set {
//            self[RequestsKey] = newValue
//        }
//    }
//    var users: FetchedResults<User>? {
//        get {
//            return self[UsersKey]
//        }
//        set {
//            self[UsersKey] = newValue
//        }
//    }
//    var loggedUser: FetchedResults<LoggedUser>? {
//        get {
//            return self[LoggedUserKey]
//        }
//        set {
//            self[LoggedUserKey] = newValue
//        }
//    }
//}

//func deleteOldBonds(tasks: FetchedResults<Task>, requests: FetchedResults<Request>, users: FetchedResults<User>) {
//    let threshold = Date().advanced(by: -259200)
//    for task in tasks {
//        guard task.date < threshold else {break}
//        context.delete(task)
//        //se ci sono altri task o request che fanno uso di quell'utente
//        let userID = task.needer.id
//        let tasksWithSameUser = tasks.compactMap() { elem in
//            elem.needer.id == userID
//        }
//        let requestsWithSameUser = requests.compactMap() { elem in
//            elem.helper?.id == userID
//        }
//        if tasksWithSameUser.isEmpty && requestsWithSameUser.isEmpty {
//            context.safeDelete(users.first(){ elem in
//                elem.id == userID
//            })
//        }
//    }
//    for request in requests {
//        guard request.date < threshold else {break}
//        context.delete(request)
//        //se ci sono altri task o request che fanno uso di quell'utente
//        guard let userID = request.helper?.id else {break}
//        let tasksWithSameUser = tasks.compactMap() { elem in
//            elem.needer.id == userID
//        }
//        let requestsWithSameUser = requests.compactMap() { elem in
//            elem.helper?.id == userID
//        }
//        if tasksWithSameUser.isEmpty && requestsWithSameUser.isEmpty {
//            context.safeDelete(users.first(){ elem in
//                elem.id == userID
//            })
//        }
//    }
//    try? context.save()
//}

//private func deleteOldBondsOLD() {
//    var calendar = Calendar.current
//    calendar.timeZone = NSTimeZone.local
//    guard let dateThreshold = calendar.date(byAdding: .day, value: -3, to: Date()) else {return}
//    let datePredicate = NSPredicate(format: "date < %@", dateThreshold as NSDate)
//    let taskFetch = NSFetchRequest<Task>(entityName: "Task")
//    taskFetch.predicate = datePredicate
//    taskFetch.returnsObjectsAsFaults = false
//    let reqFetch = NSFetchRequest<Request>(entityName: "Request")
//    reqFetch.predicate = datePredicate
//    reqFetch.returnsObjectsAsFaults = false
//    guard let oldTasks = try? context.fetch(taskFetch) else {return}
//    for task in oldTasks {
//        context.delete(task)
//    }
//    guard let oldRequests = try? context.fetch(reqFetch) else {return}
//    for request in oldRequests {
//        context.delete(request)
//    }
//}


//class MapController {
//    private static let locationManager = CLLocationManager()
//    private static let delegate = LocationManagerDelegate(action: updateLocation(lastLocation:))
//    static var lastLocation: CLLocation?
//    static let horizontalAccuracy: Double = 50
//    
//    static func initController() {
//        locationManager.requestWhenInUseAuthorization()
//        if CLLocationManager.locationServicesEnabled() {
//            print("Loc Enabled")
//            locationManager.delegate = delegate
//            locationManager.desiredAccuracy = kCLLocationAccuracyBest
//            locationManager.requestWhenInUseAuthorization()
//            locationManager.startUpdatingLocation()
//        }
//    }
//    
//    static func requestETA(source: CLLocation? = lastLocation, destination: CLLocationCoordinate2D, completion: @escaping (String?, String?) -> Void) { //(eta, error)
//        guard let source = source else {print("Source can't be nil for requesting ETA"); return}
//        let request = MKDirections.Request()
//        request.source = MKMapItem(placemark: MKPlacemark(coordinate: source.coordinate))
//        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
//        request.requestsAlternateRoutes = false
//        request.transportType = .walking
//        let directions = MKDirections(request: request)
//        directions.calculateETA { (res, error) in
//            guard error == nil, let res = res else {print("Error while getting ETA"); completion(nil, "ETA unavailable"); return}
//            let eta = res.expectedTravelTime
//            let hour = eta>7200 ? "hrs" : "hr"
//            if eta > 3600 {
//                completion("\(Int(eta/3600)) \(hour) \(Int((Int(eta)%3600)/60)) min", nil)
//            } else {
//                completion("\(Int(eta/60)) min walk", nil)
//            }
//        }
//    }
//    
//    
//    static func getSnapshot(location: CLLocationCoordinate2D, style: UIUserInterfaceStyle, width: CGFloat = 320, height: CGFloat = 350, completion: @escaping (MKMapSnapshotter.Snapshot?, String?) -> Void) { //(snapshot, error) -> Void
//        let mapSnapshotOptions = MKMapSnapshotter.Options()
//        let mapSpan = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
//        let region = MKCoordinateRegion(center: location, span: mapSpan)
//        mapSnapshotOptions.region = region
//        mapSnapshotOptions.size = CGSize(width: width, height: height)
//        mapSnapshotOptions.traitCollection = UITraitCollection(userInterfaceStyle: style)
//        MKMapSnapshotter(options: mapSnapshotOptions).start { (snapshot:MKMapSnapshotter.Snapshot?, error:Error?) in
//            completion(snapshot,error?.localizedDescription)
//        }
//    }
//    
//    static func coordinatesToAddress(_ location: CLLocationCoordinate2D, completion: @escaping (String?, String?)-> Void) { //(address, error) -> Void
//        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: location.latitude, longitude: location.longitude)) {(placemarks, error) in
//            guard error == nil, let p = placemarks?.first else {completion(nil,"Reverse geocoder failed"); return}
//            completion(self.extractAddress(p),nil)
//        }
//    }
//    
//    static func addressToCoordinates(_ address: String, completion: @escaping (CLLocationCoordinate2D?, String?)-> Void) { //(coordinates, error) -> Void
//        CLGeocoder().geocodeAddressString(address) {(placemarks, error) in
//            guard error == nil, let placemark = placemarks?.first, let coordinate = placemark.location?.coordinate else {completion(nil,"Geocoder failed"); return}
//            completion(coordinate,nil)
//        }
//    }
//    
//    static func openInMaps<Element:Need>(need: Element) {
//        Shared.instance.openingMaps = Date()
//        let request = MKDirections.Request()
//        if lastLocation != nil {
//            request.source = MKMapItem(placemark: MKPlacemark(coordinate: lastLocation!.coordinate))
//        }
//        let destination = MKMapItem(placemark: MKPlacemark(coordinate: need.position))
//        var username: String? = nil
//        username = (need as? Task)?.needer.name ?? (need as? Discoverable)?.needer.name
//        destination.name = "\(username ?? "Someone")'s request: \(need.title)"
//        request.destination = destination
//        request.destination?.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeWalking])
//    }
//    
//    static private func updateLocation(lastLocation: CLLocation) {
//        self.lastLocation = lastLocation
//        if lastLocation.horizontalAccuracy < horizontalAccuracy { // quando la posizione è abbastanza precisa richiede l'ETA di task e discoverable
//            locationManager.stopUpdatingLocation()
//        }
//    }
//    
//    static private func extractAddress(_ p: CLPlacemark) -> String {
//        var address = ""
//        if let streetInfo1 = p.thoroughfare {
//            address = "\(address)\(streetInfo1), "
//        }
//        if let streetInfo2 = p.subThoroughfare {
//            address = "\(address)\(streetInfo2), "
//        }
//        if let locality = p.locality {
//            address = "\(address)\(locality)"
//        }
//        /*if let postalCode = p.postalCode {
//            address = "\(address)\(postalCode), "
//        }
//        if let country = p.country {
//            address = "\(address)\(country)"
//        }*/
//        return address
//    }
//}
//
//class LocationManagerDelegate: NSObject, CLLocationManagerDelegate {
//    var action: (CLLocation) -> Void
//    
//    init(action: @escaping (CLLocation) -> Void) {
//        self.action = action
//        super.init()
//    }
//    
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        guard CoreDataController.shared.loggedUser != nil, let location = locations.last else { return }
//        action(location)
//    }
//}


//per ora mai usata. decidi
//private func revertChanges() {
//        self.name = CoreDataController.shared.loggedUser!.name
//        self.surname = CoreDataController.shared.loggedUser!.surname ?? ""
//        self.phoneNumber = CoreDataController.shared.loggedUser!.phoneNumber ?? ""
//        self.profilePic = CoreDataController.shared.loggedUser!.photo ?? NobodyAccepted.instance.photo!
//}

//        var conf = PHPickerConfiguration()
//        conf.filter = .images
//        conf.selectionLimit = 2
//        let phpicker = PHPickerViewController(configuration: conf)
//        phpicker.modalPresentationStyle = .fullScreen
//        let del = PHPickerController($profilePic.photo)
//        phpicker.delegate = del
//        vc.modalPresentationCapturesStatusBarAppearance = true

//    @State var name = CoreDataController.shared.loggedUser!.name
//    @State var surname = CoreDataController.shared.loggedUser!.surname ?? ""
//    @State var phoneNumber = CoreDataController.shared.loggedUser!.phoneNumber ?? ""
//    @State var profilePic = CoreDataController.shared.loggedUser!.photo ?? NobodyAccepted.instance.photo!

//let actionSheet = ActionSheet(title: Text("Choose"), message: Text("Choose"), buttons: [
//    .default(Text("Take a picture"), action: {source = .camera; showPicker.toggle()}),
//    .default(Text("Choose from library"), action: {source = .photoLibrary; showPicker.toggle()}),
//    .cancel()
//])

//    @State var showActionSheet = false
//    var actionSheet: ActionSheet {
//        ActionSheet(title: Text("Upload a profile pic"), message: Text("Choose Option"), buttons: [
//            .default(Text("Take a picture").orange()) {
//                self.showActionSheet.toggle()
//                self.underlyingVC.presentViewInChildVC(ImagePicker(image: self.$profilePic, source: .camera).edgesIgnoringSafeArea(.all), hideStatusBar: true)
//            },
//            .default(Text("Photo Library").orange()) {
//                self.showActionSheet.toggle()
//                self.underlyingVC.presentViewInChildVC(ImagePicker(image: self.$profilePic, source: .photoLibrary).edgesIgnoringSafeArea(.all), hideStatusBar: true)
//            },
//            .destructive(Text("Cancel"))
//        ])
//    }


//Button(action: {if self.vc.isEditing{self.showActionSheet.toggle()}}){
//    profilePic
//        .overlayIf(.constant(self.vc.isEditing), toOverlay: editPhotoOverlay, alignment: .bottom)
//        .clipShape(Circle())
//        .overlay(Circle().stroke(Color.white, lineWidth: 1))
//        .alert(isPresented: $alertPhotoUploadFailed) {
//            Alert(title: Text("Error while uploading profile pic"), message: Text("Check your connection and try again later"), dismissButton: .default(Text("Got it!").orange()))
//        }
//}.buttonStyle(PlainButtonStyle()).padding()

//class ImagePicker: UIViewController, PHPickerViewControllerDelegate, UINavigationControllerDelegate, CropViewControllerDelegate {
//    let imageBinding: Binding<UIImage>
//    let picker: PHPickerViewController
//    
//    init(_ image: Binding<UIImage>) {
//        var config = PHPickerConfiguration()
//        config.selectionLimit = 1
//        config.filter = PHPickerFilter.images
//        picker = PHPickerViewController(configuration: config)
//        imageBinding = image
//        super.init(nibName: nil, bundle: nil)
//        self.modalPresentationStyle = .automatic
//        picker.delegate = self
//        view.tintColor = .systemOrange
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
//        results.first?.itemProvider.loadObject(ofClass: UIImage.self, completionHandler: { (object, error) in
//            if let image = object as? UIImage {
//                DispatchQueue.main.async {
//                    self.imageBinding.wrappedValue = image
//                    let cropController = CropViewController(croppingStyle: .default, image: image)
//                    cropController.delegate = self
//                    cropController.aspectRatioPreset = .presetSquare
//                    cropController.aspectRatioLockEnabled = true
//                    cropController.resetAspectRatioEnabled = false
//                    cropController.aspectRatioPickerButtonHidden = true
//                    self.present(cropController)
//                }
//            }
//        })
//    }
//    
//    public func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
//        self.imageBinding.wrappedValue = image
//        cropViewController.dismiss()
//    }
//    public func cropViewController(_ cropViewController: CropViewController, didFinishCancelled cancelled: Bool) {
//        cropViewController.dismiss()
//    }
//    
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        let safeArea = self.view.safeAreaInsets
//        picker.view.frame = {
//            let size = CGSize(width: UIScreen.main.bounds.width, height: view.bounds.height - safeArea.top)
//            let origin = CGPoint(x: 0, y: UIScreen.main.bounds.origin.y + safeArea.top)
//            return CGRect(origin: origin, size: size)
//        }()
//    }
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        self.view.addSubview(picker.view)
//        self.view.backgroundColor = .init(red: 0.9763854146, green: 0.9765252471, blue: 0.9763546586, alpha: 0.99)
//    }
//}


/*
struct TaskList: View {
    @ObservedObject var cdc = CoreDataController.shared
    @State var selectedTask: Task?
    @State var showModal = false
    
    var body: some View {
        let activeTasks = cdc.activeTasksController.fetchedObjects ?? []
        let expiredTasks = cdc.expiredTasksController.fetchedObjects ?? []
        return ScrollView(.vertical) {
            VStack(alignment: .leading) {
                ForEach(activeTasks, id: \.id) { current in
                    Button(action: {
                        self.selectedTask = current
                        self.showModal = true
                    }) {
                        NeedPreview(need: current, user: current.user)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                if !activeTasks.isEmpty && !expiredTasks.isEmpty {
                    Divider()
                }
                ForEach(expiredTasks, id: \.id) { current in
                    Button(action: {
                        self.selectedTask = current
                        self.showModal = true
                    }) {
                        NeedPreview(need: current, user: current.user)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(10)
            .sheet(isPresented: self.$showModal) {DetailedView<Task, User>(need: selectedTask!)}
        }
    }
}

struct RequestList: View {
    @ObservedObject var cdc = CoreDataController.shared
    @State var selectedRequest: Request?
    @State var showModal = false
    
    var body: some View {
        let activeRequests = cdc.activeRequestsController.fetchedObjects ?? []
        let expiredRequests = cdc.expiredRequestsController.fetchedObjects ?? []
        return ScrollView(.vertical) {
            VStack(alignment: .leading) {
                ForEach(activeRequests, id: \.id) { current in
                    Button(action: {
                        self.selectedRequest = current
                        self.showModal = true
                    }) {
                        NeedPreview(need: current, user: current.user)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                if !activeRequests.isEmpty && !expiredRequests.isEmpty {
                    Divider()
                }
                ForEach(expiredRequests, id: \.id) { current in
                    Button(action: {
                        self.selectedRequest = current
                        self.showModal = true
                    }) {
                        NeedPreview(need: current, user: current.user)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(10)
            .sheet(isPresented: self.$showModal) {DetailedView<Request, User>(need: selectedRequest!)}
        }
    }
}

//RoundedRectangle(cornerRadius: 15, style: .continuous)
//            .fill(LinearGradient(gradient: Gradient(colors: [Color(UIColor(#colorLiteral(red: 0.9450980392, green: 0.8392156863, blue: 0.6705882353, alpha: 1))), Color(UIColor(#colorLiteral(red: 0.9450980392, green: 0.8392156863, blue: 0.6705882353, alpha: 1)))]), startPoint: .topLeading, endPoint: .bottomTrailing))
//)
*/

//struct ImagePicker: UIViewControllerRepresentable {
//    @Binding var image: Image
//    let source: UIImagePickerController.SourceType
//
//    func makeCoordinator() -> Coordinator {
//        return Coordinator(image: $image)
//    }
//
//    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate, CropViewControllerDelegate {
//        @Binding var image: Image
//        init(image: Binding<Image>) {
//            self._image = image
//        }
//        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//            guard let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
//            let cropController = CropViewController(croppingStyle: .default, image: selectedImage)
//            cropController.delegate = self
//            cropController.aspectRatioPreset = .presetSquare
//            cropController.aspectRatioLockEnabled = true
//            cropController.resetAspectRatioEnabled = false
//            cropController.aspectRatioPickerButtonHidden = true
//            picker.pushViewController(cropController, animated: true)
//        }
//        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
//            picker.dismiss(animated: true)
//        }
//        public func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
//            self.image = Image(uiImage: image)
//            cropViewController.dismiss(animated: true)
//        }
//        public func cropViewController(_ cropViewController: CropViewController, didFinishCancelled cancelled: Bool) {
//            cropViewController.dismiss(animated: true)
//        }
//
//    }
//
//    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
//        let picker = UIImagePickerController()
//        picker.delegate = context.coordinator
//        picker.imageExportPreset = .compatible
//        picker.allowsEditing = false
//        picker.view.tintColor = .systemOrange
//        if source != .camera {
//            picker.sourceType = .photoLibrary
//        } else {
//            picker.sourceType = .camera
//            picker.cameraCaptureMode = .photo
//            picker.showsCameraControls = true
//        }
//        return picker
//    }
//
//    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {}
//}


//
//struct TasksListView: View {
//    var body: some View {
//        VStack (alignment: .leading, spacing: 10){
//            Button(action: {withAnimation{HomeView.show()}}) {
//                HStack(spacing: 15) {
//                    Image(systemName: "chevron.left")
//                        .font(.headline).foregroundColor(Color(.systemOrange))
//                    Text("Your tasks")
//                        .fontWeight(.bold)
//                        .font(.title)
//                    Spacer()
//                }.padding([.top,.horizontal])
//            }.buttonStyle(PlainButtonStyle())
//            ListView(mode: .TaskViews)
//            Spacer()
//        }
//    }
//}

//struct DiscoverablePreview: View {
//    @ObservedObject var discoverable: Discoverable
//    @ObservedObject var user: DiscoverableUser
//
//    var body: some View {
//        let isExpired = discoverable.isExpired()
//        return VStack(alignment: .leading, spacing: 0) {
//            HStack {
//                user.avatar
//                VStack(alignment: .leading) {
//                    Text(user.identity)
//                    Text(discoverable.title).font(.subheadline).fontWeight(.light)
//                }
//                .font(.title) //c'era 26 di grandezza invece di 28
//                .lineLimit(1)
//                .tint(.white)
//                .padding(.leading, 5)
//                .offset(y: -1)
//                Spacer()
//            }
//            Spacer()
//            HStack {
//                Text(discoverable.city)
//                Spacer()
//                Text("\(discoverable.date, formatter: customDateFormat)")
//            }.font(.body).tint(.secondary).offset(y: 1)
//        }
//        .padding(12)
//        .backgroundIf(isExpired, .expiredTask, .task)
//        .loadingOverlay(isPresented: $discoverable.waitingForServerResponse)
//        .cornerRadius(10)
//    }
//}
//
//struct TaskPreview: View {
//    @ObservedObject var task: Task
//    @ObservedObject var user: DiscoverableUser
//
//    var body: some View {
//        let isExpired = task.isExpired()
//        return VStack(alignment: .leading, spacing: 0) {
//            HStack {
//                user.avatar
//                VStack(alignment: .leading) {
//                    Text(user.identity)
//                    Text(task.title).font(.subheadline).fontWeight(.light)
//                }
//                .font(.title) //c'era 26 di grandezza invece di 28
//                .lineLimit(1)
//                .tintIf(isExpired, .white, .task) //usa l'arancione del BG dei task per il testo delle request non accettate
//                .padding(.leading, 5)
//                .offset(y: -1)
//                Spacer()
//            }
//            Spacer()
//            HStack {
//                Text(task.city)
//                Spacer()
//                Text("\(task.date, formatter: customDateFormat)")
//            }.font(.body).tint(.secondary).offset(y: 1)
//        }
//        .padding(12)
//        .backgroundIf(isExpired, .expiredTask, .task)
//        .loadingOverlay(isPresented: $task.waitingForServerResponse)
//        .cornerRadius(10)
//    }
//}


//struct RequestsListView: View {
//    var body: some View {
//        VStack (alignment: .leading, spacing: 10){
//            Button(action: {withAnimation{HomeView.show()}}) {
//                HStack(spacing: 15) {
//                    Image(systemName: "chevron.left")
//                        .font(.headline).orange()
//                    Text("Your requests")
//                        .fontWeight(.bold)
//                        .font(.title)
//                    Spacer()
//                }.padding([.top,.horizontal])
//            }.buttonStyle(PlainButtonStyle())
//            ListView(mode: .RequestViews)
//            Spacer()
//        }
//    }
//}

//struct RequestView_Previews: PreviewProvider {
//    static var previews: some View {
//        RequestView(request: Task(neederUser: User(name: "Gio", surname: "Fal", email: "giancarlosorrentino99@gmail.com", photoURL: URL(string: "https://images.unsplash.com/photo-1518806118471-f28b20a1d79d?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=3400&q=80")!, isHelper: 0), title: "Prova", descr: "Prova", date: Date(), latitude: 41, longitude: 15, id: 2))
//    }
//}

//struct DetailedView_Previews: PreviewProvider {
//    static var previews: some View {
//        DetailedView(requiredBy: .RequestViews, selectedTask: Task(neederID: "mio", title: "Preview", date: Date()+20000, latitude: 40.1, longitude: 14.5, _id: "ciao"))
//    }
//}


/*
 if needType == .discoverable {
     DirectionsButton(need: need)
     Spacer()
     DoItButton(discoverable: need as! Discoverable)
 } else if needType == .request {
     if isExpired {
         if user == nil {
             Spacer()
             AskAgainButton(request: need as! Request)
             Spacer()
         } else {
             ThankButton(helperToReport: true, need: need as! Request)
             Spacer()
             ReportButton(helperToReport: true, need: need as! Request)
         }
     } else {
         Spacer()
         DontNeedAnymoreButton(request: need as! Request)
         Spacer()
     }
 } else {
     if isExpired {
         ThankButton(helperToReport: false, need: need as! Task)
         Spacer()
         ReportButton(helperToReport: false, need: need as! Task)
     } else {
         DirectionsButton(need: need)
         Spacer()
         CantDoItButton(task: need as! Task)
     }
 }
 */
