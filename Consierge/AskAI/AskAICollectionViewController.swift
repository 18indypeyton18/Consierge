
import UIKit
import CoreLocation
import SafariServices

class AskAICollectionViewController: UICollectionViewController {
    
    typealias DataSourceType = UICollectionViewDiffableDataSource<ViewModel.Section, ViewModel.Item>
    
    enum ViewModel {
        //First 3 cases are header elements: header and segment won't change; viewTop is updated based on the chosen segment
        //Various sections after that setup to contain Place collectionViewCells seperated by Place neighborhood and Place genre
        enum Section: Hashable {
            case gptPrompts
            case gptGooglePlace
            case gptNotFoundPlace
            case gptLoading
            case askAIInput
            case gptClear
        }
        enum Item: Hashable {
            case gptPrompt(prompt: String)
            case gptGooglePlace(place: Place)
            case gptNotFoundPlace(place: GPTPlace)
            case gptLoading(gptPlaces: Int, googlePlaces: Int)
            case askAIInput
            case gptClear
            
            func hash(into hasher: inout Hasher) {
                switch self {
                case .gptPrompt(let prompt):
                    hasher.combine(prompt)
                case .gptGooglePlace(let place):
                    hasher.combine("\(place.name)\(place.id)\(place.fsqID ?? "")")
                case .gptNotFoundPlace(let place):
                    hasher.combine("\(place.name)\(place.address)")
                case .gptLoading(let gptPlaces, let googlePlaces):
                    hasher.combine("GPTLoading\(gptPlaces)\(googlePlaces)")
                case .askAIInput:
                    hasher.combine("askAIInput")
                case .gptClear:
                    hasher.combine("GPTClear")
                }
            }
            static func == (lhs: AskAICollectionViewController.ViewModel.Item, rhs: AskAICollectionViewController.ViewModel.Item) -> Bool {
                switch (lhs, rhs){
                case (.gptGooglePlace(let lhs), .gptGooglePlace(let rhs)):
                    return "\(lhs.name)\(lhs.id)" == "\(rhs.name)\(rhs.id)"
                default:
                    return false
                }
            }
        }
    }
    
    struct Model {
        var sections: [ViewModel.Section] = []
        var model: [ViewModel.Section:[ViewModel.Item]] = [:]
        var sectionRanks: [ViewModel.Section:Int] = [:]
        
        var locValue: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        var locDenied = false
        var locCounter = 0
        let locationManager = CLLocationManager()
        
        var cityCenter: CLLocationCoordinate2D?
    }
    struct GPTModel {
        enum AskAIMode {
            case suggestingPrompts
            case loadingPlaces
            case displayingPlaces
        }
        var askAIMode: AskAIMode = .suggestingPrompts
        var suggestedPrompts = [String]()
        
        var lastestUserPrompt: String?
        
        var gptPlaces = [GPTPlace]()
        var gptGooglePlaces = [GooglePlace]()
        var gptNotFoundPlaces = [GPTPlace]()
        
        let colors: [UIColor] = [
            UIColor(red: 1.0, green: 0.9, blue: 0.9, alpha: 1.0), // light red
            UIColor(red: 0.9, green: 1.0, blue: 0.9, alpha: 1.0), // light green
            UIColor(red: 0.9, green: 0.9, blue: 1.0, alpha: 1.0), // light blue
            UIColor(red: 1.0, green: 1.0, blue: 0.9, alpha: 1.0), // light yellow
            UIColor(red: 1.0, green: 0.9, blue: 1.0, alpha: 1.0), // light pink
            UIColor(red: 0.9, green: 1.0, blue: 1.0, alpha: 1.0), // light cyan
            UIColor(red: 1.0, green: 0.95, blue: 0.8, alpha: 1.0), // light orange
            UIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0), // light periwinkle
            UIColor(red: 0.9, green: 0.8, blue: 1.0, alpha: 1.0), // light purple
            UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)  // white
        ]
        var selectedColor: UIColor?
        
        var googlyIDs: [String] = []
    }
    
    var dataSource: DataSourceType!
    var model = Model()
    var gptModel = GPTModel()
    
    // Add a state flag or token
    private var apiRequestToken = UUID()
    
    
    var googlePlacesRequestTask: Task<Void,Never>? = nil
    var openAIRequestTask: Task<Void, Never>? = nil
    deinit {
        googlePlacesRequestTask?.cancel()
        openAIRequestTask?.cancel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupPage()
        collectionView.collectionViewLayout = createLayout()
        dataSource = createDataSource()
        collectionView.dataSource = dataSource
        updateCollectionView()
    }
    
    func setupPage() {
        
        collectionView.register(AskAIInputCollectionViewCell.self, forCellWithReuseIdentifier: "AskAIInput")
        getUserLoc()
        update()
    }
    
    func resetView() {
        gptModel.suggestedPrompts = []
        gptModel.gptPlaces = []
        gptModel.gptGooglePlaces = []
        gptModel.askAIMode = .suggestingPrompts
    }
    
    func update() {
        getSuggestedGPTPrompts()
    }
    
    func createDataSource() -> DataSourceType {
        let dataSource = DataSourceType(collectionView: collectionView) { (collectionView, indexPath, item) in
            switch item {
            case .askAIInput:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AskAIInput", for: indexPath) as! AskAIInputCollectionViewCell
                cell.delegate = self
                return cell
                
            case .gptPrompt(let prompt):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GPTPrompt", for: indexPath) as! GPTPromptCollectionViewCell
                
                cell.prompt = prompt
                cell.promptLabel.text = prompt
                
                let colors: [UIColor] = [
                        UIColor(red: 1.0, green: 0.9, blue: 0.9, alpha: 1.0), // light red
                        UIColor(red: 0.9, green: 1.0, blue: 0.9, alpha: 1.0), // light green
                        UIColor(red: 0.9, green: 0.9, blue: 1.0, alpha: 1.0), // light blue
                        UIColor(red: 1.0, green: 1.0, blue: 0.9, alpha: 1.0), // light yellow
                        UIColor(red: 1.0, green: 0.9, blue: 1.0, alpha: 1.0), // light pink
                        UIColor(red: 0.9, green: 1.0, blue: 1.0, alpha: 1.0), // light cyan
                        UIColor(red: 1.0, green: 0.95, blue: 0.8, alpha: 1.0), // light orange
                        UIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0), // light periwinkle
                        UIColor(red: 0.9, green: 0.8, blue: 1.0, alpha: 1.0), // light purple
                        UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)  // white
                    ]
                if self.gptModel.selectedColor == nil {
                    self.gptModel.selectedColor = self.gptModel.colors.randomElement()
                }
                guard let selectedColor = self.gptModel.selectedColor else { return cell }
                cell.styleCell(color: selectedColor)
                
                return cell
            case .gptGooglePlace(let place):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GPTPlace", for: indexPath) as! GPTPlaceCollectionViewCell
                //Place object stored in each instance of ViewModel.Item and can be used to configure the cell
                cell.place = place
                
                //fetch image with cells fetchImage function
                //activity indicator stopped once the image is returned
                cell.imageRequestTask?.cancel()
                cell.imageRequestTask = nil
                cell.placePic.image = nil
                
                cell.fetchImage(imageURL: place.imageURL)
                
                //image task will take time so animate an activity indicator to show activity in progress
                cell.activityIndicator.isHidden = false
                cell.activityIndicator.startAnimating()
                
                cell.placeNameLabel.text = place.name
                cell.neiCatLabel.text = "\(place.neighborhood) - \(place.genre)"
                let (distance, fromWho) = self.distanceFromYou(place: place)
                cell.milesFromUserLabel.text = "\(String(format: "%.2f", distance)) miles from \(fromWho)"
                if let place = place as? ConciergePlace {
                    cell.communityLovesLabel.text = "\(place.communityVotes) Community Loves"
                } else if let place = place as? FSQPlace {
                    cell.communityLovesLabel.text = "Rating - \(place.rating ?? 0) / Popularity - \(place.popularity ?? 0)"
                } else if let place = place as? GooglePlace {
                    if let rating = place.rating {
                        cell.communityLovesLabel.text = "Rating - \(String(format: "%.2f", rating))"
                    } else {
                        cell.communityLovesLabel.text = "No Rating"
                    }
                }
                
                cell.delegate = self
                
                //return cell for each item
                return cell
            case .gptNotFoundPlace(let place):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AutoCompletion", for: indexPath) as! SearchAutoCompletionCollectionViewCell
                //Place object stored in each instance of ViewModel.Item and can be used to configure the cell
                
                cell.styleCell()
                
                cell.placeNameLabel.text = place.name
                cell.placeAddressLabel.text = place.address
                cell.cellType = .place
                cell.gptPlace = place
                
                //return cell for each item
                return cell
            case .gptLoading(let gptPlaces, let googlePlaces):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GPTLoading", for: indexPath) as! GPTLoadingCollectionViewCell
                if !cell.activityIndicator.isAnimating {
                    cell.activityIndicator.startAnimating()
                }
                
                if gptPlaces == 0 {
                    cell.gptPlacesLoadedLabel.text = self.gptModel.lastestUserPrompt ?? ""
                    cell.googlePlacesLoadedLabel.text = ""
                } else {
                    cell.gptPlacesLoadedLabel.text = "ChatGPT replied with \(gptPlaces) places"
                    cell.googlePlacesLoadedLabel.text = "Google Maps Platform replied with \(googlePlaces) places"
                }
                return cell
            case .gptClear:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GPTClear", for: indexPath) as! GPTClearCollectionViewCell
                cell.delegate = self
                
                return cell
            }
        }
        return dataSource
    }
    
    func createLayout() -> UICollectionViewCompositionalLayout {
        
        let layout = UICollectionViewCompositionalLayout { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            let section = self.model.sections[sectionIndex]
            switch section {
            case .askAIInput:
                // Define layout for search input cell with estimated height
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(60))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(60))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                let sectionLayout = NSCollectionLayoutSection(group: group)
                sectionLayout.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0)
                return sectionLayout
                
            case .gptPrompts:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(60))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 5, bottom: 6, trailing: 5)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(60))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10)
                
                return section
            case .gptGooglePlace:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(125))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 10)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(125))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
                
                // Set the count to 3 to display three cells side by side
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0)
                
                return section
            case .gptNotFoundPlace:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(60))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 5, bottom: 3, trailing: 5)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(60))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0)
                
                return section
                
            case .gptLoading:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.96), heightDimension: .absolute(150))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                var groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(150))
                var group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 4, bottom: 8, trailing: 4)
                
                return section
            case .gptClear:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.96), heightDimension: .absolute(15))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(15))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                switch self.gptModel.askAIMode {
                case .loadingPlaces:
                    section.contentInsets = NSDirectionalEdgeInsets(top: 40, leading: 0, bottom: 2, trailing: 0)
                default:
                    section.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0)
                }
                
                return section
            }
        }
        return layout
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? GPTPromptCollectionViewCell, let prompt = cell.prompt {
            submitGPTPrompt(prompt: prompt)
        }
    }
    
    func updateCollectionView() {
        if let itemsBySection = createItemsBySection() {
            model.model = itemsBySection
            self.dataSource.applySnapshotUsing(sectionIDs: self.model.sections, itemsBySection: itemsBySection)
        }
    }
    
    func createItemsBySection() -> [ViewModel.Section:[ViewModel.Item]]? {
        var itemsBySection: [ViewModel.Section:[ViewModel.Item]]?
        
        itemsBySection = createAskAIItemsBySection()
        
        guard let itemsBySection = itemsBySection else { return nil }
        
        model.sections = itemsBySection.keys.sorted { lhs, rhs in
            if model.sectionRanks[lhs] ?? 0 != model.sectionRanks[rhs] ?? 0 {
                return model.sectionRanks[lhs] ?? 0 > model.sectionRanks[rhs] ?? 0
            } else {
                //if there's a tie settle it alphabetically
                return lhs.hashValue < rhs.hashValue
            }
        }
        
        return itemsBySection
    }
    
    func createAskAIItemsBySection()  -> [ViewModel.Section:[ViewModel.Item]]? {
        
        var itemsBySection: [ViewModel.Section:[ViewModel.Item]] = [:]
        
        switch gptModel.askAIMode {
        case .suggestingPrompts:
            itemsBySection[.askAIInput] = [.askAIInput]
            model.sectionRanks[.askAIInput] = 10000
            
            var promptItems: [ViewModel.Item] = []
            for gptPrompt in gptModel.suggestedPrompts {
                promptItems.append(.gptPrompt(prompt: gptPrompt))
            }
            itemsBySection[.gptPrompts] = promptItems
            model.sectionRanks[.gptPrompts] = 500
        case .loadingPlaces:
            itemsBySection[.gptClear] = [.gptClear]
            model.sectionRanks[.gptClear] = 1500
            
            itemsBySection[.gptLoading] = [.gptLoading(gptPlaces: gptModel.gptPlaces.count, googlePlaces: gptModel.gptGooglePlaces.count)]
            model.sectionRanks[.gptLoading] = 1000
            
            var placeItems: [ViewModel.Item] = []
            for place in gptModel.gptGooglePlaces {
                placeItems.append(.gptGooglePlace(place: place))
            }
            itemsBySection[.gptGooglePlace] = placeItems
            model.sectionRanks[.gptGooglePlace] = 100
        case .displayingPlaces:
            itemsBySection[.askAIInput] = [.askAIInput]
            model.sectionRanks[.askAIInput] = 10000
            
            itemsBySection[.gptClear] = [.gptClear]
            model.sectionRanks[.gptClear] = 1500
            
            var placeItems: [ViewModel.Item] = []
            for place in gptModel.gptGooglePlaces {
                placeItems.append(.gptGooglePlace(place: place))
            }
            
            var notFoundPlaceItems: [ViewModel.Item] = []
            for place in gptModel.gptNotFoundPlaces {
                print("Not Found Place", place.name)
                notFoundPlaceItems.append(.gptNotFoundPlace(place: place))
            }
            
            itemsBySection[.gptGooglePlace] = placeItems
            itemsBySection[.gptNotFoundPlace] = notFoundPlaceItems
            model.sectionRanks[.gptGooglePlace] = 100
            model.sectionRanks[.gptNotFoundPlace] = 10
        }
        
        return itemsBySection
    }
    
    func resetAskAIView() {
        // Invalidate the current token
        apiRequestToken = UUID()
        
        gptModel.suggestedPrompts = []
        gptModel.gptPlaces = []
        gptModel.gptGooglePlaces = []
        gptModel.gptNotFoundPlaces = []
        
        openAIRequestTask?.cancel()
        openAIRequestTask = nil
        googlePlacesRequestTask?.cancel()
        googlePlacesRequestTask = nil
        
        getSuggestedGPTPrompts()
        gptModel.askAIMode = .suggestingPrompts
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "ViewMapFromAskAI" {
            let mapViewController = segue.destination as! MapViewController
            mapViewController.places = gptModel.gptGooglePlaces
            mapViewController.gptPlaces = gptModel.gptNotFoundPlaces
        }
    }
    
    @IBSegueAction func gptPlaceSelected(_ coder: NSCoder, sender: Any?) -> UICollectionViewController? {
        guard let cell = sender as? GPTPlaceCollectionViewCell, let place = cell.place, let img = cell.placePic.image, let indexPath = collectionView.indexPath(for: cell), let section = dataSource.sectionIdentifier(for: indexPath.section) else {return nil}
        return placeSelected(place: place, img: img, sec: section, coder: coder)
    }
    
    func placeSelected(place: Place, img: UIImage, sec: ViewModel.Section, coder: NSCoder) -> UICollectionViewController? {
        var places = [Place]()
        
        let items = model.model[sec] ?? []
        
        items.forEach({ item in
            switch item {
            case .gptGooglePlace(let place):
                places.append(place)
            default:
                break
            }
        })
        
        //return DetailVC
        return PlaceDetailCollectionViewController(coder: coder, place: place, sectionsPlaces: places, placePic: img, placeTypeID: 0)
    }
    
    
    @IBSegueAction func applePlaceSelected(_ coder: NSCoder, sender: Any?) -> GPTPlaceViewController? {
        guard let cell = sender as? SearchAutoCompletionCollectionViewCell, let place = cell.gptPlace else {return nil}
        
        return GPTPlaceViewController(coder: coder, place: place)
    }
}


extension AskAICollectionViewController: AskAIInputCollectionViewCellDelegate {
    func didSubmitPrompt(_ prompt: String) {
        gptModel.gptPlaces = []
        gptModel.gptGooglePlaces = []
        submitGPTPrompt(prompt: prompt)
    }
    
    func didChangeText() {
        // Trigger a layout update when the text changes
        // Find the index path of the search input cell
        if let searchInputSection = model.sections.firstIndex(of: .askAIInput) {
            let indexPath = IndexPath(item: 0, section: searchInputSection)
            // Perform batch updates to animate the cell resizing
            collectionView.performBatchUpdates(nil, completion: nil)
        }
    }
    
    func configureGPTPromptCell(_ cell: GPTPromptCollectionViewCell) {
        if self.gptModel.selectedColor == nil {
            self.gptModel.selectedColor = self.gptModel.colors.randomElement()
        }
        if let selectedColor = self.gptModel.selectedColor {
            cell.styleCell(color: selectedColor)
        }
    }

    func configureGPTPlaceCell(_ cell: GPTPlaceCollectionViewCell, with place: Place) {
        // Configure place cell as per existing logic
        cell.fetchImage(imageURL: place.imageURL)
        cell.activityIndicator.isHidden = false
        cell.activityIndicator.startAnimating()
        cell.placeNameLabel.text = place.name
        cell.neiCatLabel.text = "\(place.neighborhood) - \(place.genre)"
        let (distance, fromWho) = self.distanceFromYou(place: place)
        cell.milesFromUserLabel.text = "\(String(format: "%.2f", distance)) miles from \(fromWho)"
        
        if let place = place as? ConciergePlace {
            cell.communityLovesLabel.text = "\(place.communityVotes) Community Loves"
        } else if let place = place as? FSQPlace {
            cell.communityLovesLabel.text = "Rating - \(place.rating ?? 0) / Popularity - \(place.popularity ?? 0)"
        } else if let place = place as? GooglePlace {
            if let rating = place.rating {
                cell.communityLovesLabel.text = "Rating - \(String(format: "%.2f", rating))"
            } else {
                cell.communityLovesLabel.text = "No Rating"
            }
        }
        
        cell.delegate = self
    }

    func configureGPTLoadingCell(_ cell: GPTLoadingCollectionViewCell, gptPlaces: Int, googlePlaces: Int) {
        if !cell.activityIndicator.isAnimating {
            cell.activityIndicator.startAnimating()
        }
        
        if gptPlaces == 0 {
            cell.gptPlacesLoadedLabel.text = self.gptModel.lastestUserPrompt ?? ""
            cell.googlePlacesLoadedLabel.text = ""
        } else {
            cell.gptPlacesLoadedLabel.text = "ChatGPT replied with \(gptPlaces) places"
            cell.googlePlacesLoadedLabel.text = "Google Maps Platform replied with \(googlePlaces) places"
        }
    }
}


extension AskAICollectionViewController {
    func distanceFromYou(place: Place) -> (Double,String) {
        if model.locDenied == false, model.locValue.latitude != 0 {
            let from = CLLocation(latitude: model.locValue.latitude, longitude: model.locValue.longitude)
            let to = CLLocation(latitude: place.latitude, longitude: place.longitude)
            
            let distance = to.distance(from: from)
            
            let distanceToReturn = distance/1609.34
            
            return (distanceToReturn, "You")
        } else if model.cityCenter != nil {
            let lat = model.cityCenter?.latitude ?? 0.0
            let lon = model.cityCenter?.longitude ?? 0.0
            let from = CLLocation(latitude: lat, longitude: lon)
            let to = CLLocation(latitude: place.latitude, longitude: place.longitude)
            
            let distance = to.distance(from: from)
            
            let distanceToReturn = distance/1609.34
            
            return (distanceToReturn, "City Center")
        }else {
            let lat = currentUser.latitude ?? 0.0
            let lon = currentUser.longitude ?? 0.0
            let from = CLLocation(latitude: lat, longitude: lon)
            let to = CLLocation(latitude: place.latitude, longitude: place.longitude)
            
            let distance = to.distance(from: from)
            
            let distanceToReturn = distance/1609.34
            
            return (distanceToReturn, "City Center")
        }
    }
}

// MARK: Location Manager Extension
extension AskAICollectionViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //method to get the user's current location coordinates
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        self.model.locValue = locValue
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("location finder error")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        //called when the location authorization status is changed - if authorized start updating user's location
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
            updateCollectionView()
        default:
            manager.stopUpdatingLocation()
        }
    }
    
    
    
    func getUserLoc() {
        model.locationManager.requestWhenInUseAuthorization()
        if let latitude = currentUser.latitude, latitude != 0, let longitude = currentUser.longitude, longitude != 0 {
            model.locValue = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            model.locDenied = false
        }
    }
}



import OpenAIKit
//import GooglePlaces

extension AskAICollectionViewController {
    func getSuggestedGPTPrompts() {
        
        var gptPrompt = """
You are providing suggested prompts to an iOS app that will be displayed to the user. The user will be able to click one of the prompts and another request will be made to suggest places for the user to browse. The prompts should be a good search term that would have associated places in a Point of Interest database like Google Maps Platform or Apple Maps. Keep it interesting for the user by providing obvious prompts along with some creative ones they wouldn't immediately think of. Keep each prompt grounded in a geographic location, keep most of the suggestions in the USA. If the ll parameter below has a valid latitude,longitude value, include prompts like 'Near Me' and suggest more prompts near the users geographic location. A user could be looking for places near them, or they could be looking for cool spots on an upcoming vacation -- Don't suggest 100% prompts based on the users location, always spice it up a bit on at least 30-50% of the suggested prompts.

        Provide the response in a JSON format. Don't provide any supporting text, only the JSON response. See the required format below.
--------------------------------------------------------------------------------------------------
        {"suggestedPrompts": [{"prompt": "prompt1"},{"prompt": "prompt2"}]}
--------------------------------------------------------------------------------------------------

        Please provide a list of 1-10 suggested prompts for the user.
        ll: 
"""
        if !model.locDenied && model.locValue.latitude != 0 && model.locValue.longitude != 0 {
            gptPrompt += "\(model.locValue.latitude),\(model.locValue.longitude)"
        }
        
        let username = currentUser.username ?? "\(currentUser.firstName) \(currentUser.lastName)"
        let aiMessage = AIMessage(role: .user, content: gptPrompt)
        openAI.sendChatCompletion(newMessage: aiMessage, previousMessages: [], model: .gptV4(.gpt4), maxTokens: 500, n: 1, user: username, completion: { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let aiResult):
                // Handle the result actions
                if let text = aiResult.choices.first?.message?.content {
                    self.parseGPTPromptsResponse(text: text)
                }
            case .failure(let error):
                //Handle the error
                let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default))
                self.present(alert, animated: true)
            }
        })
    }
    
    func submitGPTPrompt(prompt: String) {
        gptModel.lastestUserPrompt = prompt
        
        let currentToken = apiRequestToken
        
        gptModel.askAIMode = .loadingPlaces
        updateCollectionView()
        
        var gptPrompt = """
You are providing places to an iOS app that will be displayed to the user. Please provide a list of places based on a prompt that a user is submitting. The user is either selecting a suggested prompt or typing one of their own. Do the best you can to match each of the conditions and provide 1-10 places for the user to further interact with in the app. Ideally it should be a place that would have an associated record in a Point of Interest database like Google Maps Platform or Apple Maps. Keep all of the places grounded in a single geographic location/city - also return this location in the response. If the ll parameter below has a valid latitude,longitude value, and the user didn't specify a different location in their prompt, target places near the user.

Provide the response in a JSON format with Place Name and Place Address. Don't provide any supporting text, only the JSON response. See the required format below.
--------------------------------------------------------------------------------------------------
{"suggestedPlaces": [{"name": "placeName1", "address":"address1", "website":"website1"},{"name": "placeName2", "address":"address2", "website":"website2"}], "location": {"cityName": "cityName", "cityCenterLatitude": latitude (Decimal), "cityCenterLongitude": longitude (Decimal)}}
--------------------------------------------------------------------------------------------------

User Prompt: \(prompt)
ll: 
"""
        if !model.locDenied && model.locValue.latitude != 0 && model.locValue.longitude != 0 {
            gptPrompt += "\(model.locValue.latitude),\(model.locValue.longitude)"
        }
        
        let username = currentUser.username ?? "\(currentUser.firstName) \(currentUser.lastName)"
        let aiMessage = AIMessage(role: .user, content: gptPrompt)
        openAI.sendChatCompletion(newMessage: aiMessage, previousMessages: [], model: .gptV4(.gpt4), maxTokens: 500, n: 1, user: username, completion: { [weak self] result in
            guard let self = self else { return }
            
            // Check if the token matches
            if self.apiRequestToken != currentToken {
                // The view has been reset; ignore this result
                return
            }
            switch result {
            case .success(let aiResult):
                print("successful response from OpenAI")
                // Handle the result actions
                if let text = aiResult.choices.first?.message?.content {
                    self.parseGPTPlacesResponse(text: text)
                }
            case .failure(let error):
                //Handle the error
                let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default))
                self.present(alert, animated: true)
            }
        })
    }
    
    func parseGPTPromptsResponse(text: String) {
        // Convert the string to a Data object
        guard let jsonData = text.data(using: .utf8) else {
            print("Error: Cannot convert string to Data object")
            return
        }

        // Create an instance of JSONDecoder
        let decoder = JSONDecoder()

        // Attempt to decode the Data object into our Swift structs
        do {
            let response = try decoder.decode(GPTPromptsResponse.self, from: jsonData)
            // Successfully decoded, you can now use the data
            for prompt in response.suggestedPrompts {
                gptModel.suggestedPrompts.append(prompt.prompt)
            }
        } catch {
            // If decoding fails, print an error message
            gptModel.askAIMode = .suggestingPrompts
        }
        
        DispatchQueue.main.async {
            UIView.transition(with: self.view, duration: 0.8, options: .showHideTransitionViews, animations: { [weak self] () -> Void in
                self?.updateCollectionView()
            }, completion: nil)
        }
    }
    
    func parseGPTPlacesResponse(text: String) {
        // Convert the string to a Data object
        guard let jsonData = text.data(using: .utf8) else {
            print("Error: Cannot convert string to Data object")
            return
        }

        // Create an instance of JSONDecoder
        let decoder = JSONDecoder()

        // Attempt to decode the Data object into our Swift structs
        do {
            let response = try decoder.decode(GPTPlacesResponse.self, from: jsonData)
            // Successfully decoded, you can now use the data
            for place in response.suggestedPlaces {
                gptModel.gptPlaces.append(place)
            }
            if let lat = response.location?.cityCenterLatitude, let lon = response.location?.cityCenterLongitude {
                model.cityCenter = CLLocationCoordinate2D(latitude: 0, longitude: 0)
            }
        } catch {
            // If decoding fails, print an error message
            gptModel.askAIMode = .suggestingPrompts
            DispatchQueue.main.async {
                self.updateCollectionView()
            }
            return
        }
        
        DispatchQueue.main.async {
            print("UCV2")
            self.updateCollectionView()
        }
        getGPTGooglePlaces()
    }
    
    func getGPTGooglePlaces() {
        let currentToken = apiRequestToken
        
        guard !gptModel.gptPlaces.isEmpty else { return }
        
        var ll = ""
        
        switch (model.locDenied, model.locValue.longitude) {
        case (true, _), (false, 0.0):
            let lat = currentUser.latitude ?? 0.0
            let lon = currentUser.longitude ?? 0.0
            ll = "\(lat),\(lon)"
        default:
            ll = "\(model.locValue.latitude),\(model.locValue.longitude)"
        }
        
        gptModel.gptGooglePlaces = []
        
        googlePlacesRequestTask = Task {
            for place in gptModel.gptPlaces {
                
                if Task.isCancelled || self.apiRequestToken != currentToken {
                    return
                }
                print("GooglePlacesRequest!!")
                
                let query = "\(place.name) \(place.address)"
                if let googleFindParent = try? await GoogleFindCandidatePlacesRequest(textQuery: query, location: ll).send(), googleFindParent.results.count > 0 {
                    print("GPTGoogle Place Request", place.name)
                    let googleFindPlaceDecoded = googleFindParent.results
                    let _ = googleFindPlaceDecoded[0].place_id
                    let candidate = googleFindParent.results[0]
                    
                    let placeID = candidate.place_id
                    print("placeID", placeID)
                    if let googleParent = try? await GooglePlaceDetailRequest(placeID: placeID).send() {
                        let googlyPlace = googleParent.result
                        let appendPlace = googlyPlace.placeify()
                        if gptModel.googlyIDs.contains(placeID) == false {
                            gptModel.gptGooglePlaces.append(appendPlace)
                            gptModel.googlyIDs.append(placeID)
                            print("appendPlace", appendPlace.name)
                            DispatchQueue.main.async {
                                // Check the token before updating the UI
                                if self.apiRequestToken == currentToken {
                                    self.updateCollectionView()
                                }
                            }
                        }
                    } else {
                        gptModel.gptNotFoundPlaces.append(place)
                        print("Google Place Detail failed")
                    }
                } else {
                    gptModel.gptNotFoundPlaces.append(place)
                    print("Google Place Candidates failed")
                }
            }
            DispatchQueue.main.async {
                // Check the token before updating the UI
                if self.apiRequestToken == currentToken {
                    self.gptModel.askAIMode = .displayingPlaces
                    self.updateCollectionView()
                }
            }
            googlePlacesRequestTask = nil
        }
    }
}


extension AskAICollectionViewController: GPTPlaceCollectionViewCellDelegate, GPTClearCollectionViewCellDelegate {
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
    
    func clearPressed() {
        resetAskAIView()
        updateCollectionView()
    }
}
