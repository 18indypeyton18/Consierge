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
    
    weak var delegate: AddCommentDelegate?

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
            guard let placeID = place?.id, let cityID = place?.cityID.cityID, let placeTypeID = place?.placeTypeID else { break }
            let addTag = AddTag(tagID: 0, tagName: tag, userID: currentUser.id, placeID: placeID, cityID: cityID, placeTypeID: placeTypeID)
            tagFunctions.addTag(addTag: addTag)
        }
        
        let comment = tvCell.reviewTextView.text ?? "default comment plz fix"
        
        let date = Date.now.ISO8601Format()
        
        var user = currentUser.username
        if ((user?.isEmpty) != nil) {
            user = currentUser.firstName + " " + currentUser.lastName.prefix(1)
        }
        
        let placeType = placeSource.rawValue
        if placeSource == .fsq {
            guard let _ = place?.fsqID else {return}
            let addComment = Comment(ID: 1, username: user ?? "abcUser23", commentDate: date, comment: comment, placeID: 1, fsqID: place?.fsqID, placeType: placeType, communityScore: 1, status: "Approved")
            
            addCommentRequestTask = Task {
                let resultValue = try? await AddFSQCommentRequest(comment: addComment).send()
                if let resultValue = resultValue {
                    if resultValue["status"] == "Success" {
                        DispatchQueue.main.async {
                            self.delegate?.didAddComment()
                            self.navigationController?.popViewController(animated: true)
                        }
                    } else {
                        // print(resultValue)
                    }
                } else {
                    // print("unknown error")
                }
            }
        } else {
            let addComment = Comment(ID: 1, username: user ?? "abcUser23", commentDate: date, comment: comment, placeID: place?.id ?? 1, placeType: placeType, communityScore: 1, status: "Approved")
            addCommentRequestTask = Task {
                let resultValue = try? await AddCommentRequest(comment: addComment).send()
                if let resultValue = resultValue {
                    if resultValue["status"] == "Success" {
                        DispatchQueue.main.async {
                            let commentId = Int(resultValue["commentId"] ?? "0") ?? 0
                            self.moderateReview(comment: addComment, commentId: commentId)
                            self.delegate?.didAddComment()
                            self.navigationController?.popViewController(animated: true)
                        }
                    } else {
                        // print(resultValue)
                    }
                } else {
                    // print("unknown error")
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
protocol AddCommentDelegate: AnyObject {
    func didAddComment()
}

extension AddCommentCollectionViewController {
    
    func moderateReview(comment: Comment, commentId: Int) {
        let commentText = comment.comment
        
        let systemPrompt = """
You are moderating user submitted content. The acceptable moderationResult values are "Approved", "Review", "Rejected"
        Provide the response in a JSON format. Don't provide any supporting text, only the JSON response. The response should start with the character "{" and end with the character "}". See the required format below.
--------------------------------------------------------------------------------------------------
        {"moderationResult": "Review"}
--------------------------------------------------------------------------------------------------

"""
        
        var gptPrompt = """
You are a content moderation assistant. A user has submitted a Review for a place:

'
"""
        gptPrompt += commentText
        
        gptPrompt += """
'

Evaluate this Review against the following rules:

1. **Profanity & Obscenity:** No swear words, crude language, or sexual explicitness.  
2. **Hate Speech & Slurs:** No insults or slurs targeting protected groups (race, religion, gender, sexuality, etc.).  
3. **Harassment & Threats:** No threats, intimidation, or personal attacks.  
4. **Violence & Self-harm:** No graphic violence or encouragement of self-harm.  
5. **Illegal Activity:** No admission or promotion of crimes.  
6. **Context & Tone:** Harmless jokes, puns or non-offensive slang should be **approved**, even if mildly cheeky.

**Output only one** of these values (no extra text):
- **Approved**  → meets all rules  
- **Review**    → borderline or ambiguous (human review needed)  
- **Rejected**  → clearly violates one or more rules

Respond with exactly:
        {"moderationResult": "Approved"/"Review"/"Rejected"}
"""
        
        let request = ChatGPTCompletionRequest(model: "gpt-4o", systemPrompt: systemPrompt, prompts: [gptPrompt], maxTokens: 500, temperature: 0.7, username: "system")
        
        Task {
            let response = try await request.send()
            if let text = response.choices.first?.message.content {
                self.parseGPTModerationResponse(text: text, commentId: commentId)
            } else {
                // print("GPT Moderation for AskAI Error")
            }
        }
    }
    
    func parseGPTModerationResponse(text: String, commentId: Int) {
        // Convert the string to a Data object
        guard let jsonData = text.data(using: .utf8) else {
            // print("Error: Cannot convert string to Data object")
            return
        }

        // Create an instance of JSONDecoder
        let decoder = JSONDecoder()

        // Attempt to decode the Data object into our Swift structs
        do {
            let response = try decoder.decode(GPTModerationResponse.self, from: jsonData)
            Task {
                let status = response.moderationResult
                let commentStatus = CommentStatus(commentId: commentId, status: status)
                
                let _ = try? await UpdateCommentStatus(commentStatus: commentStatus).send()
            }
        } catch {
            // print("GPTModerationResponse decode failed")
        }
    }
}
