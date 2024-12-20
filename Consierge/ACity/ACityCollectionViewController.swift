//
//  ACityCollectionViewController.swift
//  Consierge
//
//  Created by Austin McLaughlin on 12/26/23.
//

let defaultCity = City(cityID: -1, name: "Chicago", nickname: "Chitown", imageURL: "", latitude: 41.8781, longitude: -87.6298, n: 41.9781, w: -87.7298, s: 41.7781, e: -87.5298)


import UIKit
import MapKit
import CoreLocation
import SafariServices

class ACityCollectionViewController: UICollectionViewController {
    
    var city: City = defaultCity
    
    enum Filter {
        case neighborhoods
        case categories
        case tags
        case distanceFromUser
    }
    var filters = [Filter]()
    
    let searchController = UISearchController()

    typealias DataSourceType = UICollectionViewDiffableDataSource<ViewModel.Section, ViewModel.Item>
    enum ViewModel {
        //First 3 cases are header elements: header and segment won't change; viewTop is updated based on the chosen segment
        //Various sections after that setup to contain Place collectionViewCells seperated by Place neighborhood and Place genre
        enum Section: Hashable {
            case placeTypes
            case filtersAndSort
            case placeBox(headerText: String, sectionType: PlaceSectionType, full: Bool, idx: Int? = nil)
            case placeDetail(headerText: String, sectionType: PlaceSectionType, full: Bool, idx: Int? = nil)
            case userLovedList(full: Bool)
            case rankedList
            case placeSearchList(src: PlaceSource)
            case searchAutoCompletionResults
            case gptPrompts
            case gptPlace
            case gptLoading
            case gptClear
            
            static func <(lhs: ACityCollectionViewController.ViewModel.Section, rhs: ACityCollectionViewController.ViewModel.Section) -> Bool {
                switch (lhs, rhs) {
                case (.placeBox(let lhsPlace, _, _, _), .placeBox(let rhsPlace, _, _, _)):
                    return lhsPlace < rhsPlace
                default:
                    return false
                }
            }
        }
        enum Item: Hashable/*, Comparable*/ {
            case placeType(_ placeType: PlaceType, selected: Bool)
            case viewModeSelector
            case sortMethodSelector
            case filtersSelector(selectedFilters: Int)
            case askAISelector
            case mapSelector
            case placeBox(place: Place)
            case placeDetail(place: Place)
            case placeList(place: Place)
            case rankedList(place: Place)
            case placeSearchList(place: Place)
            case placeSearchListApple(place: MKMapItem)
            case searchAutoCompletionResult(autoCompletion: MKLocalSearchCompletion)
            case gptPrompt(prompt: String)
            case gptPlace(place: Place)
            case gptLoading(gptPlaces: Int, googlePlaces: Int)
            case gptClear
            
            func hash(into hasher: inout Hasher) {
                switch self{
                case .placeType(let placeType, let selected):
                    hasher.combine("\(placeType.name)\(placeType.id)\(selected)")
                case .viewModeSelector:
                    hasher.combine("viewModeSelector")
                case .sortMethodSelector:
                    hasher.combine("sortMethodSelector")
                case .filtersSelector:
                    hasher.combine("filtersSelector")
                case .askAISelector:
                    hasher.combine("askAISelector")
                case .mapSelector:
                    hasher.combine("mapSelector")
                case .placeBox(let place):
                    hasher.combine("\(place.name)\(place.id)\(place.fsqID ?? "")")
                case .placeDetail(let place):
                    hasher.combine("\(place.name)\(place.id)\(place.fsqID ?? "")")
                case .placeList(let place):
                    hasher.combine("\(place.name)\(place.id)\(place.fsqID ?? "")")
                case .rankedList(let place):
                    hasher.combine("\(place.name)\(place.id)\(place.fsqID ?? "")")
                case .placeSearchList(let place):
                    hasher.combine("\(place.name)\(place.id)\(place.fsqID ?? "")")
                case .placeSearchListApple(let place):
                    hasher.combine("\(place.placemark.name ?? "")\(place.name ?? "")")
                case .searchAutoCompletionResult(let autoCompletion):
                    hasher.combine("\(autoCompletion.title)\(autoCompletion.subtitle)")
                case .gptPrompt(let prompt):
                    hasher.combine(prompt)
                case .gptPlace(let place):
                    hasher.combine("\(place.name)\(place.id)\(place.fsqID ?? "")")
                case .gptLoading(let gptPlaces, let googlePlaces):
                    hasher.combine("GPTLoading\(gptPlaces)\(googlePlaces)")
                case .gptClear:
                    hasher.combine("GPTClear")
                }
            }
            static func == (lhs: ACityCollectionViewController.ViewModel.Item, rhs: ACityCollectionViewController.ViewModel.Item) -> Bool {
                switch (lhs, rhs){
                case (.placeType(let lPlaceType, let lSelected), .placeType(let rPlaceType, let rSelected)):
                    return "\(lPlaceType.name)\(lPlaceType.id)\(lSelected)" == "\(rPlaceType.name)\(rPlaceType.id)\(rSelected)"
                case (.placeBox(let lhs), .placeBox(let rhs)):
                    return "\(lhs.name)\(lhs.id)" == "\(rhs.name)\(rhs.id)"
                case (.placeDetail(let lhs), .placeDetail(let rhs)):
                    return "\(lhs.name)\(lhs.id)" == "\(rhs.name)\(rhs.id)"
                case (.placeList(let lhs), .placeList(let rhs)):
                    return "\(lhs.name)\(lhs.id)" == "\(rhs.name)\(rhs.id)"
                case (.rankedList(let lhs), .rankedList(let rhs)):
                    return "\(lhs.name)\(lhs.id)" == "\(rhs.name)\(rhs.id)"
                case (.placeSearchList(let lhs), .placeSearchList(let rhs)):
                    return "\(lhs.name)\(lhs.id)\(lhs.fsqID ?? "")" == "\(rhs.name)\(rhs.id)\(rhs.fsqID ?? "")"
                case (.placeSearchListApple(let lhs), .placeSearchListApple(let rhs)):
                    return lhs == rhs
                case (.searchAutoCompletionResult(let lhs), .searchAutoCompletionResult(let rhs)):
                    return lhs == rhs
                case (.gptPlace(let lhs), .gptPlace(let rhs)):
                    return "\(lhs.name)\(lhs.id)" == "\(rhs.name)\(rhs.id)"
                default:
                    return false
                }
            }
            static func <(lhs: ACityCollectionViewController.ViewModel.Item, rhs: ACityCollectionViewController.ViewModel.Item) -> Bool {
                switch (lhs, rhs){
                case (.placeBox(let lhsPlace), .placeBox(let rhsPlace)):
                    return lhsPlace.communityVotes > rhsPlace.communityVotes
                case (.placeDetail(let lhsPlace), .placeDetail(let rhsPlace)):
                    return lhsPlace.communityVotes > rhsPlace.communityVotes
                case (.placeList(let lhsPlace), .placeList(let rhsPlace)):
                    return lhsPlace.communityVotes > rhsPlace.communityVotes
                case (.rankedList(let lhsPlace), .rankedList(let rhsPlace)):
                    return lhsPlace.communityVotes > rhsPlace.communityVotes
                case (.placeSearchList(let lhsPlace), .placeSearchList(let rhsPlace)):
                    return lhsPlace.communityVotes > rhsPlace.communityVotes
                case (.gptPlace(let lhsPlace), .gptPlace(let rhsPlace)):
                    return lhsPlace.communityVotes > rhsPlace.communityVotes
                default:
                    return false
                }
            }
        }
    }
    
    // MARK: Model
    struct Model {
        enum SortMethod {
            case popular, location, recent
        }
        var sortMethod: SortMethod = .popular
        
        enum GridOrList {
            case grid, list
        }
        var gridOrList: GridOrList = .grid
        
        //setup sort method as "popular", updated as the user sets the other sort methods. Used by UpdateCollectionView to properly sort.
        enum CurrentMode {
            case curated, filtered, askAI, query
        }
        var currentMode: CurrentMode = .curated
        
        enum AskAICurrentMode {
            case readyToSearch, loading, showingResults
        }
        var askAICurrentMode: AskAICurrentMode = .readyToSearch
        
        enum ViewMode {
            case grid, list, detail
        }
        var viewMode: ViewMode = .grid
        
        enum QueryMode {
            case autoCompletion
            case showingResults
        }
        var queryMode: QueryMode = .showingResults
        
        var sections = [ViewModel.Section]()
        var model: [ViewModel.Section:[ViewModel.Item]] = [:]
        var sectionRanks: [ViewModel.Section:Int] = [.placeTypes:1000000]
        
        var placeTypes = [PlaceType]()
        var selectedPlaceType: PlaceType?
        var filteredPlaceTypes = [PlaceType]()
        
        var places = [ConciergePlace]()
        var filteredPlaces = [ConciergePlace]()
        
        var contextMenuIsFSQ = false
        var contextMenuPlace: Place?
        
        var locValue: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        var locDenied = false
        var locCounter = 0
        let locationManager = CLLocationManager()
        
        let group = DispatchGroup()
        
        var lovedListFull = false
        
        var categories: [Genre]?
        var neighborhoods: [Neighborhood]?
        var tags: [PlaceTag]?
        
        var selectedCategory: Genre?
        var selectedNeighborhood: Neighborhood?
        var selectedTags: [PlaceTag]?
        var selectedTagIndexes = Set<Int>()
        var selectedTagPlaceIDs: [Int]?
    }
    struct FSQModel {
        var fsqPlaces = [FSQPlace]()
        var fsqIDs: [String] = []
        var fsqLovedPlaces: [FSQPlace] = []
    }
    struct AppleMapKitModel {
        var selectedPlace: MKMapItem?
        var applePlaces = [MKMapItem]()
        
        var searchCompleter = MKLocalSearchCompleter()
        var autoCompletionResults = [MKLocalSearchCompletion]()
        
        var localSearch: MKLocalSearch? {
            willSet {
                // Clear the results and cancel the currently running local search before starting a new search.
                applePlaces = []
                localSearch?.cancel()
            }
        }
        
        var searchRegion: MKCoordinateRegion = MKCoordinateRegion(MKMapRect.world)
    }
    struct GoogleMapsModel {
        var googlePlaces: [GooglePlace] = []
        var googlyIDs: [String] = []
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
    }
    
    var dataSource: DataSourceType!
    var model = Model()
    var fsqModel = FSQModel()
    var appleMapKitModel = AppleMapKitModel()
    var googleMapsModel = GoogleMapsModel()
    var gptModel = GPTModel()
    
    var placeTypesRequestTask: Task<Void, Never>? = nil
    var getPlacesRequestTask: Task<Void, Never>? = nil
    var neighborhoodsRequestTask: Task<Void, Never>? = nil
    var genresRequestTask: Task<Void, Never>? = nil
    var fsqPlacesRequestTask: Task<Void, Never>? = nil
    var googlePlacesRequestTask: Task<Void,Never>? = nil
    var tagsRequestTask: Task<Void, Never>? = nil
    var openAIRequestTask: Task<Void, Never>? = nil
    deinit {
        placeTypesRequestTask?.cancel()
        getPlacesRequestTask?.cancel()
        neighborhoodsRequestTask?.cancel()
        genresRequestTask?.cancel()
        fsqPlacesRequestTask?.cancel()
        googlePlacesRequestTask?.cancel()
        tagsRequestTask?.cancel()
        openAIRequestTask?.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPage()
        collectionView.collectionViewLayout = createLayout()
        dataSource = createDataSource()
        collectionView.dataSource = dataSource
    }
    override func viewDidAppear(_ animated: Bool) {
        updateCollectionView()
        super.viewDidAppear(animated)
    }
    
    func setupPage() {
        if UserDefaults.standard.bool(forKey: "loggedIn") && currentUser.email != "GuestUser" {
            let currentUserID = currentUser.id
            UserDefaultFunctions().getUserLovedPlaces(currentUserID: currentUserID)
            getUserLoc()
        }
        getCity()
        getPlaceTypes()
        getNeighborhoods()
        getCategories()
        getTags()
        getSuggestedGPTPrompts()
        updateProfPic()
        
        navigationItem.searchController = searchController
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.hidesSearchBarWhenScrolling = true
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        
        model.locationManager.delegate = self
        model.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        
        appleMapKitModel.searchRegion = MKCoordinateRegion(MKMapRect(origin: MKMapPoint(CLLocationCoordinate2D(latitude: city.latitude, longitude: city.longitude)), size: MKMapSize(width: 1000.0, height: 1000.0)))
        appleMapKitModel.searchCompleter.delegate = self
        
        let role = currentUser.role
        if role != "Noob" {
            //tabBarController?.viewControllers?.insert(NewPlaceTab, at: 1)
        } else {
            if tabBarController?.viewControllers?.endIndex == 4 {
                tabBarController?.viewControllers?.remove(at: 2)
            }
        }
        
        collectionView.register(SectionBackgroundCollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.ElementKind.background, withReuseIdentifier: "SectionBackground")
        collectionView.register(NamedSectionHeaderView.self, forSupplementaryViewOfKind: "SectionHeader", withReuseIdentifier: "HeaderView")
        userLovedPlacesGroup.notify(queue: .main) {
            self.updateCollectionView()
            self.model.group.notify(queue: .main) {
                self.getFSQLovedPlaces()
            }
        }
        update()
    }
    
    func getCity() {
        let cityGetter = CityGetter()
        let cityID = UserDefaults.standard.integer(forKey: "userBaseCity")
        if city.cityID != -1 {
        } else if cityID != 0 && cityID != -1 {
            let cities = cityGetter.returnCities()
            for c in cities {
                if c.cityID == cityID {
                    city = c
                }
            }
        } else if let baseCity = cityGetter.getUserBaseCity() {
            city = baseCity
            UserDefaults.standard.set(city.cityID, forKey: "userBaseCity")
        } else if currentUser.latitude != 0.0 {
            city = cityGetter.getClosestCity(user: currentUser) ?? defaultCity
            if city.cityID == -1 {
                performSegue(withIdentifier: "SelectCity", sender: nil)
            }
            UserDefaults.standard.set(city.cityID, forKey: "userBaseCity")
        } else {
            performSegue(withIdentifier: "SelectCity", sender: nil)
        }
        self.navigationItem.title = city.name
    }
    
    func getPlaceTypes() {
        model.group.enter()
        placeTypesRequestTask?.cancel()
        placeTypesRequestTask = Task {
            if let placeTypes = try? await PlaceTypesByCityRequest(cityID: city.cityID).send() {
                model.placeTypes = placeTypes.sorted()
                if model.selectedPlaceType == nil {
                    model.selectedPlaceType = model.placeTypes[0]
                }
                updateCollectionView()
            } else {
                model.placeTypes = [PlaceType(id: 1, name: "Restaurants", iconName: "fork.knife", clicked: 219, fsqCategoryCode: "13068,13236,13099,13303,13199,13276,13272,13352,13377,13040,13030,13383,13095,13289,13302,13338,13064,13334,13001,13137,13141,13332,13054,13052,13345,13148,13134,13026,13294,13027,13039,13049,13057,13388,13030,13145,13165,13135,13191,13314,13177,13144,13055,13058,13342,13381"), PlaceType(id: 2, name: "Cafes", iconName: "cup.and.saucer", clicked: 221, fsqCategoryCode: "13034,17063,13016"), PlaceType(id: 8, name: "Pubs", iconName: "spigot", clicked: 65, fsqCategoryCode: "13018,13006,13010,13015,13022,13023,13389,10045")]
                if model.selectedPlaceType == nil {
                    model.selectedPlaceType = model.placeTypes[0]
                }
                updateCollectionView()
            }
            if let placeTypes = try? await AllPlaceTypesRequest().send() {
                for placeType in placeTypes {
                    allPlaceTypes[placeType.id] = placeType
                }
            }
            model.group.leave()
            placeTypesRequestTask = nil
        }
    }
    
    func getNeighborhoods() {
        neighborhoodsRequestTask?.cancel()
        neighborhoodsRequestTask = Task {
            model.neighborhoods = []
            if let neighborhoods = try? await NeighborhoodRequest(cityID: city.cityID).send() {
                for neighborhood in neighborhoods {
                    self.model.neighborhoods?.append(neighborhood)
                }
            } else {
                model.neighborhoods = []
            }
            neighborhoodsRequestTask = nil
        }
    }
    
    func getCategories() {
        genresRequestTask?.cancel()
        genresRequestTask = Task {
            model.categories = []
            if let categories = try? await GenreRequest(placeTypeID: model.selectedPlaceType?.id ?? 1).send() {
                for category in categories {
                    self.model.categories?.append(category)
                }
            } else {
                model.categories = []
            }
            genresRequestTask = nil
        }
    }
    
    func getTags() {
        tagsRequestTask?.cancel()
        tagsRequestTask = Task {
            model.tags = []
            if let tags = try? await CityTagsRequest(cityID: city.cityID).send() {
                for tag in tags {
                    self.model.tags?.append(tag)
                }
            } else {
                model.tags = []
            }
            tagsRequestTask = nil
        }
    }
    
    
    func getSelectedTags(tags: [PlaceTag]) {
        var placeIDs = [Int]()
        
        model.group.enter()  // DispatchGroup enter
        
        // Use Task to perform async work
        tagsRequestTask = Task {
            for tag in tags {
                // Execute async network request
                if let placeTags = try? await GetSelectedTags(tag: tag.tagName, city: city.cityID).send() {
                    for placeTag in placeTags {
                        placeIDs.append(placeTag.placeID)
                    }
                }
            }
            
            model.selectedTagPlaceIDs = placeIDs
            model.group.leave()  // DispatchGroup leave
            tagsRequestTask = nil
        }
    }
    
    func getUserLoc() {
        model.locationManager.requestWhenInUseAuthorization()
        if let latitude = currentUser.latitude, latitude != 0, let longitude = currentUser.longitude, longitude != 0 {
            model.locValue = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            model.locDenied = false
        }
    }
    
    func getFSQLovedPlaces() {
        fsqPlacesRequestTask = Task {
            for lovedPlace in lovedFSQPlaces {
                let fsqID = lovedPlace.fsqID
                var place: Place?
                if let fsqPlace = try? await getFSQPlaceRequest(fsqID: fsqID).send() {
                    place = fsqPlace.placeify()
                    if let place = place as? FSQPlace {
                        userFSQLovedPlaces.append(place)
                    }
                }
                if lovedPlace.placeTypeID == model.selectedPlaceType?.id && lovedPlace.cityID == city.cityID {
                    if let place = place as? FSQPlace {
                        fsqModel.fsqLovedPlaces.append(place)
                    }
                }
            }
            fsqPlacesRequestTask = nil
            updateCollectionView()
        }
    }
    
    func resetView() {
        model.currentMode = .curated
        model.selectedCategory = nil
        model.selectedNeighborhood = nil
        model.selectedTags = nil
        model.selectedTagIndexes = Set<Int>()
        googleMapsModel.googlePlaces = []
        googleMapsModel.googlyIDs = []
        fsqModel.fsqPlaces = []
        searchController.searchBar.text = ""
        searchController.searchBar.placeholder = "Search"
        searchController.isActive = false
        gptModel.suggestedPrompts = []
        gptModel.gptPlaces = []
        gptModel.gptGooglePlaces = []
        gptModel.askAIMode = .suggestingPrompts
    }
    
    func resetAskAIView() {
        gptModel.suggestedPrompts = []
        gptModel.gptPlaces = []
        gptModel.gptGooglePlaces = []
        openAIRequestTask?.cancel()
        openAIRequestTask = nil
        googlePlacesRequestTask?.cancel()
        googlePlacesRequestTask = nil
        getSuggestedGPTPrompts()
        gptModel.askAIMode = .suggestingPrompts
    }
    
    func deallocateMem() {
        
    }
    
    func update() {
        getPlacesRequestTask?.cancel()
        getPlacesRequestTask = Task {
            if let places = try? await GetPlacesRequest(cityID: city.cityID, placeTypeID: model.selectedPlaceType?.id ?? 1).send() {
                model.places = places
                model.filteredPlaces = places
            } else {
                model.places = []
                model.filteredPlaces = []
            }
            DispatchQueue.main.async {
                UIView.transition(with: self.view, duration: 0.4, options: .showHideTransitionViews, animations: { () -> Void in
                    self.updateCollectionView()
                }, completion: nil)
            }
            getPlacesRequestTask = nil
        }
    }
    
    func updateCollectionView() {
        if let itemsBySection = createItemsBySection() {
            model.model = itemsBySection
            self.dataSource.applySnapshotUsing(sectionIDs: self.model.sections, itemsBySection: itemsBySection)
        }
    }
    
    // MARK: Create Data Source
    func createDataSource() -> DataSourceType {
        //use DataSourceType closure provided by UICollectionViewDiffableDataSource class to setup each collectionViewCell
        navigationItem.title = city.name
        let dataSource = DataSourceType(collectionView: collectionView) { (collectionView, indexPath, item) in
            switch item {
            case .placeType(let placeType, let selected):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlaceType", for: indexPath) as! PlaceTypeCollectionViewCell
                
                cell.placeTypeName.text = placeType.name
                cell.iconImg.image = UIImage(systemName: placeType.iconName)
                cell.placeType = placeType
                
                cell.selectedPlaceTypeBar.layer.shadowColor = UIColor.gray.cgColor
                cell.selectedPlaceTypeBar.layer.shadowOffset = CGSize(width: 0.0, height: 0.5)
                cell.selectedPlaceTypeBar.layer.shadowOpacity = 0.5
                
                if selected {
                    cell.selectedPlaceTypeBar.backgroundColor = .black
                    //cell.placeTypeName.font = UIFont(name: "Apple SD Gothic Neo Bold", size: 18)
                } else {
                    cell.selectedPlaceTypeBar.backgroundColor = .white
                    //cell.placeTypeName.font = UIFont(name: "Apple SD Gothic Neo Normal", size: 18)
                }
                return cell
            case .viewModeSelector:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ViewModeSelector", for: indexPath) as! ViewModeSelectorCollectionViewCell
                
                switch self.model.viewMode {
                case .grid:
                    cell.iconImg.image = UIImage(systemName: "circle.grid.3x3")
                    cell.viewModeLabel.text = "Grid"
                case .detail:
                    cell.iconImg.image = UIImage(systemName: "doc.richtext")
                    cell.viewModeLabel.text = "Detail"
                case .list:
                    cell.iconImg.image = UIImage(systemName: "list.number")
                    cell.viewModeLabel.text = "List"
                }
                return cell
            case .sortMethodSelector:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SortMethodSelector", for: indexPath) as! SortMethodSelectorCollectionViewCell
                switch self.model.sortMethod {
                case .popular:
                    cell.iconImg.image = UIImage(systemName: "square.3.layers.3d.top.filled")
                    cell.sortMethodLabel.text = "Popular"
                case .location:
                    cell.iconImg.image = UIImage(systemName: "square.3.layers.3d.middle.filled")
                    cell.sortMethodLabel.text = "Location"
                case .recent:
                    cell.iconImg.image = UIImage(systemName: "square.3.layers.3d.bottom.filled")
                    cell.sortMethodLabel.text = "Recent"
                }
                return cell
            case .filtersSelector(let selectedFilters):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FiltersSelector", for: indexPath) as! FiltersSelectorCollectionViewCell
                if selectedFilters > 0 {
                    cell.layer.cornerRadius = 8.0 // Optional: Add corner radius for rounded corners
                    cell.layer.shadowColor = UIColor.darkGray.cgColor
                    cell.backgroundColor = UIColor.blue.withAlphaComponent(0.05)
                    cell.selectedIndicator.isHidden = false
                    cell.selectedIndicator.image = UIImage(systemName: "\(selectedFilters).circle.fill")
                    cell.styleCell()
                } else {
                    cell.backgroundColor = UIColor.clear
                    cell.selectedIndicator.isHidden = true
                }
                return cell
            case .askAISelector:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AskAISelector", for: indexPath) as! AskAISelectorCollectionViewCell
                if self.model.currentMode == .askAI {
                    cell.AskAISelectorLabel.textColor = .link
                } else {
                    cell.AskAISelectorLabel.textColor = .black
                }
                return cell
            case .mapSelector:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MapSelector", for: indexPath) as! MapSelectorCollectionViewCell
                return cell
            case .placeBox(let place):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlaceBox", for: indexPath) as! PlaceBoxCollectionViewCell
                //Place object stored in each instance of ViewModel.Item and can be used to configure the cell
                cell.place = place
                cell.placeTypeID = self.model.selectedPlaceType?.id
                cell.cityID = self.city.cityID
                
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
                let (distance, fromWho) = self.distanceFromYou(place: place)
                cell.milesFromUserLabel.text = "\(String(format: "%.0f", distance)) mi (\(fromWho))"
                
                cell.delegate = self
                
                //return cell for each item
                return cell
            case .placeDetail(let place):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlaceDetail", for: indexPath) as! PlaceDetailCollectionViewCell
                //Place object stored in each instance of ViewModel.Item and can be used to configure the cell
                cell.place = place
                cell.placeTypeID = self.model.selectedPlaceType?.id
                cell.cityID = self.city.cityID
                
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
            case .placeList(let place):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LovedPlace", for: indexPath) as! LovedPlaceCollectionViewCell
                //Place object stored in each instance of ViewModel.Item and can be used to configure the cell
                cell.place = place
                cell.placeTypeID = self.model.selectedPlaceType?.id
                cell.cityID = self.city.cityID
                
                //fetch image with cells fetchImage function
                //activity indicator stopped once the image is returned
                cell.imageRequestTask?.cancel()
                cell.imageRequestTask = nil
                cell.placePic.image = nil
                cell.descriptionLabel.text = "\(place.genre) - \(place.neighborhood)"
                
                cell.fetchImage(imageURL: place.imageURL)
                
                cell.placeNameLabel.text = place.name
                
                cell.delegate = self
                
                //return cell for each item
                return cell
            case .rankedList(let place):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RankedPlace", for: indexPath) as! RankedPlaceCollectionViewCell
                //Place object stored in each instance of ViewModel.Item and can be used to configure the cell
                cell.place = place
                cell.placeTypeID = self.model.selectedPlaceType?.id
                cell.cityID = self.city.cityID
                
                //fetch image with cells fetchImage function
                //activity indicator stopped once the image is returned
                cell.imageRequestTask?.cancel()
                cell.imageRequestTask = nil
                cell.placePic.image = nil
                
                cell.fetchImage(imageURL: place.imageURL)
                
                //image task will take time so animate an activity indicator to show activity in progress
                cell.placeNameLabel.text = place.name
                cell.neiCatLabel.text = "\(place.genre) - \(place.neighborhood)"
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
                cell.rankLabel.text = "\(indexPath.item+1)"
                
                cell.delegate = self
                
                //return cell for each item
                return cell
            case .placeSearchList(let place):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SearchedPlace", for: indexPath) as! PlaceSearchCollectionViewCell
                //Place object stored in each instance of ViewModel.Item and can be used to configure the cell
                cell.place = place
                cell.placeTypeID = self.model.selectedPlaceType?.id
                cell.cityID = self.city.cityID
                
                //fetch image with cells fetchImage function
                //activity indicator stopped once the image is returned
                cell.imageRequestTask?.cancel()
                cell.imageRequestTask = nil
                cell.placePic.image = nil
                
                cell.fetchImage(imageURL: place.imageURL)
                
                //image task will take time so animate an activity indicator to show activity in progress
                cell.placeNameLabel.text = place.name
                cell.neiCatLabel.text = "\(place.genre) - \(place.neighborhood)"
                
                cell.delegate = self
                
                //return cell for each item
                return cell
                
            case .placeSearchListApple(let place):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AutoCompletion", for: indexPath) as! SearchAutoCompletionCollectionViewCell
                //Place object stored in each instance of ViewModel.Item and can be used to configure the cell
                
                cell.placeNameLabel.text = place.name
                cell.placeAddressLabel.text = place.placemark.title
                cell.applePlace = place
                cell.cellType = .place
                
                //return cell for each item
                return cell
            case .searchAutoCompletionResult(let autoCompletion):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AutoCompletion", for: indexPath) as! SearchAutoCompletionCollectionViewCell
                cell.placeNameLabel.text = autoCompletion.title
                cell.placeAddressLabel.text = autoCompletion.subtitle
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
            case .gptPlace(let place):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GPTPlace", for: indexPath) as! GPTPlaceCollectionViewCell
                //Place object stored in each instance of ViewModel.Item and can be used to configure the cell
                cell.place = place
                cell.placeTypeID = self.model.selectedPlaceType?.id
                cell.cityID = self.city.cityID
                
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
        
        dataSource.supplementaryViewProvider = { [weak self] (collectionView: UICollectionView, kind: String, indexPath: IndexPath) -> UICollectionReusableView? in
            // Make sure self is available; otherwise, return nil.
            guard let self = self else { return nil }
            
            if kind == UICollectionView.ElementKind.background {
                if let background = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "SectionBackground", for: indexPath) as? SectionBackgroundCollectionReusableView {
                    return background
                }
            } else if kind == "SectionHeader" {
                if let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "HeaderView", for: indexPath) as? NamedSectionHeaderView {
                    let section = dataSource.snapshot().sectionIdentifiers[indexPath.section]
                    switch section {
                    case .placeBox(let headerText, let sectionType, let full, _):
                        header.nameLabel.textColor = .darkText
                        header.nameLabel.font = UIFont.preferredFont(forTextStyle: .headline)
                        header.backgroundColor = .white
                        switch sectionType {
                        case .neighborhood:
                            header.nameLabel.text = "The best of \(headerText)"
                        default:
                            header.nameLabel.text = headerText
                        }
                        header.delegate = self
                        header.actionButton.isHidden = !full
                    case .placeDetail(let headerText, let sectionType, let full, _):
                        header.nameLabel.textColor = .darkText
                        header.nameLabel.font = UIFont.preferredFont(forTextStyle: .headline)
                        header.backgroundColor = .white
                        switch sectionType {
                        case .neighborhood:
                            header.nameLabel.text = "The best of \(headerText)"
                        default:
                            header.nameLabel.text = headerText
                        }
                        header.delegate = self
                        header.actionButton.isHidden = !full
                    case .userLovedList(let full):
                        header.nameLabel.textColor = .darkText
                        header.nameLabel.font = UIFont.preferredFont(forTextStyle: .headline)
                        header.backgroundColor = .white
                        header.nameLabel.text = "That You've Loved ❤️"
                        header.delegate = self
                        header.actionButton.isHidden = !full
                    case .placeSearchList(src: .concierge):
                        header.nameLabel.text = "Consierge Results"
                        header.actionButton.isHidden = true
                    case .placeSearchList(src: .fsq):
                        header.nameLabel.text = "Foursquare Results"
                        header.actionButton.isHidden = true
                    case .placeSearchList(src: .google):
                        header.nameLabel.text = "Google Maps Results"
                        header.actionButton.isHidden = true
                    case .placeSearchList(src: .apple):
                        header.nameLabel.text = "Apple Maps Results"
                        header.actionButton.isHidden = true
                    default:
                        return nil
                    }
                    return header
                }
            }
            return nil
        }
        
        return dataSource
    }
    
    func createLayout() -> UICollectionViewCompositionalLayout {
        
        let layout = UICollectionViewCompositionalLayout { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            let section = self.model.sections[sectionIndex]
            switch section {
            case .placeTypes:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.28), heightDimension: .absolute(40))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.28), heightDimension: .absolute(40))
                
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 2, bottom: 10, trailing: 0)
                section.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary

                return section
            case .filtersAndSort:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.96), heightDimension: .absolute(38))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                var groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(38))
                var group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                switch self.model.currentMode {
                case .askAI:
                    break
                default:
                    let itemSize1 = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.24), heightDimension: .absolute(38))
                    let item1 = NSCollectionLayoutItem(layoutSize: itemSize1)
                    
                    let itemSize2 = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.24), heightDimension: .absolute(38))
                    let item2 = NSCollectionLayoutItem(layoutSize: itemSize2)
                    
                    let itemSize3 = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.24), heightDimension: .absolute(38))
                    let item3 = NSCollectionLayoutItem(layoutSize: itemSize3)
                    
                    let itemSize4 = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.24), heightDimension: .absolute(38))
                    let item4 = NSCollectionLayoutItem(layoutSize: itemSize4)
                    
                    groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(38))
                    group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item1, item2, item3, item4])
                }
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 4, bottom: 8, trailing: 4)
                
                let sectionBackground = NSCollectionLayoutDecorationItem.background( elementKind: UICollectionView.ElementKind.background)
                section.decorationItems = [sectionBackground]
                
                return section
            case .placeBox:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalWidth(1))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(150), heightDimension: .absolute(150))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 8)
                
                let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(24))
                let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: "SectionHeader", alignment: .top)
                sectionHeader.pinToVisibleBounds = true
                
                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
                section.boundarySupplementaryItems = [sectionHeader]
                
                return section
                
            case .placeDetail:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(142))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 3, leading: 0, bottom: 0, trailing: 0)

                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.92), heightDimension: .absolute(142))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 8)

                // Set the count to 3 to display three cells side by side
                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
                
                let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(24))
                let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: "SectionHeader", alignment: .top)
                sectionHeader.pinToVisibleBounds = true
                section.boundarySupplementaryItems = [sectionHeader]

                return section

            case .userLovedList:
                let (numItems, height) = self.getUserLovedListHeight()
                
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(height))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 0, trailing: 0)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.55), heightDimension: .absolute(height))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitem: item, count: numItems)
                
                let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(24))
                let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: "SectionHeader", alignment: .top)
                sectionHeader.pinToVisibleBounds = true
                
                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .groupPaging
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 7, trailing: 0)
                section.boundarySupplementaryItems = [sectionHeader]
                
                return section
            case .rankedList:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(75))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 3, leading: 5, bottom: 2, trailing: 5)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(75))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 7, trailing: 0)
                
                return section
            case .placeSearchList:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(60))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 5, bottom: 3, trailing: 5)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(60))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0)
                
                let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(24))
                let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: "SectionHeader", alignment: .top)
                sectionHeader.pinToVisibleBounds = true
                section.boundarySupplementaryItems = [sectionHeader]
                
                return section
            case .searchAutoCompletionResults:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(60))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 5, bottom: 3, trailing: 5)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(60))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0)
                
                return section
            case .gptPrompts:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(60))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 5, bottom: 6, trailing: 5)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(60))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10)
                
                return section
            case .gptPlace:
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
                section.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0)
                
                return section
            }
        }
        layout.register(SectionBackgroundCollectionReusableView.self, forDecorationViewOfKind: UICollectionView.ElementKind.background)
        return layout
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            if model.currentMode == .query && model.queryMode == .autoCompletion {
                guard let cell = collectionView.cellForItem(at: indexPath) as? SearchAutoCompletionCollectionViewCell else { return }
                let placeNameText = cell.placeNameLabel.text
                var subtitleText = cell.placeAddressLabel.text
                if subtitleText == "Search Nearby" {
                    subtitleText = city.name
                }
                search(for: "\(placeNameText ?? "") \(subtitleText ?? "")", alt: placeNameText ?? "")
            } else if model.currentMode == .query && model.queryMode == .showingResults && model.filteredPlaceTypes.count == 0 {
                // Place clicked
            } else {
                guard let selectedCell = collectionView.cellForItem(at: indexPath) as? PlaceTypeCollectionViewCell, let selectPlaceType = selectedCell.placeType else {return}
                model.selectedPlaceType = selectPlaceType
                resetView()
                fsqModel.fsqPlaces = []
                getCategories()
                Task {
                    guard let selectedPlaceType = model.selectedPlaceType else {return}
                    let _ = try? await PlaceTypeClickedRequest(placeTypeID: selectedPlaceType.id).send()
                }
                update()
            }
        case 1:
            
            if let _ = collectionView.cellForItem(at: indexPath) as? ViewModeSelectorCollectionViewCell {
                switch model.viewMode {
                case .grid:
                    model.viewMode = .detail
                case .detail:
                    model.viewMode = .list
                case .list:
                    model.viewMode = .grid
                }
            } else if let _ = collectionView.cellForItem(at: indexPath) as? SortMethodSelectorCollectionViewCell {
                switch model.sortMethod {
                case .popular:
                    model.sortMethod = .location
                case .location:
                    model.sortMethod = .recent
                case .recent:
                    model.sortMethod = .popular
                }
            } else if let _ = collectionView.cellForItem(at: indexPath) as? AskAISelectorCollectionViewCell {
                switch model.currentMode {
                case .askAI:
                    resetView()
                default:
                    model.currentMode = .askAI
                    getSuggestedGPTPrompts()
                }
            }
            
            UIView.transition(with: view, duration: 0.4, options: .showHideTransitionViews, animations: { [weak self] () -> Void in
                self?.updateCollectionView()
            }, completion: nil)
        default:
            break
        }
        
        if let cell = collectionView.cellForItem(at: indexPath) as? SearchAutoCompletionCollectionViewCell, cell.cellType == .place {
            performSegue(withIdentifier: "ApplePlaceClicked", sender: cell)
        }
        
        if let cell = collectionView.cellForItem(at: indexPath) as? GPTPromptCollectionViewCell, let prompt = cell.prompt {
            print(("gpt prompt clicked"))
            submitGPTPrompt(prompt: prompt)
        }
    }
    
    
    @IBSegueAction func placeBoxSelected(_ coder: NSCoder, sender: UICollectionViewCell?) -> UICollectionViewController? {
        guard let cell = sender as? PlaceBoxCollectionViewCell, let place = cell.place, let img = cell.placePic.image, let indexPath = collectionView.indexPath(for: cell), let section = dataSource.sectionIdentifier(for: indexPath.section) else {return nil}
        return placeSelected(place: place, img: img, sec: section, coder: coder)
    }
    @IBSegueAction func lovedPlaceSelected(_ coder: NSCoder, sender: UICollectionViewCell?) -> UICollectionViewController? {
        guard let cell = sender as? LovedPlaceCollectionViewCell, let place = cell.place, let img = cell.placePic.image, let indexPath = collectionView.indexPath(for: cell), let section = dataSource.sectionIdentifier(for: indexPath.section) else {return nil}
        return placeSelected(place: place, img: img, sec: section, coder: coder)
    }
    @IBSegueAction func placeDetailSelected(_ coder: NSCoder, sender: UICollectionViewCell?) -> UICollectionViewController? {
        guard let cell = sender as? PlaceDetailCollectionViewCell, let place = cell.place, let img = cell.placePic.image, let indexPath = collectionView.indexPath(for: cell), let section = dataSource.sectionIdentifier(for: indexPath.section) else {return nil}
        return placeSelected(place: place, img: img, sec: section, coder: coder)
    }
    @IBSegueAction func rankedPlaceSelected(_ coder: NSCoder, sender: UICollectionViewCell?) -> UICollectionViewController? {
        guard let cell = sender as? RankedPlaceCollectionViewCell, let place = cell.place, let img = cell.placePic.image, let indexPath = collectionView.indexPath(for: cell), let section = dataSource.sectionIdentifier(for: indexPath.section) else {return nil}
        return placeSelected(place: place, img: img, sec: section, coder: coder)
    }
    @IBSegueAction func searchedPlaceSelected(_ coder: NSCoder, sender: UICollectionViewCell?) -> UICollectionViewController? {
        guard let cell = sender as? PlaceSearchCollectionViewCell, let place = cell.place, let img = cell.placePic.image, let indexPath = collectionView.indexPath(for: cell), let section = dataSource.sectionIdentifier(for: indexPath.section) else {return nil}
        return placeSelected(place: place, img: img, sec: section, coder: coder)
    }
    
    @IBSegueAction func applePlaceSelected(_ coder: NSCoder, sender: Any?) -> ApplePlaceViewController? {
        
        guard let cell = sender as? SearchAutoCompletionCollectionViewCell, let place = cell.applePlace else {return nil}
        
        return ApplePlaceViewController(coder: coder, place: place)
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
            case .placeList(let place), .placeBox(let place), .placeDetail(let place), .rankedList(let place), .placeSearchList(let place), .gptPlace(let place):
                places.append(place)
            default:
                break
            }
        })
        
        //return DetailVC
        return PlaceDetailCollectionViewController(coder: coder, place: place, sectionsPlaces: places, placePic: img, placeTypeID: model.selectedPlaceType?.id)
    }
    
    @IBAction func unwindFromCitySelector(_ segue: UIStoryboardSegue) {
        if let sourceVC = segue.source as? CitySelectorCollectionViewController {
            city = sourceVC.selectedCity ?? defaultCity
            navigationItem.title = city.name
            getPlaceTypes()
            getNeighborhoods()
            update()
            deallocateMem()
            resetView()
            model.group.notify(queue: .main) {
                guard let selectedPlaceType = self.model.selectedPlaceType else {return}
                if !self.model.placeTypes.contains(selectedPlaceType) {
                    if !self.model.placeTypes.isEmpty {
                        self.model.selectedPlaceType = self.model.placeTypes[0]
                        self.update()
                    }
                }
            }
        }
    }
    
    @IBAction func unwindFromFilters(segue: UIStoryboardSegue) {
        if !filters.isEmpty {
            model.currentMode = .filtered
            getFSQPlaces()
        } else {
            model.currentMode = .curated
            model.filteredPlaces = model.places
            updateCollectionView()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SelectFilters" {
            let navController = segue.destination as! UINavigationController
            let filtersACityVC = navController.topViewController as! FiltersACityCollectionViewController
            filtersACityVC.categories = model.categories ?? []
            filtersACityVC.neighborhoods = model.neighborhoods ?? []
            filtersACityVC.tags = model.tags ?? []
            filtersACityVC.selectedNeighborhood = model.selectedNeighborhood
            filtersACityVC.selectedCategory = model.selectedCategory
            filtersACityVC.selectedTags = model.selectedTags ?? []
            filtersACityVC.selectedTagIndexes = model.selectedTagIndexes
        } else if segue.identifier == "ViewMap" {
            let mapViewController = segue.destination as! MapViewController
            switch model.currentMode {
            case .askAI:
                mapViewController.places = gptModel.gptGooglePlaces
            default:
                mapViewController.places = model.filteredPlaces + fsqModel.fsqPlaces + fsqModel.fsqLovedPlaces
            }
        }
    }
}

extension ACityCollectionViewController {
    func createItemsBySection() -> [ViewModel.Section:[ViewModel.Item]]? {
        var itemsBySection: [ViewModel.Section:[ViewModel.Item]]?
        
        switch model.currentMode {
        case .curated:
            itemsBySection = createCuratedItemsBySection()
        case .filtered:
            model.model = createCuratedItemsBySection() ?? [:]
            itemsBySection = createFilteredItemsBySection()
        case .query:
            switch model.queryMode {
            case .autoCompletion:
                itemsBySection = createSearchAutoCompletionItemsBySection()
            case .showingResults:
                itemsBySection = createQueryItemsBySection()
            }
        case .askAI:
            itemsBySection = createAskAIItemsBySection()
        }
        
        guard var itemsBySection = itemsBySection else {return nil}
        model.sections = itemsBySection.keys.sorted { lhs, rhs in
            if model.sectionRanks[lhs] ?? 0 != model.sectionRanks[rhs] ?? 0 {
                return model.sectionRanks[lhs] ?? 0 > model.sectionRanks[rhs] ?? 0
            } else {
                //if there's a tie settle it alphabetically
                return lhs < rhs
            }
        }
        
        //extract Items/places from each section and sort the places/Items within the section
        for sectionA in model.sections {
            var placesArray = itemsBySection[sectionA]
            placesArray = placesArray?.sorted(by: { lhs, rhs in
                switch (lhs, rhs){
                case (.placeBox(let lhsPlace), .placeBox(let rhsPlace)):
                    switch model.sortMethod {
                    case .popular:
                        return lhsPlace.communityVotes > rhsPlace.communityVotes
                    case .location:
                        return returnDistanceScore(place: lhsPlace) > returnDistanceScore(place: rhsPlace)
                    case .recent:
                        return lhsPlace.id > rhsPlace.id
                    }
                case (.placeDetail(let lhsPlace), .placeDetail(let rhsPlace)):
                    switch model.sortMethod {
                    case .popular:
                        return lhsPlace.communityVotes > rhsPlace.communityVotes
                    case .location:
                        return returnDistanceScore(place: lhsPlace) > returnDistanceScore(place: rhsPlace)
                    case .recent:
                        return lhsPlace.id > rhsPlace.id
                    }
                case (.placeList(let lhsPlace), .placeList(let rhsPlace)):
                    let lhsIndex = userLovedPlaces.firstIndex { "\($0.name) \($0.fsqID ?? "") \($0.id)" == "\(lhsPlace.name) \(lhsPlace.fsqID ?? "") \(lhsPlace.id)" } ?? 100000
                    let rhsIndex = userLovedPlaces.firstIndex { "\($0.name) \($0.fsqID ?? "") \($0.id)" == "\(rhsPlace.name) \(rhsPlace.fsqID ?? "") \(rhsPlace.id)" } ?? 100000
                    if lhsIndex == rhsIndex {
                        return lhsPlace.communityVotes > rhsPlace.communityVotes
                    } else {
                        return lhsIndex < rhsIndex
                    }
                case (.gptPlace(let lhsPlace), .gptPlace(let rhsPlace)):
                    switch model.sortMethod {
                    case .popular:
                        return lhsPlace.communityVotes > rhsPlace.communityVotes
                    case .location:
                        return returnDistanceScore(place: lhsPlace) > returnDistanceScore(place: rhsPlace)
                    case .recent:
                        return lhsPlace.id > rhsPlace.id
                    }
                default:
                    return false
                }
            })
            itemsBySection[sectionA] = placesArray
        }
                                                    
        return itemsBySection
    }
    
    func createCuratedItemsBySection() -> [ViewModel.Section:[ViewModel.Item]]? {
        var numSelectedFilters = 0
        if model.selectedNeighborhood != nil { numSelectedFilters += 1 }
        if model.selectedCategory != nil { numSelectedFilters += 1 }
        if model.selectedTags != nil { numSelectedFilters += 1 }
        let filtersItem: ViewModel.Item = .filtersSelector(selectedFilters: numSelectedFilters)
        
        var itemsBySection: [ViewModel.Section:[ViewModel.Item]] = [.filtersAndSort:[.viewModeSelector, .sortMethodSelector, filtersItem, .askAISelector]]
        var placeTypeItems: [ViewModel.Item] = []
        for placeType in model.placeTypes {
            if placeType == model.selectedPlaceType {
                placeTypeItems.append(.placeType(placeType, selected: true))
            } else {
                placeTypeItems.append(.placeType(placeType, selected: false))
            }
        }
        if !placeTypeItems.isEmpty {
            itemsBySection[.placeTypes] = placeTypeItems
            model.sectionRanks[.filtersAndSort] = 250000
        } else {
            return nil
        }
        
        for place in model.filteredPlaces {
            let placeLoved = userLovedPlaces.contains { thisPlace in
                "\(thisPlace.name)\(thisPlace.id)\(thisPlace.fsqID ?? "")" == "\(place.name)\(place.id)\(place.fsqID ?? "")"
            }
            switch (placeLoved, model.viewMode) {
            case (true, .detail), (true, .grid):
                if var placesArray = itemsBySection[.userLovedList(full: false)] {
                    //if that section contains less than 10 item
                    placesArray.append(.placeList(place: place))
                    if placesArray.count < 8 {
                        itemsBySection[.userLovedList(full: false)] = placesArray
                    } else {
                        itemsBySection.removeValue(forKey: .userLovedList(full: false))
                        itemsBySection[.userLovedList(full: true)] = placesArray
                    }
                } else if var _  = itemsBySection[.userLovedList(full: true)]{
                    print("section is full")
                } else {
                    itemsBySection[.userLovedList(full: false)] = [.placeList(place: place)]
                    model.sectionRanks[.userLovedList(full: false)] = 100000
                }
            case (_, .list):
                if var placesArray = itemsBySection[.rankedList] {
                    //if that section contains less than 10 item
                    placesArray.append(.rankedList(place: place))
                    if placesArray.count < 8 {
                        itemsBySection[.rankedList] = placesArray
                    } else {
                        itemsBySection.removeValue(forKey: .userLovedList(full: false))
                        itemsBySection[.rankedList] = placesArray
                    }
                } else {
                    itemsBySection[.rankedList] = [.rankedList(place: place)]
                    model.sectionRanks[.rankedList] = 100000
                }
            case (false, .detail):
                if var placesArray = itemsBySection[.placeDetail(headerText: place.neighborhood, sectionType: .neighborhood, full: false)], placesArray.isEmpty != true {
                    //if that section contains less than 10 items
                    if placesArray.count < 4 {
                        //then add the current place
                        placesArray.append(.placeDetail(place: place))
                        itemsBySection[.placeDetail(headerText: (place.neighborhood), sectionType: .neighborhood, full: false)] = placesArray
                        // and add communityLoves value to that section's rank
                        switch model.sortMethod {
                        case .recent:
                            model.sectionRanks[.placeDetail(headerText: place.neighborhood, sectionType: .neighborhood, full: false)]! += place.id
                        case .location:
                            model.sectionRanks[.placeDetail(headerText: place.neighborhood, sectionType: .neighborhood, full: false)]! += Int(returnDistanceScore(place: place))
                        case .popular:
                            model.sectionRanks[.placeDetail(headerText: place.neighborhood, sectionType: .neighborhood, full: false)]! += place.communityVotes
                        }
                    } else {
                        //if place's genre exists in itemsBySection (only accessed after neighborhood exists and is maxed out)
                        if var placesArray2 = itemsBySection[.placeDetail(headerText: place.genre, sectionType: .category, full: false)] {
                            //if that section contains less than 10 items
                            if placesArray2.count < 4 {
                                //then add the current place
                                placesArray2.append(.placeDetail(place: place))
                                itemsBySection[.placeDetail(headerText: place.genre, sectionType: .category, full: false)] = placesArray2
                                //and add communityVotes value to sectionRank
                                switch model.sortMethod {
                                case .recent:
                                    model.sectionRanks[.placeDetail(headerText: place.genre, sectionType: .category, full: false)]! += place.id
                                case .location:
                                    model.sectionRanks[.placeDetail(headerText: place.genre, sectionType: .category, full: false)]! += Int(returnDistanceScore(place: place))
                                case .popular:
                                    model.sectionRanks[.placeDetail(headerText: place.genre, sectionType: .category, full: false)]! += place.communityVotes
                                }
                            }
                            if placesArray2.count == 4 {
                                itemsBySection.removeValue(forKey: .placeDetail(headerText: place.genre, sectionType: .category, full: false))
                                itemsBySection[.placeDetail(headerText: (place.genre), sectionType: .category, full: true)] = placesArray2
                                switch model.sortMethod {
                                case .recent:
                                    model.sectionRanks[.placeDetail(headerText: place.genre, sectionType: .category, full: true)]! = (model.sectionRanks[.placeDetail(headerText: place.genre, sectionType: .category, full: false)] ?? 0) + place.id
                                case .location:
                                    model.sectionRanks[.placeDetail(headerText: place.genre, sectionType: .category, full: true)]! = (model.sectionRanks[.placeDetail(headerText: place.genre, sectionType: .category, full: false)] ?? 0) + Int(returnDistanceScore(place: place))
                                case .popular:
                                    model.sectionRanks[.placeDetail(headerText: place.genre, sectionType: .category, full: true)]! = (model.sectionRanks[.placeDetail(headerText: place.genre, sectionType: .category, full: false)] ?? 0) + place.communityVotes
                                }
                            }
                        } else {
                            itemsBySection[.placeDetail(headerText: place.genre, sectionType: .category, full: false)] = [.placeBox(place: place)]
                            switch model.sortMethod {
                            case .recent:
                                model.sectionRanks[.placeDetail(headerText: place.genre, sectionType: .category, full: false)] = place.id
                            case .location:
                                model.sectionRanks[.placeDetail(headerText: place.genre, sectionType: .category, full: false)] = Int(returnDistanceScore(place: place))
                            case.popular:
                                model.sectionRanks[.placeDetail(headerText: place.genre, sectionType: .category, full: false)] = place.communityVotes
                            }
                        }
                    }
                    if placesArray.count == 4 {
                        itemsBySection.removeValue(forKey: .placeDetail(headerText: (place.neighborhood), sectionType: .neighborhood, full: false))
                        itemsBySection[.placeDetail(headerText: (place.neighborhood), sectionType: .neighborhood, full: true)] = placesArray
                        switch model.sortMethod {
                        case .recent:
                            model.sectionRanks[.placeDetail(headerText: place.neighborhood, sectionType: .neighborhood, full: true)]! = (model.sectionRanks[.placeDetail(headerText: place.neighborhood, sectionType: .neighborhood, full: false)] ?? 0) + place.id
                        case .location:
                            model.sectionRanks[.placeDetail(headerText: place.neighborhood, sectionType: .neighborhood, full: true)]! = (model.sectionRanks[.placeDetail(headerText: place.neighborhood, sectionType: .neighborhood, full: false)] ?? 0) + Int(returnDistanceScore(place: place))
                        case .popular:
                            model.sectionRanks[.placeDetail(headerText: place.neighborhood, sectionType: .neighborhood, full: true)] = (model.sectionRanks[.placeDetail(headerText: place.neighborhood, sectionType: .neighborhood, full: false)] ?? 0) + place.communityVotes
                        }
                    }
                } else {
                    itemsBySection[.placeDetail(headerText: place.neighborhood, sectionType: .neighborhood, full: false)] = [.placeDetail(place: place)]
                    model.sectionRanks[.placeDetail(headerText: place.neighborhood, sectionType: .neighborhood, full: false)] = place.communityVotes
                }
                
            case (false, .grid):
                if var placesArray = itemsBySection[.placeBox(headerText: place.neighborhood, sectionType: .neighborhood, full: false)], placesArray.isEmpty != true {
                    //if that section contains less than 10 items
                    if placesArray.count < 4 {
                        //then add the current place
                        placesArray.append(.placeBox(place: place))
                        itemsBySection[.placeBox(headerText: (place.neighborhood), sectionType: .neighborhood, full: false)] = placesArray
                        // and add communityLoves value to that section's rank
                        switch model.sortMethod {
                        case .recent:
                            model.sectionRanks[.placeBox(headerText: place.neighborhood, sectionType: .neighborhood, full: false)]! += place.id
                        case .location:
                            model.sectionRanks[.placeBox(headerText: place.neighborhood, sectionType: .neighborhood, full: false)]! += Int(returnDistanceScore(place: place))
                        case .popular:
                            model.sectionRanks[.placeBox(headerText: place.neighborhood, sectionType: .neighborhood, full: false)]! += place.communityVotes
                        }
                    } else {
                        //if place's genre exists in itemsBySection (only accessed after neighborhood exists and is maxed out)
                        if var placesArray2 = itemsBySection[.placeBox(headerText: place.genre, sectionType: .category, full: false)] {
                            //if that section contains less than 10 items
                            if placesArray2.count < 4 {
                                //then add the current place
                                placesArray2.append(.placeBox(place: place))
                                itemsBySection[.placeBox(headerText: place.genre, sectionType: .category, full: false)] = placesArray2
                                //and add communityVotes value to sectionRank
                                switch model.sortMethod {
                                case .recent:
                                    model.sectionRanks[.placeBox(headerText: place.genre, sectionType: .category, full: false)]! += place.id
                                case .location:
                                    model.sectionRanks[.placeBox(headerText: place.genre, sectionType: .category, full: false)]! += Int(returnDistanceScore(place: place))
                                case .popular:
                                    model.sectionRanks[.placeBox(headerText: place.genre, sectionType: .category, full: false)]! += place.communityVotes
                                }
                            }
                            if placesArray2.count == 4 {
                                itemsBySection.removeValue(forKey: .placeBox(headerText: place.genre, sectionType: .category, full: false))
                                itemsBySection[.placeBox(headerText: (place.genre), sectionType: .category, full: true)] = placesArray2
                                switch model.sortMethod {
                                case .recent:
                                    model.sectionRanks[.placeBox(headerText: place.genre, sectionType: .category, full: true)]! = (model.sectionRanks[.placeBox(headerText: place.genre, sectionType: .category, full: false)] ?? 0) + place.id
                                case .location:
                                    model.sectionRanks[.placeBox(headerText: place.genre, sectionType: .category, full: true)]! = (model.sectionRanks[.placeBox(headerText: place.genre, sectionType: .category, full: false)] ?? 0) + Int(returnDistanceScore(place: place))
                                case .popular:
                                    model.sectionRanks[.placeBox(headerText: place.genre, sectionType: .category, full: true)]! = (model.sectionRanks[.placeBox(headerText: place.genre, sectionType: .category, full: false)] ?? 0) + place.communityVotes
                                }
                            }
                        } else {
                            itemsBySection[.placeBox(headerText: place.genre, sectionType: .category, full: false)] = [.placeBox(place: place)]
                            switch model.sortMethod {
                            case .recent:
                                model.sectionRanks[.placeBox(headerText: place.genre, sectionType: .category, full: false)] = place.id
                            case .location:
                                model.sectionRanks[.placeBox(headerText: place.genre, sectionType: .category, full: false)] = Int(returnDistanceScore(place: place))
                            case.popular:
                                model.sectionRanks[.placeBox(headerText: place.genre, sectionType: .category, full: false)] = place.communityVotes
                            }
                        }
                    }
                    if placesArray.count == 4 {
                        itemsBySection.removeValue(forKey: .placeBox(headerText: (place.neighborhood), sectionType: .neighborhood, full: false))
                        itemsBySection[.placeBox(headerText: (place.neighborhood), sectionType: .neighborhood, full: true)] = placesArray
                        switch model.sortMethod {
                        case .recent:
                            model.sectionRanks[.placeBox(headerText: place.neighborhood, sectionType: .neighborhood, full: true)]! = (model.sectionRanks[.placeBox(headerText: place.neighborhood, sectionType: .neighborhood, full: false)] ?? 0) + place.id
                        case .location:
                            model.sectionRanks[.placeBox(headerText: place.neighborhood, sectionType: .neighborhood, full: true)]! = (model.sectionRanks[.placeBox(headerText: place.neighborhood, sectionType: .neighborhood, full: false)] ?? 0) + Int(returnDistanceScore(place: place))
                        case .popular:
                            model.sectionRanks[.placeBox(headerText: place.neighborhood, sectionType: .neighborhood, full: true)] = (model.sectionRanks[.placeBox(headerText: place.neighborhood, sectionType: .neighborhood, full: false)] ?? 0) + place.communityVotes
                        }
                    }
                } else {
                    itemsBySection[.placeBox(headerText: place.neighborhood, sectionType: .neighborhood, full: false)] = [.placeBox(place: place)]
                    model.sectionRanks[.placeBox(headerText: place.neighborhood, sectionType: .neighborhood, full: false)] = place.communityVotes
                }
            }
            fsqModel.fsqIDs.append(place.fsqID ?? "")
        }
        
        for place in fsqModel.fsqLovedPlaces {
            switch model.viewMode {
            case .list:
                if var placesArray = itemsBySection[.rankedList] {
                    //if that section contains less than 10 item
                    placesArray.append(.rankedList(place: place))
                    if placesArray.count < 8 {
                        itemsBySection[.rankedList] = placesArray
                    } else {
                        itemsBySection.removeValue(forKey: .userLovedList(full: false))
                        itemsBySection[.rankedList] = placesArray
                    }
                } else {
                    itemsBySection[.rankedList] = [.rankedList(place: place)]
                    model.sectionRanks[.rankedList] = 100000
                }
            default:
                if var placesArray = itemsBySection[.userLovedList(full: false)] {
                    //if that section contains less than 10 item
                    placesArray.append(.placeList(place: place))
                    if placesArray.count < 8 {
                        itemsBySection[.userLovedList(full: false)] = placesArray
                    } else {
                        itemsBySection.removeValue(forKey: .userLovedList(full: false))
                        itemsBySection[.userLovedList(full: true)] = placesArray
                    }
                } else if var _  = itemsBySection[.userLovedList(full: true)]{
                    print("section is full")
                } else {
                    itemsBySection[.userLovedList(full: false)] = [.placeList(place: place)]
                    model.sectionRanks[.userLovedList(full: false)] = 100000
                }
            }
        }
        
        return itemsBySection
    }
    
    func createFilteredItemsBySection() -> [ViewModel.Section:[ViewModel.Item]]? {
        var itemsBySection = model.model
        var currentPlaces: [ViewModel.Item] = []
        var ct = 0
        var bigCt = 0
        
        let fsqPlaces = fsqModel.fsqPlaces
        
        switch model.viewMode {
        case .list:
            for place in fsqPlaces {
                let placeLoved = userLovedPlaces.contains { thisPlace in
                    "\(thisPlace.name)\(thisPlace.id)\(thisPlace.fsqID ?? "")" == "\(place.name)\(place.id)\(place.fsqID ?? "")"
                }
                if placeLoved == false {
                    currentPlaces.append(.rankedList(place: place))
                }
            }
            itemsBySection[.rankedList] = currentPlaces
        case .grid:
            var headerText = ""
            var secType: PlaceSectionType = .category
            switch (model.selectedCategory == nil, model.selectedNeighborhood == nil) {
            case (true, true): break
            case (false, true):
                headerText = model.selectedCategory?.name ?? ""
            case (true, false):
                headerText = model.selectedNeighborhood?.name ?? ""
                secType = .neighborhood
            case (false, false):
                headerText = "\(model.selectedCategory?.name ?? "") in \(model.selectedNeighborhood?.name ?? "")"
            }
            
            for place in fsqPlaces {
                let placeLoved = userLovedPlaces.contains { thisPlace in
                    "\(thisPlace.name)\(thisPlace.id)\(thisPlace.fsqID ?? "")" == "\(place.name)\(place.id)\(place.fsqID ?? "")"
                }
                if placeLoved == false {
                    currentPlaces.append(.placeBox(place: place))
                    ct += 1
                    bigCt += 1
                }
                if ct%4 == 0 {
                    itemsBySection[.placeBox(headerText: headerText, sectionType: secType, full: false, idx: bigCt/4)] = currentPlaces
                    model.sectionRanks[.placeBox(headerText: headerText, sectionType: secType, full: false, idx: bigCt/4)] = 50-bigCt
                    currentPlaces = []
                }
            }
        case .detail:
            
            var headerText = ""
            var secType: PlaceSectionType = .category
            switch (model.selectedCategory == nil, model.selectedNeighborhood == nil) {
            case (true, true): break
            case (false, true):
                headerText = model.selectedCategory?.name ?? ""
            case (true, false):
                headerText = model.selectedNeighborhood?.name ?? ""
                secType = .neighborhood
            case (false, false):
                headerText = "\(model.selectedCategory?.name ?? "") in \(model.selectedNeighborhood?.name ?? "")"
            }
            
            for place in fsqPlaces {
                let placeLoved = userLovedPlaces.contains { thisPlace in
                    "\(thisPlace.name)\(thisPlace.id)\(thisPlace.fsqID ?? "")" == "\(place.name)\(place.id)\(place.fsqID ?? "")"
                }
                if placeLoved == false {
                    currentPlaces.append(.placeDetail(place: place))
                    ct += 1
                    bigCt += 1
                }
                if ct%4 == 0 {
                    itemsBySection[.placeDetail(headerText: headerText, sectionType: secType, full: false, idx: bigCt/4)] = currentPlaces
                    model.sectionRanks[.placeDetail(headerText: headerText, sectionType: secType, full: false, idx: bigCt/4)] = 50-bigCt
                    currentPlaces = []
                }
            }
        }
        
        return itemsBySection
    }
    
    func createQueryItemsBySection() -> [ViewModel.Section:[ViewModel.Item]]? {
        var itemsBySection: [ViewModel.Section:[ViewModel.Item]] = [.filtersAndSort:[.viewModeSelector, .sortMethodSelector, .mapSelector]]
        var placeTypeItems: [ViewModel.Item] = []
        for placeType in model.filteredPlaceTypes {
            placeTypeItems.append(.placeType(placeType, selected: true))
        }
        if !placeTypeItems.isEmpty {
            itemsBySection[.placeTypes] = placeTypeItems
            model.sectionRanks[.filtersAndSort] = 250000
        }
        
        var currentPlaces1 = [ViewModel.Item]()
        var currentPlaces2 = [ViewModel.Item]()
        var currentPlaces3 = [ViewModel.Item]()
        var currentPlaces4 = [ViewModel.Item]()
        for place in model.filteredPlaces {
            currentPlaces1.append(.placeSearchList(place: place))
        }
        for place in fsqModel.fsqPlaces {
            currentPlaces2.append(.placeSearchList(place: place))
        }
        for place in googleMapsModel.googlePlaces {
            currentPlaces3.append(.placeSearchList(place: place))
        }
        for place in appleMapKitModel.applePlaces {
            currentPlaces4.append(.placeSearchListApple(place: place))
        }
        if currentPlaces1.isEmpty == false {
            model.sectionRanks[.placeSearchList(src: .concierge)] = 20
            itemsBySection[.placeSearchList(src: .concierge)] = currentPlaces1
        }
        if currentPlaces2.isEmpty == false {
            model.sectionRanks[.placeSearchList(src: .fsq)] = 10
            itemsBySection[.placeSearchList(src: .fsq)] = currentPlaces2
        }
        if currentPlaces3.isEmpty == false {
            model.sectionRanks[.placeSearchList(src: .google)] = 15
            itemsBySection[.placeSearchList(src: .google)] = currentPlaces3
        }
        if currentPlaces4.isEmpty == false {
            model.sectionRanks[.placeSearchList(src: .apple)] = 5
            itemsBySection[.placeSearchList(src: .apple)] = currentPlaces4
        }
        
        return itemsBySection
    }
    
    func createSearchAutoCompletionItemsBySection() -> [ViewModel.Section:[ViewModel.Item]]? {
        var itemsBySection: [ViewModel.Section:[ViewModel.Item]] = [:]
        var currentPlaces = [ViewModel.Item]()
        var completions = [String]()
        for completion in appleMapKitModel.autoCompletionResults {
            if completions.contains("\(completion.title)\(completion.subtitle)") == false {
                currentPlaces.append(.searchAutoCompletionResult(autoCompletion: completion))
                model.sectionRanks[.searchAutoCompletionResults] = 100
                completions.append("\(completion.title)\(completion.subtitle)")
            }
        }
        itemsBySection[.searchAutoCompletionResults] = currentPlaces
        return itemsBySection
    }
    
    func createAskAIItemsBySection()  -> [ViewModel.Section:[ViewModel.Item]]? {
        searchController.searchBar.placeholder = "Ask AI"
        
        var itemsBySection: [ViewModel.Section:[ViewModel.Item]] = [.filtersAndSort:[.askAISelector]]
        
        var placeTypeItems: [ViewModel.Item] = []
        for placeType in model.placeTypes {
            if placeType == model.selectedPlaceType {
                placeTypeItems.append(.placeType(placeType, selected: true))
            } else {
                placeTypeItems.append(.placeType(placeType, selected: false))
            }
        }
        if !placeTypeItems.isEmpty {
            itemsBySection[.placeTypes] = placeTypeItems
            model.sectionRanks[.filtersAndSort] = 250000
        } else {
            return nil
        }
        
        switch gptModel.askAIMode {
        case .suggestingPrompts:
            var promptItems: [ViewModel.Item] = []
            for gptPrompt in gptModel.suggestedPrompts {
                promptItems.append(.gptPrompt(prompt: gptPrompt))
            }
            itemsBySection[.gptPrompts] = promptItems
            model.sectionRanks[.gptPrompts] = 500
        case .loadingPlaces:
            itemsBySection[.gptLoading] = [.gptLoading(gptPlaces: gptModel.gptPlaces.count, googlePlaces: gptModel.gptGooglePlaces.count)]
            model.sectionRanks[.gptLoading] = 1000
            
            var placeItems: [ViewModel.Item] = []
            for place in gptModel.gptGooglePlaces {
                placeItems.append(.gptPlace(place: place))
            }
            itemsBySection[.gptPlace] = placeItems
            model.sectionRanks[.gptPlace] = 100
            
            itemsBySection[.gptClear] = [.gptClear]
            model.sectionRanks[.gptClear] = 1500
        case .displayingPlaces:
            var placeItems: [ViewModel.Item] = []
            for place in gptModel.gptGooglePlaces {
                placeItems.append(.gptPlace(place: place))
            }
            itemsBySection[.gptPlace] = placeItems
            model.sectionRanks[.gptPlace] = 100
            
            itemsBySection[.gptClear] = [.gptClear]
            model.sectionRanks[.gptClear] = 1500
        }
        
        return itemsBySection
    }
}

extension UICollectionView {
    struct ElementKind {
        static let background = "background-element-kind"
    }
}

extension ACityCollectionViewController: PlaceBoxCollectionViewCellDelegate, LovedPlaceCollectionViewCellDelegate, PlaceDetailCollectionViewCellDelegate, RankedPlaceCollectionViewCellDelegate, PlaceSearchCollectionViewCellDelegate, GPTPlaceCollectionViewCellDelegate, GPTClearCollectionViewCellDelegate {
    
    func placeLoved(place: Place) {
        UIView.transition(with: view, duration: 0.8, options: .showHideTransitionViews, animations: { [weak self] () -> Void in
            self?.updateCollectionView()
        }, completion: nil)
    }
    
    func presentDirections(address: String, placeName: String) {
        OpenMapDirections.present(in: self, sourceView: self.view, address: address, placeName: placeName)
    }
    
    func presentWebsite(url: URL) {
        let safariViewController = SFSafariViewController(url: url)
        present(safariViewController, animated: true, completion: nil)
    }
    
    func addToItinerary(_ place: Place, isFSQ: Bool) {
        model.contextMenuIsFSQ = isFSQ
        model.contextMenuPlace = place
        self.performSegue(withIdentifier: "AddToItinerary", sender: nil)
    }
    
    @IBAction func unwindFromAddToItinerary(segue: UIStoryboardSegue) {}
    
    func addComment(_ restaurantID: Int) {
        performSegue(withIdentifier: "CommentsandPhotos", sender: nil)
    }
    
    func seePhotos(_ restaurantID: Int) {
        performSegue(withIdentifier: "CommentsandPhotos", sender: nil)
    }
    
    func getPlace() {
    }
    
    func clearPressed() {
        resetAskAIView()
        updateCollectionView()
    }
}

extension ACityCollectionViewController {
    func getUserLovedListHeight() -> (Int, CGFloat) {
        if let numberOfItems = model.model[.userLovedList(full: model.lovedListFull)]?.count, numberOfItems > 0 {
            switch numberOfItems {
            case 1:
                return (1,50)
            default:
                return (2,100)
            }
        } else {
            return (0,0.0)
        }
    }
}

extension ACityCollectionViewController: NamedSectionHeaderViewDelegate {
    // Implement the delegate method
    func headerViewButtonTapped(_ headerView: NamedSectionHeaderView) {
        // Perform the desired actions and segue here
        // You have access to the headerView if needed
        // Example: perform a segue
    }
}

extension ACityCollectionViewController {
    
    func getFSQPlaces() {
        fsqModel.fsqPlaces = []
        
        var i = model.places.count
        while i < fsqModel.fsqIDs.count {
            fsqModel.fsqIDs.remove(at: i)
            i += 1
        }
        
        let neiSelected = filters.contains(where: { filter in filter == .neighborhoods })
        let catSelected = filters.contains(where: { filter in filter == .categories })
        let tagsSelected = filters.contains(where: { filter in filter == .tags })
        
        if tagsSelected, let selectedTags = model.selectedTags {
            getSelectedTags(tags: selectedTags)
        }
        
        var sort = ""
        
        switch model.sortMethod {
        case .popular:
            sort = "RELEVANCE"
        case .location:
            sort = "DISTANCE"
        case .recent:
            sort = "RATING"
        }
        
        // Cancel previous FSQ request task
        fsqPlacesRequestTask?.cancel()

        // Common filter logic
        if tagsSelected {
            model.group.notify(queue: .global()) {
                self.applyFilters(neiSelected: neiSelected, catSelected: catSelected, tagsSelected: tagsSelected, sort: sort)
            }
        } else {
            applyFilters(neiSelected: neiSelected, catSelected: catSelected, tagsSelected: tagsSelected, sort: sort)
        }
    }

    private func applyFilters(neiSelected: Bool, catSelected: Bool, tagsSelected: Bool, sort: String) {
        var categoryCode: String? = nil
        var ll = ""
        
        let selectedNeighborhood = model.selectedNeighborhood
        let selectedCategory = model.selectedCategory
        let selectedTagPlaceIDs = model.selectedTagPlaceIDs
        
        // Update based on filters
        if selectedCategory != nil {
            categoryCode = String(selectedCategory?.fsqCategoryCode ?? 0)
        }
        
        if model.sortMethod == .location {
            ll = "\(model.locValue.latitude),\(model.locValue.longitude)"
        } else {
            ll = "\(city.latitude),\(city.longitude)"
        }
        
        model.filteredPlaces = model.places.filter { place in
            var matches = true
            if neiSelected {
                matches = matches && place.neighborhood.localizedCaseInsensitiveContains(selectedNeighborhood?.name ?? "")
            }
            if catSelected {
                matches = matches && place.genre.localizedCaseInsensitiveContains(selectedCategory?.name ?? "")
            }
            if tagsSelected {
                matches = matches && ((model.selectedTagPlaceIDs?.contains(where: { pID in place.id == pID })) == true)
            }
            
            return matches
        }
        
        // Make FSQ update calls based on selected filters
        if neiSelected || catSelected || tagsSelected {
            if neiSelected {
                fsqUpdateDefault(categoryCode: categoryCode, sort: sort)
            } else if catSelected {
                if categoryCode != "0" {
                    fsqUpdateCategory(categoryCode: categoryCode ?? "", ll: ll, sort: sort)
                } else if let selectedCategoryQuery = selectedCategory?.name {
                    fsqUpdateQuery(query: selectedCategoryQuery)
                }
            } else if tagsSelected {
                self.updateCollectionView()  // Tags-only update
            }
        } else {
            model.filteredPlaces = model.places  // No filters, return all places
            updateCollectionView()
        }
    }
    
    func fsqUpdateCategory(categoryCode: String, ll: String, sort: String) {
        fsqPlacesRequestTask = Task {
            if let fsqParent = try? await FSQPlaceLLRequest(category: categoryCode, ll: ll, radius: 10000, sort: sort, limit: 50).send(), fsqParent.results.count > 0 {
                let fsqDecoded = fsqParent.results
                for place in fsqDecoded {
                    let appendPlace = place.placeify()
                    if fsqModel.fsqIDs.contains(appendPlace.fsqID ?? "") == false {
                        fsqModel.fsqIDs.append(appendPlace.fsqID ?? "")
                        fsqModel.fsqPlaces.append(appendPlace)
                    }
                }
                fsqPlacesRequestTask = nil
                UIView.transition(with: self.view, duration: 0.4, options: .showHideTransitionViews, animations: { () -> Void in
                    self.updateCollectionView()
                }, completion: nil)
            } else {
                resetView()
                UIView.transition(with: self.view, duration: 0.4, options: .showHideTransitionViews, animations: { () -> Void in
                    self.updateCollectionView()
                }, completion: nil)
            }
        }
    }
    
    func fsqUpdateDefault(categoryCode: String?, sort: String){
        guard let selectedNeighborhood = model.selectedNeighborhood else {return}
        model.group.enter()
        fsqPlacesRequestTask = Task { [weak self] in
            guard let self = self else {return}
            if let fsqParent = try? await FSQPlaceNearRequest(categories: categoryCode, near: "\(selectedNeighborhood.name) \(city.name)", sort: sort, limit: 50).send(), fsqParent.results.count > 0 {
                let fsqDecoded = fsqParent.results
                for place in fsqDecoded {
                    let appendPlace = place.placeify()
                    if fsqModel.fsqIDs.contains(appendPlace.fsqID ?? "") == false {
                        fsqModel.fsqIDs.append(appendPlace.fsqID ?? "")
                        fsqModel.fsqPlaces.append(appendPlace)
                    }
                }
                fsqPlacesRequestTask = nil
                UIView.transition(with: self.view, duration: 0.4, options: .showHideTransitionViews, animations: { () -> Void in
                    self.updateCollectionView()
                }, completion: nil)
            } else {
                resetView()
                UIView.transition(with: self.view, duration: 0.4, options: .showHideTransitionViews, animations: { () -> Void in
                    self.updateCollectionView()
                }, completion: nil)
            }
            model.group.leave()
        }
    }
    
    func fsqUpdateQuery(query: String) {
        
        var sort = ""
        var ll = ""
        var radius = 0
        fsqModel.fsqPlaces = []
        
        switch (model.locDenied, model.locValue.longitude) {
        case (true, _), (false, 0.0):
            ll = "\(city.latitude),\(city.longitude)"
            radius = 10000
        default:
            ll = "\(model.locValue.latitude),\(model.locValue.longitude)"
            radius = 5000
        }
        
        switch model.sortMethod {
        case .popular:
            sort = "RELEVANCE"
        case .location:
            sort = "DISTANCE"
        case .recent:
            sort = "POPULARITY"
        }
        
        fsqPlacesRequestTask?.cancel()
        fsqPlacesRequestTask = Task {
            if let fsqParent = try? await FSQQueryRequest(query: query, ll: ll, radius: radius, sort: sort, limit: 7).send(), fsqParent.results.count > 0 {
                let fsqDecoded = fsqParent.results
                for place in fsqDecoded {
                    let appendPlace = place.placeify()
                    if fsqModel.fsqIDs.contains(appendPlace.fsqID ?? "") == false {
                        fsqModel.fsqIDs.append(appendPlace.fsqID ?? "")
                        fsqModel.fsqPlaces.append(appendPlace)
                    }
                }
                fsqPlacesRequestTask = nil
                updateCollectionView()
            }
        }
    }
}

extension ACityCollectionViewController {
    func googleUpdateQuery(query: String) {
        var ll = ""
        
        switch (model.locDenied, model.locValue.longitude) {
        case (true, _), (false, 0.0):
            ll = "\(city.latitude),\(city.longitude)"
        default:
            ll = "\(model.locValue.latitude),\(model.locValue.longitude)"
        }
        
        googleMapsModel.googlePlaces = []
        googlePlacesRequestTask = Task {
            if let googleFindParent = try? await GoogleFindCandidatePlacesRequest(textQuery: query, location: ll).send(), googleFindParent.results.count > 0 {
                let googleFindPlaceDecoded = googleFindParent.results
                let _ = googleFindPlaceDecoded[0].place_id
                for candidate in googleFindParent.results {
                    if googleMapsModel.googlePlaces.count > 6 { break }
                    let placeID = candidate.place_id
                    if let googleParent = try? await GooglePlaceDetailRequest(placeID: placeID).send() {
                        let place = googleParent.result
                        let appendPlace = place.placeify()
                        if googleMapsModel.googlyIDs.contains(placeID) == false {
                            googleMapsModel.googlePlaces.append(appendPlace)
                            googleMapsModel.googlyIDs.append(placeID)
                        }
                    }
                }
            }
            googlePlacesRequestTask = nil
            updateCollectionView()
        }
    }
}

extension ACityCollectionViewController {
    func returnDistanceScore(place: Place) -> Double {
        //method to calculate the distance from the user's current location to the location of the place passed to the method
        //latitude and longitude added to Place in the DB upon creation
        
        let from = CLLocation(latitude: model.locValue.latitude, longitude: model.locValue.longitude)
        let to = CLLocation(latitude: place.latitude, longitude: place.longitude)
        
        
        let distance = to.distance(from: from)

        let distanceScore = 50-(distance/1609.34)

        return distanceScore
    }
    
    func distanceFromYou(place: Place) -> (Double,String) {
        if model.locDenied == false, model.locValue.latitude != 0 {
            let from = CLLocation(latitude: model.locValue.latitude, longitude: model.locValue.longitude)
            let to = CLLocation(latitude: place.latitude, longitude: place.longitude)
            
            let distance = to.distance(from: from)

            let distanceToReturn = distance/1609.34
            
            return (distanceToReturn, "You")
        } else {
            let from = CLLocation(latitude: city.latitude, longitude: city.longitude)
            let to = CLLocation(latitude: place.latitude, longitude: place.longitude)
            
            let distance = to.distance(from: from)

            let distanceToReturn = distance/1609.34
            
            return (distanceToReturn, "City Center")
        }
    }
}

// MARK: Location Manager Extension
extension ACityCollectionViewController: CLLocationManagerDelegate {
    
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
}

extension ACityCollectionViewController: UISearchResultsUpdating, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        if model.currentMode != .askAI {
            if let searchString = searchController.searchBar.text, !searchString.isEmpty {
                model.currentMode = .query
                model.queryMode = .autoCompletion
                appleMapKitModel.applePlaces = []
                appleMapKitModel.autoCompletionResults = []
                
                appleMapKitModel.searchCompleter.queryFragment = searchString
            } else {
                model.currentMode = .curated
                model.filteredPlaces = model.places
                model.filteredPlaceTypes = model.placeTypes
                fsqModel.fsqPlaces = []
                appleMapKitModel.applePlaces = []
            }
        }
        
        UIView.transition(with: self.view, duration: 0.4, options: .showHideTransitionViews, animations: { () -> Void in
            self.updateCollectionView()
        }, completion: nil)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        switch model.currentMode {
        case .askAI:
            if let prompt = searchController.searchBar.text, !prompt.isEmpty {
                // Update your search results based on the entered text
                submitGPTPrompt(prompt: prompt)
                searchBar.resignFirstResponder()
            }
        default:
            if let searchString = searchController.searchBar.text, !searchString.isEmpty {
                search(for: "\(searchString)", alt: searchString)
                searchBar.resignFirstResponder()
            }
        }
    }
}

extension ACityCollectionViewController: MKLocalSearchCompleterDelegate {
    func startProvidingCompletions() {
        appleMapKitModel.searchCompleter = MKLocalSearchCompleter()
        
        var region = MKCoordinateRegion()
        let regionInMeters = 10000.0
        switch model.locDenied {
        case false:
            let location = CLLocationCoordinate2D(latitude: model.locValue.latitude, longitude: model.locValue.longitude)
            region = MKCoordinateRegion(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
        case true:
            let location = CLLocationCoordinate2D(latitude: city.latitude, longitude: city.longitude)
            region = MKCoordinateRegion(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
        }
        appleMapKitModel.searchCompleter.region = region
        
        // Only include matches for travel-related points of interest, and exclude address-based results.
        appleMapKitModel.searchCompleter.resultTypes = .pointOfInterest
        appleMapKitModel.searchCompleter.pointOfInterestFilter = MKPointOfInterestFilter(including: MKPointOfInterestCategory.travelPointsOfInterest)
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // As the user types, new completion suggestions continuously return to this method.
        // Refresh the UI with the new results.
        let results = completer.results.map { result in
            return result
        }
        
        appleMapKitModel.autoCompletionResults = results
        
        updateCollectionView()
    }
    
    private func search(for queryString: String?, alt: String?) {
        guard let queryString = queryString else { return }
        
        //Apple MapKit Places
        let searchRequest = MKLocalSearch.Request()
        // Only display results that are in travel-related categories.
        searchRequest.pointOfInterestFilter = MKPointOfInterestFilter(including: MKPointOfInterestCategory.travelPointsOfInterest)
        searchRequest.naturalLanguageQuery = queryString
        search(using: searchRequest)
        
        
        // Implement after the user clicks a search completion or hits enter/return
        //Concierge Places
        model.filteredPlaces = model.places.filter { (place) -> Bool in
            place.name.localizedCaseInsensitiveContains(queryString) || place.neighborhood.localizedCaseInsensitiveContains(queryString) || place.genre.localizedCaseInsensitiveContains(queryString)
        }
        model.filteredPlaceTypes = model.placeTypes.filter({ placeType in
            placeType.name.localizedCaseInsensitiveContains(queryString)
        })
        
        //fsq and google places
        if queryString.count > 3 {
            if let _ = alt {
                fsqUpdateQuery(query: queryString)
            }
            appleMapKitModel.searchCompleter.queryFragment = queryString
            googleUpdateQuery(query: queryString)
        }
        model.queryMode = .showingResults
    }
    
    private func search(using searchRequest: MKLocalSearch.Request) {
        // Confine the map search area to an area around the user's current location.
        switch model.locDenied {
        case false:
            appleMapKitModel.searchRegion = MKCoordinateRegion(center: model.locValue, latitudinalMeters: 5_000, longitudinalMeters: 5_000)
        case true:
            appleMapKitModel.searchRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: city.latitude, longitude: city.longitude), latitudinalMeters: 20_000, longitudinalMeters: 20_000)
        }
        searchRequest.region = appleMapKitModel.searchRegion
        
        // Include only point-of-interest results. This excludes results based on address matches.
        searchRequest.resultTypes = .pointOfInterest
        
        appleMapKitModel.localSearch = MKLocalSearch(request: searchRequest)
        
        appleMapKitModel.localSearch?.start { [unowned self] (response, error) in
            guard error == nil, let applePlaces = response?.mapItems else {
                return
            }
            self.appleMapKitModel.applePlaces += applePlaces
            
            updateCollectionView()
        }
    }
}

import OpenAIKit

extension ACityCollectionViewController {
    func getSuggestedGPTPrompts() {
        let placeTypeName = model.selectedPlaceType?.name ?? "Place"
        let cityName = city.name
        let gptPrompt = """
You are providing suggested prompts to an iOS app that will be displayed to the user. The user will be able to click one of the prompts and another request will be made to suggest places for the user to browse. The prompts should be relevant for the Place Type and City provided and be a good search term that would have associated places in a Point of Interest database like Google Maps Platform or Apple Maps. Keep it interesting for the user by providing obvious prompts along with some creative ones they wouldn't immediately think of.
        Provide the response in a JSON format. Don't provide any supporting text, only the JSON response.
        {
          "suggestedPrompts": [{"prompt": "prompt1"},{"prompt": "prompt2"}]
        }
        Please provide a list of 1-10 suggested prompts for a user browsing *\(placeTypeName)* in *\(cityName)*.
"""
        let username = currentUser.username ?? "\(currentUser.firstName) \(currentUser.lastName)"
        let aiMessage = AIMessage(role: .user, content: gptPrompt)
        openAI.sendChatCompletion(newMessage: aiMessage, previousMessages: [], model: .gptV4(.gpt4), maxTokens: 500, n: 1, user: username, completion: { [weak self] result in
            switch result {
            case .success(let aiResult):
                // Handle the result actions
                if let text = aiResult.choices.first?.message?.content {
                    self?.parseGPTPromptsResponse(text: text)
                }
            case .failure(let error):
                //Handle the error
                let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default))
                self?.present(alert, animated: true)
            }
        })
    }
    
    func submitGPTPrompt(prompt: String) {
        gptModel.lastestUserPrompt = prompt
        gptModel.gptGooglePlaces = []
        gptModel.gptPlaces = []
        
        gptModel.askAIMode = .loadingPlaces
        updateCollectionView()
        
        let placeTypeName = model.selectedPlaceType?.name ?? "Place"
        let cityName = city.name
        let gptPrompt = """
You are providing places to an iOS app that will be displayed to the user. Please provide a list of places based on a prompt that a user is submitting. The user is either selecting a suggested prompt or typing one of their own. Included with this is a Place Type and a City. Do the best you can to match each of the conditions and provide 1-10 places for the user to further interact with in the app. Ideally it should be a place that would have an associated record in a Point of Interest database like Google Maps Platform or Apple Maps.

Provide the response in a JSON format with Place Name, Place Address, and Place Website. Don't provide any supporting text, only the JSON response. 
{
  "suggestedPlaces": [
{"name": "placeName1", "address":"address1", "website":"website1"},
{"name": "placeName2", "address":"address2", "website":"website2"}]
}

User Prompt: \(prompt)
City: \(cityName)
Place Type: \(placeTypeName)
"""
        let username = currentUser.username ?? "\(currentUser.firstName) \(currentUser.lastName)"
        let aiMessage = AIMessage(role: .user, content: gptPrompt)
        openAIRequestTask = Task {
            openAI.sendChatCompletion(newMessage: aiMessage, previousMessages: [], model: .gptV4(.gpt4), maxTokens: 500, n: 1, user: username, completion: { [weak self] result in
                switch result {
                case .success(let aiResult):
                    // Handle the result actions
                    if let text = aiResult.choices.first?.message?.content {
                        self?.parseGPTPlacesResponse(text: text)
                    }
                case .failure(let error):
                    //Handle the error
                    let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default))
                    self?.present(alert, animated: true)
                }
            })
        }
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
            print("Error decoding JSON: \(error)")
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
        } catch {
            // If decoding fails, print an error message
            print("Error decoding JSON: \(error)")
        }
        
        DispatchQueue.main.async {
            self.updateCollectionView()
        }
        getGPTGooglePlaces()
    }
    
    func getGPTGooglePlaces() {
        guard !gptModel.gptPlaces.isEmpty else { return }
        var ll = ""
        
        switch (model.locDenied, model.locValue.longitude) {
        case (true, _), (false, 0.0):
            ll = "\(city.latitude),\(city.longitude)"
        default:
            ll = "\(model.locValue.latitude),\(model.locValue.longitude)"
        }
        
        gptModel.gptGooglePlaces = []
        
        googlePlacesRequestTask = Task {
            for place in gptModel.gptPlaces {
                let query = "\(place.name) \(place.address)"
                if let googleFindParent = try? await GoogleFindCandidatePlacesRequest(textQuery: query, location: ll).send(), googleFindParent.results.count > 0 {
                    let googleFindPlaceDecoded = googleFindParent.results
                    let _ = googleFindPlaceDecoded[0].place_id
                    let candidate = googleFindParent.results[0]
                    
                    let placeID = candidate.place_id
                    if let googleParent = try? await GooglePlaceDetailRequest(placeID: placeID).send() {
                        let googlyPlace = googleParent.result
                        let appendPlace = googlyPlace.placeify()
                        
                        if googleMapsModel.googlyIDs.contains(placeID) == false {
                            gptModel.gptGooglePlaces.append(appendPlace)
                            googleMapsModel.googlyIDs.append(placeID)
                            DispatchQueue.main.async {
                                self.updateCollectionView()
                            }
                        }
                    }
                }
            }
            DispatchQueue.main.async {
                self.updateCollectionView()
            }
            gptModel.askAIMode = .displayingPlaces
            googlePlacesRequestTask = nil
        }
    }
}

extension ACityCollectionViewController {
    
    //Pre Fetch User Prof Pic for User Account Tab
    func updateProfPic() {
        //method to fetch the user's profile pic while the view loads and display it in the circular profPic image view
        
        var profPicURL: String?
        if let profPicLink = currentUser.profPicImageURL {
            profPicURL = profPicLink
        }
        
        if let profPicURL = profPicURL {
            Task {
                if let image = try? await ImageRequest(path: profPicURL).send() {
                    profPicture = image
                }
            }
        }
    }
}
