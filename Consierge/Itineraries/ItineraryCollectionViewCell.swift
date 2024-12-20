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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Add border to the cell's content view
        contentView.layer.cornerRadius = 5.0
        contentView.layer.borderWidth = 0.75
        contentView.layer.borderColor = UIColor.clear.cgColor
    }
    
    func fetchImage(imageURL: String) {
        let picGetter = PicGetter()
        picGetter.delegate = self
        picGetter.getConciergeImageURLOnly(path: imageURL)
        
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
    
    func updatePic(image: UIImage) {
        DispatchQueue.main.async {
            self.coverImage.image = image
            self.activityIndicator.stopAnimating()
            self.activityIndicator.isHidden = true
        }
    }
    
    func returnPic(image: UIImage, i: Int) {
    }
}
