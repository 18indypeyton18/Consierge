//
//  GPTPlaceCollectionViewCell.swift
//  Consierge
//
//  Created by Austin McLaughlin on 10/6/24.
//

import UIKit

class GPTPlaceCollectionViewCell: UICollectionViewCell {
    @IBOutlet var placePic: UIImageView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet var placeNameLabel: UILabel!
    @IBOutlet var neiCatLabel: UILabel!
    @IBOutlet var milesFromUserLabel: UILabel!
    @IBOutlet var communityLovesLabel: UILabel!
    
    var place: Place?
    
    var placeTypeID: Int?
    var cityID: Int?
    
    weak var delegate: GPTPlaceCollectionViewCellDelegate?
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
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Add border to the cell's content view
        contentView.layer.cornerRadius = 5.0
        contentView.layer.borderWidth = 0.75
        contentView.layer.borderColor = UIColor.clear.cgColor
    }
    
    var imageRequestTask: Task<Void,Never>? = nil
    deinit {
        imageRequestTask?.cancel()
    }
}

extension GPTPlaceCollectionViewCell: UIContextMenuInteractionDelegate {
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
                    placeTypeName = allPlaceTypes[place.placeTypeID ?? 0]?.name ?? "Place"
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
extension GPTPlaceCollectionViewCell: PicGetterDelegate {
    func updatePics(images: [UIImage]) {}
    
    func updatePics(image: UIImage, i: Int?) {}
    
    func updatePic(image: UIImage) {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.activityIndicator.isHidden = true
                                    
            self.placePic.layer.cornerRadius = 8.0
            self.placePic.layer.borderWidth = 1.0
            self.placePic.layer.borderColor = UIColor.systemGray5.cgColor
            self.placePic.layer.masksToBounds = true
            
            self.placePic.image = image
            
            // Set cell background color
            self.backgroundColor = UIColor.white
            
            // Create shadow for the entire cell
            self.layer.cornerRadius = 10.0 // Optional: Add corner radius for rounded corners
            self.layer.shadowColor = UIColor.darkGray.cgColor
            self.layer.shadowOpacity = 0.1
            self.layer.shadowOffset = CGSize(width: 0, height: 2)
            self.layer.shadowRadius = 4.0
            self.layer.masksToBounds = false
            
            // Create border around the entire cell
            self.layer.borderWidth = 1.0
            self.layer.borderColor = UIColor.systemGray6.cgColor
        }
    }
    
    func returnPic(image: UIImage, i: Int) {
    }
}

extension GPTPlaceCollectionViewCell {
    func pushToItinerary() {
        guard let place = place else {return}
        delegate?.addToItinerary(place, isFSQ: false)
    }
    
    func addComments() {
        
    }
}

extension GPTPlaceCollectionViewCell {
    //Fetch Image from the server based on imageURL
    
    func fetchImage(imageURL: String) {
        if let place = place as? ConciergePlace {
            picGetter.getConciergeImage(place: place)
        } else if let place = place as? FSQPlace {
            picGetter.getFSQImage(imageURL: place.imageURL)
        } else if let place = place as? GooglePlace {
            picGetter.getGoogleImage(photo_reference: place.imageURL)
        }
    }
}


protocol GPTPlaceCollectionViewCellDelegate: AnyObject {
    //Delegate function used by ACity to immediately add a new Place to the view
    func addToItinerary(_ place: Place, isFSQ: Bool)
    func addComment(_ placeID: Int)
    func seePhotos(_ placeID: Int)
    func presentWebsite(url: URL)
    func presentDirections(address: String, placeName: String)
    func placeLoved(place: Place)
}
