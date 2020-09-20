//
//  MapView.swift
//  BackOn
//
//  Created by Riccio Vincenzo, Sorrentino Giancarlo, Triuzzi Emanuele, Zanfardino Gennaro on 25/02/2020.
//  Copyright © 2020 Riccio Vincenzo, Sorrentino Giancarlo, Triuzzi Emanuele, Zanfardino Gennaro. All rights reserved.
//

import SwiftUI
import UIKit
import MapKit

class NeedAnnotation<Element:Need>: NSObject, MKAnnotation, Identifiable {
    @ObservedObject var need: Element
    // This property must be key-value observable, which the `@objc dynamic` attributes provide.
    @objc dynamic var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    init(_ need: Element) {
        self.need = need
        self.coordinate = need.position
        super.init()
    }
}

class LastLocationAnnotation: NSObject, MKAnnotation, Identifiable {
    // This property must be key-value observable, which the `@objc dynamic` attributes provide.
    @objc dynamic var coordinate: CLLocationCoordinate2D
    override init() {
        self.coordinate = Geo.controller.lastLocation!.coordinate
        super.init()
    }
}

class MapCoordinator: NSObject, MKMapViewDelegate {
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
        if annotation.isKind(of: MKPointAnnotation.self) {
            let view = MKAnnotationView(annotation: annotation, reuseIdentifier: nil)
            view.canShowCallout = false
            view.displayPriority = .required
            view.image = UIImage(named: "Marker")
            return view
        } else if annotation.isKind(of: MKUserLocation.self) {
            return nil
        } else {
            let view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: nil)
            view.canShowCallout = false
            view.displayPriority = .required
            return view
        }
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
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

struct MapView<Element:Need>: UIViewRepresentable {
    var need: Element?

    func makeCoordinator() -> MapCoordinator {
        if need == nil {
            return MapCoordinator(isDiscoverMap: true)
        } else {
            return MapCoordinator(isDiscoverMap: false)
        }
    }

    func makeUIView(context: Context) -> MKMapView {
        let discoverTabController = Discover.controller
        let mapView = MKMapView(frame: UIScreen.main.bounds)
        let mapSpan = MKCoordinateSpan(latitudeDelta: 0.007, longitudeDelta: 0.007)
        mapView.delegate = context.coordinator
        mapView.showsCompass = false
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        //let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotationOnLongPress(gesture:)))
        //longPressGesture.minimumPressDuration = 1.0
        //mapView.addGestureRecognizer(...) quello che serve per riconoscere una gesture
        // vedi https://stackoverflow.com/questions/40844336/create-long-press-gesture-recognizer-with-annotation-pin
        if let selectedNeed = need {
            if selectedNeed is Request {
                mapView.addAnnotation(generateAnnotation(selectedNeed, title: "Your request"))
            } else {
                mapView.addAnnotation(generateAnnotation(selectedNeed, title: "\(selectedNeed.user!.name)'s request"))
                addRoute(mapView: mapView)
            }
            mapView.setRegion(MKCoordinateRegion(center: selectedNeed.position, span: mapSpan), animated: true)
        } else { //è il mappone
            if let lastLocation = Geo.controller.lastLocation {
                mapView.setRegion(MKCoordinateRegion(center: lastLocation.coordinate, span: mapSpan), animated: true)
                for discoverable in discoverTabController.discoverables.values {
                    mapView.addAnnotation(generateAnnotation(discoverable, title: discoverable.needer.name))
                }
                discoverTabController.baseMKMap = mapView
            }
        }
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {}

    private func generateAnnotation<Element:Need>( _ need: Element, title: String) -> NeedAnnotation<Element> {
        let annotation = NeedAnnotation(need)
        annotation.title = title
        annotation.subtitle = need.title
        return annotation
    }

    func addRoute(mapView: MKMapView){
        guard let lastLocation = Geo.controller.lastLocation else {return}
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: lastLocation.coordinate, addressDictionary: nil))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: need!.position, addressDictionary: nil))
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
