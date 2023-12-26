//
//  SectionBackgroundCollectionReusableView.swift
//  Consierge
//
//  Created by Austin McLaughlin on 1/8/24.
//

import UIKit

class SectionBackgroundCollectionReusableView: UICollectionReusableView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        let containerView = UIView()
        containerView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.1)
        containerView.layer.cornerRadius = 10.0
        containerView.clipsToBounds = true
        
        // Add the container view as a subview
        addSubview(containerView)
        
        // Define the padding values
        let padding: CGFloat = 8.0 // Adjust the padding value as needed
        
        // Set up constraints for the container view with padding
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.layer.shadowColor = UIColor.gray.cgColor
        containerView.layer.shadowRadius = 1.0
        containerView.layer.shadowOffset = CGSize(width: 0.5, height: -1.0)
        containerView.layer.shadowOpacity = 0.8
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding)
        ])
    }
}


class SectionFooterView: UICollectionReusableView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.systemGray5
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
