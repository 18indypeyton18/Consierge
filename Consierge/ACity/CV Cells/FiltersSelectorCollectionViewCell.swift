//
//  FiltersSelectorCollectionViewCell.swift
//  Consierge
//
//  Created by Austin McLaughlin on 1/6/24.
//

import UIKit

class FiltersSelectorCollectionViewCell: UICollectionViewCell {
    @IBOutlet var selectedIndicator: UIImageView!
    @IBOutlet var sliderImage: UIImageView!
    
    func styleCell() {
        contentView.clipsToBounds = false
    }
}
