//
//  UserAccountHeaderCollectionViewCell.swift
//  Consierge
//
//  Created by Austin McLaughlin on 12/28/23.
//

import UIKit

class UserAccountHeaderCollectionViewCell: UICollectionViewCell {
    
    weak var delegate: UserAccountHeaderCellDelegate?
    
    @IBOutlet var userNameLabel: UILabel!
    @IBOutlet var profPicImageView: UIImageView!
    @IBOutlet var placesAuthoredLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Enable user interaction on the image view
        profPicImageView.isUserInteractionEnabled = true
        // Add tap gesture recognizer to the image view
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(profPicTapped))
        profPicImageView.addGestureRecognizer(tapGesture)
        addGestureToLabel(label: placesAuthoredLabel, action: #selector(authorLabelTapped))
    }
    
    @objc func profPicTapped() {
        delegate?.updateProfPicClicked()
    }
    
    func addGestureToLabel(label: UILabel, action: Selector) {
        label.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: action)
        label.addGestureRecognizer(tapGesture)
    }
    
    @objc func authorLabelTapped() {
        delegate?.authorLabelClicked() // Trigger delegate method
    }
}
protocol UserAccountHeaderCellDelegate: AnyObject {
    func updateProfPicClicked()
    func authorLabelClicked()
}
