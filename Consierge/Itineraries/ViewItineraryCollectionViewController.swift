//
//  ViewItineraryCollectionViewController.swift
//  Consierge
//
//  Created by Austin McLaughlin on 12/7/24.
//

import UIKit

private let reuseIdentifier = "Cell"

class ViewItineraryCollectionViewController: UICollectionViewController, UpdateItineraryLineTableViewControllerDelegate {
    
    typealias DataSourceType = UICollectionViewDiffableDataSource<ViewModel.Section, ViewModel.Item>
    
    //setup ViewModel design. Section will always be ItineraryLine and store both the Place & the ItineraryLine
    //Item will be Place or Itinerary Line and store the respective object.
    enum ViewModel {
        enum Section: Comparable, Hashable {
            case itineraryLine(_ itineraryLine: ItineraryLine, _ place: Place)

            static func == (lhs: ViewItineraryCollectionViewController.ViewModel.Section, rhs: ViewItineraryCollectionViewController.ViewModel.Section) -> Bool {
                switch (lhs, rhs){
                case (.itineraryLine(let lhsIL, _),.itineraryLine(let rhsIL, _)):
                    if lhsIL.ID == rhsIL.ID{
                        return true
                    } else {
                        return false
                    }
                }
            }
            
            func hash(into hasher: inout Hasher) {
                switch self{
                case .itineraryLine(let itineraryLine, _):
                    hasher.combine(itineraryLine.ID)
                }
            }
            
            static func < (lhs: ViewItineraryCollectionViewController.ViewModel.Section, rhs: ViewItineraryCollectionViewController.ViewModel.Section) -> Bool {
                switch (lhs, rhs) {
                case (.itineraryLine(let lhsIL, _),.itineraryLine(let rhsIL, _)):
                    return lhsIL < rhsIL
                }
            }
        }
        enum Item: Hashable {
            case place(_ place: Place)
            case itineraryLine(_ itineraryLine: ItineraryLine)
            
            func hash(into hasher: inout Hasher) {
                switch self {
                case .place(let place):
                    hasher.combine("\(place.id)\(place.fsqID ?? "")\(place.name)")
                case .itineraryLine(let itineraryLine):
                    hasher.combine(itineraryLine)
                }
            }

            static func == (lhs: ViewItineraryCollectionViewController.ViewModel.Item, rhs: ViewItineraryCollectionViewController.ViewModel.Item) -> Bool {
                switch (lhs, rhs) {
                case (.place(let lhsPlace), .place(let rhsPlace)):
                    return "\(lhsPlace.id)\(lhsPlace.fsqID ?? "")\(lhsPlace.name)" == "\(rhsPlace.id)\(rhsPlace.fsqID ?? "")\(rhsPlace.name)"
                case (.itineraryLine(let lhsItineraryLine), .itineraryLine(let rhsItineraryLine)):
                    return lhsItineraryLine == rhsItineraryLine
                default:
                    return false
                }
            }
        }
    }
    
    struct Model {
        var itineraryLinesPlaces = [Int:Place]()
        var placesInOrder = [Place]()
    }
    
    @IBOutlet var editTabBarButton: UIBarButtonItem!
    
    
    var dataSource: DataSourceType!
    var model = Model()

    var itinerary: Itinerary
    var itineraryLines: [ItineraryLine]
    
    var inEditMode = false
    
    var updateTask: Task<Void,Never>? = nil
    var imageRequestTask: Task<Void,Never>? = nil
    var itineraryRequestTask: Task<Void,Never>? = nil

    deinit {
        updateTask?.cancel()
        imageRequestTask?.cancel()
        itineraryRequestTask?.cancel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = itinerary.name
        
        //fetch Place details from each itineraryLines
        update()
        
        //set datasource and delegates
        dataSource = createDataSource()
        collectionView.dataSource = dataSource
        collectionView.collectionViewLayout = createLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    init?(coder: NSCoder, itinerary: Itinerary, itineraryLines: [ItineraryLine]) {
        //initialize required Itinerary and ItineraryLines values
        self.itinerary = itinerary
        self.itineraryLines = itineraryLines
        super.init(coder: coder)
    }
    
    func update() {
        //fetch Place for each itineraryLine
        //iterates through each ItineraryLine, determines type, and fetches each Place individually
        updateTask = Task {
            for itineraryLine in itineraryLines {
                let placeID = itineraryLine.placeID
                switch itineraryLine.type {
                case "fsqRestaurant", "fsqCafe", "fsqBar", "fsqActivity":
                    if let fsqPlace = try? await getFSQPlaceRequest(fsqID: itineraryLine.fsqID).send() {
                        let place = fsqPlace.placeify()
                        model.itineraryLinesPlaces[itineraryLine.ID] = place
                    }
                case "googleRestaurant", "googleCafe", "googleBar", "googleActivity":
                    print("Fetching Google Place \(itineraryLine.fsqID)")
                    if let googleParent = try? await GooglePlaceDetailRequest(placeID: itineraryLine.fsqID).send() {
                        let googlePlace = googleParent.result
                        let place = googlePlace.placeify()
                        model.itineraryLinesPlaces[itineraryLine.ID] = place
                    }
                default:
                    if let place = try? await SinglePlaceRequest(placeID: placeID).send() {
                        model.itineraryLinesPlaces[itineraryLine.ID] = place[0]
                    }
                }
            }
            updateCollectionView()
            
            updateTask = nil
        }
    }

    func updateCollectionView() {
        //create Snapshot - 1 section per itineraryLine. Each section contains 1 Place Item and 1 Itinerary Line Item.
        
        var itemsBySection: [ViewModel.Section:[ViewModel.Item]] = [:]
        for itineraryLine in itineraryLines {
            guard let place = model.itineraryLinesPlaces[itineraryLine.ID] else { return }
            
            print("itemsBySection - \(itineraryLine.ID)\(place.name)")
            itemsBySection[.itineraryLine(itineraryLine, place)] = [.place(place), .itineraryLine(itineraryLine)]
        }
        let sectionIDs = itemsBySection.keys.sorted { $0 > $1 }
        
        for sectionID in sectionIDs {
            switch sectionID {
            case .itineraryLine(_, let place):
                self.model.placesInOrder.append(place)
            default:
                break
            }
        }
        
        DispatchQueue.main.async {
            self.dataSource.applySnapshotUsing(sectionIDs: sectionIDs, itemsBySection: itemsBySection)
        }
    }
    
    func createDataSource() -> DataSourceType {
        //Create DataSource -- fetch Place image and Place name for Place Item
        // -- ItineraryLine needs to display the Date/Time and the Custom Note
        
        let dataSource = DataSourceType(collectionView: collectionView) { (collectionView, indexPath, item) in
            print(indexPath)
            print(item)
            switch item {
            case .place(let place):
                
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlaceBoxItinerary", for: indexPath) as! PlaceBoxCollectionViewCell
                //Place object stored in each instance of ViewModel.Item and can be used to configure the cell
                cell.place = place
                cell.placeTypeID = place.placeTypeID
                cell.cityID = place.cityID.cityID
                
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
                
                //return cell for each item
                return cell
                
            case .itineraryLine(let itineraryLine):
                switch self.inEditMode {
                case false:
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ItineraryLine", for: indexPath) as! ItineraryLineCollectionViewCell
                    cell.itineraryLine = itineraryLine
                    if let itineraryLineDate = itineraryLine.startDateDate {
                        let itineraryLineDateString = itineraryLineDate.formatted(date: .abbreviated, time: .shortened)
                        cell.startDateLabel.text = "\(itineraryLineDateString)"
                    } else {
                        cell.startDateLabel.text = "No date set"
                    }
                    if itineraryLine.customNote != "" {
                        cell.customNoteLabel.text = itineraryLine.customNote
                    } else {
                        cell.customNoteLabel.text = "No note set"
                    }
                                    
                    return cell
                case true:
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EditRestaurant", for: indexPath) as! ItineraryLineEditCollectionViewCell
                    
                    cell.itineraryLine = itineraryLine
                    cell.delegate = self
                    
                    return cell
                }
            }
        }
        return dataSource
    }
    
    func createLayout() -> UICollectionViewCompositionalLayout {
        //Place gets 40% of the width, ItineraryLine gets 50% of the width (10% spacing)
        //each Section gets absolute height of 40
        
        let placeItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.4), heightDimension: .fractionalHeight(1))
        let placeItem = NSCollectionLayoutItem(layoutSize: placeItemSize)
        
        let itineraryLineSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .fractionalHeight(1))
        let itineraryLineItem = NSCollectionLayoutItem(layoutSize: itineraryLineSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(140))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [placeItem, itineraryLineItem])
        group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 2, bottom: 0, trailing: 2)
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    @IBSegueAction func updateItLine(_ coder: NSCoder, sender: UICollectionViewCell?) -> UpdateItineraryLineTableViewController? {
        
        let cell = sender as! ItineraryLineCollectionViewCell
        let indexPath = collectionView.indexPath(for: cell)
        guard let section = dataSource.sectionIdentifier(for: indexPath?.section ?? 0) else { return nil }
        
        switch section {
        case .itineraryLine(let itineraryLine, let place):
            let updateLineController = UpdateItineraryLineTableViewController(coder: coder, itineraryLine: itineraryLine, place: place)
            updateLineController?.delegate = self
            return updateLineController
        }
    }
    @IBSegueAction func plcSelected(_ coder: NSCoder, sender: UICollectionViewCell?) -> PlaceDetailCollectionViewController? {
        
        guard let cell = sender, let indexPath = collectionView.indexPath(for: cell), let item = dataSource.itemIdentifier(for: indexPath), let placeBox = collectionView.cellForItem(at: indexPath) as? PlaceBoxCollectionViewCell else { return nil }
        
        var place: Place? = nil
        
        switch item {
        case .place(let selectedPlace):
            place = selectedPlace
        default:
            break
        }
        
        guard let pic = placeBox.placePic.image, let place = place else {return nil}
        
        return PlaceDetailCollectionViewController(coder: coder, place: place, sectionsPlaces: model.placesInOrder, placePic: pic, placeTypeID: place.placeTypeID)
    }
    
    
    @IBAction func unwindToViewItinerary(segue: UIStoryboardSegue) {}
    
    func updateItineraryLineTableViewController(_ controller: UpdateItineraryLineTableViewController) {
        //delegate method from UpdateItineraryLine to refresh the view and update the ItineraryLine date/time and custom note values
        refreshItinerary()
    }
    
    func refreshItinerary() {
        //Fetch ItineraryLines to refresh the data for date/time and custom note
        itineraryRequestTask?.cancel()
        itineraryRequestTask = nil
                
        itineraryRequestTask = Task {
            if let userItineraryLines = try? await UserItineraryLinesRequest(itineraryID: itinerary.ID).send() {
                itineraryLines = userItineraryLines.sorted { $0 > $1 }
                DispatchQueue.main.async {
                    self.update()
                }
            }
        }
    }
    @IBAction func editItineraryLine(_ sender: Any) {
        switch inEditMode {
        case true:
            inEditMode.toggle()
            editTabBarButton.title = "Edit"
            dataSource = createDataSource()
            update()
        case false:
            inEditMode.toggle()
            editTabBarButton.title = "Done"
            dataSource = createDataSource()
            updateCollectionView()
        }
    }
    
}



extension ViewItineraryCollectionViewController {
    
    func fetchFSQImageThrows(url: URL) async throws -> UIImage {
        enum PhotoInfoError: Error, LocalizedError {
            case itemNotFound
            case imageDataMissing
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw PhotoInfoError.imageDataMissing
        }
        
        guard let image = UIImage(data: data) else {
            throw PhotoInfoError.imageDataMissing
        }
        
        return image
    }
}

extension ViewItineraryCollectionViewController: ItineraryLineEditCollectionViewCellDelegate {
    func updateAfterDelete(_ itineraryLine: ItineraryLine) {
        let itineraryLineIndex = itineraryLines.firstIndex { $0 == itineraryLine } ?? 0
        itineraryLines.remove(at: itineraryLineIndex)
        updateCollectionView()
    }
}
