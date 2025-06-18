//
//  ReviewCommentCollectionViewCell.swift
//  Consierge
//
//  Created by Austin McLaughlin on 5/25/25.
//

import UIKit

class ReviewCommentCollectionViewCell: UICollectionViewCell {
    var comment: Comment?
    var placeTag: ReviewTag?
    @IBOutlet var commentLabel: UILabel!
}
