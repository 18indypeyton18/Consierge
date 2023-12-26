//
//  UserAccountCollectionViewController.swift
//  Consierge
//
//  Created by Austin McLaughlin on 12/28/23.
//

import UIKit
import SafariServices

var profPicture: UIImage?

class UserAccountCollectionViewController: UICollectionViewController, UINavigationControllerDelegate {
    
    var selectedSegmentIndex = 0
    var profPicURL: String?
    
    var imageRequestTask: Task<Void,Never>? = nil
    var fsqPlacesRequestTask: Task<Void, Never>? = nil
    deinit {
        imageRequestTask?.cancel()
        fsqPlacesRequestTask?.cancel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupPage()
        collectionView.collectionViewLayout = createLayout()
        
    }
    
    func setupPage() {
        if profPicture == nil {
            print("NIL")
            updateProfPic()
        } else {
            let indexSet = IndexSet(integer: 0)
            collectionView.reloadSections(indexSet)
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 3
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        switch section {
        case 0:
            return 1
        case 1:
            return 2
        default:
            return userLovedPlaces.count + userFSQLovedPlaces.count
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UserAccountHeader", for: indexPath) as! UserAccountHeaderCollectionViewCell
            
            cell.userNameLabel.text = "Hi, \(currentUser.firstName)!"
            
            //circular profile pic
            cell.profPicImageView.layer.borderWidth = 1.0
            cell.profPicImageView.layer.masksToBounds = false
            cell.profPicImageView.layer.borderColor = UIColor.white.cgColor
            cell.profPicImageView.layer.cornerRadius = cell.profPicImageView.frame.size.width / 2
            cell.profPicImageView.clipsToBounds = true
            
            if let profPicture = profPicture {
                cell.profPicImageView.image = profPicture
            }
            
            cell.delegate = self
        
            return cell
        case 1:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UserAccountSegment", for: indexPath) as! UserAccountSegmentControllerCollectionViewCell
            
            if indexPath.item != 0 {
                cell.segmentName.text = "Itineraries"
                cell.segmentIcon.image = UIImage(systemName: "list.clipboard")
            } else {
                cell.segmentName.text = "Loved Places"
                cell.segmentIcon.image = UIImage(systemName: "heart")
            }
            
            cell.segmentSelectedBar.layer.shadowColor = UIColor.gray.cgColor
            cell.segmentSelectedBar.layer.shadowOffset = CGSize(width: 0.0, height: 0.5)
            cell.segmentSelectedBar.layer.shadowOpacity = 0.5
            
            if indexPath.item == selectedSegmentIndex  {
                cell.segmentSelectedBar.backgroundColor = .black
                //cell.placeTypeName.font = UIFont(name: "Apple SD Gothic Neo Bold", size: 18)
            } else {
                cell.segmentSelectedBar.backgroundColor = .white
                //cell.placeTypeName.font = UIFont(name: "Apple SD Gothic Neo Normal", size: 18)
            }
            
            return cell
        default:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UserAccountLovedPlace", for: indexPath) as! UserAccountLovedPlaceCollectionViewCell
            
            //Place object stored in each instance of ViewModel.Item and can be used to configure the cell
            var place: Place?
            if indexPath.item < userLovedPlaces.count {
                place = userLovedPlaces[indexPath.item]
            } else {
                place = userFSQLovedPlaces[indexPath.item - userLovedPlaces.count]
            }
            guard let place = place else { return cell }
            
            cell.place = place
            
            //fetch image with cells fetchImage function
            //activity indicator stopped once the image is returned
            cell.imageRequestTask?.cancel()
            cell.imageRequestTask = nil
            
            cell.fetchImage(imageURL: place.imageURL)
            
            cell.placeNameLabel.text = place.name
            
            switch place.self {
            case is FSQPlace:
                break
            default:
                cell.dateLovedLabel.text = getLovedPlaceTimestamp(placeID: place.id, placeSource: .concierge)
            }
            
            cell.delegate = self
            
            //return cell for each item
            return cell
        }
    }
    
    func createLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            switch sectionIndex {
            case 0:
                let size = NSCollectionLayoutSize(widthDimension:.fractionalWidth(1), heightDimension: .absolute(125))
                let item = NSCollectionLayoutItem(layoutSize: size)
                
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 5, trailing: 0)
                
                return section
            case 1:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .absolute(40))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .absolute(40))
                
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0)
                section.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
                
                return section
            default:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(70))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 3, leading: 5, bottom: 2, trailing: 5)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(70))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 7, trailing: 0)
                
                return section
            }
        }
        return layout
    }
    
    @IBSegueAction func lovedPlaceSelected(_ coder: NSCoder, sender: Any?) -> UICollectionViewController? {
        guard let cell = sender as? UserAccountLovedPlaceCollectionViewCell, let place = cell.place, let img = cell.placePic.image, let indexPath = collectionView.indexPath(for: cell) else {return nil}
        return placeSelected(place: place, img: img, coder: coder)
    }
    
    func placeSelected(place: Place, img: UIImage, coder: NSCoder) -> UICollectionViewController? {
        //return DetailVC
        return PlaceDetailCollectionViewController(coder: coder, place: place, sectionsPlaces: userLovedPlaces, placePic: img, placeTypeID: 0)
    }
}

extension UserAccountCollectionViewController: UserAccountHeaderCellDelegate, UIImagePickerControllerDelegate {
    func updateProfPicClicked() {
        print("updateProfPicClicked")
        //Display an Alert Controller at the bottom of the screen allowing the user to either select an image or use the camera to take a new image
        
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
                imagePicker.sourceType = .photoLibrary
                self.present(imagePicker, animated:true, completion: nil)
            })
            alertController.addAction(photoLibraryAction)
        }
        
        alertController.popoverPresentationController?.sourceView = collectionView
        
        present(alertController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        //Once the user has selected an image or takena  new iamge call the uploadPic(image) func and update the profPic imageView
        guard let selectedImage = info[.originalImage] as? UIImage else {return}
        uploadPic(pic: selectedImage)
        profPicture = selectedImage

        dismiss(animated: true, completion: nil)
    }
    
    func uploadPic(pic: UIImage) {
        print("uploadPic")
        //Triggered after a profile pic is uploaded - used to upload the image and set the correct path on the User Record in the DB
        
        let userID = currentUser.id
        let fileName = "\(userID).jpeg"
        
        let imageURL = "/Concierge/photos/users/\(fileName)"
        
        let params = ["name": "AustinMcL","id": "12345","type":"users"]
        
        
        let imageUpload = ImageUpload(image: pic, imageURL: imageURL, key: "restaurantPic", params: params, fileName: fileName)!
        let userProfPic = ProfilePic(imageURL: imageURL, userID: userID)
        print("userProfPic!!!", userProfPic)
        Task {
            try? await NewImageRequest(imageUpload: imageUpload).send()
        }
        Task {
            let result = try? await UpdateUserProfPicRequest(profilePic: userProfPic).send()
            if let _ = result {
                UserDefaults.standard.set(imageURL, forKey: "profPicURL")
            } else {
                print("error uploading User Profile Pic")
            }
        }
    }
    
    func updateProfPic() {
        //method to fetch the user's profile pic while the view loads and display it in the circular profPic image view
        
        if let profPicLink = currentUser.profPicImageURL {
            profPicURL = profPicLink
        }
        
        if let profPicURL = profPicURL {
            print("url exists", profPicURL)
            imageRequestTask = Task {
                if let image = try? await ImageRequest(path: profPicURL).send() {
                    print("image got")
                    DispatchQueue.main.async {
                        profPicture = image
                        let indexSet = IndexSet(integer: 0)
                        self.collectionView.reloadSections(indexSet)
                    }
                }
                self.imageRequestTask = nil
            }
        }
    }
}

extension UserAccountCollectionViewController: UserAccountLovedPlaceCollectionViewCellDelegate {
    func addToItinerary(_ place: any Place, isFSQ: Bool) {
    }
    
    func addComment(_ placeID: Int) {
    }
    
    func seePhotos(_ placeID: Int) {
    }
    
    func presentWebsite(url: URL) {
        let safariViewController = SFSafariViewController(url: url)
        present(safariViewController, animated: true, completion: nil)
    }
    
    func presentDirections(address: String, placeName: String) {
        OpenMapDirections.present(in: self, sourceView: self.view, address: address, placeName: placeName)
    }
    
    func placeLoved(place: any Place) {
    }
}

extension UserAccountCollectionViewController {
    func getLovedPlaceTimestamp(placeID: Int, placeSource: PlaceSource) -> String {
        if placeSource == .concierge {
            let lovePlace = lovedPlaceDict["\(placeID)"]
            let dateString = lovePlace?.lovedDate
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            dateFormatter.timeZone = TimeZone(abbreviation: "UTC")

            if let dateString = dateString, let date = dateFormatter.date(from: dateString) {
                return timeAgo(from: date)
            }
            else {
                return ""
            }
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
