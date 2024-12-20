//
//  MassEditCollectionViewCell.swift
//  ConciergePF for Admins
//
//  Created by Austin McLaughlin on 5/16/23.
//

import UIKit

class MassEditCollectionViewCell: UICollectionViewCell {
    weak var delegate: MassEditCollectionViewCellDelegate?
    var selectAllButtonState = false

    @IBOutlet var selectAllCellsButton: UIButton!
    
    @IBAction func approveAll(_ sender: Any) {
        delegate?.approveSelected()
    }
    
    @IBAction func rejectAll(_ sender: Any) {
        delegate?.rejectSelected()
    }
    
    @IBAction func selectAllRows(_ sender: Any) {
        switch selectAllButtonState {
        case false:
            self.delegate?.selectAllRows()
            selectAllCellsButton.setTitle("Select None", for: .normal)
        case true:
            self.delegate?.deselectAllRows()
            selectAllCellsButton.setTitle("Select All", for: .normal)
        }
        selectAllButtonState.toggle()
    }
}

protocol MassEditCollectionViewCellDelegate: AnyObject {
    //Delegate function used by ACity to immediately add a new Place to the view
    func approveSelected()
    func rejectSelected()
    func selectAllRows()
    func deselectAllRows()
}
