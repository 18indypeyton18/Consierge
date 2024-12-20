//
//  ItineraryLineEditCollectionViewCell.swift
//  Consierge
//
//  Created by Austin McLaughlin on 12/7/24.
//

import UIKit

class ItineraryLineEditCollectionViewCell: UICollectionViewCell {
    
    var itineraryLine: ItineraryLine?
    
    weak var delegate: ItineraryLineEditCollectionViewCellDelegate?
        
    @IBAction func deleteItineraryLine(_ sender: Any) {
        Task {
            if let itineraryLine = itineraryLine {
                let resultValue = try? await DeleteItineraryLineRequest(itineraryLine: itineraryLine).send()
                if let resultValue = resultValue {
                    if resultValue["status"] == "Success" {
                        self.delegate?.updateAfterDelete(itineraryLine)
                    }
                }
            }
        }
    }
}

protocol ItineraryLineEditCollectionViewCellDelegate: AnyObject {
    //Delegate function used by ACity to immediately add a new Place to the view
    func updateAfterDelete(_ itineraryLine: ItineraryLine)
}
