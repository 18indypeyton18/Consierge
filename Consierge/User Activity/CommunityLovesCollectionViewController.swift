//
//  CommunityLovesCollectionViewController.swift
//  Consierge
//
//  Created by Austin McLaughlin on 3/2/25.
//

import UIKit

private let reuseIdentifier = "Cell"

class CommunityLovesCollectionViewController: UICollectionViewController {
    
    var placeID = 0
    
    var users = [User]()
    var thisRecencyDict = [Int:Int]()
    var thisLovedPlaceDict = [Int:LovePlace]()
    
    var selectedUser: User?
    
    var communityLovesRequestTask: Task<Void,Never>? = nil
    deinit {
        communityLovesRequestTask?.cancel()
    }

    override func viewDidLoad() {
        loadPage()
        collectionView.collectionViewLayout = createLayout()
        super.viewDidLoad()
    }
    
    func loadPage() {
        if placeID == 0 { return }
        getCommunityLovesUsers()
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return users.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UserAccountLovedPlace", for: indexPath) as! UserAccountLovedPlaceCollectionViewCell
        
        let thisUser = users[indexPath.item]
        
        cell.fetchUserProfPicImage(profPicURL: thisUser.profPicImageURL)
        
        cell.placeNameLabel.text = "\(thisUser.firstName) \(thisUser.lastName)"
        
        cell.dateLovedLabel.text = getLovedPlaceTimestamp(userID: thisUser.id)
        
        return cell
    }
    
    func createLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(70))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 3, leading: 5, bottom: 2, trailing: 5)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(70))
            let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 7, trailing: 0)
            
            return section
        }
        return layout
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedUser = users[indexPath.item]
        performSegue(withIdentifier: "UserActivity", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "UserActivity" {
            let cvc = segue.destination as! UserActivityCollectionViewController
            guard let selectedUser = selectedUser else { return }
            cvc.userID = selectedUser.id
            if let uName = selectedUser.username, uName != "" {
                cvc.userName = uName
            } else {
                cvc.userName = "\(selectedUser.firstName) \(selectedUser.lastName.first ?? " ")"
            }
            cvc.selectedSegmentIndex = 0
        }
    }
}

extension CommunityLovesCollectionViewController {
    func getCommunityLovesUsers() {
        communityLovesRequestTask = Task {
            if let communityLovesUsers = try? await CommunityLovesUsersRequest(placeID: placeID).send() {
                users = communityLovesUsers
            }
            
            if let lovedPlaces = try? await CommunityLovesPlacesRequest(placeID: placeID).send() {
                
                for lovedPlace in lovedPlaces {
                    thisRecencyDict[lovedPlace.userID] = lovedPlace.ID
                    thisLovedPlaceDict[lovedPlace.userID] = lovedPlace
                }
            }
            sortUsers()
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    func sortUsers() {
        users = users.sorted(by: { lhs, rhs in
            if let lhsRecency = thisRecencyDict[lhs.id], let rhsRecency = thisRecencyDict[rhs.id] {
                return lhsRecency > rhsRecency
            } else {
                return lhs.id > rhs.id
            }
        })
    }
}

extension CommunityLovesCollectionViewController {
    func getLovedPlaceTimestamp(userID: Int) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
    
        let lovePlace = thisLovedPlaceDict[userID]
        let dateString = lovePlace?.lovedDate
        guard var dateString = dateString else { return "" }
        
        if dateString.hasSuffix("Z") {
            dateString = String(dateString.dropLast())
            dateString = dateString.replacingOccurrences(of: "T", with: " ")
        }

        if let date = dateFormatter.date(from: dateString) {
            return timeAgo(from: date)
        }
        else {
            return ""
        }
    }
    
    func timeAgo(from lovedDate: Date, in timeZone: TimeZone = TimeZone.current) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .weekOfYear, .day, .hour, .minute], from: lovedDate, to: now)
        
        if let year = components.year, year >= 1 {
            return "\(year)y ago"
        } else if let month = components.month, month >= 1 {
            return "\(month)mo ago"
        } else if let week = components.weekOfYear, week >= 1 {
            return "\(week)w ago"
        } else if let day = components.day, day >= 1 {
            return "\(day)d ago"
        } else if let hour = components.hour, hour >= 1 {
            return "\(hour)h ago"
        } else if let minute = components.minute, minute >= 1 {
            return "\(minute)m ago"
        } else {
            return "just now"
        }
    }
}


