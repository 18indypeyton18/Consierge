//
//  PlaceDetailCollectionViewController.swift
//  Consierge
//
//  Created by Austin McLaughlin on 1/22/24.
//

import UIKit
import SafariServices
import MapKit
import PhotosUI

private let reuseIdentifier = "Cell"

class PlaceDetailCollectionViewController: UICollectionViewController {
    
    @IBOutlet var lovePlaceButton: UIBarButtonItem!
    
    var place: Place
    var placeSource:PlaceSource = .concierge
    
    var sectionsPlaces: [Place]
    var sectionPlacePics = [Int:UIImage]()
    var placeIndex = 0
    
    var placePic: UIImage
    
    var isLoved = false
    
    var placePics = [Int:UIImage]()
    var picIndex = 1
    
    var tags: [PlaceTag] = []
    var comments = [Comment]()
    
    var placeNeighborhood: Neighborhood?
    var neiSelected = false
    var placeCategory: Genre?
    var catSelected = false
    var selectedTag: PlaceTag?
    var tagSelected = false
    
    var uploadedPics = [UIImage]()
    var picHeight = 333.0
    var descrHeight = 0.01
    
    var heartFill = false
    
    var sprite = [UIImage]()
    var spriteBackwards = [UIImage]()
    
    let group = DispatchGroup()
    
    var isFSQPlace = false
    var isGooglePlace = false
    
    var commentVotes = [Int: String]()
    
    let lovePlaceFunctions = LovePlaceFunctions()
    let picGetter = PicGetter()
    let tagFunctions = TagFunctions()
    
    var placeTypeID: Int?
    var cityID: Int?
    
    var segment = 0
    var type = ""
    var selectedPicIndex = 0
    
    var imageRequestTask: Task<Void,Never>? = nil
    var commentsRequestTask: Task<Void,Never>? = nil
    var newImageRequestTask: Task<Void,Never>? = nil
    var additionalImageRequestTask: Task<Void,Never>? = nil
    var tagsRequestTask: Task<Void,Never>? = nil
    var neiAndCatTask: Task<Void,Never>? = nil

    deinit {
        imageRequestTask?.cancel()
        commentsRequestTask?.cancel()
        newImageRequestTask?.cancel()
        additionalImageRequestTask?.cancel()
        tagsRequestTask?.cancel()
        neiAndCatTask?.cancel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getPlaceIndex()
        getHeartAnimationImgs()
        loadPage()
        loadSectionImages()
        loadCatAndNei()
        collectionView.setCollectionViewLayout(generateLayout(), animated: true)
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    init?(coder: NSCoder, place: Place, sectionsPlaces: [Place], placePic: UIImage, placeTypeID: Int?) {
        //init with required Place and optional section of Places
        self.place = place
        self.sectionsPlaces = sectionsPlaces
        self.placePic = placePic
        self.placeTypeID = placeTypeID
        super.init(coder: coder)
    }
    
    func loadPage() {
        self.navigationItem.title = place.name
        loadImages()
        if let pic = sectionPlacePics[placeIndex] {
            placePic = pic
        }
        picHeight = getPicHeight()
        getType()
        setupPage()
        updateHeartAtLoad()
        lovePlaceFunctions.delegate = self
        picGetter.delegate = self
        switch (isFSQPlace, isGooglePlace) {
        case (false, false):
            getComments()
        case (true, false):
            getFSQComments()
        default:
            getComments()
        }
        getTags()
        
        UIView.transition(with: collectionView, duration: 0.2, options: .transitionCrossDissolve, animations: { () -> Void in
            self.collectionView.reloadData()
        }, completion: nil)
    }
    
    func loadImages() {
        //API Requests to fetch cover photo & additional photos.
        placePics = [:]
        if let place = place as? ConciergePlace {
            picGetter.getConciergeImages(place: place, type: "Concierge")
        }
        if let place = place as? FSQPlace {
            if place.photoURLs.isEmpty == false {
                var i = 0
                for imageURL in place.photoURLs {
                    picGetter.getFSQImages(imageURL: imageURL, i: i)
                    i += 1
                }
            } else {
                let imageURL = place.imageURL
                picGetter.getFSQImages(imageURL: imageURL, i: 0)
            }
        }
        if let place = place as? GooglePlace {
            var i = 0
            for imageURL in place.photoURLs {
                picGetter.getGoogleImages(photo_reference: imageURL, i: i)
                i += 1
            }
        }
    }
    
    func loadSectionImages() {
        var i = 0
        for place in sectionsPlaces {
            if let place = place as? ConciergePlace {
                picGetter.returnConciergeImage(place: place, i: i)
            }
            if let place = place as? FSQPlace {
                picGetter.returnFSQImage(imageURL: place.imageURL, i: i)
            }
            if let place = place as? GooglePlace {
                picGetter.returnGoogleImage(photo_reference: place.imageURL, i: i)
            }
            i += 1
        }
    }
    
    func getPlaceIndex() {
        //finds the current place in the array passed to the sectionsPlaces variable and saves that index
                
        if let place = place as? ConciergePlace {
            placeIndex = sectionsPlaces.firstIndex { $0 as? ConciergePlace == place } ?? 0
        }
        if let fsqPlace = place as? FSQPlace {
            placeIndex = sectionsPlaces.firstIndex { $0 as? FSQPlace == fsqPlace } ?? 0
        }
    }
    
    func setupPage() {
        //Swipe Gesture Recognizers used to change to a new Place and update UI elements accordingly
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(swipedLeft))
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(swipedRight))
        swipeLeft.direction = .left
        swipeRight.direction = .right
        
        self.view.addGestureRecognizer(swipeLeft)
        self.view.addGestureRecognizer(swipeRight)
    }
    
    func getType() {
        switch place {
        case is FSQPlace:
            type = "FSQ"
            placeSource = .fsq
            isFSQPlace = true
            isGooglePlace = false
        case is GooglePlace:
            type = "Google"
            placeSource = .google
            isFSQPlace = false
            isGooglePlace = true
        default: type =
            "Concierge"
            placeSource = .concierge
            isFSQPlace = false
            isGooglePlace = false
        }
    }
    
    func getHeartAnimationImgs() {
        var j = 17
        for i in 0..<18 {
            if let heartImage = UIImage(named: "heart\(i)") {
                sprite.append(heartImage)
            }
            if let heartImage = UIImage(named: "heart\(j)") {
                spriteBackwards.append(heartImage)
            }
            j-=1
        }
    }
    
    @objc func swipedLeft() {
        if (placeIndex+1) < sectionsPlaces.count {
            placeIndex += 1
            self.place = sectionsPlaces[placeIndex]
            loadPage()
        }
    }
    @objc func swipedRight() {
        if placeIndex != 0 {
            placeIndex -= 1
            self.place = sectionsPlaces[placeIndex]
            loadPage()
        }
    }
    
    @objc func doubleTapped() {
        //trigger LovePlace or LoveFSQPlace when user doubleTaps on the imageView
        switch (isFSQPlace, isGooglePlace) {
        case (true, _):
            print("love FSQ")
            loveFSQAction()
        case (_, true):
            loveGooglyAction()
        default:
            lovePlaceAction()
        }
    }
    
    func lovePlaceAction() {
        lovePlaceFunctions.lovePlace(place: place, placeSource: .concierge)
        updateHeartButton()
    }
    
    func loveFSQAction() {
        guard let place = place as? FSQPlace else {return}
        lovePlaceFunctions.loveFSQPlace(place: place, placeSource: .fsq, placeTypeID: self.placeTypeID ?? 0, cityID: cityID ?? 0)
        updateHeartButton()
    }
    
    func loveGooglyAction() {
        guard let place = place as? GooglePlace else {return}
        lovePlaceFunctions.lovePlace(place: place, placeSource: .google)
        updateHeartButton()
    }
    
    func updateHeartButton() {
        // Create a UIImageView instance
        let imageView = UIImageView()

        // Set the content mode of the imageView to scale aspect fit
        imageView.contentMode = .scaleAspectFit
        
        // Disable autoresizing mask translation
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        var placeLoved = false
        switch isFSQPlace {
        case true:
            placeLoved = lovedFSQPlaces.contains { lp in
                lp.fsqID == place.fsqID
            }
        case false:
            placeLoved = userLovedPlaces.contains { thisPlace in
                "\(thisPlace.name)\(thisPlace.id)\(thisPlace.fsqID ?? "")" == "\(place.name)\(place.id)\(place.fsqID ?? "")"
            }
        }
        
        switch placeLoved {
        case true:
            imageView.animationImages = sprite
            imageView.animationDuration = 0.5
            imageView.animationRepeatCount = 1
            imageView.startAnimating()
            imageView.image = UIImage(named: "heart17.png")
        case false:
            imageView.animationImages = spriteBackwards
            imageView.animationDuration = 0.5
            imageView.animationRepeatCount = 1
            imageView.startAnimating()
            imageView.image = UIImage(named: "heart1.png")
        }
        
        // Set the UIImageView instance as the customView of the UIBarButtonItem
        lovePlaceButton.customView = imageView
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(lovePlaceButtonTapped))
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapGesture)
        
        // Apply width and height constraints
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 25), // Adjust the width as per your requirement
            imageView.heightAnchor.constraint(equalToConstant: 25) // Adjust the height as per your requirement
        ])
    }
    
    func updateHeartAtLoad() {
        // Create a UIImageView instance
        let imageView = UIImageView()

        // Set the content mode of the imageView to scale aspect fit
        imageView.contentMode = .scaleAspectFit
        
        // Disable autoresizing mask translation
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        var placeLoved = false
        switch isFSQPlace {
        case true:
            placeLoved = lovedFSQPlaces.contains { lp in
                lp.fsqID == place.fsqID
            }
        case false:
            placeLoved = userLovedPlaces.contains { thisPlace in
                "\(thisPlace.name)\(thisPlace.id)\(thisPlace.fsqID ?? "")" == "\(place.name)\(place.id)\(place.fsqID ?? "")"
            }
        }
        
        switch placeLoved {
        case true:
            imageView.image = UIImage(named: "heart17.png")
        case false:
            imageView.image = UIImage(named: "heart1.png")
        }
        
        // Set the UIImageView instance as the customView of the UIBarButtonItem
        lovePlaceButton.customView = imageView
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(lovePlaceButtonTapped))
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapGesture)
        
        // Apply width and height constraints
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 25), // Adjust the width as per your requirement
            imageView.heightAnchor.constraint(equalToConstant: 25) // Adjust the height as per your requirement
        ])
    }
    
    func getComments() {
        //fetch all comments for the current place & type
        comments = []
        commentVotes = [:]
        commentsRequestTask?.cancel()
        commentsRequestTask = Task {
            if let comments = try? await CommentsRequest(placeID: place.id, type: type).send() {
                self.comments = comments.sorted(by: { lhs, rhs in
                    if lhs.communityScore != rhs.communityScore {
                        return lhs.communityScore > rhs.communityScore
                    } else if let lhsDate = lhs.commentDateDate, let rhsDate = rhs.commentDateDate, lhsDate != rhsDate {
                        return lhsDate > rhsDate
                    } else {
                        return lhs.username < rhs.username
                    }
                })
            }
            if let commentVotes = try? await UserCommentVotesRequest(userID: currentUser.id).send() {
                for commentVote in commentVotes {
                    self.commentVotes[commentVote.commentID] = commentVote.value
                }
            }
            collectionView.reloadData()
            commentsRequestTask = nil
        }
        collectionView.reloadData()
    }
    
    func getFSQComments() {
        //fetch all comments for the current place & type
        comments = []
        commentsRequestTask?.cancel()
        commentsRequestTask = Task {
            if let comments = try? await FSQCommentsRequest(fsqID: place.fsqID, type: type).send() {
                self.comments = comments.sorted(by: { lhs, rhs in
                    if lhs.communityScore != rhs.communityScore {
                        return lhs.communityScore > rhs.communityScore
                    } else if let lhsDate = lhs.commentDateDate, let rhsDate = rhs.commentDateDate, lhsDate != rhsDate {
                        return lhsDate > rhsDate
                    } else {
                        return lhs.username < rhs.username
                    }
                })
            }
            collectionView.reloadData()
            commentsRequestTask = nil
        }
        collectionView.reloadData()
    }
    
    @objc func lovePlaceButtonTapped() {
        switch (isFSQPlace, isGooglePlace) {
        case (true, _):
            loveFSQAction()
        case (_, true):
            loveGooglyAction()
        default:
            lovePlaceAction()
        }
    }
    
    func getPicHeight() -> CGFloat {
        let width = collectionView.bounds.width
        let heightOnWidthRatio = (placePic.size.height) / (placePic.size.width)
        let newHeight = width * heightOnWidthRatio
        
        return newHeight
    }
    
    func getTags() {
        tagsRequestTask = Task {
            if let tags = try? await PlaceTagsRequest(placeID: place.id).send() {
                self.tags = tags.sorted(by: { lhs, rhs in
                    lhs.count > rhs.count
                })
            }
            collectionView.reloadData()
            tagsRequestTask = nil
        }
        collectionView.reloadData()
    }
    
    func loadCatAndNei() {
        neiAndCatTask = Task {
            if let cat = try? await GetPlaceCategoryRequest(category: place.genre, placeTypeID: place.placeTypeID).send() {
                placeCategory = cat[0]
            }
            
            if let nei = try? await GetPlaceNeighborhoodRequest(neighborhood: place.neighborhood, cityID: place.cityID.cityID).send() {
                placeNeighborhood = nei[0]
            }
            neiAndCatTask = nil
        }
    }
    
    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 8
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 7:
            switch segment {
            case 1:
                let role = currentUser.role
                if role != "GuestUser" {
                    return (comments.count + 1)
                } else {
                    return (comments.count)
                }
            default:
                guard placePics.isEmpty == false else {return 0}
                guard isFSQPlace == false && isGooglePlace == false else {return placePics.keys.count}
                return (placePics.keys.count + 1)
            }
        case 6:
            return 2
        case 3:
            return tags.count + 1
        default:
            return 1
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        switch (indexPath.item, indexPath.section) {
        case (0, 0):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlacePic", for: indexPath) as! PlacePicCollectionViewCell
            
            cell.placePic.image = placePic
            /*
            cell.placePic.layer.cornerRadius = 0.0
            cell.placePic.layer.borderWidth = 0.0
            cell.placePic.layer.borderColor = UIColor.clear.cgColor
            cell.placePic.layer.masksToBounds = true*/
            cell.placePic.layer.shadowColor = UIColor.lightGray.cgColor
            cell.placePic.layer.shadowOffset = CGSize(width: 0, height: 1)
            cell.placePic.layer.shadowRadius = 2.0
            cell.placePic.layer.shadowOpacity = 0.5
        
            let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
            doubleTap.numberOfTapsRequired = 2
            
            cell.addGestureRecognizer(doubleTap)
            
            return cell
        case (0, 1):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlaceName", for: indexPath) as! PlaceNameCollectionViewCell
            cell.placeNameLabel.text = place.name
            cell.setupMoreOptionsButton()
            cell.isFSQ = isFSQPlace
            
            cell.delegate = self
            
            return cell
        case (0, 2):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlaceWebsiteAndDirections", for: indexPath) as! PlaceWebsiteAndDirectionsCollectionViewCell
            if place.website == "https://google.com" {
                cell.websiteButton.isEnabled = false
            } else {
                cell.websiteURL = place.website
            }
            
            cell.placeCategoryLabel.text = "\(place.genre)"
            cell.placeNeighborhoodLabel.text = "\(place.neighborhood)"
            
            cell.delegate = self
            return cell
        case (tags.count, 3):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddTag", for: indexPath) as! AddTagCollectionViewCell
            cell.delegate = self
            return cell
        case (_, 3):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Tag", for: indexPath) as! PlaceTagCollectionViewCell
            cell.tagName.text = tags[indexPath.item].tagName
            cell.tagNum.text = "\(tags[indexPath.item].count)"
            switch indexPath.item {
            case 1:
                cell.backgroundColor = BACKGROUND2
            case 2:
                cell.backgroundColor = BACKGROUND3
            case 0:
                cell.backgroundColor = BACKGROUND1
            default: break
            }
            cell.style()
            return cell
        case (0, 4):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlaceDescription", for: indexPath) as! PlaceDescriptionCollectionViewCell
            cell.placeDescription.text = place.descr
            descrHeight = Double(cell.bounds.height)

            return cell
        case (0, 5):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PinPlaceMapView", for: indexPath) as! PinPlaceMapViewCollectionViewCell
                
            // Configure the MapView in the cell
            cell.configureMapView(with: place)
            
            return cell
        case (_, 6):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlaceDetailSegment", for: indexPath) as! PlaceSegmentControllerCollectionViewCell
            cell.delegate = self
            if indexPath.item == 0 {
                cell.iconImg.image = UIImage(systemName: "photo")
                cell.segmentName.text = "Photos (\(placePics.count))"
            } else {
                cell.iconImg.image = UIImage(systemName: "text.badge.plus")
                cell.segmentName.text = "Reviews (\(comments.count))"
            }
            
            cell.selectedPlaceTypeBar.layer.shadowColor = UIColor.gray.cgColor
            cell.selectedPlaceTypeBar.layer.shadowOffset = CGSize(width: 0.0, height: 0.5)
            cell.selectedPlaceTypeBar.layer.shadowOpacity = 0.5
            
            if segment == indexPath.item {
                cell.selectedPlaceTypeBar.backgroundColor = .black
                //cell.placeTypeName.font = UIFont(name: "Apple SD Gothic Neo Bold", size: 18)
            } else {
                cell.selectedPlaceTypeBar.backgroundColor = .white
                //cell.placeTypeName.font = UIFont(name: "Apple SD Gothic Neo Normal", size: 18)
            }
            
            return cell
        default:
            switch segment {
            case 1:
                let role = currentUser.role
                //1st index for Comments segment will be 'AddComment' cell
                if indexPath.row == 0, role != "GuestUser" {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddComment", for: indexPath) as! AddCommentCollectionViewCell
                    return cell
                } else {
                    //remaining cells will display one comment per cell in order by date
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Comment", for: indexPath) as! CommentCollectionViewCell
                    
                    var comment: Comment
                    if role != "GuestUser" {
                        comment = comments[(indexPath.row-1)]
                    } else {
                        comment = comments[(indexPath.row)]
                    }
                    cell.usernameLabel.text = comment.username
                    cell.dateLabel.text = comment.commentDate
                    cell.commentLabel.text = comment.comment
                    
                    cell.scoreLabel.text = String(comment.communityScore)
                    if let voteValue = commentVotes[comment.ID] {
                        switch voteValue {
                        case "up":
                            cell.upVoteButton.tintColor = .systemGreen
                            cell.downVoteButton.tintColor = .systemBlue
                        case "down":
                            cell.downVoteButton.tintColor = .systemRed
                            cell.upVoteButton.tintColor = .systemBlue
                        default:
                            cell.upVoteButton.tintColor = .systemBlue
                            cell.downVoteButton.tintColor = .systemBlue
                        }
                    }
                    
                    cell.commentIndex = indexPath.row-1
                    cell.delegate = self
                    
                    return cell
                }
            default:
                //final index for the Photos segment will display the "AddPhoto" cell
                if indexPath.row < placePics.keys.count {
                    //remaining cells will display one photo per cell
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AdditionalPhoto", for: indexPath) as! AdditionalPhotosCollectionViewCell
                    if let photo = placePics[(indexPath.row+1)] {
                        cell.additionalRestaurantPic.image = photo
                    }
                    return cell
                } else {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddPhoto", for: indexPath)
                    return cell
                }
            }
        }
    }
    
    func generateLayout() -> UICollectionViewCompositionalLayout {
        
        let layout = UICollectionViewCompositionalLayout { [unowned self] (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            
            switch sectionIndex {
            case 0:
                
                let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(picHeight))
                let item = NSCollectionLayoutItem(layoutSize: size)
                
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, repeatingSubitem: item, count: 1)
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0)
        
                return section
            case 1, 2:
                let size = NSCollectionLayoutSize(widthDimension:.fractionalWidth(1), heightDimension: .estimated(33))
                let item = NSCollectionLayoutItem(layoutSize: size)
                
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0)
                
                return section
            case 3:
                let size = NSCollectionLayoutSize(widthDimension: NSCollectionLayoutDimension.estimated(33), heightDimension: NSCollectionLayoutDimension.absolute(35))
                let item = NSCollectionLayoutItem(layoutSize: size)
                item.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10)

                let groupSize = NSCollectionLayoutSize(widthDimension: NSCollectionLayoutDimension.fractionalWidth(1), heightDimension: NSCollectionLayoutDimension.absolute(35))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, repeatingSubitem: item, count: 4)
                group.interItemSpacing = .fixed(10)
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 10, trailing: 20)
                 
                return section
            case 4:
                let size = NSCollectionLayoutSize(widthDimension:.fractionalWidth(1), heightDimension: .estimated(descrHeight))
                let item = NSCollectionLayoutItem(layoutSize: size)
                
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 15, trailing: 0)
                
                return section
            case 5:
                let size = NSCollectionLayoutSize(
                    widthDimension: NSCollectionLayoutDimension.fractionalWidth(1),
                    heightDimension: NSCollectionLayoutDimension.absolute(200)
                )
                let item = NSCollectionLayoutItem(layoutSize: size)
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, repeatingSubitem: item, count: 1)

                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
                section.interGroupSpacing = 10
                 
                return section
                
            case 6:
                let size = NSCollectionLayoutSize(widthDimension:.fractionalWidth(0.5), heightDimension: .absolute(40))
                let item = NSCollectionLayoutItem(layoutSize: size)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(40))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0)
                
                return section
            default:
                switch segment{
                case 1:
                    let size = NSCollectionLayoutSize(
                        widthDimension: NSCollectionLayoutDimension.fractionalWidth(1),
                        heightDimension: NSCollectionLayoutDimension.estimated(40)
                    )
                    let item = NSCollectionLayoutItem(layoutSize: size)
                    let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, repeatingSubitem: item, count: 1)

                    let section = NSCollectionLayoutSection(group: group)
                    section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
                    section.interGroupSpacing = 10
                     
                    return section
                default:
                    let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.45), heightDimension: .fractionalHeight(1.0))
                    let item = NSCollectionLayoutItem(layoutSize: itemSize)
                    
                    item.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 3, bottom: 2, trailing: 3)
                    
                    let groupsize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(130.0))
                    let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupsize, repeatingSubitem: item, count: 2)
                    
                    group.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 3, trailing: 2)
                    
                    let section = NSCollectionLayoutSection(group: group)
                    
                    return section
                }
            }
            
        }
        
        return layout
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //find which segment we're in
        //Comments segment will only allow user to click the first cell 'AddComment'
        //Photos cell will allow user to either scroll through the fetched image OR use an alert controller to allow a new image(s) to be uploaded
        if indexPath.section == 7 {
            switch segment {
            case 1:
                if indexPath.row == 0 {
                    performSegue(withIdentifier: "NewReview", sender: nil)
                }
            default:
                if indexPath.row < placePics.count {
                    selectedPicIndex = indexPath.row
                    performSegue(withIdentifier: "ShowAdditionalPhotos", sender: nil)
                } else {
                    displayImageUploadChoices()
                }
            }
        } else if indexPath.section == 6 {
            if segment == 0 {
                segment = 1
            } else {
                segment = 0
            }
            collectionView.reloadData()
        } else if indexPath.section == 3 {
            print("Hi")
            guard indexPath.item != tags.count else { return }
            print("Hello")
            let tag = tags[indexPath.item]
            selectedTag = tag
            tagSelected = true
            performSegue(withIdentifier: "UnwindFromFiltersToACity", sender: nil)
        } else if indexPath.section == 5 {
            OpenMapDirections.present(in: self, sourceView: self.view, address: place.address, placeName: place.name)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //Prepare for different Segues
        
        
        //if CommentsAndPhotos page we need to pass the type, the place, and the Comments OR the picIndex and photos depending on which segment is selected
        if segue.identifier == "ShowAdditionalPhotos" {
            let additionalPhotoVC = segue.destination as! AdditionalPhotoViewController
            var photos = [UIImage]()
            for i in placePics.keys.sorted() {
                if let photo = placePics[i] {
                    photos.append(photo)
                }
            }
            additionalPhotoVC.photos = photos
            
            additionalPhotoVC.picIndex = selectedPicIndex
            
        } else if segue.identifier == "NewReview" {
            let reviewVC = segue.destination as! AddCommentCollectionViewController
            reviewVC.place = place
            reviewVC.placeSource = placeSource
        } else if let dest = segue.destination as? ACityCollectionViewController {
            guard segue.identifier == "UnwindFromFiltersToACity" else {return}
            if catSelected {
                dest.model.selectedNeighborhood = nil
                dest.model.selectedTags = nil
                dest.model.selectedTagIndexes = Set<Int>()
                dest.model.selectedTagPlaceIDs = nil
                
                dest.filters = [.categories]
                dest.model.selectedCategory = placeCategory
            } else if neiSelected {
                dest.model.selectedCategory = nil
                dest.model.selectedTags = nil
                dest.model.selectedTagIndexes = Set<Int>()
                dest.model.selectedTagPlaceIDs = nil
                
                dest.filters = [.neighborhoods]
                dest.model.selectedNeighborhood = placeNeighborhood
            } else if tagSelected {
                dest.model.selectedCategory = nil
                dest.model.selectedNeighborhood = nil
                
                if let tag = selectedTag {
                    dest.model.selectedTags = [tag]
                    dest.filters = [.tags]
                    dest.model.selectedTagIndexes = Set<Int>()
                    dest.model.selectedTagPlaceIDs = nil
                }
            }
        }
    }
    
    

}

extension PlaceDetailCollectionViewController: PlaceNameCollectionViewCellDelegate {
    func addToItinerary() {
        self.performSegue(withIdentifier: "AddToItinerary", sender: nil)
    }
    func proposeEdit() {
        self.performSegue(withIdentifier: "EditPlace", sender: nil)
    }
}

extension PlaceDetailCollectionViewController: PlaceWebsiteAndDirectionsCollectionViewCellDelegate {
    func presentWebsite(url: URL) {
        let safariViewController = SFSafariViewController(url: url)
        present(safariViewController, animated: true, completion: nil)
    }
    func categoryPressed() {
        catSelected = true
        if placeCategory == nil {
            placeCategory = Genre(ID: 0, name: place.genre, placeTypeID: place.placeTypeID ?? 0, clicked: 1, fsqCategoryCode: 0)
        }
        performSegue(withIdentifier: "UnwindFromFiltersToACity", sender: nil)
    }
    func neighborhoodPressed() {
        neiSelected = true
        if placeNeighborhood == nil {
            placeNeighborhood = Neighborhood(ID: 0, cityID: place.cityID.cityID, name: place.neighborhood, clicked: 1)
        }
        performSegue(withIdentifier: "UnwindFromFiltersToACity", sender: nil)
    }
}

extension PlaceDetailCollectionViewController: PlaceSegmentControllerCollectionViewCellDelegate {
    func segmentChanged(segment: Int) {
        self.segment = segment
        let descrCell = self.collectionView.cellForItem(at: IndexPath(item: 0, section: 3))
        descrHeight = Double(descrCell?.bounds.height ?? 0.0)
        collectionView.reloadSections(IndexSet(integer: 5))
        collectionView.setCollectionViewLayout(generateLayout(), animated: true)
    }
}

extension PlaceDetailCollectionViewController: CommentCollectionViewCellDelegate {
    func upVote(commentIndex: Int) {
        let type = placeSource.rawValue
        let role = currentUser.role
        if  role != "GuestUser" {
            let userID = currentUser.id
            let commentID = comments[commentIndex].ID
            let commentUpvote = CommentUpvote(userID: userID, commentID: commentID, type: type, value: "")
            Task {
                if let result = try? await commentUpvoteRequest(commentUpvote: commentUpvote).send() {
                    if result["status"] == "Success" {
                        switch result["message"] {
                        case "up":
                            commentVotes[commentID] = "up"
                        case "neutral":
                            commentVotes[commentID] = "neutral"
                        default: break
                        }
                        comments[commentIndex].communityScore += 1
                        collectionView.reloadData()
                    } else {
                        print(result)
                    }
                }
            }
        }
    }
    
    func downVote(commentIndex: Int) {
        let type = placeSource.rawValue
        let role = currentUser.role
        if role != "GuestUser" {
            let userID = currentUser.id
            let type = type
            let commentID = comments[commentIndex].ID
            let commentUpvote = CommentUpvote(userID: userID, commentID: commentID, type: type, value: "")
            Task {
                if let result = try? await commentDownvoteRequest(commentUpvote: commentUpvote).send() {
                    if result["status"] == "Success" {
                        switch result["message"] {
                        case "down":
                            commentVotes[commentID] = "down"
                        case "neutral":
                            commentVotes[commentID] = "neutral"
                        default: break
                        }
                        comments[commentIndex].communityScore -= 1
                        collectionView.reloadData()
                    } else {
                        print(result)
                    }
                }
            }
        }
    }
}

extension PlaceDetailCollectionViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate, PHPickerViewControllerDelegate {
    
    func displayImageUploadChoices() {
        //allow user to either upload pictures from their photo library or take a new photo with their camera
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        let alertController = UIAlertController(title: "Choose Image", message: nil, preferredStyle: .actionSheet)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let cameraAction = UIAlertAction(title: "Camera", style: .default, handler: { action in
                imagePicker.sourceType = .camera
                self.present(imagePicker, animated:true, completion: nil)
            })
            alertController.addAction(cameraAction)
        }
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let photoLibraryAction = UIAlertAction(title: "Camera Roll", style: .default, handler: { action in
                self.selectPics()
            })
            alertController.addAction(photoLibraryAction)
        }
        
        alertController.popoverPresentationController?.sourceView = self.view
        
        present(alertController, animated: true, completion: nil)
    }
    
    func selectPics() {
        //PHPicker function to allow user to select a number of photos to add to the current place
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 5
        config.filter = .images
        config.selection = .ordered
        
        let picVC = PHPickerViewController(configuration: config)
        
        picVC.delegate = self
        
        present(picVC, animated: true)
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        //PHPIcker delegate method called once the user finishes selecting the images
        
        picker.dismiss(animated: true, completion:  nil)
        
        let group = DispatchGroup()
        for result in results {
            group.enter()
            result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                defer {
                    group.leave()
                }
                guard let image = object as? UIImage, error == nil else {return}
                self.uploadedPics.append(image)
            }
        }
        let coverPhotoFileName = "\(place.name)\(place.neighborhood)"
        group.notify(queue: .main) {
            self.uploadPics(restaurantID: String(self.place.id), path: coverPhotoFileName)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        //used for the Camera option - triggered once the user takes photo and clicks save
        
        guard let selectedImage = info[.originalImage] as? UIImage else { return }
        uploadedPics.append(selectedImage)
        
        let coverPhotoFileName = "\(place.name)\(place.neighborhood)"
        
        uploadPics(restaurantID: String(place.id), path: coverPhotoFileName)
        
        dismiss(animated: true)
    }
    
    func uploadPics(restaurantID: String, path: String) {
        //API Call to upload selected images
        
        let group = DispatchGroup()
        
        var n = placePics.keys.count + 1
        
        for pic in uploadedPics {
            var additionalPhoto: AdditionalPhoto?
            var fileName: String = ""
            var imageURL: String = ""
            let params = ["name": "AustinMcL","id": "12345","type":"restaurants"]
            
            fileName = "\(path)\(n).jpeg"
            imageURL = "/Concierge/photos/restaurants/\(path)\(n).jpeg"
            additionalPhoto = AdditionalPhoto(placeID: Int(restaurantID) ?? 0, path: imageURL, photoIndex: n)
            
            group.enter()
            let imageUpload = ImageUpload(image: pic, imageURL: imageURL, key: "restaurantPic", params: params, fileName: fileName)!
            newImageRequestTask = Task {
                let newImage = try? await NewImageRequest(imageUpload: imageUpload).send()
                newImageRequestTask = nil
                group.leave()
            }
            group.enter()
            if let additionalPhoto = additionalPhoto {
                additionalImageRequestTask = Task {
                    let addPhotoRequest = try? await AdditionalPhotoRequest(additionalPhoto: additionalPhoto).send()
                    print(addPhotoRequest)
                    group.leave()
                    additionalImageRequestTask = nil
                }
            }
            n += 1
        }
        group.notify(queue: .main) {
            self.loadImages()
        }
    }
    
}

extension PlaceDetailCollectionViewController: LovePlaceDelegate {
    func updatePage() {
        updateHeartButton()
    }
}

extension PlaceDetailCollectionViewController: PicGetterDelegate {
    func updatePic(image: UIImage) {}
    
    func updatePics(images: [UIImage]) {
        var i = 1
        for pic in images {
            placePics[i] = pic
            i += 1
        }
        DispatchQueue.main.async {
            self.picHeight = self.getPicHeight()
            self.collectionView.reloadData()
        }
    }
    
    func updatePics(image: UIImage, i: Int?) {
        DispatchQueue.main.async {
            guard let i = i else {return}
            self.placePics[i+1] = image
            self.collectionView.reloadSections(IndexSet(integer: 7))
            if i == 0 {
                self.picHeight = self.getPicHeight()
                self.collectionView.reloadSections(IndexSet(integer: 0))
            }
        }
    }
    
    func returnPic(image: UIImage, i: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            sectionPlacePics[i] = image
        }
    }
}

extension PlaceDetailCollectionViewController: AddTagCollectionViewCellDelegate {
    func addTag() {
        presentTagInputPopup()
    }
    
    
    func presentTagInputPopup() {
        // Create the alert controller
        let alertController = UIAlertController(title: "Add Tag", message: "Enter a tag for this place.", preferredStyle: .alert)
        
        // Add a text field to the alert
        alertController.addTextField { textField in
            textField.placeholder = "Enter tag here"
            textField.autocapitalizationType = .words
        }
        
        // Define the Submit action
        let submitAction = UIAlertAction(title: "Submit", style: .default) { [weak self, weak alertController] _ in
            guard let self = self,
                  let textField = alertController?.textFields?.first,
                  let tagText = textField.text, !tagText.trimmingCharacters(in: .whitespaces).isEmpty else {
                // Optionally, show an error if the text is empty
                self?.showAlert(title: "Invalid Input", message: "Please enter a valid tag.")
                return
            }
            
            // Trigger the external action with the entered tag
            self.handleTagSubmission(tag: tagText)
        }
        
        // Define the Cancel action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        // Add actions to the alert controller
        alertController.addAction(submitAction)
        alertController.addAction(cancelAction)
        
        // Present the alert controller
        present(alertController, animated: true, completion: nil)
    }
    
    // Helper method to show alerts
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func handleTagSubmission(tag: String) {
        let addTag = AddTag(tagID: 0, tagName: tag, userID: currentUser.id, placeID: place.id, cityID: place.cityID.cityID)
        tagFunctions.addTag(addTag: addTag)
    }
}
