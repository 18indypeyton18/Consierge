//
//  NamedSectionHeaderView.swift
//  Concierge 0.1
//
//  Created by Austin McLaughlin on 7/5/22.
//

import UIKit

class NamedSectionHeaderView: UICollectionReusableView {
    //Section Header for ACity Place type sections
    weak var delegate: NamedSectionHeaderViewDelegate?
    var neighborhood: String?
    var genre: String?
    var lovedPlaces = false
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .darkText
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        
        
        return label
    }()
    
    let actionButton: UIButton = {
            let button = UIButton()
        button.setTitle("See All", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.addTarget(NamedSectionHeaderView.self, action: #selector(buttonTapped), for: .touchUpInside)
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        // Create the look of the Section header and specify location within the CollectionViewController
        backgroundColor = .white
        
        addSubview(nameLabel)
        addSubview(actionButton) // Add the button as a subview
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        actionButton.translatesAutoresizingMaskIntoConstraints = false // Make sure to set this to false for auto layout
        
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            nameLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            // Add constraints for the button to be on the far right of the header view
            actionButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            actionButton.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
    
    @objc private func buttonTapped() {
        delegate?.headerViewButtonTapped(self)
    }
}

protocol NamedSectionHeaderViewDelegate: AnyObject {
    func headerViewButtonTapped(_ headerView: NamedSectionHeaderView)
}
