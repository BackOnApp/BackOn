//
//  MapViewSwiftUI.swift
//  BackOn
//
//  Created by Vincenzo Riccio on 07/09/2020.
//

import SwiftUI
import MapKit
import CoreLocation

extension MKPointAnnotation: Identifiable { }

struct MapViewNEW<Element:Need>: View {
    private let positionBinding: Binding<MKCoordinateRegion>
    var annotations = Array<NeedAnnotation<Element>>()
    var selectedNeed: Element?
    
    init(need: Element? = nil) {
        let mapSpan = MKCoordinateSpan(latitudeDelta: 0.007, longitudeDelta: 0.007)
        let map = MKMapView.appearance()
        map.showsTraffic = false
        map.showsBuildings = false
        map.showsScale = false
        map.showsCompass = false
        map.showsUserLocation = false
        map.userTrackingMode = .none
        //#TODO controlla che il pin cambia posizione quando lastLocation cambia
        if need == nil {
            positionBinding = Binding(get: {MKCoordinateRegion(center: Geo.controller.lastLocation!.coordinate, span: mapSpan)}, set: {new in})
            for discoverable in Discover.controller.discoverables.values {
                let annotation = NeedAnnotation(discoverable as! Element)
                annotation.title = discoverable.needer.name
                annotation.coordinate = discoverable.position
                annotations.append(annotation)
            }
//            Discover.controller.baseMKMap = map
        } else {
            selectedNeed = need
            positionBinding = Binding(get: {MKCoordinateRegion(center: need!.position, span: mapSpan)}, set: {new in})
            if need! is Request {
                let annotation = NeedAnnotation(selectedNeed!)
                annotation.title = "Your request"
                annotation.coordinate = need!.position
                annotations.append(annotation)
            } else {
                let annotation = NeedAnnotation(selectedNeed!)
                annotation.title = "\(selectedNeed!.user!.name)'s request"
                annotation.coordinate = need!.position
                annotations.append(annotation)
                addRoute(mapView: map)
            }
        }
        if Geo.controller.lastLocation != nil {
            let annotation = MKPointAnnotation()
            annotation.title = "You"
            annotation.coordinate = Geo.controller.lastLocation!.coordinate
            map.addAnnotation(annotation)
        }
    }
    
    var body: some View {
        return Map(coordinateRegion: positionBinding, annotationItems: annotations) { ann in
            MapAnnotation(coordinate: ann.coordinate) {
                Button(action: {print("tapp"); Discover.controller.showSheet(discoverable: (ann as! NeedAnnotation<Discoverable>).need)}) {
                    Image(systemName: "pencil.slash").imageScale(.large).font(.largeTitle)
                }
            }
//            MapMarker(coordinate: ann.coordinate)
        }
    }
    
    private func generateAnnotation<Element:Need>( _ need: Element, title: String) -> NeedAnnotation<Element> {
        let annotation = NeedAnnotation(need)
        annotation.title = title
        annotation.subtitle = need.title
        return annotation
    }
    
    func addRoute(mapView: MKMapView) {
        guard let lastLocation = Geo.controller.lastLocation else {print("Can't add route. lastLocation is nil"); return}
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: lastLocation.coordinate, addressDictionary: nil))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: selectedNeed!.position, addressDictionary: nil))
        request.requestsAlternateRoutes = false
        request.transportType = .walking
        MKDirections(request: request).calculate { (response, error) in
            guard error == nil, let response = response else {print("Error while adding route:",error!.localizedDescription);return}
            var fastestRoute: MKRoute = response.routes[0]
            for route in response.routes {
                if route.expectedTravelTime < fastestRoute.expectedTravelTime {
                    fastestRoute = route
                }
            }
            mapView.addOverlay(fastestRoute.polyline, level: .aboveRoads)
        }
    }
}

class MapDelegate: NSObject, MKMapViewDelegate {
    let isDiscoverMap: Bool
    let discoverTabController = Discover.controller
    
    init(isDiscoverMap: Bool) {
        self.isDiscoverMap = isDiscoverMap
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIScreen.main.traitCollection.userInterfaceStyle != .dark ? #colorLiteral(red: 0, green: 0.6529515386, blue: 1, alpha: 1) : #colorLiteral(red: 0.2057153285, green: 0.5236110687, blue: 0.8851857781, alpha: 1)
        renderer.lineWidth = 6.0
        return renderer
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        print("draw")
        if annotation.isKind(of: MKPointAnnotation.self) {
            let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: nil)
            view.canShowCallout = true
            view.displayPriority = .required
            view.pinTintColor = .systemBlue
            return view
        } else {
            let view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: nil)
            view.canShowCallout = false
            view.displayPriority = .required
            return view
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        print("selezionata")
        guard isDiscoverMap else {return}
        guard !view.annotation!.isKind(of: MKPointAnnotation.self) else {return}
        discoverTabController.showSheet(discoverable: (view.annotation! as! NeedAnnotation).need)
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        guard isDiscoverMap else {return}
        guard !view.annotation!.isKind(of: MKUserLocation.self) else {return}
        discoverTabController.closeSheet()
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        print("update")
        guard let location = userLocation.location else { return }
        if location.horizontalAccuracy < Geo.controller.horizontalAccuracy {
            let myLocation = MKPointAnnotation()
            myLocation.coordinate = location.coordinate
            myLocation.title = "You"
            mapView.addAnnotation(myLocation)
            mapView.showsUserLocation = false
        }
    }
}


