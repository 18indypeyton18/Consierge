//
//  SearchAutoCompletionCollectionViewCell.swift
//  Pods
//
//  Created by Austin McLaughlin on 2/15/24.
//

import UIKit
import MapKit

class SearchAutoCompletionCollectionViewCell: UICollectionViewCell {
    @IBOutlet var placeNameLabel: UILabel!
    @IBOutlet var placeAddressLabel: UILabel!
    
    var applePlace: MKMapItem?
    var gptPlace: GPTPlace?
    var cellType: CellType = .autocomplete
    
    enum CellType {
        case autocomplete
        case place
    }
    
    override func prepareForReuse() {
        applePlace = nil
        super.prepareForReuse()
    }
    
    func styleCell() {
        
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
