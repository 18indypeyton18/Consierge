//
//  PlaceTypeCollectionViewCell.swift
//  Consierge
//
//  Created by Austin McLaughlin on 1/9/24.
//

import UIKit

class PlaceTypeCollectionViewCell: UICollectionViewCell {
    @IBOutlet var iconImg: UIImageView!
    @IBOutlet var placeTypeName: UILabel!
    @IBOutlet var selectedPlaceTypeBar: UIView!
    
    var placeType: PlaceType?
}
