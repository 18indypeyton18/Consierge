//
//  ApplePlaceViewController.swift
//  Consierge
//
//  Created by Austin McLaughlin on 9/20/24.
//

import UIKit
import MapKit
import SafariServices

class ApplePlaceViewController: UIViewController {
    
    var place: MKMapItem
    
    @IBOutlet var placeName: UILabel!
    @IBOutlet var phoneButton: UIButton!
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
    init?(coder: NSCoder, place: MKMapItem) {
        //init with required Place and optional section of Places
        self.place = place
        super.init(coder: coder)
    }
    
    func loadPage() {
        self.navigationItem.title = place.name
        placeName.text = place.name
        
        if let phoneNumber = place.phoneNumber, !phoneNumber.isEmpty {
            phoneButton.setTitle(phoneNumber, for: .normal)
            phoneButton.isHidden = false
        } else {
            phoneButton.setTitle("No Phone Available", for: .normal)
            phoneButton.isHidden = true // Optionally hide the button if no phone number
        }
        
        if let websiteURL = place.url {
            websiteButton.setTitle(websiteURL.absoluteString, for: .normal)
            websiteButton.isHidden = false
        } else {
            websiteButton.setTitle("No Website Available", for: .normal)
            websiteButton.isHidden = true // Optionally hide the button if no URL
        }
        
        addPinToMap()
    }
    
    func addPinToMap() {
        // Ensure the placemark has coordinates
        guard let coordinate = place.placemark.location?.coordinate else { return }
        
        // Create an annotation
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = place.name
        
        // Optionally, add a subtitle
        if let phone = place.phoneNumber {
            annotation.subtitle = phone
        }
        
        // Add the annotation to the map
        pinPlaceMapView.addAnnotation(annotation)
        
        // Center the map on the annotation
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        pinPlaceMapView.setRegion(region, animated: true)
    }
    
    @IBAction func websiteButtonTapped(_ sender: Any) {
        if let websiteURL = place.url {
            presentWebsite(url: websiteURL)
        }
    }
    
    @IBAction func phoneButtonTapped(_ sender: Any) {
        initiatePhoneCall()
    }
    
    func initiatePhoneCall() {
        // Ensure the phone number exists and is valid
        guard let phoneNumber = place.phoneNumber else {
            showAlert(title: "Unavailable", message: "This place does not have a phone number.")
            return
        }
        
        // Remove any non-digit characters (optional but recommended)
        let sanitizedNumber = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        // Create the tel URL
        if let phoneURL = URL(string: "tel://\(sanitizedNumber)"),
           UIApplication.shared.canOpenURL(phoneURL) {
            UIApplication.shared.open(phoneURL, options: [:], completionHandler: nil)
        } else {
            // Show an alert if the device cannot make phone calls
            showAlert(title: "Error", message: "Your device cannot make phone calls.")
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
