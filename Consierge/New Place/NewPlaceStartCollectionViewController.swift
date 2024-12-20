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
    var selectedAddress: String?
    var photoAdded = false
    
    var uploadedPics = [UIImage]()
    
    var searchCompleter = MKLocalSearchCompleter()
    var searchResults = [MKLocalSearchCompletion]()

    let addressIndexPath = IndexPath(item:0, section: 1)
    
    let imagePicker = UIImagePickerController()
    var picVC: PHPickerViewController?
    
    var validatedCity: City?
    var cityID: Int = 0
    var placeTypeID: Int = 0
    
    let group = DispatchGroup()
    
    var place: ConciergePlace?
    
    
    var cityRequestTask: Task<Void, Never>? = nil
    var placeTypeRequestTask: Task<Void, Never>? = nil
    var neighborhoodRequestTask: Task<Void, Never>? = nil
    var categoryRequestTask: Task<Void, Never>? = nil
    deinit {
        cityRequestTask?.cancel()
        placeTypeRequestTask?.cancel()
        neighborhoodRequestTask?.cancel()
        categoryRequestTask?.cancel()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.collectionViewLayout = createLayout()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = .pointOfInterest
        shouldSaveEnabled()
        
        imagePicker.delegate = self
        
        //PHPicker function to allow user to select a number of photos to add to the current place
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 5
        config.filter = .images
        config.selection = .ordered
        
        picVC = PHPickerViewController(configuration: config)
        
        guard let picVC = picVC else { return }
        picVC.delegate = self
        
        
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    func shouldSaveEnabled() {
        nextButton.isEnabled = addressSelected && photoAdded
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 6
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        switch section {
        case 2:
            if searchResults.count > 5 {
                return 5
            } else {
                return searchResults.count
            }
        case 5:
            return uploadedPics.count
        default:
            return 1
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TextLabel", for: indexPath)
            return cell
        case 1:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SearchPlace", for: indexPath) as! PlaceAddressSearchCollectionViewCell
            cell.delegate = self
            return cell
        case 2:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddressSuggestion", for: indexPath) as! AddressSuggestionCollectionViewCell
            cell.addressLabel.text = "\(searchResults[indexPath.item].title) \(searchResults[indexPath.item].subtitle)"
            return cell
        case 3:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Separator", for: indexPath)
            return cell
        case 4:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChoosePhotos", for: indexPath) as! ChoosePhotosCollectionViewCell
            cell.delegate = self
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
            
            switch sectionIndex {
            case 5:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.50), heightDimension: .fractionalHeight(1))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(140))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
                section.orthogonalScrollingBehavior = .continuous
                
                return section
            case 2:
                let size = NSCollectionLayoutSize(
                    widthDimension: NSCollectionLayoutDimension.fractionalWidth(1),
                    heightDimension: NSCollectionLayoutDimension.estimated(33)
                )
                let item = NSCollectionLayoutItem(layoutSize: size)
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitem: item, count: 1)

                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
                section.interGroupSpacing = 10
                return section
            default:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                var hgt = 33.0
                if sectionIndex == 0 {
                    hgt = 90
                } else if sectionIndex == 3 {
                    hgt = 10.75
                } else if sectionIndex == 4 {
                    hgt = 55
                }
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(hgt))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)
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
}


extension NewPlaceStartCollectionViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate, PHPickerViewControllerDelegate, ChoosePhotosCellDelegate {
    func choosePhotos() {
        displayImageUploadChoices()
    }
    
    func displayImageUploadChoices() {
        selectPics()
    }
    
    func selectPics() {
        guard let picVC = picVC else { return }
        present(picVC, animated: true)
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        //PHPIcker delegate method called once the user finishes selecting the images
        picker.dismiss(animated: true, completion:  nil)
        
        for result in results {
            result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                guard let image = object as? UIImage, error == nil else {return}
                self.photoAdded = true
                DispatchQueue.main.async {
                    self.uploadedPics.append(image)
                    self.shouldSaveEnabled()
                    self.collectionView.reloadSections([5])
                }
            }
        }
    }
}

extension NewPlaceStartCollectionViewController: MKLocalSearchCompleterDelegate, PlaceAddressSearchCellDelegate {
    func addressUpdated(address: String) {
        addressSelected = false
        selectedAddress = nil
        
        if address.count > 1 {
            searchCompleter.queryFragment = address
        } else {
            searchResults = []
            collectionView.reloadSections([2])
        }
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
        shouldSaveEnabled()
    
        guard let cell = collectionView.cellForItem(at: addressIndexPath) as? PlaceAddressSearchCollectionViewCell else {return}
        cell.cityAddressText.text = ""
        selectedAddress = nil
        
        searchResults = []
        collectionView.reloadSections([2])
    }
}

import OpenAIKit
extension NewPlaceStartCollectionViewController {
    func aiAutofillPlaceDetails() {
        guard let selectedAddress = selectedAddress else {return}
        
        group.enter()
        
        let gptPrompt = """
Hello! Please act as an autocompletion agent for an application allowing users to create places. 

Based on the below address please provide autocompletion results for the remaining fields.
\(selectedAddress)

The following fields are required:
    - place name
    - place address
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

Provide the response in a JSON format with the exact field names provided below. Don't provide any supporting text, only the JSON response.
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
            "isLocal": true
        }
"""
        
        
        let username = currentUser.username ?? "\(currentUser.firstName) \(currentUser.lastName)"
        let aiMessage = AIMessage(role: .user, content: gptPrompt)
        openAI.sendChatCompletion(newMessage: aiMessage, previousMessages: [], model: .gptV4(.gpt4), maxTokens: 500, n: 1, user: username, completion: { [weak self] result in
            switch result {
            case .success(let aiResult):
                // Handle the result actions
                if let text = aiResult.choices.first?.message?.content {
                    print(text)
                    self?.createPlace(gptJson: text)
                }
            case .failure(let error):
                //Handle the error
                let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default))
                self?.present(alert, animated: true)
            }
        })
    }
    
    func createPlace(gptJson: String) {
        let decoder = JSONDecoder()
        
        // Attempt to decode the Data object into our Swift structs
        guard let jsonData = gptJson.data(using: .utf8) else {
            print("Error: Cannot convert string to Data object")
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
            city.imageURL = "/Concierge/photos/cityHeaders/\(gptSuggestedPlace.city.nickname).jpg"
            getOrCreateCity(city: city)
            
            // get / create place type
            group.enter()
            let placeType = PlaceType(id: 0, name: gptSuggestedPlace.placeType, iconName: "", clicked: 0, fsqCategoryCode: "")
            getOrCreatePlaceType(placeType: placeType)
            
            group.wait()
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
            
            group.wait()
            
            guard let validatedCity = validatedCity else { return }
            place = ConciergePlace(id: 0, name: gptSuggestedPlace.placeName, descr: gptSuggestedPlace.suggestedDescr, genre: gptSuggestedPlace.category, neighborhood: gptSuggestedPlace.neighborhood, isLocal: gptSuggestedPlace.isLocal, cityID: validatedCity, communityVotes: 0, imageURL: "/Concierge/photos/restaurants/\(gptSuggestedPlace.placeName)\(gptSuggestedPlace.neighborhood).jpeg", website: gptSuggestedPlace.website, address: gptSuggestedPlace.address, price: gptSuggestedPlace.price, latitude: gptSuggestedPlace.latitude, longitude: gptSuggestedPlace.longitude, fsqID: nil, specialCategory: nil, version: 1, status: "Approved", placeTypeID: placeTypeID)
        } catch {
            print("decoding error, json decoder failed to decode the object: \(error)")
            group.leave()
        }
    }
    
    func getOrCreateCity(city: City) {
        cityRequestTask?.cancel()
        cityRequestTask = Task {
            if let returnCity = try? await GetOrCreateCityRequest(city: city).send() {
                print("CITY!, ",returnCity)
                cityID = returnCity.cityID
                validatedCity = returnCity
            } else {
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
                print("PLACETYPE!, ", returnPlaceType)
                placeTypeID = returnPlaceType.id
            } else {
                placeTypeID = 0
            }
            group.leave()
            placeTypeRequestTask = nil
        }
    }
    
    func getOrCreateGenre(genre: Genre) {
        categoryRequestTask?.cancel()
        categoryRequestTask = Task {
            if let returnGenre = try? await GetOrCreateGenreRequest(genre: genre).send() {
                print("GENRE!, ", returnGenre)
            } else {
                print("err")
            }
            group.leave()
            categoryRequestTask = nil
        }
    }
    
    
    func getOrCreateNeighborhood(neighborhood: Neighborhood) {
        neighborhoodRequestTask?.cancel()
        neighborhoodRequestTask = Task {
            if let returnNeighborhood = try? await GetOrCreateNeighborhoodRequest(neighborhood: neighborhood).send() {
                print("NEIGHBORHOOD!, ", returnNeighborhood)
            } else {
                print("err")
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
