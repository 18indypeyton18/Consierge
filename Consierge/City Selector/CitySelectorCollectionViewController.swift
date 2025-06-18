//
//  CitySelectorCollectionViewController.swift
//  Consierge
//
//  Created by Austin McLaughlin on 12/28/23.
//

import UIKit
import PhotosUI

private let reuseIdentifier = "Cell"

class CitySelectorCollectionViewController: UICollectionViewController, UISearchResultsUpdating {
    
    var selectedCity: City? = nil
    
    var pickerCity: City?
    
    var picVC: PHPickerViewController?
    
    //Initiate Data Source using DiffableDataSource - allows dynamic updates with creation of an initial dataSource and Snapshots when updates are needed, see CreateDataSource and UpdateCollectionView methods
    
    typealias DataSourceType = UICollectionViewDiffableDataSource<ViewModel.Section, ViewModel.Item>
    
    //Initiate ViewModel section and Item
    enum ViewModel {
        enum Section {
            case main
            case refresh
        }
        enum Item: Hashable {
            case city(_ city: City)
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
    var newImageRequestTask: Task<Void,Never>? = nil
    
    deinit {
        imageRequestTask?.cancel()
        citiesRequestTask?.cancel()
        defaultCitiesRequestTask?.cancel()
        newImageRequestTask?.cancel()
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
                cell.delegate = self
                
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
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
                
                return section
            case .refresh:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(80))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
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

extension CitySelectorCollectionViewController: CityCollectionViewCellDelegate {
    func addPhoto(city: City?) {
        selectPics(city: city)
    }
}

extension CitySelectorCollectionViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate, PHPickerViewControllerDelegate {
    
    func selectPics(city: City?) {
        guard let city = city else { return }
        pickerCity = city
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 1
        config.filter = .images
        
        picVC = PHPickerViewController(configuration: config)
        
        guard let picVC = picVC else { return }
        picVC.delegate = self
        
//        imagePicker.delegate = self
        
        present(picVC, animated: true)
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        // You limited selection to 1, so just grab the first result.
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }

        provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            guard let self = self else { return }

            if let _ = error {
                // print("Error loading image:", error)
                return
            }

            guard let image = object as? UIImage else {
                // print("Could not cast object to UIImage")
                return
            }

            // Anything that touches UI or relies on the image must happen here,
            // on the main thread.
            DispatchQueue.main.async {
                if let city = self.pickerCity {
                    self.uploadPic(city: city, img: image)
                }
            }
        }
    }

    func uploadPic(city: City, img: UIImage) {
        
        let params = ["name": "AustinMcL","id": "12345","type":"cities"]
        
        let headerImageURL = "/cities/\(city.cityID).jpeg"
        let fileName = "\(city.cityID).jpeg"
        
        //create ImageUpload object with the image, determined path, params, and fileName
        let imageUpload = ImageUpload(image: img, imageURL: headerImageURL, key: "restaurantPic", params: params, fileName: fileName)
        
        guard let imageUpload = imageUpload else { return }
        
        newImageRequestTask = Task {
            let newImage = try? await NewImageRequest(imageUpload: imageUpload).send()
            if let _ = newImage {
                // print("image uploaded!")
                imgUploaded(city: city, headerImageURL: headerImageURL)
            } else {
                // print("error with image upload request")
            }
            newImageRequestTask = nil
        }
    }
    
    func imgUploaded(city: City?, headerImageURL: String) {
        guard let city = city else { return }
        
        Task {
            let cityImgUpdate = CityImgUpdate(cityID: city.cityID, headerImageURL: headerImageURL)
            let resultValue = try? await UpdateCityImgURL(cityImgUpdate: cityImgUpdate).send()
            if let resultValue = resultValue, resultValue["message"] == "Success" {
                // print("image url updated!")
                DispatchQueue.main.async {
                    self.updateCollectionView()
                }
            } else {
                // print("ERRRR")
            }
        }
    }
}
