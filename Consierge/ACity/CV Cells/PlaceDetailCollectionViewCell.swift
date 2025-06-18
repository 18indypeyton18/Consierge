//
//  PlaceDetailCollectionViewCell.swift
//  Consierge
//
//  Created by Austin McLaughlin on 1/15/24.
//

import UIKit

class PlaceDetailCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var placePic: UIImageView!
    @IBOutlet var placeNameLabel: UILabel!
    
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet var neiCatLabel: UILabel!
    @IBOutlet var communityLovesLabel: UILabel!
    @IBOutlet var milesFromUserLabel: UILabel!
    
    
    @IBOutlet var tag1Label: UILabel!
    @IBOutlet var tag2Label: UILabel!
    @IBOutlet var tag3Label: UILabel!
    @IBOutlet var tag4Label: UILabel!
    
    var place: Place?
    
    var placeTypeID: Int?
    var cityID: Int?
    
    var fetchedPics = [String:UIImage?]()
    
    var imageRequestTask: Task<Void,Never>? = nil
    var tagsRequestTask: Task<Void,Never>? = nil
    deinit {
        imageRequestTask?.cancel()
        tagsRequestTask?.cancel()
    }
    
    var tagsDict: [String:[PlaceTag]] = [:]
    
    weak var delegate: PlaceDetailCollectionViewCellDelegate?
    let lovePlaceFunctions = LovePlaceFunctions()
    let picGetter = PicGetter()
    
    override func awakeFromNib() {
        //setup long press gesture recognizer - currently contains 1 context menu item (<3 restaurant)
        let lpgr : UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        lpgr.minimumPressDuration = 0.5
        lpgr.view?.isUserInteractionEnabled = true
        lpgr.delaysTouchesBegan = true
        lpgr.delaysTouchesBegan = true
        picGetter.delegate = self
        self.addInteraction(UIContextMenuInteraction(delegate: self as UIContextMenuInteractionDelegate))
        self.placePic.addGestureRecognizer(lpgr)
        tag1Label.isHidden = true
        tag2Label.isHidden = true
        tag3Label.isHidden = true
        tag4Label.isHidden = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Add border to the cell's content view
        contentView.layer.cornerRadius = 5.0
        contentView.layer.borderWidth = 0.75
        contentView.layer.borderColor = UIColor.clear.cgColor
    }
    
    func getPlaceID() -> String {
        guard let place = place else { return "" }
        switch place is ConciergePlace {
        case true:
            return String(place.id)
        case false:
            return place.fsqID ?? ""
        }
    }
}

extension PlaceDetailCollectionViewCell: UIContextMenuInteractionDelegate {
    //Context Menu Extension to support 'Hold to <3' functionality in ACity CVC
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { suggestedActions in
            
            let websiteAction = UIAction(title: NSLocalizedString("Website", comment: ""), image: UIImage(systemName: "safari")) { action in
                
                if let url = URL(string: self.place?.website ?? "") {
                    self.delegate?.presentWebsite(url: url)
                }
            }
            
            let directionsAction = UIAction(title: NSLocalizedString("Directions", comment: ""), image: UIImage(systemName: "map")) { action in
                self.delegate?.presentDirections(address: self.place?.address ?? "", placeName: self.place?.name ?? "")
            }
            
            let role = currentUser.role
            if role != "GuestUser" {
                
                var loveAction: UIAction
                
                guard let place = self.place else {return UIMenu()}
                
                var placeTypeName = "Place"
                if let place = place as? ConciergePlace {
                    placeTypeName = allPlaceTypes[place.placeTypeID ?? 0]?.singularName ?? "Place"
                }
                
                let placeLoved = userLovedPlaces.contains { thisPlace in
                    "\(thisPlace.name)\(thisPlace.id)\(thisPlace.fsqID ?? "")" == "\(place.name)\(place.id)\(place.fsqID ?? "")"
                }
                
                if !placeLoved {
                    loveAction =
                    UIAction(title: NSLocalizedString("Love \(placeTypeName)", comment: ""),
                             image: UIImage(systemName: "heart")) { action in
                        if let place = place as? ConciergePlace {
                            self.lovePlaceFunctions.lovePlace(place: place, placeSource: .concierge)
                        } else if let place = place as? FSQPlace {
                            self.lovePlaceFunctions.loveFSQPlace(place: place, placeSource: .fsq, placeTypeID: self.placeTypeID ?? 0, cityID: self.cityID ?? 0)
                        } 
                        self.delegate?.placeLoved(place: place)
                    }
                } else {
                    loveAction = UIAction(title: NSLocalizedString("Unlove \(placeTypeName)", comment: ""), image: UIImage(systemName: "heart.fill")) { action in
                        self.lovePlaceFunctions.lovePlace(place: self.place, placeSource: .concierge)
                        self.delegate?.placeLoved(place: place)
                    }
                }
                
                let itineraryAction = UIAction(title: NSLocalizedString("Add to Itinerary", comment: ""), image: UIImage(systemName: "list.bullet.rectangle")) { action in
                    self.pushToItinerary()
                }
                
                /*let commentAction = UIAction(title: NSLocalizedString("Add Comment", comment: ""), image: UIImage(systemName: "bubble.middle.bottom")) { action in
                 self.delegate?.addComment(self.placeID ?? 0)
                 }
                 
                 let seePhotosAction = UIAction(title: NSLocalizedString("See Photos", comment: ""), image: UIImage(systemName: "photo")) { action in
                 self.delegate?.seePhotos(self.placeID ?? 0)
                 }*/
                
                return UIMenu(title: "", children: [loveAction, itineraryAction, websiteAction, directionsAction/*, commentAction, seePhotosAction*/])
            } else {
                return UIMenu(title: "", children: [websiteAction, directionsAction/*, loveAction, itineraryAction, commentAction, seePhotosAction*/])
            }
        })
    }
    
    @objc func handleLongPress(gestureRecognizer : UILongPressGestureRecognizer){}
}

extension PlaceDetailCollectionViewCell: PicGetterDelegate {
    func updatePics(images: [UIImage]) {}
    
    func updatePics(image: UIImage, i: Int?) {}
    
    func updatePic(image: UIImage?, placeID: Int?) {
        
        let placeIDStr = String(placeID ?? place?.id ?? 0)
        fetchedPics[placeIDStr] = image
        
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.activityIndicator.isHidden = true
            
            guard placeID == nil || placeID == self.place?.id else { return }
                                    
            self.placePic.layer.cornerRadius = 10.0
            self.placePic.layer.masksToBounds = true
            
            self.placePic.image = image
            
            // Set cell background color
            self.backgroundColor = UIColor.white
            
            // Create shadow for the entire cell
            self.layer.cornerRadius = 10.0 // Optional: Add corner radius for rounded corners
            self.layer.shadowColor = UIColor.darkGray.cgColor
            self.layer.shadowOpacity = 0.05
            self.layer.shadowOffset = CGSize(width: 0, height: 2)
            self.layer.shadowRadius = 4.0
            self.layer.masksToBounds = false
            
            // Create border around the entire cell
            self.layer.borderWidth = 1.0
            self.layer.borderColor = UIColor.systemGray6.cgColor
            
            self.tag1Label.layer.cornerRadius = 8.0
            self.tag1Label.layer.borderWidth = 1.0
            self.tag1Label.layer.borderColor = UIColor.clear.cgColor
            self.tag1Label.layer.masksToBounds = true
            self.tag2Label.layer.cornerRadius = 8.0
            self.tag2Label.layer.borderWidth = 1.0
            self.tag2Label.layer.borderColor = UIColor.clear.cgColor
            self.tag3Label.layer.masksToBounds = true
            self.tag3Label.layer.cornerRadius = 8.0
            self.tag3Label.layer.borderWidth = 1.0
            self.tag3Label.layer.borderColor = UIColor.clear.cgColor
            self.tag2Label.layer.masksToBounds = true
            self.tag4Label.layer.cornerRadius = 8.0
            self.tag4Label.layer.borderWidth = 1.0
            self.tag4Label.layer.borderColor = UIColor.clear.cgColor
            self.tag4Label.layer.masksToBounds = true
        }
    }
    
    func returnPic(image: UIImage, i: Int) {
    }
}

extension PlaceDetailCollectionViewCell {
    func pushToItinerary() {
        guard let place = place else {return}
        delegate?.addToItinerary(place, isFSQ: false)
    }
    
    func addComments() {
        
    }
}

extension PlaceDetailCollectionViewCell {
    //Fetch Image from the server based on imageURL
    
    func fetchImage(imageURL: String) {
        let placeID = getPlaceID()
        if let img = fetchedPics[placeID] {
            placePic.image = img
            return
        }
        
        placePic.image = UIImage(named: "default.png")
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        if let place = place as? ConciergePlace {
            picGetter.getConciergeImage(place: place)
        } else if let place = place as? FSQPlace {
            picGetter.getFSQImage(imageURL: place.imageURL)
        }
    }
}

extension PlaceDetailCollectionViewCell {
    
    func getTags() {
        
        guard let place = place else { return }
        var thisID = place.fsqID
        if place is ConciergePlace {
            thisID = String(place.id)
        }
        if let thisID = thisID, let placeTags = tagsDict[thisID], placeTags.isEmpty == false {
            setTagLabels()
        } else {
            tagsRequestTask = Task {
                if let tags = try? await PlaceTagsRequest(placeID: place.id).send() {
                    let placeTags = tags.sorted(by: { lhs, rhs in
                        lhs.count > rhs.count
                    })
                    if let thisID = thisID { self.tagsDict[thisID] = placeTags }
                }
                setTagLabels()
                tagsRequestTask = nil
            }
        }
    }
    
    func setTagLabels() {
        
        guard let place = place else { return }
        var thisID = place.fsqID
        if place is ConciergePlace {
            thisID = String(place.id)
        }
        
        var placeTags = [PlaceTag]()
        if let thisID = thisID, let theseTags = tagsDict[thisID] {
            placeTags = theseTags
        }
        
        if placeTags.count > 0 {
            tag1Label.text = placeTags[0].tagName
            tag1Label.isHidden = false
        } else { tag1Label.isHidden = true }
        
        if placeTags.count > 1 {
            tag3Label.text = placeTags[1].tagName
            tag3Label.isHidden = false
        } else { tag3Label.isHidden = true }
        
        if placeTags.count > 2 {
            tag2Label.text = placeTags[2].tagName
            tag2Label.isHidden = false
        } else { tag2Label.isHidden = true }
        
        if placeTags.count > 3 {
            tag4Label.text = placeTags[3].tagName
            tag4Label.isHidden = false
        } else { tag4Label.isHidden = true }
    }
}


protocol PlaceDetailCollectionViewCellDelegate: AnyObject {
    //Delegate function used by ACity to immediately add a new Place to the view
    func addToItinerary(_ place: Place, isFSQ: Bool)
    func addComment(_ placeID: Int)
    func seePhotos(_ placeID: Int)
    func presentWebsite(url: URL)
    func presentDirections(address: String, placeName: String)
    func placeLoved(place: Place)
}
