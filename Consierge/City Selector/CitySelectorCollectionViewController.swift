//
//  CitySelectorCollectionViewController.swift
//  Consierge
//
//  Created by Austin McLaughlin on 12/28/23.
//

import UIKit

private let reuseIdentifier = "Cell"

class CitySelectorCollectionViewController: UICollectionViewController, UISearchResultsUpdating {
    
    var selectedCity: City? = nil
    
    //Initiate Data Source using DiffableDataSource - allows dynamic updates with creation of an initial dataSource and Snapshots when updates are needed, see CreateDataSource and UpdateCollectionView methods
    
    typealias DataSourceType = UICollectionViewDiffableDataSource<ViewModel.Section, ViewModel.Item>
    
    //Initiate ViewModel section and Item
    enum ViewModel {
        enum Section {
            case main
            case new
            case refresh
        }
        enum Item: Hashable {
            case city(_ city: City)
            case new
            case refresh
        }
    }
    
    //Initiate Model to store City values returned from DB
    struct Model {
        var cities = [City]()
        var filteredCities = [City]()
        
        var sections: [ViewModel.Section] = []
        
        //used to allow longPress Gesture
        var longPressedCityID: Int = 0
        
        var userDefaultCity: City?
    }
    
    var dataSource: DataSourceType!
    var model = Model()
    
    let searchController = UISearchController()
    
    //Create and cancel Task for API to use when user signs in
    var citiesRequestTask: Task<Void, Never>? = nil
    var imageRequestTask: Task<Void,Never>? = nil
    var defaultCitiesRequestTask: Task<Void, Never>? = nil
    
    deinit {
        imageRequestTask?.cancel()
        citiesRequestTask?.cancel()
        defaultCitiesRequestTask?.cancel()
    }
    
    var headerImages = [UIImage?]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //handles the API Request to fetch all cities
        update()
        //Setup diffableDataSource & collection view
        dataSource = createDataSource()
        collectionView.dataSource = dataSource
        collectionView.collectionViewLayout = createLayout()
        
        setupPage()
    }
    
    func setupPage() {
        navigationItem.searchController = searchController
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    @IBAction func cancelPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func update() {
        citiesRequestTask = Task {
            model.cities = CityGetter().returnCities()
            model.filteredCities = model.cities
            DispatchQueue.main.async {
                self.updateCollectionView()
            }
            citiesRequestTask = nil
        }
    }
    
    func updateCollectionView() {
        //apply snapshot to DataSource with the data from Update()
        //only 1 section (main) and 1 item for each City fetched from the DB
        var itemsBySection: [ViewModel.Section:[ViewModel.Item]] = [:]
        var items: [ViewModel.Item] = []
        var sections: [ViewModel.Section] = []
        
        for city in model.filteredCities {
            items.append(.city(city))
        }
        
        if model.cities.isEmpty {
            itemsBySection[.refresh] = [.refresh]
            sections.append(.refresh)
        } else {
            itemsBySection = [.main:items]
            sections.append(.main)
        }
        
        let role = currentUser.role
        if role != "Noob" {
            sections.append(.new)
            itemsBySection[.new] = [.new]
        }
        model.sections = sections
        
        dataSource.applySnapshotUsing(sectionIDs: sections, itemsBySection: itemsBySection)
    }
    
    func createDataSource() -> DataSourceType {
        //Initiate DataSource
        let dataSource = DataSourceType(collectionView: collectionView) { (collectionView, indexPath, item) in
            
            switch item {
            case .city(let city):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "City", for: indexPath) as! CityCollectionViewCell
                //For each cell set the label to the City's name and fetch the city's header image
                cell.nameLabel.text = city.name
                
                self.imageRequestTask = Task {
                    if let image = try? await ImageRequest(path: city.imageURL).send() {
                        cell.cityHeaderImage.image = image
                        self.headerImages.append(image)
                    }
                    self.imageRequestTask = nil
                }
                
                //set style for the cell - rounded corners and shadows
                cell.cityHeaderImage.layer.cornerRadius = 7.5
                cell.cityHeaderImage.layer.borderWidth = 1.0
                cell.cityHeaderImage.layer.borderColor = UIColor.clear.cgColor
                cell.cityHeaderImage.layer.masksToBounds = true

                cell.contentView.layer.shadowColor = UIColor.black.cgColor
                cell.contentView.layer.shadowOffset = CGSize(width: 0, height: 2.0)
                cell.contentView.layer.shadowRadius = 2.0
                cell.contentView.layer.shadowOpacity = 0.5
                
                cell.city = city
                
                return cell
            case .new:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewCity", for: indexPath) as! NewCityCollectionViewCell
                
                return cell
            case .refresh:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RefreshCities", for: indexPath) as! RefreshCollectionViewCell
                
                return cell
            }
            
        }
        return dataSource
    }
    
    func createLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { [unowned self] (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            
            //get section from layout Closure SectionIndex
            let section = self.model.sections[sectionIndex]
            //figure out which section we're in and set layout accordingly
            switch section {
            case .main:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(140))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
                
                return section
            case .new:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(80))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
                
                return section
            case .refresh:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(80))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
                
                return section
            }
        }
        //simple collection view layout - full width and 140 height + content insets
        return layout
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let _ = collectionView.cellForItem(at: indexPath) as? RefreshCollectionViewCell {
            update()
        } else if let cell = collectionView.cellForItem(at: indexPath) as? CityCollectionViewCell {
            selectedCity = cell.city
            performSegue(withIdentifier: "unwindFromCitySelector", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let dest = segue.destination as! ACityCollectionViewController
        
        if let cell = sender as? CityCollectionViewCell {
            dest.city = cell.city ?? defaultCity
        }
    }
    
    func updateSearchResults(for searchController: UISearchController){
        //filters the Cities array when the user searches and updates the collectionView with the relevant results
        
        if let searchString = searchController.searchBar.text, searchString.isEmpty == false {
            
            model.filteredCities = model.cities.filter { (city) -> Bool in
                city.name.localizedCaseInsensitiveContains(searchString)
            }
        } else {
            model.filteredCities = model.cities
        }
        updateCollectionView()
    }
}
