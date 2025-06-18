//
//  SignUpLocationViewController.swift
//  Consierge
//
//  Created by Austin McLaughlin on 12/27/23.
//

import UIKit
import MapKit
import CoreLocation

class SignUpLocationViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UITextFieldDelegate {

    let email: String
    let firstName: String
    let lastName: String
    
    var addressSelected = false
    var searchCompleter = MKLocalSearchCompleter()
    var searchResults = [MKLocalSearchCompletion]()
    
    //setup locValue in case user chooses to share location
    var locValue: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var locDenied = false
    let locationManager = CLLocationManager()
    
    var segued = false
    
    @IBOutlet var addressText: UITextField!
    @IBOutlet var shareLocButton: UIButton!
    @IBOutlet var addressCollectionView: UICollectionView!
    @IBOutlet var nextButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupPage()
        styleTextFields()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    init?(coder: NSCoder, email: String, firstName: String, lastName: String) {
        //init with required Place and optional section of Places
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        
        super.init(coder: coder)
    }
    
    func setupPage() {
        shareLocButton.layer.cornerRadius = 12
        
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.pointOfInterest, .address]
        
        addressCollectionView.dataSource = self
        addressCollectionView.delegate = self
        addressCollectionView.collectionViewLayout = createLayout()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //for addressCV return # of search results
        //for picsCV return # of uploaded pics
        return searchResults.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddressSuggestion", for: indexPath) as? AddressSuggestionCollectionViewCell else {
            return UICollectionViewCell()
        }
        let searchResult = searchResults[indexPath.row]
        cell.addressLabel.text = "\(searchResult.title) \(searchResult.subtitle)"
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //if address -> update the addressText field and set addressSelected to True
        let cell = addressCollectionView.cellForItem(at: indexPath) as! AddressSuggestionCollectionViewCell
        let address = cell.addressLabel.text
        addressText.text = address
        
        //determine the Latitude and Longitude and set those values (async closure)
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address ?? "Manhattan, NY 10036") { placemarks, error in
            let placemark = placemarks?.first
            self.locValue = CLLocationCoordinate2D(latitude: placemark?.location?.coordinate.latitude ?? 0, longitude: placemark?.location?.coordinate.longitude ?? 0)
            self.performSegue(withIdentifier: "segueToPasswordPicker", sender: nil)
        }
        
        //update the view
        addressSelected = true
        
        searchResults = []
        addressCollectionView.reloadData()
        addressText.endEditing(false)
    }
    
    func createLayout() -> UICollectionViewCompositionalLayout {
        //used for the addressesCollectionView
        
        let size = NSCollectionLayoutSize (
            widthDimension: NSCollectionLayoutDimension.fractionalWidth(1),
            heightDimension: NSCollectionLayoutDimension.estimated(33)
        )
        let item = NSCollectionLayoutItem(layoutSize: size)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
        section.interGroupSpacing = 10
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        
        return layout
    }
    
    @IBAction func locationTyped(_ sender: Any) {
        //update addressSearch results any time the text is updated
        addressSelected = false
        if addressText.text?.count ?? 1 > 2 {
            searchCompleter.queryFragment = addressText.text ?? ""
        }
    }
    
    @IBAction func shareLocation(_ sender: Any) {
        segued = false
        locationManager.requestWhenInUseAuthorization()
    }
    
    @IBAction func nextPressed(_ sender: Any) {
        moveToNext()
    }
    
    func moveToNext() {
        if searchResults != [] {
            let addy = searchResults[0].title
            let geocoder = CLGeocoder()
            geocoder.geocodeAddressString(addy) { placemarks, error in
                let placemark = placemarks?.first
                self.locValue = CLLocationCoordinate2D(latitude: placemark?.location?.coordinate.latitude ?? 0, longitude: placemark?.location?.coordinate.longitude ?? 0)
                self.performSegue(withIdentifier: "segueToPasswordPicker", sender: nil)
            }
        } else {
            self.performSegue(withIdentifier: "segueToPasswordPicker", sender: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? SignUpPasswordViewController {
            dest.email = email
            dest.firstName = firstName
            dest.lastName = lastName
            dest.longitude = locValue.longitude
            dest.latitude = locValue.latitude
        }
    }
    
    func styleTextFields() {
        //sets shadows for the text fields, sets delegates to enable the return key, and gesture recognizers to dismiss the keyboard
        let textFields = [addressText, shareLocButton, nextButton]
        for textField in textFields {
            
            textField?.layer.shadowColor = UIColor.lightGray.cgColor
            textField?.layer.shadowOffset = CGSize(width: 0, height: 1)
            textField?.layer.shadowRadius = 2.0
            textField?.layer.shadowOpacity = 0.5
        }
        
        self.addressText.delegate = self
        
        self.addressText.userActivity?.isEligibleForPrediction = true
        
        //let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        //view.addGestureRecognizer(tap)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // move to the next field if on the first 4 fields, press Login button if on the password field
        switchBasedNextTextField(textField)
        return true
    }
    
    private func switchBasedNextTextField(_ textField: UITextField) {
        if nextButton.isEnabled {
            moveToNext()
        }
    }
}

extension SignUpLocationViewController: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        //used for the address search to update results when the address is updated
        searchResults = completer.results
        
        //add results to collectionView once updated
        addressCollectionView.reloadData()
    }
}


// MARK: Location Manager Extension
extension SignUpLocationViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //method to get the user's current location coordinates
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        self.locValue = locValue
        if !segued {
            segued = true
            performSegue(withIdentifier: "segueToPasswordPicker", sender: nil)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // print("location finder error")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        //called when the location authorization status is changed - if authorized start updating user's location
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
        default:
            manager.stopUpdatingLocation()
        }
    }
}
