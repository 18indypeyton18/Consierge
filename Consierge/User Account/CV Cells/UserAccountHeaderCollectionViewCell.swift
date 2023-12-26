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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Enable user interaction on the image view
        profPicImageView.isUserInteractionEnabled = true
        // Add tap gesture recognizer to the image view
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(profPicTapped))
        profPicImageView.addGestureRecognizer(tapGesture)
    }
    
    @objc func profPicTapped() {
        delegate?.updateProfPicClicked()
    }
}
protocol UserAccountHeaderCellDelegate: AnyObject {
    func updateProfPicClicked()
}
