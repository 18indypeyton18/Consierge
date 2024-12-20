//
//  PlaceToReviewTableViewCell.swift
//  ConciergePF for Admins
//
//  Created by Austin McLaughlin on 3/5/23.
//

import UIKit

class PlaceToReviewTableViewCell: UITableViewCell {
    var placeSelected = false
    var delegate: PlaceToReviewTableViewCellDelegate?
    var placeID: Int?
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var placePic: UIImageView!
    @IBOutlet var catNeiLabel: UILabel!
    @IBOutlet var descrLabel: UILabel!
    
    @IBOutlet var websiteCheckmark: UIImageView!
    @IBOutlet var addressCheckmark: UIImageView!
    
    var imageRequestTask: Task<Void,Never>? = nil
    deinit {
        imageRequestTask?.cancel()
    }
    
    func fetchImage(imageURL: String) {
        imageRequestTask = Task {
            if let image = try? await ImageRequest(path: imageURL).send() {
                DispatchQueue.main.async {
                    self.placePic.layer.cornerRadius = 8.0
                    self.placePic.layer.borderWidth = 1.0
                    self.placePic.layer.borderColor = UIColor.clear.cgColor
                    self.placePic.layer.masksToBounds = true
                    
                    self.placePic.layer.shadowColor = UIColor.lightGray.cgColor
                    self.placePic.layer.shadowOffset = CGSize(width: 0, height: 1)
                    self.placePic.layer.shadowRadius = 2.0
                    self.placePic.layer.shadowOpacity = 0.5
                    self.placePic.image = image
                }
            } else {
                self.placePic.image = nil
            }
        }
    }
}

protocol PlaceToReviewTableViewCellDelegate: AnyObject {
    func multiSelected(placeSelected: Bool, placeID: Int)
}
