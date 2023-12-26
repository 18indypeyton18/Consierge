//
//  PlaceDetailCollectionViewCells.swift
//  Consierge
//
//  Created by Austin McLaughlin on 1/28/24.
//

import UIKit

class PlacePicCollectionViewCell: UICollectionViewCell {
    @IBOutlet var placePic: UIImageView!
}

class PlaceWebsiteAndDirectionsCollectionViewCell: UICollectionViewCell {
    @IBOutlet var websiteButton: UIButton!
    
    @IBOutlet var placeCategoryLabel: UILabel!
    @IBOutlet var placeNeighborhoodLabel: UILabel!
    
    var websiteURL: String?

    weak var delegate: PlaceWebsiteAndDirectionsCollectionViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Enable user interaction and add gesture recognizers
        addGestureToLabel(label: placeCategoryLabel, action: #selector(categoryLabelTapped))
        addGestureToLabel(label: placeNeighborhoodLabel, action: #selector(neighborhoodLabelTapped))
    }
    
    @IBAction func websiteButtonPressed(_ sender: Any) {
        print("Here")
        if let url = URL(string: websiteURL ?? "") {
            print(url)
            delegate?.presentWebsite(url: url)
        }
    }
    
    func addGestureToLabel(label: UILabel, action: Selector) {
        label.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: action)
        label.addGestureRecognizer(tapGesture)
    }
    
    // Actions for tapping on the labels
    @objc func categoryLabelTapped() {
        delegate?.categoryPressed() // Trigger delegate method
    }
    
    @objc func neighborhoodLabelTapped() {
        delegate?.neighborhoodPressed() // Trigger delegate method
    }
}
protocol PlaceWebsiteAndDirectionsCollectionViewCellDelegate: AnyObject {
    //Delegate function used by ACity to immediately add a new Place to the view
    func presentWebsite(url: URL)
    func categoryPressed()
    func neighborhoodPressed()
}

class PlaceNameCollectionViewCell: UICollectionViewCell {
    @IBOutlet var placeNameLabel: UILabel!
    @IBOutlet var moreOptionsButton: UIButton!
    
    var isFSQ = false
    
    weak var delegate: PlaceNameCollectionViewCellDelegate?
    
    func setupMoreOptionsButton() {
        //setup contextMenu for additionalOptions
        let share = UIAction(title:"Share", image: UIImage(systemName: "square.and.arrow.up")) { _ in
            //self.sharePlace()
        }
        let addToItinerary = UIAction(title: "Add To Itinerary",
          image: UIImage(systemName: "list.bullet.rectangle")) { _ in
            self.delegate?.addToItinerary()
        }
        
        if currentUser.role != "Noob", isFSQ == false {
            let proposeEdit = UIAction(title:"Propose Edit", image: UIImage(systemName: "pencil")) { _ in
                self.delegate?.proposeEdit()
            }
            moreOptionsButton.showsMenuAsPrimaryAction = true
            moreOptionsButton.menu = UIMenu(title: "", children: [addToItinerary, share, proposeEdit])
        } else {
            if currentUser.role != "GuestUser" {
                moreOptionsButton.showsMenuAsPrimaryAction = true
                moreOptionsButton.menu = UIMenu(title: "", children: [addToItinerary, share])
            } else {
                moreOptionsButton.showsMenuAsPrimaryAction = true
                moreOptionsButton.menu = UIMenu(title: "", children: [share])
            }
        }
    }
}
protocol PlaceNameCollectionViewCellDelegate: AnyObject {
    //Delegate function used by ACity to immediately add a new Place to the view
    func addToItinerary()
    func proposeEdit()
}

class PlaceDescriptionCollectionViewCell: UICollectionViewCell {
    @IBOutlet var placeDescription: UILabel!
}

class PlaceSegmentControllerCollectionViewCell: UICollectionViewCell {
    @IBOutlet var iconImg: UIImageView!
    @IBOutlet var segmentName: UILabel!
    @IBOutlet var selectedPlaceTypeBar: UIView!
    
    weak var delegate: PlaceSegmentControllerCollectionViewCellDelegate?
}
protocol PlaceSegmentControllerCollectionViewCellDelegate: AnyObject {
    //Delegate function used by ACity to immediately add a new Place to the view
    func segmentChanged(segment: Int)
}

class AdditionalPhotosCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var additionalRestaurantPic: UIImageView!
}


class CommentCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    
    @IBOutlet var upVoteButton: UIButton!
    @IBOutlet var downVoteButton: UIButton!
    
    @IBOutlet var scoreLabel: UILabel!
    
    var commentIndex: Int?
    
    weak var delegate: CommentCollectionViewCellDelegate?
    
    @IBAction func upVote(_ sender: Any) {
        delegate?.upVote(commentIndex: commentIndex ?? 0)
    }
    
    @IBAction func downVote(_ sender: Any) {
        delegate?.downVote(commentIndex: commentIndex ?? 0)
    }
}


protocol CommentCollectionViewCellDelegate: AnyObject {
    //Delegate function used by ACity to immediately add a new Place to the view
    func upVote(commentIndex: Int)
    func downVote(commentIndex: Int)
}

import MapKit

class PinPlaceMapViewCollectionViewCell: UICollectionViewCell {
    @IBOutlet var pinPlaceMapView: MKMapView!
    var place: Place?
    
    func configureMapView(with place: Place) {
        self.place = place
        
        // Convert the address to coordinates
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(place.address) { [weak self] (placemarks, error) in
            if let error = error {
                print("Geocoding error: \(error.localizedDescription)")
                return
            }
            
            if let placemark = placemarks?.first {
                // Create a MapPin with the location coordinates
                let mapPin = MKPointAnnotation()
                mapPin.coordinate = placemark.location!.coordinate
                mapPin.title = place.name
                
                // Add the pin to the MapView
                self?.pinPlaceMapView.addAnnotation(mapPin)
                
                // Set the MapView's region to focus on the pin
                let region = MKCoordinateRegion(center: mapPin.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
                self?.pinPlaceMapView.setRegion(region, animated: false)
            }
        }
    }
    
    func openInMaps() {
        guard let place = place else {
            return
        }
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(place.address) { (placemarks, error) in
            if let error = error {
                print("Geocoding error: \(error.localizedDescription)")
                return
            }
            
            if let placemark = placemarks?.first {
                let mapItem = MKMapItem(placemark: MKPlacemark(placemark: placemark))
                mapItem.name = place.name
                mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault])
            }
        }
    }
}


class AddCommentCollectionViewCell: UICollectionViewCell {
    
}

class PlaceTagCollectionViewCell: UICollectionViewCell {
    @IBOutlet var tagName: UILabel!
    @IBOutlet var tagNum: UILabel!
    
    func style() {
        self.layer.cornerRadius = 8.0 // Optional: Add corner radius for rounded corners
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowOpacity = 0.2
        self.layer.shadowOffset = CGSize(width: 0, height: 2)
        self.layer.shadowRadius = 4.0
        self.layer.masksToBounds = false
    }
}

class AddTagCollectionViewCell: UICollectionViewCell {
    weak var delegate: AddTagCollectionViewCellDelegate?
    
    @IBAction func addTagClicked(_ sender: Any) {
        delegate?.addTag()
    }
}
protocol AddTagCollectionViewCellDelegate: AnyObject {
    //Delegate function used by ACity to immediately add a new Place to the view
    func addTag()
}


class AddPhotoCollectionViewCell: UICollectionViewCell {
    
}

class ReviewTextViewCollectionViewCell: UICollectionViewCell {
    @IBOutlet var reviewTextView: UITextView!
    
    func styleCell() {
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
        self.layer.borderColor = UIColor.systemGray4.cgColor
    }
}

