//
//  LowInventoryAddNewPlaceCollectionViewCell.swift
//  Consierge
//
//  Created by Austin McLaughlin on 6/7/25.
//

import UIKit

class LowInventoryAddNewPlaceCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var addPlaceLabel: UILabel!
    
    weak var delegate: LowInventoryAddPlaceCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        styleCell()
        attributeText(fullText: addPlaceLabel.text ?? "", highlightText: "adding a place")
        attachTapGesture()
    }
    
    func styleCell() {
        // 1) Round the corners and give a light gray, semi-transparent fill
        contentView.backgroundColor = UIColor.cyan.withAlphaComponent(0.15)
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true

        // 2) Apply the shadow on the cell layer (outside the contentView)
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowOffset = CGSize(width: 0, height: 3)
        layer.shadowRadius = 8
        layer.masksToBounds = false
    }
    
    func attributeText(fullText: String, highlightText: String) {
        let attr = NSMutableAttributedString(string: fullText)
        if let range = fullText.range(of: highlightText) {
            let nsRange = NSRange(range, in: fullText)
            attr.addAttribute(.foregroundColor,
                              value: UIColor.systemBlue,
                              range: nsRange)
            attr.addAttribute(.underlineStyle,
                              value: NSUnderlineStyle.single.rawValue,
                              range: nsRange)
        }
        
        addPlaceLabel.attributedText = attr
        addPlaceLabel.numberOfLines = 0
    }
    
    func attachTapGesture() {
        addPlaceLabel.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(labelTapped))
        addPlaceLabel.addGestureRecognizer(tap)        
    }
    
    @objc private func labelTapped() {
        delegate?.addPlaceCellDidTapAddLabel()
    }
}

protocol LowInventoryAddPlaceCellDelegate: AnyObject {
    /// Called when the user taps the "add place" label
    func addPlaceCellDidTapAddLabel()
}
