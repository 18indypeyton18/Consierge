//
//  UserActivityCollectionViewController.swift
//  Consierge
//
//  Created by Austin McLaughlin on 3/1/25.
//

import UIKit
import SafariServices

private let reuseIdentifier = "Cell"

class UserActivityCollectionViewController: UICollectionViewController {
    
    var userID = 0
    var userName = ""
    
    var thisUserLovedPlaces = [Place]()
    var addedPlaces = [Place]()
    var userItineraries = [Itinerary]()
    var userItineraryLinesDict = [Int: [ItineraryLine]]()
    var thisRecencyDict = [String:Int]()
    var thisLovedPlaceDict = [String:LovePlace]()
    
    var selectedSegmentIndex = 1
    
    var itinerarySelectedPlace: Place?
    
    var group = DispatchGroup()
    
    var userLovedPlacesRequestTask: Task<Void,Never>? = nil
    var authoredRequestTask: Task<Void,Never>? = nil
    var itinerariesRequestTask: Task<Void,Never>? = nil
    var itineraryLinesRequestTask: Task<Void,Never>? = nil
    deinit {
        userLovedPlacesRequestTask?.cancel()
        authoredRequestTask?.cancel()
        itinerariesRequestTask?.cancel()
        itineraryLinesRequestTask?.cancel()
    }

    override func viewDidLoad() {
        loadPage()
        collectionView.collectionViewLayout = createLayout()
        self.navigationItem.title = userName
        super.viewDidLoad()
    }
    
    func loadPage() {
        if userID == 0 {
            userID = currentUser.id
            if let uName = currentUser.username {
                userName = uName
            } else {
                userName = "\(currentUser.firstName) \(currentUser.lastName.first ?? " ")"
            }
        }
        
        getLovedPlaces()
        getAddedPlaces()
        getUserItineraries()
        
        group.notify(queue: .main) {
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 3
        default:
            switch selectedSegmentIndex {
            case 0:
                return thisUserLovedPlaces.count
            case 1:
                return addedPlaces.count
            default:
                return userItineraries.count
            }
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UserAccountSegment", for: indexPath) as! UserAccountSegmentControllerCollectionViewCell
            
            cell.segmentName.text = "Loved"
            cell.segmentIcon.image = UIImage(systemName: "heart")
            
            if indexPath.item == 1 {
                cell.segmentName.text = "Added"
                cell.segmentIcon.image = UIImage(systemName: "pencil.circle")
            } else if indexPath.item == 2 {
                cell.segmentName.text = "Itineraries"
                cell.segmentIcon.image = UIImage(systemName: "list.clipboard")
            }
            
            cell.segmentSelectedBar.layer.shadowColor = UIColor.gray.cgColor
            cell.segmentSelectedBar.layer.shadowOffset = CGSize(width: 0.0, height: 0.5)
            cell.segmentSelectedBar.layer.shadowOpacity = 0.5
            
            if indexPath.item == selectedSegmentIndex  {
                cell.segmentSelectedBar.backgroundColor = .black
                //cell.placeTypeName.font = UIFont(name: "Apple SD Gothic Neo Bold", size: 18)
            } else {
                cell.segmentSelectedBar.backgroundColor = .white
                //cell.placeTypeName.font = UIFont(name: "Apple SD Gothic Neo Normal", size: 18)
            }
            
            return cell
        default:
            if selectedSegmentIndex == 0 || selectedSegmentIndex == 1 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UserAccountLovedPlace", for: indexPath) as! UserAccountLovedPlaceCollectionViewCell
                
                //Place object stored in each instance of ViewModel.Item and can be used to configure the cell
                var place: Place?
                if selectedSegmentIndex == 0 {
                    place = thisUserLovedPlaces[indexPath.item]
                } else {
                    place = addedPlaces[indexPath.item]
                }
                guard let place = place else { return cell }
                
                cell.place = place
                cell.placePic.image = nil
                
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
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UserAccountItinerary", for: indexPath) as! ItineraryCollectionViewCell
                
                //Place object stored in each instance of ViewModel.Item and can be used to configure the cell
                let itinerary = userItineraries[indexPath.item]
                cell.itinerary = itinerary
                
                cell.activityIndicator.startAnimating()
                cell.itineraryNameLabel.text = itinerary.name
                
                if let imageURL = itinerary.coverImageURL {
                    cell.fetchImage(imageURL: imageURL, src: itinerary.coverImageSrc)
                }
                
                guard let itLines = userItineraryLinesDict[itinerary.ID] else {return cell}
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
    
    func createLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            switch sectionIndex {
            case 0:
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0 / 3.0),
                    heightDimension: .absolute(40) // Fixed height
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(40) // Match item height
                )
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item, item, item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0)
                
                return section
            default:
                switch self.selectedSegmentIndex {
                case 0, 1:
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
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if selectedSegmentIndex == indexPath.item { return }
            selectedSegmentIndex = indexPath.item
            collectionView.reloadData()
        }
    }
    
    func getLovedPlaces() {
        getUserLovedPlaces(currentUserID: userID)
    }
    
    func getAddedPlaces() {
        authoredRequestTask = Task {
            if let places = try? await PlacesAuthoredRequest(userID: userID).send() {
                addedPlaces = places
                addedPlaces = places.sorted { lhs, rhs in
                    lhs.id > rhs.id
                }
            }
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
            authoredRequestTask = nil
        }
    }
    
    func getUserItineraries() {
        getItineraries()
    }
    
    @IBSegueAction func placeSelected(_ coder: NSCoder, sender: Any?) -> UICollectionViewController? {
        guard let cell = sender as? UserAccountLovedPlaceCollectionViewCell, let place = cell.place, let img = cell.placePic.image else {return nil}
        return placeSelected(place: place, img: img, coder: coder)
    }
    
    func placeSelected(place: Place, img: UIImage, coder: NSCoder) -> UICollectionViewController? {
        //return DetailVC
        if selectedSegmentIndex == 0 {
            return PlaceDetailCollectionViewController(coder: coder, place: place, sectionsPlaces: thisUserLovedPlaces, placePic: img, placeTypeID: 0, cityID: nil)
        } else {
            return PlaceDetailCollectionViewController(coder: coder, place: place, sectionsPlaces: addedPlaces, placePic: img, placeTypeID: 0, cityID: nil)
        }
    }
    
    @IBSegueAction func itinerarySelected(_ coder: NSCoder, sender: UICollectionViewCell?) -> ViewLimitedItineraryCollectionViewController? {
        //Segue to Viewitinerary page to display the selected Itinerary
        
        guard let cell = sender, let indexPath = collectionView.indexPath(for: cell) else { return nil }
        
        let itinerary = userItineraries[indexPath.item]
        let itineraryLines = userItineraryLinesDict[itinerary.ID]
        guard let itineraryLines = itineraryLines else {return nil}
        
        return ViewLimitedItineraryCollectionViewController(coder: coder, itinerary: itinerary, itineraryLines: itineraryLines)
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if let cell = sender as? UserAccountLovedPlaceCollectionViewCell {
            if cell.placePic.image == nil { return false }
        }
        return true
    }
    
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
    }
}

extension UserActivityCollectionViewController {
    
    func getUserLovedPlaces(currentUserID: Int) {
        thisUserLovedPlaces = []
        
        group.enter()
        userLovedPlacesRequestTask = Task {
            if let userPlacesLoved = try? await UserPlacesLovedRequest(userID: currentUserID).send() {
                thisUserLovedPlaces += userPlacesLoved
                
            }
            
            if let userLovedPlaces = try? await UserLovedPlacesRequest(userID: currentUserID).send() {
                
                for userLovedPlace in userLovedPlaces {
                    if userLovedPlace.type == "Concierge" {
                        thisRecencyDict[String(userLovedPlace.placeID)] = userLovedPlace.ID
                        thisLovedPlaceDict["\(userLovedPlace.placeID)"] = userLovedPlace
                    } else {
                        thisRecencyDict[userLovedPlace.fsqID] = userLovedPlace.ID
                        thisLovedPlaceDict["\(userLovedPlace.placeID)"] = userLovedPlace
                    }
                }
            }
            
            if let userFSQsLoved = try? await UserFSQsLovedRequest(userID: currentUserID).send() {
                for userLovedPlace in userFSQsLoved {
                    if userLovedPlace.type == "Concierge" {
                        thisRecencyDict[String(userLovedPlace.placeID)] = userLovedPlace.ID
                        thisLovedPlaceDict["\(userLovedPlace.placeID)"] = userLovedPlace
                    } else {
                        thisRecencyDict[userLovedPlace.fsqID] = userLovedPlace.ID
                        thisLovedPlaceDict["\(userLovedPlace.placeID)"] = userLovedPlace
                    }
                }
            }
            
            sortUserPlaces()
        }
    }
    func sortUserPlaces() {
        userLovedPlaces = userLovedPlaces.sorted(by: { lhs, rhs in
            switch (lhs,rhs) {
            case (is ConciergePlace, is ConciergePlace):
                if let lhsRecency = thisRecencyDict[String(lhs.id)], let rhsRecency = thisRecencyDict[String(rhs.id)] {
                    return lhsRecency > rhsRecency
                } else {
                    return lhs.name < rhs.name
                }
            case (_, is ConciergePlace):
                if let lhsRecency = thisRecencyDict[lhs.fsqID ?? ""], let rhsRecency = thisRecencyDict[String(rhs.id)] {
                    return lhsRecency > rhsRecency
                } else {
                    return lhs.name < rhs.name
                }
            case (is ConciergePlace, _):
                if let lhsRecency = thisRecencyDict[String(lhs.id)], let rhsRecency = thisRecencyDict[rhs.fsqID ?? ""] {
                    return lhsRecency > rhsRecency
                } else {
                    return lhs.name < rhs.name
                }
            default:
                if let lhsRecency = thisRecencyDict[lhs.fsqID ?? ""], let rhsRecency = thisRecencyDict[rhs.fsqID ?? ""] {
                    return lhsRecency > rhsRecency
                } else {
                    return lhs.name < rhs.name
                }
            }
        })
        group.leave()
    }
}

extension UserActivityCollectionViewController {
    func getItineraries() {
        itinerariesRequestTask?.cancel()
        itinerariesRequestTask = Task {
            if let it = try? await UserItinerariesRequest(userID: userID).send() {
                userItineraries = it
                for itinerary in userItineraries {
                    getItineraryLines(itineraryId: itinerary.ID)
                }
            } else {
                userItineraries = []
            }
            itinerariesRequestTask = nil
        }
    }
    
    func getItineraryLines(itineraryId: Int) {
        itineraryLinesRequestTask = Task {
            if let itineraryLines = try? await UserItineraryLinesRequest(itineraryID: itineraryId).send() {
                DispatchQueue.main.async {
                    self.userItineraryLinesDict[itineraryId] = itineraryLines
                }
            } else {
                self.userItineraryLinesDict[itineraryId] = []
            }
            itineraryLinesRequestTask = nil
        }
    }
}


extension UserActivityCollectionViewController {
    func getLovedPlaceTimestamp(placeID: Int, fsqID: String, placeSource: PlaceSource) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        if placeSource == .concierge {
            let lovePlace = thisLovedPlaceDict["\(placeID)"]
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
            let lovePlace = thisLovedPlaceDict[fsqID]
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

extension UserActivityCollectionViewController {
    func formatDateToReadableString(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        return dateFormatter.string(from: date)
    }
}


extension UserActivityCollectionViewController: UserAccountLovedPlaceCollectionViewCellDelegate {
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

extension UserActivityCollectionViewController: ItineraryCellDelegate {
    func updateAfterDelete(_ itinerary: Itinerary) {
        let indexSet = IndexSet(integer: 2)
        self.collectionView.reloadSections(indexSet)
    }
}
