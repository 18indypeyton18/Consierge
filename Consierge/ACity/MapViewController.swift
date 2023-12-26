//
//  MapViewController.swift
//  Consierge
//
//  Created by Austin McLaughlin on 10/5/24.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet var mapView: MKMapView!
    
    let coordinate = CLLocationCoordinate2D(latitude: 41.91343, longitude: -87.64764)

    let locationManager = CLLocationManager()
    
    let regionInMeters = 10000.0
    
    var imageRequestTask: Task<Void,Never>? = nil
    deinit { imageRequestTask?.cancel() }
    
    var latitudeTotal = 0.0
    var longitudeTotal = 0.0
    
    var places: [Place] = []
    var applePlaces: [MKMapItem] = []
    var gptPlaces: [GPTPlace] = []
    var placePics: [String: UIImage] = [:]
    
    var selectedPlace: Place?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        checkLocationServices()
    }
    
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func checkLocationServices() {
        DispatchQueue.global().async {
            if CLLocationManager.locationServicesEnabled() {
                print("LOCATIONENABLED")
                self.setupLocationManager()
                self.checkLocationAuthorization()
            } else {
                print("LOCATIONNOTENABLED")
                DispatchQueue.main.async {
                    self.addPins()
                    self.getCenter()
                }
            }
        }
    }
    
    func checkLocationAuthorization() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        case .restricted:
            addPins()
            getCenter()
        case .denied:
            addPins()
            getCenter()
        case .authorizedAlways, .authorizedWhenInUse:
            mapView.showsUserLocation = true
            addPins()
            getCenter()
        @unknown default:
            break
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation.title != "My Location" else { return nil }
        
        let identifier = "PlaceAnnotation"
        
        if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) {
            annotationView.annotation = annotation
            return annotationView
        } else {
            let annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView.canShowCallout = true
            
            let rightButton = UIButton(type: .detailDisclosure)
            annotationView.rightCalloutAccessoryView = rightButton
            
            return annotationView
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let annotation = view.annotation as? MKPointAnnotation {
            let place = places.first { $0.name == annotation.title }
            selectedPlace = place
            performSegue(withIdentifier: "PlaceSelectedFromMap", sender: nil)
        }
    }
    
    func addPins() {
        
        for place in places {
            let geoCoder = CLGeocoder()
            geoCoder.geocodeAddressString(place.address) { (placemarks, error) in
                guard
                    let placemarks = placemarks,
                    let location = placemarks.first?.location
                else {
                    // handle no location found
                    return
                }
                
                let annotation = MKPointAnnotation()
                annotation.title = place.name
                annotation.subtitle = place.address
                annotation.coordinate = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)

                self.mapView.addAnnotation(annotation)
            }
        }
        
        for place in gptPlaces {
            let geoCoder = CLGeocoder()
            geoCoder.geocodeAddressString(place.address) { (placemarks, error) in
                guard
                    let placemarks = placemarks,
                    let location = placemarks.first?.location
                else {
                    // handle no location found
                    return
                }
                
                let annotation = MKPointAnnotation()
                annotation.title = place.name
                annotation.subtitle = place.address
                annotation.coordinate = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)

                self.mapView.addAnnotation(annotation)
            }
        }
    }
    
    func getCenter() {
        guard !places.isEmpty else {
            print("No places available to center the map.")
            return
        }
        
        var latitudeTotal = 0.0
        var longitudeTotal = 0.0
        let count = Double(places.count)
        
        for place in places {
            latitudeTotal += place.latitude
            longitudeTotal += place.longitude
        }
        
        let latitudeAvg = latitudeTotal / count
        let longitudeAvg = longitudeTotal / count
        
        guard !latitudeAvg.isNaN, !longitudeAvg.isNaN else {
            print("Invalid coordinates for centering the map.")
            return
        }
        
        let location = CLLocationCoordinate2D(latitude: latitudeAvg, longitude: longitudeAvg)
        let region = MKCoordinateRegion(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
        mapView.setRegion(region, animated: false)
    }
}



extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {return}
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let _ = MKCoordinateRegion.init(center: center, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
}
