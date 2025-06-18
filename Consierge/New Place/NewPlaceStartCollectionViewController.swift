//
//  NewPlaceStartCollectionViewController.swift
//  Consierge
//
//  Created by Austin McLaughlin on 12/9/24.
//

import UIKit
import PhotosUI
import MapKit

private let reuseIdentifier = "Cell"

class NewPlaceStartCollectionViewController: UICollectionViewController {
    
    @IBOutlet var nextButton: UIBarButtonItem!
    
    var addressSelected = false
    var photoAdded = false
    var placeAlreadyExists = true
    
    var selectedAddress: String?
    
    var uploadedPics = [UIImage]()
    
    var searchCompleter = MKLocalSearchCompleter()
    var searchResults = [MKLocalSearchCompletion]()

    let addressIndexPath = IndexPath(item:0, section: 1)
    
    let imagePicker = UIImagePickerController()
    var picVC: PHPickerViewController?
    
    var autoCompleteInProgress = false
    
    var validatedCity: City?
    var cityID: Int = 0
    var placeTypeID: Int = 0
    
    let group = DispatchGroup()
    
    var place: ConciergePlace?
    
    var existingPlace: ConciergePlace?
    
    
    var cityRequestTask: Task<Void, Never>? = nil
    var placeTypeRequestTask: Task<Void, Never>? = nil
    var neighborhoodRequestTask: Task<Void, Never>? = nil
    var categoryRequestTask: Task<Void, Never>? = nil
    var placeExistsRequestTask: Task<Void, Never>? = nil
    deinit {
        cityRequestTask?.cancel()
        placeTypeRequestTask?.cancel()
        neighborhoodRequestTask?.cancel()
        categoryRequestTask?.cancel()
        placeExistsRequestTask?.cancel()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.collectionViewLayout = createLayout()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = .pointOfInterest
        shouldSaveEnabled()
        
        imagePicker.delegate = self
        
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    func shouldSaveEnabled() {
        DispatchQueue.main.async {
            self.nextButton.isEnabled = self.addressSelected && self.photoAdded && self.place != nil && !self.autoCompleteInProgress && !self.placeAlreadyExists
        }
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 8
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        switch section {
        case 2:
            switch addressSelected {
            case true:
                return 1
            case false:
                if searchResults.count > 10 {
                    return 10
                } else {
                    return searchResults.count
                }
            }
        case 5:
            return uploadedPics.count
        case 6, 7:
            if existingPlace != nil { return 1 }
            else { return 0 }
        default:
            return 1
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TextLabel", for: indexPath)
            return cell
        case 6:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AlreadyExistsLabel", for: indexPath)
            return cell
        case 1:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SearchPlace", for: indexPath) as! PlaceAddressSearchCollectionViewCell
            cell.delegate = self
            cell.turnOffAutoCorrect()
            
            return cell
        case 2:
            switch addressSelected {
            case false:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddressSuggestion", for: indexPath) as! AddressSuggestionCollectionViewCell
                cell.addressLabel.text = "\(searchResults[indexPath.item].title) \(searchResults[indexPath.item].subtitle)"
                return cell
            case true:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AutoFillStatus", for: indexPath) as! AutoFillStatusCollectionViewCell
                
                switch autoCompleteInProgress {
                case true:
                    cell.autoCompleteLabel.text = "Autocompleting place details"
                    cell.autoCompleteLabel.isHidden = false
                    cell.autoCompleteLabel.textColor = .black
                    cell.activityIndicator.isHidden = false
                    cell.activityIndicator.startAnimating()
                case false:
                    if place == nil {
                        cell.autoCompleteLabel.isHidden = true
                    } else {
                        cell.autoCompleteLabel.isHidden = false
                        cell.autoCompleteLabel.text = "Autocomplete successful"
                        cell.autoCompleteLabel.textColor = .systemGreen
                    }
                    cell.activityIndicator.isHidden = true
                    cell.activityIndicator.stopAnimating()
                }
                return cell
            }
        case 3:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Separator", for: indexPath)
            return cell
        case 4:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChoosePhotos", for: indexPath) as! ChoosePhotosCollectionViewCell
            cell.delegate = self
            return cell
        case 7:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlaceBox", for: indexPath) as! PlaceBoxCollectionViewCell
            //Place object stored in each instance of ViewModel.Item and can be used to configure the cell
            if let existingPlace = existingPlace {
                cell.place = existingPlace
                cell.placeTypeID = existingPlace.placeTypeID
                cell.cityID = existingPlace.placeTypeID
                
                cell.imageRequestTask?.cancel()
                cell.imageRequestTask = nil
                cell.placePic.image = nil
                cell.fetchImage(imageURL: existingPlace.imageURL)
                
                cell.activityIndicator.isHidden = false
                cell.activityIndicator.startAnimating()
                
                cell.placeNameLabel.text = existingPlace.name
            }
            
            return cell
        default:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UploadedPic", for: indexPath) as! UploadedPicCollectionViewCell
            
            cell.uploadedPicImg.image = uploadedPics[indexPath.item]
            cell.idx = indexPath.item
            cell.styleCell()
            cell.delegate = self
            
            return cell
        }
    }
    
    
    func createLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout {  (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            
            switch (sectionIndex, self.addressSelected) {
            case (5, _):
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.50), heightDimension: .fractionalHeight(1))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(140))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
                section.orthogonalScrollingBehavior = .continuous
                
                return section
            case (2, false):
                let size = NSCollectionLayoutSize(
                    widthDimension: NSCollectionLayoutDimension.fractionalWidth(1),
                    heightDimension: NSCollectionLayoutDimension.estimated(33)
                )
                let item = NSCollectionLayoutItem(layoutSize: size)
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitems: [item])

                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
                section.interGroupSpacing = 10
                return section
            case (7, _):
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalWidth(1))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(150), heightDimension: .absolute(150))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 8)
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
                
                return section
            default:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                var hgt = 33.0
                if sectionIndex == 0 || sectionIndex == 6 {
                    hgt = 90
                } else if sectionIndex == 3 {
                    hgt = 10.75
                } else if sectionIndex == 4 {
                    hgt = 55
                }
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(hgt))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
                
                return section
            }
        }
        //simple collection view layout - full width and 140 height + content insets
        return layout
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch indexPath.section {
        case 2:
            selectedAddress = "\(searchResults[indexPath.item].title) \(searchResults[indexPath.item].subtitle)"
            
            aiAutofillPlaceDetails()
            
            addressSelected = true
            autoCompleteInProgress = true
            placeExists(placeName: searchResults[indexPath.item].title, address: searchResults[indexPath.item].subtitle)
            shouldSaveEnabled()
            
            guard let cell = collectionView.cellForItem(at: addressIndexPath) as? PlaceAddressSearchCollectionViewCell, let selectedAddress = selectedAddress else {return}
            cell.cityAddressText.text = selectedAddress
            
            searchResults = []
            collectionView.reloadSections([2])
        default: break
        }
    }
    
    
    @IBSegueAction func nextPressed(_ coder: NSCoder, sender: Any?) -> NewPlaceFinishCollectionViewController? {
        group.wait()
        
        guard let place = place else { return nil }
        
        return NewPlaceFinishCollectionViewController(coder: coder, place: place, uploadedPics: uploadedPics)
    }
    
    @IBAction func unwindToStartCollectionViewController(_ segue: UIStoryboardSegue) {
        place = nil
        addressSelected = false
        existingPlace = nil
        placeAlreadyExists = true
        selectedAddress = nil
        photoAdded = false
        autoCompleteInProgress = false
        uploadedPics = []
        searchResults = []
        if let cell = collectionView.cellForItem(at: addressIndexPath) as? PlaceAddressSearchCollectionViewCell {
            cell.cityAddressText.text = ""
        }
        
        shouldSaveEnabled()
        collectionView.reloadData()
    }
    
    @IBSegueAction func placeSelected(_ coder: NSCoder, sender: UICollectionViewCell?) -> PlaceDetailCollectionViewController? {
        guard let existingPlace = existingPlace, let cell = sender as? PlaceBoxCollectionViewCell, let img = cell.placePic.image else { return nil }
        
        return PlaceDetailCollectionViewController(coder: coder, place: existingPlace, sectionsPlaces: [existingPlace], placePic: img, placeTypeID: existingPlace.placeTypeID, cityID: existingPlace.cityID.cityID)
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if let cell = sender as? PlaceBoxCollectionViewCell {
            if cell.placePic.image == nil { return false }
        }
        return true
    }
}


extension NewPlaceStartCollectionViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate, PHPickerViewControllerDelegate, ChoosePhotosCellDelegate {
    func choosePhotos() {
        displayImageUploadChoices()
    }
    
    func displayImageUploadChoices() {
        selectPics()
    }
    
    func selectPics() {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 5
        config.filter = .images
        config.selection = .ordered
        
        picVC = PHPickerViewController(configuration: config)
        
        guard let picVC = picVC else { return }
        picVC.delegate = self
        
        present(picVC, animated: true)
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)

        // Temporary array to store newly picked images in order
        var newImagesInOrder = Array<UIImage?>(repeating: nil, count: results.count)
        let dispatchGroup = DispatchGroup()

        for (index, result) in results.enumerated() {
            dispatchGroup.enter()
            result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                defer { dispatchGroup.leave() }

                guard let image = object as? UIImage, error == nil else { return }

                newImagesInOrder[index] = image
            }
        }

        dispatchGroup.notify(queue: .main) {
            let newImages = newImagesInOrder.compactMap { $0 }
            self.uploadedPics.append(contentsOf: newImages)

            self.photoAdded = !self.uploadedPics.isEmpty
            self.shouldSaveEnabled()
            self.collectionView.reloadSections([5])
        }
    }

}

extension NewPlaceStartCollectionViewController: MKLocalSearchCompleterDelegate, PlaceAddressSearchCellDelegate {
    func addressUpdated(address: String) {
        addressSelected = false
        existingPlace = nil
        selectedAddress = nil
        place = nil
        autoCompleteInProgress = false
        shouldSaveEnabled()
        
        if address.count > 1 {
            searchCompleter.queryFragment = address
        } else {
            searchResults = []
        }
        collectionView.reloadSections([2])
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        //used for the address search to update results when the address is updated
        completer.resultTypes = [.pointOfInterest]
        searchResults = completer.results
        
        //add results to collectionView once updated
        collectionView.reloadSections([2])
    }
    
    func clearAddressText() {
        addressSelected = false
        place = nil
        existingPlace = nil
        placeAlreadyExists = true
        autoCompleteInProgress = false
        shouldSaveEnabled()
    
        guard let cell = collectionView.cellForItem(at: addressIndexPath) as? PlaceAddressSearchCollectionViewCell else {return}
        cell.cityAddressText.text = ""
        selectedAddress = nil
        
        searchResults = []
        collectionView.reloadSections([2, 6, 7])
    }
}

extension NewPlaceStartCollectionViewController {
    func aiAutofillPlaceDetails() {
        // print("selectedAddress is null: \(selectedAddress == nil)")
        guard let selectedAddress = selectedAddress else {
            clearAddressText()
            return
        }
        
        group.enter()
        
        let systemPrompt = """
You are an autocompletion agent for an application allowing users to create places.

Provide the response in a JSON format. Don't provide any supporting text, only the JSON response. This includes markdown like ``` ``` or json. Only include the valid JSON. The response should start with the character "{" and end with the character "}". See the required format below.
        {
            "placeName": "Place Name Value", 
            "address": "123 Address st City, ST 10000", 
            "city": {
                "cityID": 0,
                "name": "City Name",
                "nickname": "City Nickname",
                "imageURL": "",
                "latitude": 37.3230,
                "longitude": −122.0321823,
                "latitude": 37.3230,
                "n": 38.3230,
                "w": −123.0321823,
                "s": 36.3230,
                "e": −121.0321823,
                "status": "Approved"
            },
            "placeType": "Place Type Value", 
            "website": "https://website.com", 
            "category":"Category", 
            "neighborhood":"Upper East Side", 
            "suggestedDescr": "Suggested description for the place. This will contain a colorful description of the place or perhaps some useful information for people wanting to know more",
            "price": 2,
            "latitude": 37.3230,
            "longitude": −122.0321823,  
            "isLocal": true,
            "phoneNumber": "+1-303-202-2020",
            "menuURL": https://website.com/menu"
        }
"""
        
        let gptPrompt = """
Hello! Please act as an autocompletion agent for an application allowing users to create places. 

Based on the below address please provide autocompletion results for the remaining fields.
\(selectedAddress)

The following fields are required:
    - place name
    - place address (in the format "123 Sixth Ave, New York, NY 10014, United States")
    - place City (a city object with several fields)
        - cityID (always leave as 0)
        - city name
        - city nickname
        - city image url (always leave as an empty string)
        - city center latitude 
        - city center longitude
        - city northern longitude
        - city western latitude
        - city southern longitude
        - city eastern latitude
        - city status (always "Approved")
    - place type (like restaurant, cafe, shopping, museum, etc.)
    - website
    - category (like cuisine for a restaurant place type, or category of cafe for a cafe place type)
    - neighborhood
    - suggested description (a description of this place for someone looking for more info and potentially visiting)
    - price (1-4) (data type is Integer)
    - latitude (data type is Double)
    - longitude (data type is Double)
    - isLocal (whether the place is a chain [False] or a local spot [True]) (data type is Boolean).
    - phoneNumber (String, places phone number in the format +1-303-202-2020, if available, if not leave it out)
    - menuURL (URL to the places menu online, if available, if available, if not leave it out)
"""
        
        let request = ChatGPTCompletionRequest(model: "gpt-4o", systemPrompt: systemPrompt, prompts: [gptPrompt], maxTokens: 500, temperature: 0.5, username: "admin")
        
        
        Task {
            let response = try await request.send()
            if let text = response.choices.first?.message.content {
                if self.autoCompleteInProgress {
                    self.createPlace(gptJson: text)
                } else {
                    // print("auto complete not in progress")
                }
            } else {
                // print("GPT Response not received")
                autoCompleteInProgress = false
                let alert = UIAlertController(title: "Error", message: "GPT Create Place failed", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default))
                self.present(alert, animated: true)
            }
        }
    }
    
    func createPlace(gptJson: String) {
        let decoder = JSONDecoder()
        
        // Attempt to decode the Data object into our Swift structs
        guard let jsonData = gptJson.data(using: .utf8) else {
            autoCompleteInProgress = false
            return
        }
        
        let gptSuggestedPlace: GPTSuggestedConciergePlace?
        
        do {
            gptSuggestedPlace = try decoder.decode(GPTSuggestedConciergePlace.self, from: jsonData)
            group.leave()
            
            guard let gptSuggestedPlace = gptSuggestedPlace else {return}
            
            // get / create city API
            group.enter()
            var city = gptSuggestedPlace.city
            city.imageURL = "/cities/\(gptSuggestedPlace.city.nickname).jpg"
            getOrCreateCity(city: city)
            
            // get / create place type
            group.enter()
            let placeType = PlaceType(id: 0, name: gptSuggestedPlace.placeType, iconName: "", clicked: 0, fsqCategoryCode: "", singularName: gptSuggestedPlace.placeType)
            getOrCreatePlaceType(placeType: placeType)
            
            group.notify(queue: .main) { [weak self] in
                guard let self = self else { return }
                
                // get / create category
                // dependent on place type
                group.enter()
                let genre = Genre(ID: 0, name: gptSuggestedPlace.category, placeTypeID: placeTypeID, clicked: 0, fsqCategoryCode: 0)
                getOrCreateGenre(genre: genre)
                
                // get / create neighborhood
                // dependent on city
                group.enter()
                let neighborhood = Neighborhood(ID: 0, cityID: cityID, name: gptSuggestedPlace.neighborhood, clicked: 0)
                getOrCreateNeighborhood(neighborhood: neighborhood)
                
                group.notify(queue: .main) { [weak self] in
                    guard let self = self else { return }
                    
                    guard let validatedCity = validatedCity else { return }
                    let currentUserID = currentUser.id
                    let currentUserProfPic = currentUser.profPicImageURL
                    var currentUserUsername = ""
                    if let uName = currentUser.username, uName != "" {
                        currentUserUsername = uName
                    } else {
                        currentUserUsername = "\(currentUser.firstName) \(currentUser.lastName.first ?? " ")"
                    }
                    place = ConciergePlace(id: 0, name: gptSuggestedPlace.placeName, descr: gptSuggestedPlace.suggestedDescr, genre: gptSuggestedPlace.category, neighborhood: gptSuggestedPlace.neighborhood, isLocal: gptSuggestedPlace.isLocal, cityID: validatedCity, communityVotes: 0, imageURL: "/places/.jpeg", website: gptSuggestedPlace.website, address: gptSuggestedPlace.address, price: gptSuggestedPlace.price, latitude: gptSuggestedPlace.latitude, longitude: gptSuggestedPlace.longitude, fsqID: nil, specialCategory: nil, version: 1, status: "Approved", placeTypeID: placeTypeID, authorId: currentUserID, authorName: currentUserUsername, authorProfPic: currentUserProfPic, phoneNumber: gptSuggestedPlace.phoneNumber, menuURL: gptSuggestedPlace.menuURL, coverStatus: nil)
                    autoCompleteInProgress = false
                    shouldSaveEnabled()
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                }
            }
        } catch {
            // print("decoding error, json decoder failed to decode the object: \(error)")
            autoCompleteInProgress = false
            group.leave()
        }
    }
    
    func getOrCreateCity(city: City) {
        cityRequestTask?.cancel()
        cityRequestTask = Task {
            if let returnCity = try? await GetOrCreateCityRequest(city: city).send() {
                cityID = returnCity.cityID
                validatedCity = returnCity
            } else {
                // print("error getting or creating city")
                cityID = 0
            }
            group.leave()
            cityRequestTask = nil
        }
    }
    
    func getOrCreatePlaceType(placeType: PlaceType) {
        placeTypeRequestTask?.cancel()
        placeTypeRequestTask = Task {
            if let returnPlaceType = try? await GetOrCreatePlaceTypeRequest(placeType: placeType).send() {
                placeTypeID = returnPlaceType.id
            } else {
                // print("error getting or creating place type")
                placeTypeID = 0
            }
            group.leave()
            placeTypeRequestTask = nil
        }
    }
    
    func getOrCreateGenre(genre: Genre) {
        categoryRequestTask?.cancel()
        categoryRequestTask = Task {
            if let _ = try? await GetOrCreateGenreRequest(genre: genre).send() {
//                print("GENRE!, ", returnGenre)
            } else {
                // print("error retrieving category")
            }
            group.leave()
            categoryRequestTask = nil
        }
    }
    
    
    func getOrCreateNeighborhood(neighborhood: Neighborhood) {
        neighborhoodRequestTask?.cancel()
        neighborhoodRequestTask = Task {
            if let _ = try? await GetOrCreateNeighborhoodRequest(neighborhood: neighborhood).send() {
//                print("NEIGHBORHOOD!, ", returnNeighborhood)
            } else {
                // print("error retrieving neighborhood")
            }
            group.leave()
            neighborhoodRequestTask = nil
        }
    }
}

extension NewPlaceStartCollectionViewController: UploadedPhotoCellDelegate {
    func removePic(idx: Int) {
        uploadedPics.remove(at: idx)
        if uploadedPics.isEmpty {
            photoAdded = false
            shouldSaveEnabled()
        }
        collectionView.reloadSections([5])
    }
}

extension NewPlaceStartCollectionViewController {
    func placeExists(placeName: String, address: String) {
        placeExistsRequestTask?.cancel()
        placeExistsRequestTask = Task {
            if let places = try? await PlaceExistsRequest(placeName: placeName, address: address).send() {
                if places.count > 0 {
                    existingPlace = places[0]
                    placeAlreadyExists = true
                } else {
                    placeAlreadyExists = false
                }
            } else {
                placeAlreadyExists = false
            }
            DispatchQueue.main.async {
                self.collectionView.reloadSections([6, 7])
            }
            placeExistsRequestTask = nil
        }
    }
}
