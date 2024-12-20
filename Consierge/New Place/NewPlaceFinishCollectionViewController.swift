//
//  NewPlaceFinishCollectionViewController.swift
//  Consierge
//
//  Created by Austin McLaughlin on 12/17/24.
//

import UIKit

private let reuseIdentifier = "Cell"

class NewPlaceFinishCollectionViewController: UICollectionViewController {
    
    var uploadedPics = [UIImage]()
    
    var place: ConciergePlace
    
    var newPlaceRequestTask: Task<Void,Never>? = nil
    var newImageRequestTask: Task<Void,Never>? = nil
    var additionalImageRequestTask: Task<Void,Never>? = nil
    
    deinit {
        newPlaceRequestTask?.cancel()
        newImageRequestTask?.cancel()
        additionalImageRequestTask?.cancel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.collectionViewLayout = createLayout()
        navigationItem.title = place.name
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    init?(coder: NSCoder, place: ConciergePlace, uploadedPics: [UIImage]) {
        //init with required Place and optional section of Places
        self.place = place
        self.uploadedPics = uploadedPics
        super.init(coder: coder)
    }
    
    
    // MARK: UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 6
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        switch section {
        case 1:
            return uploadedPics.count
        default:
            return 1
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlaceAttribute", for: indexPath) as! EditPlaceAttributeCollectionViewCell
            cell.attributeTextField.placeholder = "Place Name"
            cell.attributeTextField.text = place.name
            return cell
        case 2:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlaceAttribute", for: indexPath) as! EditPlaceAttributeCollectionViewCell
            cell.attributeTextField.placeholder = "Category"
            cell.attributeTextField.text = place.genre
            return cell
        case 3:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlaceAttribute", for: indexPath) as! EditPlaceAttributeCollectionViewCell
            cell.attributeTextField.placeholder = "Neighborhood"
            cell.attributeTextField.text = place.neighborhood
            return cell
        case 4:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddressSuggestion", for: indexPath) as! AddressSuggestionCollectionViewCell
            cell.addressLabel.text = place.address
            return cell
        case 5:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlaceDescription", for: indexPath) as! EditPlaceDescrCollectionViewCell
            cell.descrTextView.text =  place.descr
            return cell
        default:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UploadedPic", for: indexPath) as! UploadedPicCollectionViewCell
            cell.uploadedPicImg.image = uploadedPics[indexPath.item]
            cell.idx = indexPath.item
            cell.styleCell()
            cell.delegate = self
            
            return cell
        }
    }
    
    func createLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout {  (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            
            switch sectionIndex {
            case 1:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.50), heightDimension: .fractionalHeight(1))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(140))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
                section.orthogonalScrollingBehavior = .continuous
                
                return section
            case 4:
                let size = NSCollectionLayoutSize(widthDimension: NSCollectionLayoutDimension.fractionalWidth(1), heightDimension: NSCollectionLayoutDimension.estimated(33))
                let item = NSCollectionLayoutItem(layoutSize: size)
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitem: item, count: 1)
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
                section.interGroupSpacing = 10
                
                return section
            case 5:
                let size = NSCollectionLayoutSize(widthDimension: NSCollectionLayoutDimension.fractionalWidth(1), heightDimension: NSCollectionLayoutDimension.estimated(200))
                let item = NSCollectionLayoutItem(layoutSize: size)
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitem: item, count: 1)
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
                section.interGroupSpacing = 10
                
                return section
            default:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(40.0))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
                
                return section
            }
        }
        //simple collection view layout - full width and 140 height + content insets
        return layout
    }
    
    
    @IBAction func donePressed(_ sender: Any) {
        // upload Place
        
        //restaurant
        //create the string to be used for the image uploads. CoverPhoto will contain the Name+Neighborhood name. rest will have the name+neighborhood+n name.
        let coverPhotoFileName = "\(place.name)\(place.neighborhood)"
        let coverPhotoFileNameWExtension = "\(coverPhotoFileName).jpeg"
        let coverPhotoImageURL = "/Concierge/photos/restaurants/\(coverPhotoFileNameWExtension)"
        
        
        //create the new Task for the API request
        newPlaceRequestTask = Task {
            print(place)
            //try sending the NewRestaurant and save returned resultValue
            let resultValue = try? await NewPlaceRequest(place: place).send()
            
            DispatchQueue.main.async {
                var myAlert = UIAlertController(title: resultValue?["status"], message: resultValue?["message"], preferredStyle: UIAlertController.Style.alert)
                
                //attempt to capture the restaurant's ID from the Task
                if let placeID = resultValue?["ID"] {
                    //if Successful run the uploadPics method to save each image and add AdditionalPhoto entries
                    self.uploadPics(placeID: placeID, path: coverPhotoFileName)
                    
                    //Display the result to the user
                    if resultValue?["status"] == "Success" {
                        let okAction = UIAlertAction(title: "Close", style: UIAlertAction.Style.default) { action in
                            //self.uploadIndicator.stopAnimating()
                            self.navigationController?.popToRootViewController(animated: true)
                        }
                        myAlert.addAction(okAction)
                        self.present(myAlert, animated: true, completion: nil)
                    }
                } else if resultValue?["status"] == "Error" {
                    //Display the failed result to the user and stay on the page
                    let okAction = UIAlertAction(title: "Close", style: UIAlertAction.Style.default)
                    
                    myAlert.addAction(okAction)
                    self.present(myAlert, animated: true, completion: nil)
                } else {
                    //Display the failed result to the user and stay on the page
                    myAlert = UIAlertController(title: "Error", message: "undefined error", preferredStyle: UIAlertController.Style.alert)
                    let okAction = UIAlertAction(title: "Close", style: UIAlertAction.Style.default)
                    
                    myAlert.addAction(okAction)
                    self.present(myAlert, animated: true, completion: nil)
                }
            }
            newPlaceRequestTask = nil
        }
        
        // upload AdditionalImage entries
        
        // upload Images
    }
    
    func uploadPics(placeID: String, path: String) {
        //triggered after a successful newPlace API call
        
        //setup n to use for additional photos Path & index
        var n = 1
        
        //for each pic in UploadedPics
        for pic in uploadedPics {
            //initiate AdditionalPhoto object for use in the AdditionalPhoto request
            var additionalPhoto: AdditionalPhoto?
            var fileName: String = ""
            var imageURL: String = ""
            let params = ["name": "AustinMcL","id": "12345","type":"restaurants"]
            
            //is this the Cover Photo or an Additional Photo
            if n > 1 {
                //add n to the path name and add jpeg extension for the fileName (used to upload image)
                fileName = "\(path)\(n).jpeg"
                //setup rest of path for the imageURL (used to reference the image in the DB)
                imageURL = "/Concierge/photos/restaurants/\(path)\(n).jpeg"
                //create the AdditionalPhoto object
                
                additionalPhoto = AdditionalPhoto(placeID: Int(placeID) ?? 0, path: imageURL, photoIndex: n, status: "Approved")
            }
            else {
                //otherwise keep the og path and add jpeg extension (used to upload image)
                fileName = "\(path).jpeg"
                //setup rest of path for the imageURL (used to reference the image in the DB)
                imageURL = "/Concierge/photos/restaurants/\(path).jpeg"
            }
            
            //create ImageUpload object with the image, determined path, params, and fileName
            let imageUpload = ImageUpload(image: pic, imageURL: imageURL, key: "restaurantPic", params: params, fileName: fileName)!
            print(imageUpload)
            newImageRequestTask = Task {
                let newImage = try? await NewImageRequest(imageUpload: imageUpload).send()
                if let newImage = newImage {
                    print(newImage)
                } else {
                    print("error with image upload request")
                }
                newImageRequestTask = nil
            }
            
            //if n>1 and an additionalPhoto object was created
            //hit the AdditionalPhoto API
            if let additionalPhoto = additionalPhoto {
                additionalImageRequestTask = Task {
                    let addPhotoRequest = try? await AdditionalPhotoRequest(additionalPhoto: additionalPhoto).send()
                    additionalImageRequestTask = nil
                    if let addPhotoRequest = addPhotoRequest {
                        print(addPhotoRequest)
                    } else {
                        print("error with AdditionalPhoto request")
                    }
                }
            }
            n += 1
        }
    }
}



extension NewPlaceFinishCollectionViewController: UploadedPhotoCellDelegate {
    func removePic(idx: Int) {
        uploadedPics.remove(at: idx)
        collectionView.reloadSections([1])
    }
}
