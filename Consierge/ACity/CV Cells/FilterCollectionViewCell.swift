//
//  FilterCollectionViewCell.swift
//  Consierge
//
//  Created by Austin McLaughlin on 1/16/24.
//

import UIKit

class FilterCollectionViewCell: UICollectionViewCell {
    @IBOutlet var filter: UILabel!
    @IBOutlet var xMarker: UIImageView!
    
    var nei: Neighborhood?
    var cat: Genre?
    
    func styleCell(background: Int) {
        // Create shadow for the entire cell
        self.layer.cornerRadius = 8.0 // Optional: Add corner radius for rounded corners
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowOpacity = 0.2
        self.layer.shadowOffset = CGSize(width: 0, height: 2)
        self.layer.shadowRadius = 4.0
        self.layer.masksToBounds = false
        
        switch background {
        case 2:
            self.backgroundColor = BACKGROUND2
        case 3:
            self.backgroundColor = BACKGROUND3
        default:
            self.backgroundColor = BACKGROUND1
        }
        
        contentView.clipsToBounds = false
    }
}

class FilterLabelCollectionViewCell: UICollectionViewCell, UISearchBarDelegate {
    @IBOutlet var filterLabel: UILabel!
    @IBOutlet var filterText: UISearchBar!
    
    enum FilterType {
        case Neighborhood
        case Category
        case Tag
    }
    
    weak var delegate: FilterLabelCollectionViewCellDelegate?
    var filterType: FilterType?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        filterText.delegate = self // Setting the UISearchBar delegate
    }
    override func prepareForReuse() {
        filterText.text = ""
        super.prepareForReuse()
    }
    
    @IBAction func addFilterPressed(_ sender: Any) {
        guard let filter = filterText.text else { return }
        delegate?.addFilter(filter: filter, filterType: filterType)
    }
    // Called when the user hits return (Search button) in the search bar
        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let filter = searchBar.text else { return }
        delegate?.addFilter(filter: filter, filterType: filterType) // Call the same delegate as 'Add' button
    }
    
    // Called when the text in the search bar changes
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        delegate?.searchFilters(text: searchText, filterType: filterType) // Call the new delegate method for text change
    }
}
protocol FilterLabelCollectionViewCellDelegate: AnyObject {
    func addFilter(filter: String, filterType: FilterLabelCollectionViewCell.FilterType?)
    func searchFilters(text: String, filterType: FilterLabelCollectionViewCell.FilterType?)
}

class SliderFilterCollectionViewCell: UICollectionViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var milesSlider: UISlider!
    @IBOutlet var milesLabel: UILabel!
    @IBOutlet var dropDown: UIImageView!
    
    weak var delegate: SliderFilterCollectionViewCellDelegate?
    
    var milesMax: Float = 100.0
    var milesMin: Float = 0.1 // Minimum value

    override func awakeFromNib() {
        super.awakeFromNib()
        
        milesSlider.minimumValue = 0.0
        milesSlider.maximumValue = 1.0
        milesSlider.value = 0.0
        
        // Initialize the label with the minimum value
        updateMilesLabel(for: milesSlider.value)
    }
    
    @IBAction func milesSlideValueChanged(_ sender: UISlider) {
        updateMilesLabel(for: sender.value)
    }
    
    private func updateMilesLabel(for sliderValue: Float) {
        // Calculate the miles based on the slider value
        let miles = milesMin * pow((milesMax / milesMin), sliderValue)
        milesLabel.text = "\(String(format: "%.2f", miles)) miles"
        delegate?.sliderUpdated(miles: miles)
    }
}
protocol SliderFilterCollectionViewCellDelegate: AnyObject {
    func sliderUpdated(miles: Float)
}

class ResetFiltersCollectionViewCell: UICollectionViewCell {
    @IBOutlet var resetButton: UIButton!
    
    weak var delegate: ResetFiltersCollectionViewCellDelegate?
    
    func styleCell() {
        resetButton.layer.cornerRadius = 8.0 // Optional: Add corner radius for rounded corners
        resetButton.layer.shadowColor = UIColor.darkGray.cgColor
        resetButton.layer.shadowOpacity = 0.2
        resetButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        resetButton.layer.shadowRadius = 4.0
        resetButton.layer.masksToBounds = false
        resetButton.layer.borderWidth = 1.0
        resetButton.layer.borderColor = UIColor.darkGray.cgColor
    }
    
    @IBAction func resetFilters(_ sender: Any) {
        delegate?.reset()
    }
}
protocol ResetFiltersCollectionViewCellDelegate: AnyObject {
    func reset()
}
