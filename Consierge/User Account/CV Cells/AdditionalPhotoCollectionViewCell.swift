//
//  AdditionalPhotoCollectionViewCell.swift
//  ConciergePF for Admins
//
//  Created by Austin McLaughlin on 5/16/23.
//

import UIKit

class AdditionalPhotoCollectionViewCell: UICollectionViewCell {
    @IBOutlet var placePic: UIImageView!
    var additionalPhoto: AdditionalPhoto?
    
    var imageRequestTask: Task<Void,Never>? = nil
    deinit {
        imageRequestTask?.cancel()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let noView = UIView(frame: bounds)
        noView.backgroundColor = nil
        self.backgroundView = noView

        let blueView = UIView(frame: bounds)
        blueView.backgroundColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
        self.selectedBackgroundView = blueView
    }
    
    func fetchImage(imageURL: String) {
        imageRequestTask = Task {
            if let image = try? await ImageRequest(path: imageURL).send() {
                DispatchQueue.main.async {
                    self.placePic.image = image
                }
                imageRequestTask?.cancel()
            } else {
                self.placePic.image = nil
            }
        }
    }
}
