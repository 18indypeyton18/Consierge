//
//  CityCollectionViewCell.swift
//  Consierge
//
//  Created by Austin McLaughlin on 12/28/23.
//

import UIKit

class CityCollectionViewCell: UICollectionViewCell {
    
    var city: City?
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var cityHeaderImage: UIImageView!
    
    weak var delegate: CityCollectionViewCellDelegate?
    
    override func awakeFromNib() {
        let lpgr : UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        lpgr.minimumPressDuration = 0.5
        lpgr.view?.isUserInteractionEnabled = true
        lpgr.delaysTouchesBegan = true
        self.addInteraction(UIContextMenuInteraction(delegate: self as UIContextMenuInteractionDelegate))
        self.cityHeaderImage.addGestureRecognizer(lpgr)
    }
}

extension CityCollectionViewCell: UIContextMenuInteractionDelegate {
    //Context Menu Extension to support 'Hold to <3' functionality in ACity CVC
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { suggestedActions in
            
            
            let role = currentUser.role
            if role == "Admin" {
                
                let photoAction = UIAction(title: NSLocalizedString("Add Photo", comment: ""),
                         image: UIImage(systemName: "photo")) { action in
                    self.delegate?.addPhoto(city: self.city)
                }
                return UIMenu(title: "", children: [photoAction])
            } else {
                return UIMenu(title: "", children: [])
            }
        })
    }
    
    @objc func handleLongPress(gestureRecognizer : UILongPressGestureRecognizer){}
}


protocol CityCollectionViewCellDelegate: AnyObject {
    func addPhoto(city: City?)
}
