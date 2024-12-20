//
//  ItineraryLineCollectionViewCell.swift
//  Consierge
//
//  Created by Austin McLaughlin on 12/7/24.
//

import UIKit

class ItineraryLineCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var startDateLabel: UILabel!
    @IBOutlet var customNoteLabel: UILabel!
    
    var itineraryLine: ItineraryLine?
    
}
