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
    
    weak var delegate: FiltersSelectorCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        contentView.addGestureRecognizer(longPressGesture)
    }
    
    @objc private func handleLongPress() {
        delegate?.resetFilters()
    }
    
    func styleCell() {
        contentView.clipsToBounds = false
    }
}
protocol FiltersSelectorCellDelegate: AnyObject {
    //Delegate function used by ACity to immediately add a new Place to the view
    func resetFilters()
}
