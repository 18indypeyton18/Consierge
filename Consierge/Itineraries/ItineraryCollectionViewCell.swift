//
//  ItineraryCollectionViewCell.swift
//  Consierge
//
//  Created by Austin McLaughlin on 11/30/24.
//

import UIKit

class ItineraryCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var itineraryNameLabel: UILabel!
    @IBOutlet var coverImage: UIImageView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var placeName1: UILabel!
    @IBOutlet var itineraryDesc1: UILabel!
    @IBOutlet var placeName2: UILabel!
    @IBOutlet var itineraryDesc2: UILabel!
    @IBOutlet var dotDotDotLabel: UILabel!
    @IBOutlet var separator: UIView!
    
    weak var delegate: ItineraryCellDelegate?
    
    var itinerary: Itinerary?
    
    override func awakeFromNib() {
        //setup long press gesture recognizer - currently contains 1 context menu item (<3 restaurant)
        let lpgr : UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        lpgr.minimumPressDuration = 0.5
        lpgr.view?.isUserInteractionEnabled = true
        lpgr.delaysTouchesBegan = true
        self.addInteraction(UIContextMenuInteraction(delegate: self as UIContextMenuInteractionDelegate))
        self.addGestureRecognizer(lpgr)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        coverImage.image = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Add border to the cell's content view
        contentView.layer.cornerRadius = 5.0
        contentView.layer.borderWidth = 0.75
        contentView.layer.borderColor = UIColor.clear.cgColor
    }
    
    func fetchImage(imageURL: String, src: String) {
        let picGetter = PicGetter()
        picGetter.delegate = self
        
        if src == "FSQ" {
            picGetter.getFSQImage(imageURL: imageURL)
        } else {
            picGetter.getConciergeImageURLOnly(path: imageURL)
        }
        
        self.coverImage.layer.cornerRadius = 8.0
        self.coverImage.layer.borderWidth = 1.0
        self.coverImage.layer.borderColor = UIColor.systemGray5.cgColor
        self.coverImage.layer.masksToBounds = true
        
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

extension ItineraryCollectionViewCell: PicGetterDelegate {
    func updatePics(images: [UIImage]) {
    }
    
    func updatePics(image: UIImage, i: Int?) {
    }
    
    func updatePic(image: UIImage?, placeID: Int?) {
        DispatchQueue.main.async {
            self.coverImage.image = image
            self.activityIndicator.stopAnimating()
            self.activityIndicator.isHidden = true
        }
    }
    
    func returnPic(image: UIImage, i: Int) {
    }
}



extension ItineraryCollectionViewCell: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { suggestedActions in
            let deleteItineraryAction = UIAction(title: NSLocalizedString("Delete Itinerary", comment: ""), image: UIImage(systemName: "trash")) { action in
                guard let itinerary = self.itinerary else {return}
                self.deleteItinerary(itinerary: itinerary)
            }
            return UIMenu(title: "", children: [deleteItineraryAction])
        })
    }
    
    func deleteItinerary(itinerary: Itinerary) {
        Task {
            let resultValue = try? await DeleteItineraryRequest(itinerary: itinerary).send()
            if let resultValue = resultValue {
                if resultValue["status"] == "Success" {
                    guard let itineraryIndex = itineraries.firstIndex(where: { $0.ID == itinerary.ID }) else { return }
                    itineraries.remove(at: itineraryIndex)
                    itineraryLinesDict.removeValue(forKey: itinerary.ID)
                    
                    self.delegate?.updateAfterDelete(itinerary)
                }
            }
        }
    }
    
    @objc func handleLongPress(gestureRecognizer : UILongPressGestureRecognizer){}
}


protocol ItineraryCellDelegate: AnyObject {
    //Delegate function used by ACity to immediately add a new Place to the view
    func updateAfterDelete(_ itinerary: Itinerary)
}
