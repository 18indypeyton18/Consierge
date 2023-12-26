//
//  OpenDirections.swift
//  Concierge 0.1
//
//  Created by Austin McLaughlin on 7/5/22.
//

import CoreLocation
import UIKit
import MapKit

enum MapApp: String {
    case apple = "Apple Maps"
    case google = "Google Maps"
}

class OpenMapDirections {
    // Utilized by RestaurantDetail VC
    // Display an alert controller allowing to user to navigate using Apple Maps or Google Maps
    // Use Latitude and Longitude to set the destination and show the user directions
    
    static func present(in viewController: UIViewController, sourceView: UIView, address: String, placeName: String) {
        let actionSheet = UIAlertController(title: "Open Location", message: "Choose an app to open direction", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Apple Maps", style: .default, handler: { _ in
            // Pass the coordinate that you want here
            
            let geocoder = CLGeocoder()

            geocoder.geocodeAddressString(address) {
                placemarks, error in
                let placemark = placemarks?.first
                let lat = placemark?.location?.coordinate.latitude
                let lon = placemark?.location?.coordinate.longitude
                if let lat = lat, let lon = lon {
                    openMapInApp(.apple, latitude: lat, longitude: lon, placeName: placeName)
                }
            }
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Google Maps", style: .default, handler: { _ in
            // Pass the coordinate inside this URL
            let geocoder = CLGeocoder()

            geocoder.geocodeAddressString(address) {
                placemarks, error in
                let placemark = placemarks?.first
                let lat = placemark?.location?.coordinate.latitude
                let lon = placemark?.location?.coordinate.longitude
                if let lat = lat, let lon = lon {
                    openMapInApp(.google, latitude: lat, longitude: lon, placeName: placeName)
                }
            }
        }))
        
        actionSheet.popoverPresentationController?.sourceRect = sourceView.bounds
        actionSheet.popoverPresentationController?.sourceView = sourceView
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        viewController.present(actionSheet, animated: true, completion: nil)
    }
}

func openMapInApp(_ mapApp: MapApp, latitude: Double, longitude: Double, placeName: String) {
    let coordinate = "\(latitude),\(longitude)"
    switch mapApp {
    case .apple:
        // Apple Maps URL Scheme
        if let url = URL(string: "http://maps.apple.com/?ll=\(coordinate)&q=\(placeName.replacingOccurrences(of: " ", with: "+"))") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    case .google:
        // Google Maps URL Scheme
        if let url = URL(string: "comgooglemaps://?q=\(coordinate)(\(placeName.replacingOccurrences(of: " ", with: "+")))&center=\(coordinate)&zoom=14&views=traffic") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
