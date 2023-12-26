//
//  GPTPromptCollectionViewCell.swift
//  Consierge
//
//  Created by Austin McLaughlin on 10/6/24.
//

import UIKit

class GPTPromptCollectionViewCell: UICollectionViewCell {
    
    var prompt: String?
    @IBOutlet var promptLabel: UILabel!
    private let gradientLayer = CAGradientLayer()
    
    func styleCell(color: UIColor) {
        gradientLayer.colors = [
            color.withAlphaComponent(0.5).cgColor,
            color.withAlphaComponent(0.6).cgColor,
            color.withAlphaComponent(0.7).cgColor,
            color.withAlphaComponent(0.8).cgColor,
            color.withAlphaComponent(0.9).cgColor,
            color.withAlphaComponent(1.0).cgColor
        ]
        
        layer.cornerRadius = 10
        layer.masksToBounds = false
        
        layer.shadowColor = UIColor.darkGray.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4.0
        
        if gradientLayer.superlayer == nil {
            layer.insertSublayer(gradientLayer, at: 0)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = 10
    }
}
