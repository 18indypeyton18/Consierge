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
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
                section.interGroupSpacing = 10
                
                return section
            case 5:
                let size = NSCollectionLayoutSize(widthDimension: NSCollectionLayoutDimension.fractionalWidth(1), heightDimension: NSCollectionLayoutDimension.estimated(200))
                let item = NSCollectionLayoutItem(layoutSize: size)
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
                section.interGroupSpacing = 10
                
                return section
            default:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(40.0))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
                
                return section
            }
        }
        //simple collection view layout - full width and 140 height + content insets
        return layout
    }
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        check4Changes()
        donePressed()
    }
    func donePressed() {
        newPlaceRequestTask = Task {
            //try sending the NewRestaurant and save returned resultValue
            let resultValue = try? await NewPlaceRequest(place: place).send()
            
            DispatchQueue.main.async {
                var myAlert = UIAlertController(title: resultValue?["status"], message: resultValue?["message"], preferredStyle: UIAlertController.Style.alert)
                
                //attempt to capture the restaurant's ID from the Task
                if let placeID = resultValue?["ID"] {
                    //if Successful run the uploadPics method to save each image and add AdditionalPhoto entries
                    let coverPhotoFileName = "\(placeID)"
                    self.uploadPics(placeID: placeID, path: coverPhotoFileName)
                    self.moderatePlace(place: self.place, placeId: Int(placeID) ?? 0)
                    placeRecentlyAdded = (self.place.placeTypeID ?? 0) * self.place.cityID.cityID
                    
                    let okAction = UIAlertAction(title: "Close", style: UIAlertAction.Style.default) { action in
                        //self.uploadIndicator.stopAnimating()
                        self.performSegue(withIdentifier: "UnwindToStart", sender: nil)
                    }
                    myAlert.addAction(okAction)
                    self.present(myAlert, animated: true, completion: nil)
                } else if resultValue?["status"] == "Error" {
                    //Display the failed result to the user and stay on the page
                    let okAction = UIAlertAction(title: "Close", style: UIAlertAction.Style.default)
                    
                    myAlert.addAction(okAction)
                    self.present(myAlert, animated: true, completion: nil)
                    // ERROR - DONT UNWIND
                } else {
                    //Display the failed result to the user and stay on the page
                    myAlert = UIAlertController(title: "Error", message: "undefined error", preferredStyle: UIAlertController.Style.alert)
                    let okAction = UIAlertAction(title: "Close", style: UIAlertAction.Style.default)
                    
                    myAlert.addAction(okAction)
                    self.present(myAlert, animated: true, completion: nil)
                    // ERROR - DONT UNWIND
                }
            }
            newPlaceRequestTask = nil
        }
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
            let params = ["name": "AustinMcL","id": "12345","type":"places"]
            
            //is this the Cover Photo or an Additional Photo
            if n > 1 {
                //add n to the path name and add jpeg extension for the fileName (used to upload image)
                fileName = "\(path)_\(n).jpeg"
                //setup rest of path for the imageURL (used to reference the image in the DB)
                imageURL = "/places/\(path)_\(n).jpeg"
                //create the AdditionalPhoto object
                
                additionalPhoto = AdditionalPhoto(placeID: Int(placeID) ?? 0, path: imageURL, photoIndex: n, status: "Approved")
            } else {
                //otherwise keep the og path and add jpeg extension (used to upload image)
                fileName = "\(path).jpeg"
                //setup rest of path for the imageURL (used to reference the image in the DB)
                imageURL = "/places/\(path).jpeg"
                
                additionalPhoto = AdditionalPhoto(placeID: Int(placeID) ?? 0, path: imageURL, photoIndex: n, status: "Approved")
            }
            
            //create ImageUpload object with the image, determined path, params, and fileName
            let imageUpload = ImageUpload(image: pic, imageURL: imageURL, key: "restaurantPic", params: params, fileName: fileName)
            
            if let imageUpload = imageUpload {
                newImageRequestTask = Task {
                    let newImage = try? await NewImageRequest(imageUpload: imageUpload).send()

                    if let _ = newImage {
                    } else {
                        // print("error with image upload request")
                    }
                    newImageRequestTask = nil
                }
            }
            
            //if n>1 and an additionalPhoto object was created
            //hit the AdditionalPhoto API
            if let additionalPhoto = additionalPhoto {
                additionalImageRequestTask = Task {
                    let addPhotoRequest = try? await AdditionalPhotoRequest(additionalPhoto: additionalPhoto).send()
                    additionalImageRequestTask = nil
                    if let _ = addPhotoRequest {
                    } else {
                        // print("error with AdditionalPhoto request")
                    }
                }
            }
            n += 1
        }
    }
    
    func check4Changes() {
        if let cell = collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? EditPlaceAttributeCollectionViewCell, let name = cell.attributeTextField.text, name != place.name {
            place.name = name
        }
        if let cell = collectionView.cellForItem(at: IndexPath(item: 0, section: 2)) as? EditPlaceAttributeCollectionViewCell, let genre = cell.attributeTextField.text, genre != place.genre {
            place.genre = genre
        }
        if let cell = collectionView.cellForItem(at: IndexPath(item: 0, section: 3)) as? EditPlaceAttributeCollectionViewCell, let neighborhood = cell.attributeTextField.text, neighborhood != place.neighborhood {
            place.neighborhood = neighborhood
        }
        if let cell = collectionView.cellForItem(at: IndexPath(item: 0, section: 5)) as? EditPlaceDescrCollectionViewCell, let descr = cell.descrTextView.text, descr != place.descr {
            place.descr = descr
        }
    }
}



extension NewPlaceFinishCollectionViewController: UploadedPhotoCellDelegate {
    func removePic(idx: Int) {
        uploadedPics.remove(at: idx)
        collectionView.reloadSections([1])
    }
}

extension NewPlaceFinishCollectionViewController {
    
    func moderatePlace(place: ConciergePlace, placeId: Int) {
        
        let systemPrompt = """
You are moderating user submitted content. The acceptable moderationResult values are "Approved", "Review", "Rejected".
        Provide the response in a JSON format. Don't provide any supporting text, only the JSON response. The response should start with the character "{" and end with the character "}". See the required format below.
--------------------------------------------------------------------------------------------------
        {"moderationResult": "Review"}
--------------------------------------------------------------------------------------------------

Context & Tone: Harmless jokes, puns or non-offensive slang should be **approved**, even if mildly cheeky.
"""
        
        var gptPrompt = """
You are a content moderation assistant. A user has submitted a new Place. See the JSON of the place obejct below.

'
"""
        gptPrompt += place.description
        
        gptPrompt += """
'

Please evaluate every attribute of this Place object and assess if it violates any of the following rules:

1. **Profanity & Obscenity:** No swear words, crude language, or sexual explicitness.  
2. **Hate Speech & Slurs:** No insults or slurs targeting protected groups (race, religion, gender, sexuality, etc.).  
3. **Harassment & Threats:** No threats, intimidation, or personal attacks.  
4. **Violence & Self-harm:** No graphic violence or encouragement of self-harm.  
5. **Illegal Activity:** No admission or promotion of crimes.  

**Output only one** of these values (no extra text):
- **Approved**  → doesn't explicitly violates any of the above rules. 
- **Review**    → content potentially violates one of the above rules. These rules are serious infringements, so the majority of submissions will not violate these rules, be sure it potentially violates one of the above rules before marking it Review.
- **Rejected**  → clearly violates one or more rules. These rules are serious infringements, so the majority of submissions will not violate these rules, be sure it violates one of the above rules before marking it Rejected.

Respond with exactly:
        {"moderationResult": "Approved"/"Review"/"Rejected"}
"""
        
        let request = ChatGPTCompletionRequest(model: "gpt-4o", systemPrompt: systemPrompt, prompts: [gptPrompt], maxTokens: 500, temperature: 0.7, username: "system")
        
        Task {
            let response = try await request.send()
            if let text = response.choices.first?.message.content {
                self.parseGPTModerationResponse(text: text, placeId: placeId)
            } else {
                // print("GPT Moderation for AskAI Error")
            }
        }
    }
    
    func parseGPTModerationResponse(text: String, placeId: Int) {
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
                let placeStatus = PlaceStatus(placeId: placeId, status: status)
                
                let _ = try? await UpdatePlaceStatus(placeStatus: placeStatus).send()
            }
        } catch {
            // print("GPTModerationResponse decode failed")
        }
    }
}
