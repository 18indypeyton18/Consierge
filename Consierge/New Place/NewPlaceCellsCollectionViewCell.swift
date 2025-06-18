//
//  NewPlaceCellsCollectionViewCell.swift
//  Consierge
//
//  Created by Austin McLaughlin on 12/11/24.
//

import UIKit

class PlaceAddressSearchCollectionViewCell: UICollectionViewCell {
    weak var delegate: PlaceAddressSearchCellDelegate?
    
    @IBOutlet var cityAddressText: UITextField!
    
    @IBAction func addressUpdated(_ sender: Any) {
        guard let address = cityAddressText.text else { return }
        delegate?.addressUpdated(address: address)
    }
    @IBAction func clearText(_ sender: Any) {
        delegate?.clearAddressText()
    }
    
    func turnOffAutoCorrect() {
        cityAddressText.autocorrectionType = .no
        cityAddressText.spellCheckingType = .no
    }
}
protocol PlaceAddressSearchCellDelegate: AnyObject {
    func addressUpdated(address: String)
    func clearAddressText()
}

class AutoFillStatusCollectionViewCell: UICollectionViewCell {
    @IBOutlet var autoCompleteLabel: UILabel!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
}

class ChoosePhotosCollectionViewCell: UICollectionViewCell {
    weak var delegate: ChoosePhotosCellDelegate?
    @IBAction func choosePhotosPressed(_ sender: Any) {
        delegate?.choosePhotos()
    }
}
protocol ChoosePhotosCellDelegate: AnyObject {
    func choosePhotos()
}

class UploadedPicCollectionViewCell: UICollectionViewCell {
    
    weak var delegate: UploadedPhotoCellDelegate?
    var idx: Int?
    
    @IBOutlet var uploadedPicImg: UIImageView!
    @IBOutlet var removePicBtn: UIButton!
    
    @IBAction func removePicButton(_ sender: Any) {
        guard let idx = idx else { return }
        delegate?.removePic(idx: idx)
    }
    
    
    func styleCell() {
        uploadedPicImg.layer.cornerRadius = 8.0
        uploadedPicImg.layer.borderWidth = 1.0
        uploadedPicImg.layer.borderColor = UIColor.systemGray5.cgColor
        uploadedPicImg.layer.masksToBounds = true
        
        // Set cell background color
        backgroundColor = UIColor.white
        
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
        
        removePicBtn.layer.cornerRadius = 15.0
    }
}
protocol UploadedPhotoCellDelegate: AnyObject {
    func removePic(idx: Int)
}

class EditPlaceAttributeCollectionViewCell: UICollectionViewCell {
    @IBOutlet var attributeTextField: UITextField!
}

class EditPlaceDescrCollectionViewCell: UICollectionViewCell {
    @IBOutlet var descrTextView: UITextView!
}
