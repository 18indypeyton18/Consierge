//
//  MassEditTableViewCell.swift
//  ConciergePF for Admins
//
//  Created by Austin McLaughlin on 3/12/23.
//

import UIKit

class MassEditTableViewCell: UITableViewCell {

    weak var delegate: MassEditTableViewCellDelegate?
    
    
    @IBOutlet var selectAllRowsButton: UIButton!
    var selectAllButtonState = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    
    @IBAction func selectAllRows(_ sender: Any) {
        switch selectAllButtonState {
        case false:
            self.delegate?.selectAllRows()
            selectAllRowsButton.setTitle("Select None", for: .normal)
        case true:
            self.delegate?.deselectAllRows()
            selectAllRowsButton.setTitle("Select All", for: .normal)
        }
        selectAllButtonState.toggle()
    }
    
    @IBAction func approveSelected(_ sender: Any) {
        self.delegate?.approveSelected()
    }
    
    @IBAction func rejectSelected(_ sender: Any) {
        self.delegate?.rejectSelected()
    }
}
protocol MassEditTableViewCellDelegate: AnyObject {
    //Delegate function used by ACity to immediately add a new Place to the view
    func approveSelected()
    func rejectSelected()
    func selectAllRows()
    func deselectAllRows()
}
