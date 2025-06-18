//
//  GPTPlaceViewController.swift
//  Consierge
//
//  Created by Austin McLaughlin on 10/27/24.
//

import UIKit
import MapKit
import SafariServices

class GPTPlaceViewController: UIViewController, UIGestureRecognizerDelegate {
    
    var place: GPTPlace
    
    @IBOutlet var placeName: UILabel!
    @IBOutlet var websiteButton: UIButton!
    @IBOutlet var pinPlaceMapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadPage()
        // Do any additional setup after loading the view.
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    init?(coder: NSCoder, place: GPTPlace) {
        //init with required Place and optional section of Places
        self.place = place
        super.init(coder: coder)
    }
    
    func loadPage() {
        self.navigationItem.title = place.name
        placeName.text = place.name
        
        let websiteURL = place.website
        
        websiteButton.setTitle(websiteURL, for: .normal)
        websiteButton.isHidden = false
        
        addPinToMap()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(mapViewTapped(_:)))
        tapGesture.delegate = self
        pinPlaceMapView.addGestureRecognizer(tapGesture)
    }
    
    func addPinToMap() {
        // Convert the address to coordinates
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(place.address) { [weak self] (placemarks, error) in
            guard let self = self else { return }
            if let _ = error {
                // print("Geocoding error: \(error.localizedDescription)")
                return
            }
            
            if let placemark = placemarks?.first {
                // Create a MapPin with the location coordinates
                let mapPin = MKPointAnnotation()
                mapPin.coordinate = placemark.location!.coordinate
                mapPin.title = self.place.name
                
                // Add the pin to the MapView
                self.pinPlaceMapView.addAnnotation(mapPin)
                
                // Set the MapView's region to focus on the pin
                let region = MKCoordinateRegion(center: mapPin.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
                self.pinPlaceMapView.setRegion(region, animated: false)
            }
        }
    }
    
    @objc func mapViewTapped(_ sender: UITapGestureRecognizer) {
        openInMaps()
    }
    
    func openInMaps() {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(place.address) { (placemarks, error) in
            if let _ = error {
                // print("Geocoding error: \(error.localizedDescription)")
                return
            }
            
            if let placemark = placemarks?.first {
                let mapItem = MKMapItem(placemark: MKPlacemark(placemark: placemark))
                mapItem.name = self.place.name
                mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault])
            }
        }
    }
    
    @IBAction func websiteButtonTapped(_ sender: Any) {
        if let url = URL(string: place.website) {
            presentWebsite(url: url)
        }
    }
    
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func presentWebsite(url: URL) {
        let safariViewController = SFSafariViewController(url: url)
        present(safariViewController, animated: true, completion: nil)
    }

}
