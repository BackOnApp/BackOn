import CoreLocation
import MapKit
import SwiftUI

extension CLLocationCoordinate2D {
    func distance(from destination: CLLocationCoordinate2D) -> CLLocationDistance {
        return CLLocation(latitude: self.latitude, longitude: self.longitude).distance(from: CLLocation(latitude: destination.latitude, longitude: destination.longitude))
    }
}

extension CLLocation {
    func distance(from destination: CLLocationCoordinate2D) -> CLLocationDistance {
        return self.distance(from: CLLocation(latitude: destination.latitude, longitude: destination.longitude))
    }
}

class Geo: NSObject, CLLocationManagerDelegate {
    static var controller = Geo()
    @objc dynamic var lastLocation: CLLocation?
    let horizontalAccuracy: Double = 50
    let locationManager = CLLocationManager()
    @AppStorage("isUserLogged") var isUserLogged: Bool = false
    
    override private init(){
        super.init()
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard CD.controller.loggedUser != nil, let location = locations.last else { return }
        lastLocation = location
        if lastLocation!.horizontalAccuracy < horizontalAccuracy { // quando la posizione è abbastanza precisa richiede l'ETA di task e discoverable
            locationManager.stopUpdatingLocation()
            if isUserLogged {
                DB.controller.discover()
//                for task in CD.controller.activeTasksController.fetchedObjects! { task.requestETA() }
//                for task in CD.controller.expiredTasksController.fetchedObjects! { task.requestETA() }
            }
        }
    }
    
    func isLocationAccurated() -> Bool {
        return lastLocation?.horizontalAccuracy ?? horizontalAccuracy < horizontalAccuracy
    }
    
    func requestETA(source: CLLocation? = nil, destination: CLLocationCoordinate2D, completion: @escaping (String?, String?) -> Void) { //(eta, error)
        let source = source ?? lastLocation
        guard source != nil else {print("Source can't be nil for requesting ETA"); return}
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: source!.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.requestsAlternateRoutes = false
        request.transportType = .walking
        let directions = MKDirections(request: request)
        directions.calculateETA { (res, error) in
            guard error == nil, let res = res else {print("Error while getting ETA"); completion(nil, "ETA unavailable"); return}
            let eta = res.expectedTravelTime
            let hour = eta>7200 ? "hrs" : "hr"
            if eta > 3600 {
                completion("\(Int(eta/3600)) \(hour) \(Int((Int(eta)%3600)/60)) min", nil)
            } else {
                completion("\(Int(eta/60)) min walk", nil)
            }
        }
    }
    
    func getSnapshot(location: CLLocationCoordinate2D, style: UIUserInterfaceStyle, width: CGFloat = 305, height: CGFloat = 350, completion: @escaping (MKMapSnapshotter.Snapshot?, String?) -> Void) { //(snapshot, error) -> Void
        let mapSnapshotOptions = MKMapSnapshotter.Options()
        let mapSpan = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        let region = MKCoordinateRegion(center: location, span: mapSpan)
        mapSnapshotOptions.region = region
        mapSnapshotOptions.size = CGSize(width: width, height: height)
        mapSnapshotOptions.traitCollection = UITraitCollection(userInterfaceStyle: style)
        MKMapSnapshotter(options: mapSnapshotOptions).start { (snapshot, error) in
            completion(snapshot,error?.localizedDescription)
        }
    }
    
    func coordinatesToAddress(_ location: CLLocationCoordinate2D, completion: @escaping (String?, String?)-> Void) { //(address, error) -> Void
        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: location.latitude, longitude: location.longitude)) {(placemarks, error) in
            guard error == nil, let p = placemarks?.first else {completion(nil,"Reverse geocoder failed"); return}
            completion(self.extractAddress(p), nil)
        }
    }
    
    func addressToCoordinates(_ address: String, completion: @escaping (CLLocationCoordinate2D?, String?)-> Void) { //(coordinates, error) -> Void
        CLGeocoder().geocodeAddressString(address) {(placemarks, error) in
            guard error == nil, let placemark = placemarks?.first, let coordinate = placemark.location?.coordinate else {completion(nil, "Geocoder failed"); return}
            completion(coordinate, nil)
        }
    }
    
    func openInMaps<Element:Need>(need: Element) {
        //Shared.instance.openingMaps = Date()
        let request = MKDirections.Request()
        if lastLocation != nil {
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: lastLocation!.coordinate))
        }
        let destination = MKMapItem(placemark: MKPlacemark(coordinate: need.position))
        var username: String? = nil
        username = (need as? Task)?.needer.name ?? (need as? Discoverable)?.needer.name
        destination.name = "\(username ?? "Someone")'s request: \(need.title)"
        request.destination = destination
        request.destination?.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeWalking])
    }
    
    private func extractAddress(_ p: CLPlacemark) -> String {
        var address = ""
        if let streetInfo1 = p.thoroughfare {
            address = "\(address)\(streetInfo1), "
        }
        if let streetInfo2 = p.subThoroughfare {
            address = "\(address)\(streetInfo2), "
        }
        if let locality = p.locality {
            address = "\(address)\(locality)"
        }
        /*if let postalCode = p.postalCode {
            address = "\(address)\(postalCode), "
        }
        if let country = p.country {
            address = "\(address)\(country)"
        }*/
        return address
    }
    
}
