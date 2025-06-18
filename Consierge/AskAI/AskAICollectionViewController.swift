
import UIKit
import CoreLocation
import SafariServices

var askAISuggestedPrompts = [String]()

class AskAICollectionViewController: UICollectionViewController {
    
    typealias DataSourceType = UICollectionViewDiffableDataSource<ViewModel.Section, ViewModel.Item>
    
    enum ViewModel {
        //First 3 cases are header elements: header and segment won't change; viewTop is updated based on the chosen segment
        //Various sections after that setup to contain Place collectionViewCells seperated by Place neighborhood and Place genre
        enum Section: Hashable {
            case gptPrompts
            case gptFSQPlace
            case gptNotFoundPlace
            case gptLoading
            case askAIInput
            case gptClear
            case pbFSQ
        }
        enum Item: Hashable {
            case gptPrompt(prompt: String)
            case gptFSQPlace(place: Place)
            case gptNotFoundPlace(place: GPTPlace)
            case gptLoading(gptPlaces: Int, fsqPlaces: Int)
            case askAIInput
            case gptClear
            case pbFSQ
            
            func hash(into hasher: inout Hasher) {
                switch self {
                case .gptPrompt(let prompt):
                    hasher.combine(prompt)
                case .gptFSQPlace(let place):
                    hasher.combine("\(place.name)\(place.id)\(place.fsqID ?? "")")
                case .gptNotFoundPlace(let place):
                    hasher.combine("\(place.name)\(place.address)")
                case .gptLoading(let gptPlaces, let fsqPlaces):
                    hasher.combine("GPTLoading\(gptPlaces)\(fsqPlaces)")
                case .askAIInput:
                    hasher.combine("askAIInput")
                case .gptClear:
                    hasher.combine("GPTClear")
                case .pbFSQ:
                    hasher.combine("pbFSQ")
                }
            }
            static func == (lhs: AskAICollectionViewController.ViewModel.Item, rhs: AskAICollectionViewController.ViewModel.Item) -> Bool {
                switch (lhs, rhs){
                case (.gptFSQPlace(let lhs), .gptFSQPlace(let rhs)):
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
        
        var isUserTyping: Bool = false
        
        var itinerarySelectedPlace: Place?
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
        var userPrompts = [String]()
        
        var gptPlaces = [GPTPlace]()
//        var gptGooglePlaces = [GooglePlace]()
        var gptFSQPlaces = [FSQPlace]()
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
        
        var fsqIDs: [String] = []
    }
    
    var dataSource: DataSourceType!
    var model = Model()
    var gptModel = GPTModel()
    
    // Add a state flag or token
    private var apiRequestToken = UUID()
    
    @IBOutlet var mapBarButton: UIBarButtonItem!
    
    var fsqPlacesRequestTask: Task<Void,Never>? = nil
    var openAIRequestTask: Task<Void, Never>? = nil
    deinit {
        openAIRequestTask?.cancel()
        fsqPlacesRequestTask?.cancel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        gptModel.suggestedPrompts = askAISuggestedPrompts
        
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
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        tap.cancelsTouchesInView = false
        tap.delegate = self // Set the delegate
        view.addGestureRecognizer(tap)
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
                
                switch self.gptModel.askAIMode {
                case .displayingPlaces:
                    cell.placeholderLabel.text = "Refine Search"
                default:
                    cell.placeholderLabel.text = "Ask AI"
                }
                
                return cell
                
            case .gptPrompt(let prompt):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GPTPrompt", for: indexPath) as! GPTPromptCollectionViewCell
                
                cell.prompt = prompt
                cell.promptLabel.text = prompt
                
                let _: [UIColor] = [
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
            case .gptFSQPlace(let place):
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
                
                if let place = place as? FSQPlace {
                    cell.communityLovesLabel.text = "Rating - \(place.rating ?? 0) / Popularity - \(place.popularity ?? 0)"
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
            case .gptLoading(let gptPlaces, let fsqPlaces):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GPTLoading", for: indexPath) as! GPTLoadingCollectionViewCell
                if !cell.activityIndicator.isAnimating {
                    cell.activityIndicator.startAnimating()
                }
                
                if gptPlaces == 0 {
                    cell.gptPlacesLoadedLabel.text = self.gptModel.lastestUserPrompt ?? ""
                    cell.fsqPlacesLoadedLabel.text = ""
                } else {
                    cell.gptPlacesLoadedLabel.text = "ChatGPT replied with \(gptPlaces) places"
                    cell.fsqPlacesLoadedLabel.text = "Foursquare replied with \(fsqPlaces) places"
                }
                return cell
            case .gptClear:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GPTClear", for: indexPath) as! GPTClearCollectionViewCell
                cell.delegate = self
                
                return cell
            case .pbFSQ:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "poweredByFSQ", for: indexPath)
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
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(70))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 5, bottom: 6, trailing: 5)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(70))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10)
                
                return section
            case .gptFSQPlace:
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
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(150))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
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
            case .pbFSQ:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.96), heightDimension: .absolute(40))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(40))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0)
                
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
        
        shouldMapEnabled()
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
            
            itemsBySection[.gptLoading] = [.gptLoading(gptPlaces: gptModel.gptPlaces.count, fsqPlaces: gptModel.gptFSQPlaces.count)]
            model.sectionRanks[.gptLoading] = 1000
            
            var placeItems: [ViewModel.Item] = []
            for place in gptModel.gptFSQPlaces {
                placeItems.append(.gptFSQPlace(place: place))
            }
            itemsBySection[.gptFSQPlace] = placeItems
            model.sectionRanks[.gptFSQPlace] = 100
        case .displayingPlaces:
            itemsBySection[.askAIInput] = [.askAIInput]
            model.sectionRanks[.askAIInput] = 10000
            
            itemsBySection[.gptClear] = [.gptClear]
            model.sectionRanks[.gptClear] = 1500
            
            if gptModel.gptFSQPlaces.count > 0 {
                itemsBySection[.pbFSQ] = [.pbFSQ]
                model.sectionRanks[.pbFSQ] = 1250
            }
            
            var placeItems: [ViewModel.Item] = []
            for place in gptModel.gptFSQPlaces {
                placeItems.append(.gptFSQPlace(place: place))
            }
            
            var notFoundPlaceItems: [ViewModel.Item] = []
            for place in gptModel.gptNotFoundPlaces {
                notFoundPlaceItems.append(.gptNotFoundPlace(place: place))
            }
            
            itemsBySection[.gptFSQPlace] = placeItems
            itemsBySection[.gptNotFoundPlace] = notFoundPlaceItems
            model.sectionRanks[.gptFSQPlace] = 100
            model.sectionRanks[.gptNotFoundPlace] = 10
        }
        
        return itemsBySection
    }
    
    func resetAskAIView() {
        // Invalidate the current token
        apiRequestToken = UUID()
        
        gptModel.suggestedPrompts = []
        gptModel.userPrompts = []
        gptModel.gptPlaces = []
        gptModel.gptFSQPlaces = []
        gptModel.gptNotFoundPlaces = []
        
        openAIRequestTask?.cancel()
        openAIRequestTask = nil
        fsqPlacesRequestTask?.cancel()
        fsqPlacesRequestTask = nil
        
        getSuggestedGPTPrompts()
        gptModel.askAIMode = .suggestingPrompts
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "ViewMapFromAskAI" {
            let mapViewController = segue.destination as! MapViewController
            mapViewController.places = gptModel.gptFSQPlaces
            mapViewController.gptPlaces = gptModel.gptNotFoundPlaces
        } else if segue.identifier == "AddToItinerary" {
            guard let navController = segue.destination as? UINavigationController else { return }
            guard let tableController = navController.topViewController as? AddToItineraryTableViewController  else { return }
            guard let place = model.itinerarySelectedPlace else { return }
            var isFSQPlace = false
            var type = "Concierge"
            if let _ = place as? FSQPlace {
                isFSQPlace = true
                type = "FSQ"
            }
            tableController.place = place
            tableController.cityID = place.cityID
            tableController.isFSQPlace = isFSQPlace
            
            tableController.type = type
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
            case .gptFSQPlace(let place):
                places.append(place)
            default:
                break
            }
        })
        
        //return DetailVC
        return PlaceDetailCollectionViewController(coder: coder, place: place, sectionsPlaces: places, placePic: img, placeTypeID: 0, cityID: place.cityID.cityID)
    }
    
    
    @IBSegueAction func applePlaceSelected(_ coder: NSCoder, sender: Any?) -> GPTPlaceViewController? {
        guard let cell = sender as? SearchAutoCompletionCollectionViewCell, let place = cell.gptPlace else {return nil}
        
        return GPTPlaceViewController(coder: coder, place: place)
    }
}


extension AskAICollectionViewController: AskAIInputCollectionViewCellDelegate {
    func didSubmitPrompt(_ prompt: String) {
        gptModel.gptPlaces = []
        gptModel.gptFSQPlaces = []
        switch gptModel.askAIMode {
        case .displayingPlaces:
            submitGPTFeedback(prompt: prompt)
        default:
            submitGPTPrompt(prompt: prompt)
        }
    }
    
    func didChangeText(isTyping: Bool) {
        // Trigger a layout update when the text changes
        // Find the index path of the search input cell
        model.isUserTyping = isTyping
        if let searchInputSection = model.sections.firstIndex(of: .askAIInput) {
            let _ = IndexPath(item: 0, section: searchInputSection)
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
        
        if let place = place as? FSQPlace {
            if let rating = place.rating {
                cell.communityLovesLabel.text = "Rating - \(String(format: "%.2f", rating))"
            } else {
                cell.communityLovesLabel.text = "No Rating"
            }
        }
        
        cell.delegate = self
    }

    func configureGPTLoadingCell(_ cell: GPTLoadingCollectionViewCell, gptPlaces: Int, fsqPlaces: Int) {
        if !cell.activityIndicator.isAnimating {
            cell.activityIndicator.startAnimating()
        }
        
        if gptPlaces == 0 {
            cell.gptPlacesLoadedLabel.text = self.gptModel.lastestUserPrompt ?? ""
            cell.fsqPlacesLoadedLabel.text = ""
        } else {
            cell.gptPlacesLoadedLabel.text = "ChatGPT replied with \(gptPlaces) places"
            cell.fsqPlacesLoadedLabel.text = "Foursquare replied with \(fsqPlaces) places"
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
        } else {
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
        // print("location finder error")
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

//import GooglePlaces

extension AskAICollectionViewController {
    func getSuggestedGPTPrompts() {
        if gptModel.suggestedPrompts.isEmpty != true {
            return
        }
        let systemPrompt = """
                You are providing suggested search prompts for an iOS app focused on discovering interesting places and attractions.
                Each suggestion should help users quickly find exciting, unique, or popular locations from an AI Places/Point of Interest suggestion service.
                Provide the response in a JSON format. Don't provide any supporting text, only the JSON response. This includes markdown like ``` ``` or json. Only include the valid JSON. The response should start with the character "{" and end with the character "}". See the required format below.
        --------------------------------------------------------------------------------------------------
                {"suggestedPrompts": [{"prompt": "prompt1"},{"prompt": "prompt2"}]}
        --------------------------------------------------------------------------------------------------
        
        """
        
        var gptPrompt = """
                Please provide 10 engaging, creative suggested prompts to help users discover interesting places from a AI Places/Point of Interest suggestion service.
        
            Follow these guidelines:
                1. Prompts should be concise, inviting, and relevant.  
                2. Include creative suggestions users might not immediately consider—hidden gems, themed locations, trending spots, unique experiences, etc.  
                3. If the "ll" parameter has a valid latitude and longitude, ensure that 3-5 of the 10 prompts clearly relate to places near the provided coordinates, using phrases like "near me", "nearby", the local city name, or a local neighborhood. This means the remaining 4-6 recommendations should be outside the users location.
                4. If no "ll" paramter is provided, don't center the prompt suggestions around any specific location - provide prompt suggestions for a variety of locations. Still center each suggested prompt in a geographic location, but choose a variety of locations in the US, and maybe 1 suggested prompt for a geographic location outside the US.
                5. If "userID" is provided, incorporate personalization based on the user's past searches or indicated preferences. 
                6. Keep 9-10 of the 10 prompts based in geographic areas within the United States, unless the user's previous searches explicitly include international locations.
        
        Parameters provided:
        ll: 
        """
        if !model.locDenied && model.locValue.latitude != 0 && model.locValue.longitude != 0 {
            gptPrompt += "\(model.locValue.latitude),\(model.locValue.longitude)"
        }
        
        let username = String(currentUser.id)
        
        gptPrompt += "\nuserID: "
        gptPrompt += username
        
        let request = ChatGPTCompletionRequest(model: "gpt-4o", systemPrompt: systemPrompt, prompts: [gptPrompt], maxTokens: 500, temperature: 1.2, username: username)
        
        Task {
            let response = try await request.send()
            if let text = response.choices.first?.message.content {
                self.parseGPTPromptsResponse(text: text)
            } else {
                // print("GPT Prompts for AskAI Error")
            }
        }
    }
    
    func submitGPTPrompt(prompt: String) {
        gptModel.lastestUserPrompt = prompt
        
        let currentToken = apiRequestToken
        
        gptModel.askAIMode = .loadingPlaces
        updateCollectionView()
        let systemPrompt = """
        You are providing places to an iOS app that will be displayed to the user.
        
        Provide the response in a JSON format with Place Name and Place Address. Don't provide any supporting text, only the JSON response. See the required format below.  The response should start with the character "{" and end with the character "}". Dont include any whitespace. 
        --------------------------------------------------------------------------------------------------
        {"suggestedPlaces": [{"name": "placeName1", "address":"address1", "website":"website1"},{"name": "placeName2", "address":"address2", "website":"website2"}], "location": {"cityName": "cityName", "cityCenterLatitude": latitude (Decimal), "cityCenterLongitude": longitude (Decimal)}}
        --------------------------------------------------------------------------------------------------
"""
        
        var gptPrompt = """
Please provide a list of 1-10 places based on the below prompt. Ideally it should be a place that would have an associated record in a Point of Interest database like Google Maps Platform or Apple Maps. Keep all of the places grounded in a single geographic location/city - also return this location in the response. If the ll parameter below has a valid latitude,longitude value, and the user didn't specify a different location in their prompt, target places near the user.
User Prompt: \(prompt)
ll: 
"""
        if !model.locDenied && model.locValue.latitude != 0 && model.locValue.longitude != 0 {
            gptPrompt += "\(model.locValue.latitude),\(model.locValue.longitude)"
        }
        
        let username = currentUser.username ?? "\(currentUser.firstName) \(currentUser.lastName)"
        let request = ChatGPTCompletionRequest(model: "gpt-4o", systemPrompt: systemPrompt, prompts: [gptPrompt], maxTokens: 500, temperature: 0.7, username: username)
        
        
        Task {
            let response = try await request.send()
            
            if self.apiRequestToken != currentToken {
                // The view has been reset; ignore this result
                return
            }
            
            if let text = response.choices.first?.message.content {
                self.parseGPTPlacesResponse(text: text)
            } else {
                //Handle the error
                // print("GPT Places error")
            }
        }
        gptModel.userPrompts.append(gptPrompt)
    }
    
    func submitGPTFeedback(prompt: String) {
        gptModel.lastestUserPrompt = prompt
        
        let currentToken = apiRequestToken
        
        gptModel.askAIMode = .loadingPlaces
        updateCollectionView()
        
        
        let systemPrompt = """
        You are providing places to an iOS app that will be displayed to the user.
        
        Provide the response in a JSON format with Place Name and Place Address. Don't provide any supporting text, only the JSON response. See the required format below.  The response should start with the character "{" and end with the character "}". Dont include any whitespace. 
        --------------------------------------------------------------------------------------------------
        {"suggestedPlaces": [{"name": "placeName1", "address":"address1", "website":"website1"},{"name": "placeName2", "address":"address2", "website":"website2"}], "location": {"cityName": "cityName", "cityCenterLatitude": latitude (Decimal), "cityCenterLongitude": longitude (Decimal)}}
        --------------------------------------------------------------------------------------------------
"""
        
        gptModel.userPrompts.append(prompt)
        
        let username = currentUser.username ?? "\(currentUser.firstName) \(currentUser.lastName)"
        
        let request = ChatGPTCompletionRequest(model: "gpt-4o", systemPrompt: systemPrompt, prompts: gptModel.userPrompts, maxTokens: 500, temperature: 0.7, username: username)
        
        Task {
            let response = try await request.send()
        
            if self.apiRequestToken != currentToken {
                // The view has been reset; ignore this result
                return
            }
            
            if let text = response.choices.first?.message.content {
                self.parseGPTPlacesResponse(text: text)
            } else {
                //Handle the error
                // print("GPT Places error")
            }
        }
    }
    
    func parseGPTPromptsResponse(text: String) {
        // Convert the string to a Data object
        guard let jsonData = text.data(using: .utf8) else {
            // print("Error: Cannot convert string to Data object")
            return
        }

        // Create an instance of JSONDecoder
        let decoder = JSONDecoder()
        
        if gptModel.suggestedPrompts.isEmpty != true {
            return
        }
        
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
            if !self.model.isUserTyping {
                UIView.transition(with: self.view, duration: 0.8, options: .showHideTransitionViews, animations: { [weak self] () -> Void in
                    self?.updateCollectionView()
                }, completion: nil)
            }
        }
    }
    
    func parseGPTPlacesResponse(text: String) {
        // Convert the string to a Data object
        guard let jsonData = text.data(using: .utf8) else {
            // print("Error: Cannot convert string to Data object")
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
            if let _ = response.location?.cityCenterLatitude, let _ = response.location?.cityCenterLongitude {
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
            self.updateCollectionView()
        }
        getGPTFSQPlaces()
    }
    
//    func getGPTGooglePlaces() {
//        let currentToken = apiRequestToken
//        
//        guard !gptModel.gptPlaces.isEmpty else { return }
//        
//        var ll = ""
//        
//        switch (model.locDenied, model.locValue.longitude) {
//        case (true, _), (false, 0.0):
//            let lat = currentUser.latitude ?? 0.0
//            let lon = currentUser.longitude ?? 0.0
//            ll = "\(lat),\(lon)"
//        default:
//            ll = "\(model.locValue.latitude),\(model.locValue.longitude)"
//        }
//        
//        gptModel.gptGooglePlaces = []
//        
//        googlePlacesRequestTask = Task {
//            for place in gptModel.gptPlaces {
//                
//                if Task.isCancelled || self.apiRequestToken != currentToken {
//                    return
//                }
//                
//                let query = "\(place.name) \(place.address)"
//                if let googleFindParent = try? await GoogleFindCandidatePlacesRequest(textQuery: query, location: ll).send(), googleFindParent.results.count > 0 {
//                    let googleFindPlaceDecoded = googleFindParent.results
//                    let _ = googleFindPlaceDecoded[0].place_id
//                    let candidate = googleFindParent.results[0]
//                    
//                    let placeID = candidate.place_id
//                    if let googleParent = try? await GooglePlaceDetailRequest(placeID: placeID).send() {
//                        let googlyPlace = googleParent.result
//                        let appendPlace = googlyPlace.placeify()
//                        if gptModel.googlyIDs.contains(placeID) == false {
//                            gptModel.gptGooglePlaces.append(appendPlace)
//                            gptModel.googlyIDs.append(placeID)
//                            DispatchQueue.main.async {
//                                // Check the token before updating the UI
//                                if self.apiRequestToken == currentToken {
//                                    self.updateCollectionView()
//                                }
//                            }
//                        }
//                    } else {
//                        gptModel.gptNotFoundPlaces.append(place)
//                    }
//                } else {
//                    gptModel.gptNotFoundPlaces.append(place)
//                }
//            }
//            DispatchQueue.main.async {
//                // Check the token before updating the UI
//                if self.apiRequestToken == currentToken {
//                    self.gptModel.askAIMode = .displayingPlaces
//                    self.updateCollectionView()
//                }
//            }
//            googlePlacesRequestTask = nil
//        }
//    }
    
    func getGPTFSQPlaces() {
        let currentToken = apiRequestToken
        
        guard !gptModel.gptPlaces.isEmpty else { return }
        
        gptModel.gptFSQPlaces = []
        
        fsqPlacesRequestTask = Task {
            for gptPlace in gptModel.gptPlaces {
                
                if Task.isCancelled || self.apiRequestToken != currentToken {
                    return
                }
                
                if let fsqParent = try? await FSQExactPlaceRequest(query: gptPlace.name, near: gptPlace.address).send(), fsqParent.results.count > 0 {
                    let fsqDecoded = fsqParent.results
                    let fsqPlace = fsqDecoded[0]
                    if gptModel.fsqIDs.contains(fsqPlace.fsq_id) {
                        continue
                    }
                    let appendPlace = fsqPlace.placeify()
                    gptModel.gptFSQPlaces.append(appendPlace)
                    gptModel.fsqIDs.append(appendPlace.fsqID ?? "0")
                    DispatchQueue.main.async {
                        // Check the token before updating the UI
                        if self.apiRequestToken == currentToken {
                            self.updateCollectionView()
                        }
                    }
                } else {
                    gptModel.gptNotFoundPlaces.append(gptPlace)
                }
            }
            DispatchQueue.main.async {
                // Check the token before updating the UI
                if self.apiRequestToken == currentToken {
                    self.gptModel.askAIMode = .displayingPlaces
                    self.updateCollectionView()
                }
            }
            fsqPlacesRequestTask = nil
        }
    }
}


extension AskAICollectionViewController: GPTPlaceCollectionViewCellDelegate, GPTClearCollectionViewCellDelegate {
    func addToItinerary(_ place: any Place, isFSQ: Bool) {
        model.itinerarySelectedPlace = place
        self.performSegue(withIdentifier: "AddToItinerary", sender: nil)
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

extension AskAICollectionViewController: UIGestureRecognizerDelegate {
    func shouldMapEnabled() {
        mapBarButton.isEnabled = gptModel.askAIMode == .displayingPlaces
    }
    
    @objc private func handleTapGesture() {
        view.endEditing(true) // Dismiss the keyboard
        updateCollectionView() // Update the collection view
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Check if the touch is within a collection view cell
        let location = touch.location(in: collectionView)
        if let _ = collectionView.indexPathForItem(at: location) {
            // A collection view item was tapped, let the collection view handle it
            return false
        }
        // Otherwise, allow the gesture recognizer to handle the tap
        return true
    }
}
