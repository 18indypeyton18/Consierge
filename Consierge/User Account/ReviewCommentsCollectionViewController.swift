//
//  ReviewAdditionalPhotosCollectionViewController.swift
//  Concierge 0.1
//
//  Created by Austin McLaughlin on 7/21/23.
//

import UIKit

private let reuseIdentifier = "Cell"

class ReviewCommentsCollectionViewController: UICollectionViewController {

    var comments: [Comment] = []
    
    var selectedIndices: [IndexPath] = []
    
    var commentsRequestTask: Task<Void,Never>? = nil
    var imageRequestTask: Task<Void,Never>? = nil
    var approveCommentRequestTask: Task<Void,Never>? = nil

    
    deinit {
        commentsRequestTask?.cancel()
        imageRequestTask?.cancel()
        approveCommentRequestTask?.cancel()
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        update()
        collectionView.collectionViewLayout = createLayout()
    }

    func update() {
        self.commentsRequestTask = Task {
            if let comments = try? await GetCommentsToReviewRequest().send() {
                self.comments = comments
                collectionView.reloadData()
            } else {
                // print("Failed")
            }
        }
    }
    
    func approveComment(_ comment: Comment, status: String) {
        var comment = comment
        comment.status = status
        approveCommentRequestTask = Task {
            let resultValue = try? await ApproveCommentRequest(comment: comment).send()
            var myAlert = UIAlertController(title: resultValue?["status"], message: resultValue?["message"], preferredStyle: UIAlertController.Style.alert)
            if let _ = resultValue?["ID"] {
                //Display the result to the user
                if resultValue?["status"] == "Success" {
                    DispatchQueue.main.async {
                        let okAction = UIAlertAction(title: "Close", style: UIAlertAction.Style.default) { action in
                            //self.uploadIndicator.stopAnimating()
                            self.update()
                        }
                        myAlert.addAction(okAction)
                        self.present(myAlert, animated: true, completion: nil)
                    }
                }
            } else if resultValue?["status"]?.lowercased() == "error" {
                DispatchQueue.main.async {
                    //Display the failed result to the user and stay on the page
                    let okAction = UIAlertAction(title: "Close", style: UIAlertAction.Style.default)
                    myAlert.addAction(okAction)
                    self.present(myAlert, animated: true, completion: nil)
                }
            } else {
                DispatchQueue.main.async {
                    //Display the failed result to the user and stay on the page
                    myAlert = UIAlertController(title: "Error", message: "undefined error", preferredStyle: UIAlertController.Style.alert)
                    let okAction = UIAlertAction(title: "Close", style: UIAlertAction.Style.default)
                    
                    myAlert.addAction(okAction)
                    self.present(myAlert, animated: true, completion: nil)
                }
            }
        }
    }
    
    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        switch section {
        case 0:
            return 1
        default:
            return comments.count
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MassEdit", for: indexPath) as! MassEditCollectionViewCell
            cell.delegate = self
            return cell
        default:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Comment", for: indexPath) as! ReviewCommentCollectionViewCell
            let comment = comments[indexPath.item]
            cell.comment = comment
            cell.commentLabel.text = comment.comment
            return cell
        }
    }
    
    func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { (sectionIndex, environment) -> NSCollectionLayoutSection? in
                if sectionIndex == 0 {
                    // First section with one cell occupying the entire width and 110pt height
                    let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(110))
                    let item = NSCollectionLayoutItem(layoutSize: itemSize)
                    
                    let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(110))
                    let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                    let section = NSCollectionLayoutSection(group: group)
                    return section
                } else {
                    // Second section with cells displaying photos
                    let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.95), heightDimension: .estimated(100))
                    let item = NSCollectionLayoutItem(layoutSize: itemSize)
                    
                    item.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 3, bottom: 0, trailing: 3)
                    
                    let groupsize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(130.0))
                    let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupsize, subitems: [item])
                    
                    group.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 3, trailing: 2)
                    
                    let section = NSCollectionLayoutSection(group: group)
                    return section
                }
            }
            return layout
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let index = selectedIndices.firstIndex(of: indexPath) {
            selectedIndices.remove(at: index)
            let cell = collectionView.cellForItem(at: indexPath)
            cell?.isSelected = false
            cell?.contentView.backgroundColor = nil
        } else {
            selectedIndices.append(indexPath)
            let cell = collectionView.cellForItem(at: indexPath)
            cell?.isSelected = true
            cell?.contentView.backgroundColor = .systemGray5
        }
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}

extension ReviewCommentsCollectionViewController: MassEditCollectionViewCellDelegate {
    func approveSelected() {
        for indexPath in selectedIndices {
            let selectedCell = collectionView.cellForItem(at: indexPath) as? ReviewCommentCollectionViewCell
            if let comment = selectedCell?.comment {
                approveComment(comment, status: "Approved")
            }
        }
    }
    
    func rejectSelected() {
        for indexPath in selectedIndices {
            let selectedCell = collectionView.cellForItem(at: indexPath) as? ReviewCommentCollectionViewCell
            if let comment = selectedCell?.comment {
                approveComment(comment, status: "Rejected")
            }
        }
    }
    
    func selectAllRows() {
        for i in 0...comments.count {
            let iP = IndexPath(item: i, section: 1)
            let thisCell = collectionView.cellForItem(at: iP)
            if thisCell?.isSelected == false {
                selectedIndices.append(iP)
                thisCell?.isSelected = true
                thisCell?.contentView.backgroundColor = .systemGray5
            }
        }
    }
    
    func deselectAllRows() {
        for i in 0...comments.count {
            let iP = IndexPath(item: i, section: 1)
            let thisCell = collectionView.cellForItem(at: iP)
            if thisCell?.isSelected == true {
                thisCell?.isSelected = false
                thisCell?.contentView.backgroundColor = nil
            }
        }
        selectedIndices = []
    }
}
