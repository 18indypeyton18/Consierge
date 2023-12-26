//
//  GPTClearCollectionViewCell.swift
//  Consierge
//
//  Created by Austin McLaughlin on 10/12/24.
//

import UIKit

class GPTClearCollectionViewCell: UICollectionViewCell {
    @IBOutlet var clearButton: UIButton!
    
    weak var delegate: GPTClearCollectionViewCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Setting the font to Helvetica Neue Bold, 12 point size
        clearButton.titleLabel?.font = UIFont(name: "KohinoorGujarati-Regular", size: 15)
    }

    @IBAction func clearPressed(_ sender: Any) {
        delegate?.clearPressed()
    }
}

protocol GPTClearCollectionViewCellDelegate: AnyObject {
    func clearPressed()
}
