//
//  SegmentControllerCollectionViewCell.swift
//  Consierge
//
//  Created by Austin McLaughlin on 12/27/23.
//

import UIKit

class SegmentControllerCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var segmentIcon: UIImageView!
    @IBOutlet var segmentName: UILabel!
    @IBOutlet var segmentSelectedBar: UIView!
    var placeType: PlaceType?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Ensure that the icon's size remains constant
        segmentIcon.contentMode = .scaleAspectFit
        segmentIcon.translatesAutoresizingMaskIntoConstraints = false
        
        segmentSelectedBar.layer.shadowColor = UIColor.gray.cgColor
        segmentSelectedBar.layer.shadowOffset = CGSize(width: 0.0, height: 0.5)
        segmentSelectedBar.layer.shadowOpacity = 0.5
        
        segmentIcon.contentMode = .center
        segmentIcon.clipsToBounds = true
        segmentIcon.layer.masksToBounds = true
        segmentIcon.layer.cornerRadius = segmentIcon.bounds.width / 2
        segmentIcon.backgroundColor = .clear
    }
}
