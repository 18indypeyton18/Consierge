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
    var placeTypeID = 0
    var cityID = 0
    
    var selectedPlace: Place?
    
    let picGetter = PicGetter()
    
    var didAddAnnotations = false
    
    var sectionPlaces: [Place]?
    var currentPlace: Place?
    var currentPlaceImg: UIImage?
    
    
    override func viewDidLoad() {
        mapView.delegate = self
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
        checkLocationServices()
        setupDismissTapGesture()
        super.viewDidLoad()
    }
    
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func checkLocationServices() {
        DispatchQueue.global().async {
            if CLLocationManager.locationServicesEnabled() {
                self.setupLocationManager()
                self.checkLocationAuthorization()
            } else {
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
            DispatchQueue.main.async {
                self.addPins()
                self.getCenter()
            }
        case .denied:
            DispatchQueue.main.async {
                self.addPins()
                self.getCenter()
            }
        case .authorizedAlways, .authorizedWhenInUse:
            mapView.showsUserLocation = true
            DispatchQueue.main.async {
                self.addPins()
                self.getCenter()
            }
        @unknown default:
            break
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // Let the system handle the user location annotation.
        if annotation is MKUserLocation {
            return nil
        }
        
        // Handle cluster annotations separately.
        if annotation is MKClusterAnnotation {
            let identifier = "ClusterAnnotation"
            let clusterView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            clusterView.canShowCallout = true
            clusterView.markerTintColor = .systemRed
            clusterView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            return clusterView
        }
        
        // For individual place annotations.
        let identifier = "PlaceAnnotation"
        let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        annotationView.canShowCallout = false
        annotationView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        
        // This is key: assign a clustering identifier.
        annotationView.clusteringIdentifier = "cluster"
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation else { return }
        if let cluster = annotation as? MKClusterAnnotation {
            // For clusters, build an array of places.
            var clusterPlaces: [Place] = []
            for member in cluster.memberAnnotations {
                if let title = member.title, let place = self.places.first(where: { $0.name == title }) {
                    clusterPlaces.append(place)
                }
            }
            clusterPlaces = clusterPlaces.sorted { lhs, rhs in
                return lhs.communityVotes > rhs.communityVotes
            }
            // Present the preview modal with swipe support.
            self.showPlacePreview(for: clusterPlaces)
        }
        else if let pointAnnotation = annotation as? MKPointAnnotation {
            if let place = self.places.first(where: { $0.name == pointAnnotation.title }) {
                // Present the preview modal for a single place.
                self.showPlacePreview(for: [place])
            }
        }
    }
    
    func addPins() {
        guard !didAddAnnotations else { return }
        didAddAnnotations = true
        
        for place in places {
            let geoCoder = CLGeocoder()
            geoCoder.geocodeAddressString(place.address) { (placemarks, error) in
                guard let placemarks = placemarks, let location = placemarks.first?.location else {
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
            // print("Invalid coordinates for centering the map.")
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


extension MapViewController {
    // Property to keep track of the preview controller.
    var placePreviewPageController: PlacePreviewPageController? {
        get {
            return objc_getAssociatedObject(
                self,
                AssociatedKeys.previewKey
            ) as? PlacePreviewPageController
        }
        set {
            objc_setAssociatedObject(
                self,
                AssociatedKeys.previewKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
    
    private struct AssociatedKeys {
        // 1 byte of storage
        static var previewKeyStorage: UInt8 = 0
        
        // Precompute the raw‐pointer once
        static let previewKey = UnsafeRawPointer(
            &AssociatedKeys.previewKeyStorage
        )
    }

    func showPlacePreview(for places: [Place]) {
        let margin: CGFloat = 20
        let height = view.bounds.height / 3
        let bottomMargin = margin + view.safeAreaInsets.bottom
        let yOrigin = view.bounds.height - height - bottomMargin
        let width = view.bounds.width - (2 * margin)
        
        let previewPageController = PlacePreviewPageController()
        previewPageController.places = places
        sectionPlaces = places
        previewPageController.mapViewController = self
        previewPageController.view.frame = CGRect(x: margin, y: yOrigin, width: width, height: height)
        
        previewPageController.view.layer.shadowColor = UIColor.black.cgColor
        previewPageController.view.layer.shadowOpacity = 0.3
        previewPageController.view.layer.shadowRadius = 4
        
        addChild(previewPageController)
        view.addSubview(previewPageController.view)
        previewPageController.didMove(toParent: self)
        
        self.placePreviewPageController = previewPageController
    }

    func dismissPlacePreview() {
        if let preview = self.placePreviewPageController {
            preview.willMove(toParent: nil)
            preview.view.removeFromSuperview()
            preview.removeFromParent()
            self.placePreviewPageController = nil
            
            sectionPlaces = nil
            currentPlace = nil
            currentPlaceImg = nil
        }
    }

    // For dismissing the preview when tapping outside its frame:
    func setupDismissTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(mapTapped(_:)))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        mapView.addGestureRecognizer(tapGesture)
    }

    @objc func mapTapped(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self.view)
        if let previewFrame = self.placePreviewPageController?.view.frame, !previewFrame.contains(location) {
            dismissPlacePreview()
        }
    }
}

extension MapViewController {
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let sectionPlaces = sectionPlaces, let currentPlace = currentPlace, let currentPlaceImg = currentPlaceImg else {
            return
        }

        // Instantiate the PlaceDetailCollectionViewController safely
        guard let destinationVC = storyboard?.instantiateViewController(identifier: "PlaceDetail", creator: { coder in
            PlaceDetailCollectionViewController(coder: coder,
                                                place: currentPlace,
                                                sectionsPlaces: sectionPlaces,
                                                placePic: currentPlaceImg,
                                                placeTypeID: self.placeTypeID,
                                                cityID: self.cityID)
        }) else {
            return
        }

        navigationController?.pushViewController(destinationVC, animated: true)
    }
}


extension MapViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Walk up the view hierarchy from the touch's view.
        var view: UIView? = touch.view
        while let current = view {
            if current is UIControl {
                // If the touch is on a control (e.g. the callout accessory), do not let the gesture recognizer handle it.
                return false
            }
            view = current.superview
        }
        return true
    }
}
