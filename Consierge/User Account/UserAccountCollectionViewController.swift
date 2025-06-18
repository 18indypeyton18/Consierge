//
//  UserAccountCollectionViewController.swift
//  Consierge
//
//  Created by Austin McLaughlin on 12/28/23.
//

import UIKit
import SafariServices

var profPicture: UIImage?

class UserAccountCollectionViewController: UICollectionViewController, UINavigationControllerDelegate {
    
    var selectedSegmentIndex = 0
    var profPicURL: String?
    
    var itinerarySelectedPlace: Place?
    
    var placesAuthored: Int?
    
    var imageRequestTask: Task<Void,Never>? = nil
    var fsqPlacesRequestTask: Task<Void, Never>? = nil
    var authoredRequestTask: Task<Void, Never>? = nil
    deinit {
        imageRequestTask?.cancel()
        fsqPlacesRequestTask?.cancel()
        authoredRequestTask?.cancel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        if currentUser.email == "GuestUser" {
            let bundle = Bundle(identifier: "com.ALMApps.Consierge")
            let storyboard = UIStoryboard(name: "Main", bundle: bundle)
            
            let homeController = storyboard.instantiateViewController(identifier: "HomePage")
            
            (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(homeController)
        }
        
        setupPage()
        collectionView.collectionViewLayout = createLayout()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if itineraryAdded || placeRecentlyLoved {
            let indexSet = IndexSet(integer: 2)
            self.collectionView.reloadSections(indexSet)
            itineraryAdded = false
            placeRecentlyLoved = false
        }
    }
    
    func setupPage() {
        getPlacesAuthored()
        let itFunc = ItineraryFunctions()
        itFunc.delegate = self
        itFunc.getItineraries()
        if profPicture == nil {
            updateProfPic()
        } else {
            let indexSet = IndexSet(integer: 0)
            collectionView.reloadSections(indexSet)
        }
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 3
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        switch section {
        case 0:
            return 1
        case 1:
            return 2
        default:
            switch selectedSegmentIndex {
            case 0:
                return userLovedPlaces.count
            default:
                return itineraries.count
            }
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UserAccountHeader", for: indexPath) as! UserAccountHeaderCollectionViewCell
            
            cell.userNameLabel.text = "Hi, \(currentUser.firstName)!"
            
            //circular profile pic
            cell.profPicImageView.layer.borderWidth = 1.0
            cell.profPicImageView.layer.masksToBounds = false
            cell.profPicImageView.layer.borderColor = UIColor.white.cgColor
            cell.profPicImageView.layer.cornerRadius = cell.profPicImageView.frame.size.width / 2
            cell.profPicImageView.clipsToBounds = true
            
            cell.placesAuthoredLabel.text = "\(placesAuthored ?? 0) Places Added"
            
            if let profPicture = profPicture {
                cell.profPicImageView.image = profPicture
            }
            
            cell.delegate = self
        
            return cell
        case 1:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UserAccountSegment", for: indexPath) as! UserAccountSegmentControllerCollectionViewCell
            
            if indexPath.item != 0 {
                cell.segmentName.text = "Itineraries"
                cell.segmentIcon.image = UIImage(systemName: "list.clipboard")
            } else {
                cell.segmentName.text = "Loved Places"
                cell.segmentIcon.image = UIImage(systemName: "heart")
            }
            
            cell.segmentSelectedBar.layer.shadowColor = UIColor.gray.cgColor
            cell.segmentSelectedBar.layer.shadowOffset = CGSize(width: 0.0, height: 0.5)
            cell.segmentSelectedBar.layer.shadowOpacity = 0.5
            
            if indexPath.item == selectedSegmentIndex  {
                cell.segmentSelectedBar.backgroundColor = .black
            } else {
                cell.segmentSelectedBar.backgroundColor = .white
            }
            
            return cell
        default:
            switch selectedSegmentIndex {
            case 0:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UserAccountLovedPlace", for: indexPath) as! UserAccountLovedPlaceCollectionViewCell
                
                //Place object stored in each instance of ViewModel.Item and can be used to configure the cell
                var place: Place?
                place = userLovedPlaces[indexPath.item]
                guard let place = place else { return cell }
                
                cell.place = place
                
                //fetch image with cells fetchImage function
                //activity indicator stopped once the image is returned
                cell.imageRequestTask?.cancel()
                cell.imageRequestTask = nil
                
                cell.fetchImage(imageURL: place.imageURL)
                
                cell.placeNameLabel.text = place.name
                
                switch place.self {
                case is FSQPlace:
                    cell.dateLovedLabel.text = getLovedPlaceTimestamp(placeID: 0, fsqID: place.fsqID ?? "", placeSource: .fsq)
                default:
                    cell.dateLovedLabel.text = getLovedPlaceTimestamp(placeID: place.id, fsqID: "", placeSource: .concierge)
                }
                
                cell.delegate = self
                
                //return cell for each item
                return cell
            default:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UserAccountItinerary", for: indexPath) as! ItineraryCollectionViewCell
                
                //Place object stored in each instance of ViewModel.Item and can be used to configure the cell
                let itinerary = itineraries[indexPath.item]
                cell.itinerary = itinerary
                
                cell.activityIndicator.startAnimating()
                cell.itineraryNameLabel.text = itinerary.name
                
                if let imageURL = itinerary.coverImageURL {
                    cell.fetchImage(imageURL: imageURL, src: itinerary.coverImageSrc)
                }
                
                guard let itLines = itineraryLinesDict[itinerary.ID] else {return cell}
                
                switch itLines.count {
                case 0:
                    cell.placeName1.isHidden = true
                    cell.itineraryDesc1.isHidden = true
                default:
                    cell.placeName1.isHidden = false
                    cell.itineraryDesc1.isHidden = false
                    cell.placeName1.text = itLines[0].placeName
                    
                    var descrText = ""
                    if let startDateDate = itLines[0].startDateDate, itLines[0].customNote != "" {
                        let formattedDate = formatDateToReadableString(startDateDate)
                        descrText = "\(formattedDate) ~ \(itLines[0].customNote)"
                    } else if let startDateDate = itLines[0].startDateDate {
                        let formattedDate = formatDateToReadableString(startDateDate)
                        descrText = "\(formattedDate)"
                    } else if itLines[0].customNote != "" {
                        descrText = "\(itLines[0].customNote)"
                    } else {
                        descrText = ""
                    }
                    cell.itineraryDesc1.text = descrText
                    
                    cell.separator.isHidden = true
                    cell.placeName2.isHidden = true
                    cell.itineraryDesc2.isHidden = true
                    cell.dotDotDotLabel.isHidden = true
                }
                
                switch itLines.count {
                case 0, 1:
                    cell.separator.isHidden = true
                    cell.placeName2.isHidden = true
                    cell.itineraryDesc2.isHidden = true
                default:
                    cell.separator.isHidden = false
                    
                    cell.placeName2.isHidden = false
                    cell.itineraryDesc2.isHidden = false
                    cell.placeName2.text = itLines[1].placeName
                    
                    var descrText2 = ""
                    if let startDateDate = itLines[1].startDateDate, itLines[1].customNote != "" {
                        let formattedDate = formatDateToReadableString(startDateDate)
                        descrText2 = "\(formattedDate) ~ \(itLines[1].customNote)"
                    } else if let startDateDate = itLines[1].startDateDate {
                        let formattedDate = formatDateToReadableString(startDateDate)
                        descrText2 = "\(formattedDate)"
                    } else if itLines[1].customNote != "" {
                        descrText2 = "\(itLines[1].customNote)"
                    } else {
                        descrText2 = ""
                    }
                    cell.itineraryDesc2.text = descrText2
                    
                    cell.dotDotDotLabel.isHidden = false
                }
                
                if itLines.count <= 2 {
                    cell.dotDotDotLabel.isHidden = true
                }
                
                cell.delegate = self
                
                return cell
            }
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            if selectedSegmentIndex == indexPath.item { return }
            
            selectedSegmentIndex = indexPath.item
            
            let newLayout = createLayout()
            collectionView.setCollectionViewLayout(newLayout, animated: true)
            
            let indexSet: IndexSet = [1, 2]
            collectionView.reloadSections(indexSet)
            
        } else if indexPath.section == 2 {
            
        }
    }
    
    func createLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            switch sectionIndex {
            case 0:
                let size = NSCollectionLayoutSize(widthDimension:.fractionalWidth(1), heightDimension: .absolute(125))
                let item = NSCollectionLayoutItem(layoutSize: size)
                
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 5, trailing: 0)
                
                return section
            case 1:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .absolute(40))
                
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0)
                section.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
                
                return section
            default:
                switch self.selectedSegmentIndex {
                case 0:
                    let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(70))
                    let item = NSCollectionLayoutItem(layoutSize: itemSize)
                    item.contentInsets = NSDirectionalEdgeInsets(top: 3, leading: 5, bottom: 2, trailing: 5)
                    
                    let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(70))
                    let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                    
                    let section = NSCollectionLayoutSection(group: group)
                    section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 7, trailing: 0)
                    
                    return section
                default:
                    let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(160))
                    let item = NSCollectionLayoutItem(layoutSize: itemSize)
                    item.contentInsets = NSDirectionalEdgeInsets(top: 3, leading: 5, bottom: 2, trailing: 5)
                    
                    let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(160))
                    let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                    
                    let section = NSCollectionLayoutSection(group: group)
                    section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 12, trailing: 0)
                    
                    return section
                }
            }
        }
        return layout
    }
    
    @IBSegueAction func lovedPlaceSelected(_ coder: NSCoder, sender: Any?) -> UICollectionViewController? {
        guard let cell = sender as? UserAccountLovedPlaceCollectionViewCell, let place = cell.place, let img = cell.placePic.image, let _ = collectionView.indexPath(for: cell) else {return nil}
        return placeSelected(place: place, img: img, coder: coder)
    }
    
    func placeSelected(place: Place, img: UIImage, coder: NSCoder) -> UICollectionViewController? {
        //return DetailVC
        var cityID = nil as Int?
        if place.cityID.cityID > 0 { cityID = place.cityID.cityID }
        return PlaceDetailCollectionViewController(coder: coder, place: place, sectionsPlaces: userLovedPlaces, placePic: img, placeTypeID: 0, cityID: cityID)
    }
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if let cell = sender as? UserAccountLovedPlaceCollectionViewCell {
            if cell.placePic.image == nil { return false }
        }
        return true
    }
    
    
    @IBSegueAction func itinerarySelected(_ coder: NSCoder, sender: UICollectionViewCell?) -> ViewItineraryCollectionViewController? {
        //Segue to Viewitinerary page to display the selected Itinerary
        
        guard let cell = sender, let indexPath = collectionView.indexPath(for: cell) else { return nil }
        
        let itinerary = itineraries[indexPath.row]
        let itineraryLines = itineraryLinesDict[itinerary.ID]
        guard let itineraryLines = itineraryLines else {return nil}
        
        return ViewItineraryCollectionViewController(coder: coder, itinerary: itinerary, itineraryLines: itineraryLines)
    }
    
    @IBAction func unwindToUserAccount(segue: UIStoryboardSegue) {}
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AddToItinerary" {
            let navController = segue.destination as! UINavigationController
            let tableController = navController.topViewController as! AddToItineraryTableViewController
            guard let place = itinerarySelectedPlace else { return }
            var isFSQPlace = false
            var type = "Concierge"
            if let _ = place as? FSQPlace {
                isFSQPlace = true
                type = "FSQ"
            }
            tableController.place = place
            tableController.cityID = place.cityID
            tableController.isFSQPlace = isFSQPlace
            
            tableController.type = type
        }
        
        if segue.identifier == "UserActivity" {
            let cvc = segue.destination as! UserActivityCollectionViewController
            cvc.userID = currentUser.id
            if let uName = currentUser.username, uName != "" {
                cvc.userName = uName
            } else {
                cvc.userName = "\(currentUser.firstName) \(currentUser.lastName.first ?? " ")"
            }
        }
    }
    
}

extension UserAccountCollectionViewController: UserAccountHeaderCellDelegate, UIImagePickerControllerDelegate {
    func authorLabelClicked() {
        performSegue(withIdentifier: "UserActivity", sender: nil)
    }
    
    func updateProfPicClicked() {
        //Display an Alert Controller at the bottom of the screen allowing the user to either select an image or use the camera to take a new image
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        let alertController = UIAlertController(title: "Choose Image", message: nil, preferredStyle: .actionSheet)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let cameraAction = UIAlertAction(title: "Camera", style: .default, handler: { action in
                imagePicker.sourceType = .camera
                self.present(imagePicker, animated:true, completion: nil)
            })
            alertController.addAction(cameraAction)
        }
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let photoLibraryAction = UIAlertAction(title: "Camera Roll", style: .default, handler: { action in
                imagePicker.sourceType = .photoLibrary
                self.present(imagePicker, animated:true, completion: nil)
            })
            alertController.addAction(photoLibraryAction)
        }
        
        alertController.popoverPresentationController?.sourceView = collectionView
        
        present(alertController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        //Once the user has selected an image or takena  new iamge call the uploadPic(image) func and update the profPic imageView
        guard let selectedImage = info[.originalImage] as? UIImage else {return}
        uploadPic(pic: selectedImage)
        profPicture = selectedImage

        dismiss(animated: true, completion: nil)
    }
    
    func uploadPic(pic: UIImage) {
        //Triggered after a profile pic is uploaded - used to upload the image and set the correct path on the User Record in the DB
        
        let userID = currentUser.id
        let fileName = "\(userID).jpeg"
        
        let imageURL = "/users/\(fileName)"
        
        let params = ["name": "AustinMcL","id": "12345","type":"users"]
        
        
        let imageUpload = ImageUpload(image: pic, imageURL: imageURL, key: "restaurantPic", params: params, fileName: fileName)!
        let userProfPic = ProfilePic(imageURL: imageURL, userID: userID)

        Task {
            try? await NewImageRequest(imageUpload: imageUpload).send()
        }
        Task {
            let result = try? await UpdateUserProfPicRequest(profilePic: userProfPic).send()
            if let _ = result {
                UserDefaults.standard.set(imageURL, forKey: "profPicURL")
                profPicture = pic
                DispatchQueue.main.async {
                    self.collectionView.reloadSections(IndexSet(integer: 0))
                }
            } else {
                // print("error uploading User Profile Pic")
            }
        }
    }
    
    func updateProfPic() {
        //method to fetch the user's profile pic while the view loads and display it in the circular profPic image view
        
        if let profPicLink = currentUser.profPicImageURL {
            profPicURL = profPicLink
        }
        
        if let profPicURL = profPicURL {
            imageRequestTask = Task {
                if let image = try? await ImageRequest(path: profPicURL).send() {
                    DispatchQueue.main.async {
                        profPicture = image
                        let indexSet = IndexSet(integer: 0)
                        self.collectionView.reloadSections(indexSet)
                    }
                }
                self.imageRequestTask = nil
            }
        }
    }
}

extension UserAccountCollectionViewController: UserAccountLovedPlaceCollectionViewCellDelegate {
    func addToItinerary(_ place: any Place, isFSQ: Bool) {
        itinerarySelectedPlace = place
        self.performSegue(withIdentifier: "AddToItinerary", sender: nil)
    }
    
    func addComment(_ placeID: Int) {
    }
    
    func seePhotos(_ placeID: Int) {
    }
    
    func presentWebsite(url: URL) {
        let safariViewController = SFSafariViewController(url: url)
        present(safariViewController, animated: true, completion: nil)
    }
    
    func presentDirections(address: String, placeName: String) {
        OpenMapDirections.present(in: self, sourceView: self.view, address: address, placeName: placeName)
    }
    
    func placeLoved(place: any Place) {
        let indexSet = IndexSet(integer: 2)
        self.collectionView.reloadSections(indexSet)
    }
}

extension UserAccountCollectionViewController {
    func getLovedPlaceTimestamp(placeID: Int, fsqID: String, placeSource: PlaceSource) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        if placeSource == .concierge {
            let lovePlace = lovedPlaceDict["\(placeID)"]
            let dateString = lovePlace?.lovedDate
            guard var dateString = dateString else { return "" }
            
            if dateString.hasSuffix("Z") {
                dateString = String(dateString.dropLast())
                dateString = dateString.replacingOccurrences(of: "T", with: " ")
            }

            if let date = dateFormatter.date(from: dateString) {
                return timeAgo(from: date)
            }
            else {
                return ""
            }
        } else {
            let lovePlace = lovedPlaceDict[fsqID]
            let dateString = lovePlace?.lovedDate
            guard var dateString = dateString else { return "" }
            
            if dateString.hasSuffix("Z") {
                dateString = String(dateString.dropLast())
                dateString = dateString.replacingOccurrences(of: "T", with: " ")
            }

            if let date = dateFormatter.date(from: dateString) {
                return timeAgo(from: date)
            }
            else {
                return ""
            }
        }
    }
    
    func timeAgo(from lovedDate: Date, in timeZone: TimeZone = TimeZone.current) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .weekOfYear, .day, .hour, .minute], from: lovedDate, to: now)
        
        if let year = components.year, year >= 1 {
            return "\(year)y ago"
        } else if let month = components.month, month >= 1 {
            return "\(month)mo ago"
        } else if let week = components.weekOfYear, week >= 1 {
            return "\(week)w ago"
        } else if let day = components.day, day >= 1 {
            return "\(day)d ago"
        } else if let hour = components.hour, hour >= 1 {
            return "\(hour)h ago"
        } else if let minute = components.minute, minute >= 1 {
            return "\(minute)m ago"
        } else {
            return "just now"
        }
    }
}

extension UserAccountCollectionViewController {
    func formatDateToReadableString(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        return dateFormatter.string(from: date)
    }
}


extension UserAccountCollectionViewController: ItineraryCellDelegate {
    func updateAfterDelete(_ itinerary: Itinerary) {
        let indexSet = IndexSet(integer: 2)
        self.collectionView.reloadSections(indexSet)
    }
}

extension UserAccountCollectionViewController {
    func getPlacesAuthored() {
        let userID = currentUser.id
        authoredRequestTask = Task {
            if let ct = try? await PlacesAuthoredNumRequest(userID: userID).send() {
                placesAuthored = ct
            }
            let indexSet = IndexSet(integer: 0)
            DispatchQueue.main.async {
                self.collectionView.reloadSections(indexSet)
            }
            authoredRequestTask = nil
        }
    }
}

extension UserAccountCollectionViewController: ItineraryFunctionsDelegate {
    func updatePage() {
        let indexSet = IndexSet(integer: 2)
        if selectedSegmentIndex == 1 {
            DispatchQueue.main.async {
                self.collectionView.reloadSections(indexSet)
            }            
        }
    }
}
