//
//  PlacePreviewController.swift
//  Consierge
//
//  Created by Austin McLaughlin on 2/18/25.
//

import UIKit

class PlacePreviewController: UIViewController {
    
    var place: Place? {
        didSet { updateContent() }
    }

    var previewImage: UIImage? {
        didSet { imageView.image = previewImage }
    }
    
    weak var containerPageController: PlacePreviewPageController?

    // UI Elements
    let imageView = UIImageView()
    let titleLabel = UILabel()
    let addressLabel = UILabel()
    
    var fetchedPics = [String: UIImage?]()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        
        setupUI()
        
        // Tap on the preview pushes the detailed view.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(previewTapped))
        view.addGestureRecognizer(tapGesture)
    }
    
    func setupUI() {
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.numberOfLines = 1
        
        addressLabel.font = UIFont.systemFont(ofSize: 14)
        addressLabel.textColor = .secondaryLabel
        addressLabel.numberOfLines = 1
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(imageView)
        view.addSubview(titleLabel)
        view.addSubview(addressLabel)
        
        NSLayoutConstraint.activate([
            // ImageView: pinned to top, left, right. Its bottom is 10 pts above the titleLabel.
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: titleLabel.topAnchor, constant: -2),
            
            // Title Label: 10 pts below imageView, 10 pts above addressLabel, with 10 pts left/right margins.
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 2),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            titleLabel.bottomAnchor.constraint(equalTo: addressLabel.topAnchor, constant: -2),
            titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 15),
            
            // Address Label: 10 pts below titleLabel and 10 pts above the bottom of the view, with 10 pts left/right margins.
            addressLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            addressLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            addressLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            addressLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            addressLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 15)
        ])
    }


    func updateContent() {
        titleLabel.text = place?.name
        addressLabel.text = place?.address
        
        let placeID = getPlaceID()
        if let img = fetchedPics[placeID] {
            previewImage = img
            return
        }
        
        
        let picGetter = PicGetter()
        picGetter.delegate = self
        if let conciergePlace = place as? ConciergePlace {
            picGetter.getConciergeImage(place: conciergePlace)
        } else if let fsqPlace = place as? FSQPlace {
            picGetter.getFSQImage(imageURL: fsqPlace.imageURL)
        } 
    }

    @objc func previewTapped() {
        guard let previewImage = previewImage else {return}
        // Push your detail view controller.
        // Access the parent MapViewController if needed.
        if let containerVC = containerPageController,
           let mapVC = containerVC.mapViewController,
           let place = self.place,
           let storyboard = mapVC.storyboard {
            
            let destinationVC = storyboard.instantiateViewController(identifier: "PlaceDetail") { coder in
                PlaceDetailCollectionViewController(coder: coder,
                                                      place: place,
                                                      sectionsPlaces: containerVC.places,
                                                      placePic: previewImage,
                                                      placeTypeID: mapVC.placeTypeID,
                                                      cityID: mapVC.cityID)
            }
            mapVC.navigationController?.pushViewController(destinationVC, animated: true)
        }
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

extension PlacePreviewController: PicGetterDelegate {
    func updatePics(images: [UIImage]) {
    }
    
    func updatePics(image: UIImage, i: Int?) {
    }
    
    func updatePic(image: UIImage?, placeID: Int?) {
        let placeIDStr = String(placeID ?? place?.id ?? 0)
        fetchedPics[placeIDStr] = image
        
        DispatchQueue.main.async {
            self.previewImage = image
            if let containerVC = self.containerPageController, let mapVC = containerVC.mapViewController, let place = self.place {
                mapVC.currentPlace = place
                mapVC.currentPlaceImg = image
            }
        }
    }
    
    func returnPic(image: UIImage, i: Int) {
    }
}
