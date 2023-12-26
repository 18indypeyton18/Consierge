//
//  AddCommentCollectionViewController.swift
//  Consierge
//
//  Created by Austin McLaughlin on 2/6/24.
//

import UIKit

class AddCommentCollectionViewController: UICollectionViewController {
    
    var place: Place?
    var placeSource: PlaceSource = .concierge
    var tags = [String]()
    var filteredTags = [String]()
    var selectedTags = [String]()

    @IBOutlet var sendButton: UIBarButtonItem!
    
    var addCommentRequestTask: Task<Void,Never>? = nil

    deinit {
        addCommentRequestTask?.cancel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.dataSource = self
        collectionView.collectionViewLayout = createLayout()
        collectionView.register(SectionFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "FooterView")
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        switch section {
        case 2:
            return filteredTags.count
        default:
            return 1
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ReviewTextView", for: indexPath) as! ReviewTextViewCollectionViewCell
            cell.styleCell()
            
            return cell
        case 1:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FilterLabel", for: indexPath) as! FilterLabelCollectionViewCell
            cell.delegate = self
            return cell
        default:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Filter", for: indexPath) as! FilterCollectionViewCell
            
            cell.filter.text = filteredTags[indexPath.item]
            cell.layer.borderColor = UIColor.clear.cgColor
            cell.xMarker.isHidden = true
            
            cell.styleCell(background: 3)
            
            return cell
        }
    }
    
    func createLayout() -> UICollectionViewCompositionalLayout {
        
        let layout = UICollectionViewCompositionalLayout { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            switch sectionIndex {
            case 0:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(180))
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(180))
                
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)
                
                let footerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(1)) // Adjust the height as needed
                let footer = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: footerSize, elementKind: UICollectionView.elementKindSectionFooter, alignment: .bottom)
                section.boundarySupplementaryItems = [footer]
                
                return section
            case 1:
                let itemSize1 = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(75))
                let item1 = NSCollectionLayoutItem(layoutSize: itemSize1)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(75))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item1])
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 15, leading: 5, bottom: 5, trailing: 5)
                
                return section
            default:
                let itemSize = NSCollectionLayoutSize(widthDimension: .estimated(500), heightDimension: .absolute(28))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .estimated(500), heightDimension: .absolute(28))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, repeatingSubitem: item, count: 1)
                
                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .continuous
                section.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 20, bottom: 15, trailing: 20)
                section.interGroupSpacing = 10
                
                let footerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(1))
                let footer = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: footerSize, elementKind: UICollectionView.elementKindSectionFooter, alignment: .bottom)
                section.boundarySupplementaryItems = [footer]
                
                return section
            }
        }
        return layout
    }
    
    
    @IBAction func sendPressed(_ sender: Any) {
        guard let tvCell = collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? ReviewTextViewCollectionViewCell, tvCell.reviewTextView.text.isEmpty == false else {return}
        
        let tagFunctions = TagFunctions()
        for tag in tags {
            guard let placeID = place?.id, let cityID = place?.cityID.cityID else { break }
            let addTag = AddTag(tagID: 0, tagName: tag, userID: currentUser.id, placeID: placeID, cityID: cityID)
            tagFunctions.addTag(addTag: addTag)
        }
        
        let comment = tvCell.reviewTextView.text ?? "default comment plz fix"
        let date = Date.now.ISO8601Format()
        let user = UserDefaults.standard.string(forKey: "username") ?? "abcUser23"
        
        let placeType = placeSource.rawValue
        if placeSource == .fsq || placeSource == .google {
            guard let fsqID = place?.fsqID else {print("fuck");return}
            let addComment = Comment(ID: 1, username: user, commentDate: date, comment: comment, placeID: 1, fsqID: place?.fsqID, placeType: placeType, communityScore: 1)
            
            addCommentRequestTask = Task {
                let resultValue = try? await AddFSQCommentRequest(comment: addComment).send()
                if let resultValue = resultValue {
                    if resultValue["status"] == "Success" {
                        DispatchQueue.main.async {
                            print(resultValue)
                            self.navigationController?.popViewController(animated: true)
                        }
                    } else {
                        print(resultValue)
                    }
                } else {
                    print("unknown error")
                }
            }
        } else {
            let addComment = Comment(ID: 1, username: user, commentDate: date, comment: comment, placeID: place?.id ?? 1, placeType: placeType, communityScore: 1)
            print(addComment)
            addCommentRequestTask = Task {
                let resultValue = try? await AddCommentRequest(comment: addComment).send()
                if let resultValue = resultValue {
                    DispatchQueue.main.async {
                        print(resultValue)
                        self.navigationController?.popViewController(animated: true)
                    }
                } else {
                    print("unknown error")
                }
            }
        }
    }
}

extension AddCommentCollectionViewController: FilterLabelCollectionViewCellDelegate {
    func searchFilters(text: String, filterType: FilterLabelCollectionViewCell.FilterType?) {
    }
    
    func addFilter(filter: String, filterType: FilterLabelCollectionViewCell.FilterType?) {
        tags.append(filter)
        filteredTags.append(filter)
        collectionView.reloadData()
    }
}
