//
//  ViewLimitedItineraryCollectionViewController.swift
//  Consierge
//
//  Created by Austin McLaughlin on 3/2/25.
//

import UIKit

private let reuseIdentifier = "Cell"

class ViewLimitedItineraryCollectionViewController: UICollectionViewController {

    var itinerary: Itinerary
    var itineraryLines: [ItineraryLine]
    
    struct Model {
        var itineraryLinesPlaces = [Int:Place]()
        var placesInOrder = [Place]()
    }
    var model = Model()
    
    var updateTask: Task<Void,Never>? = nil

    deinit {
        updateTask?.cancel()
    }
    
    override func viewDidLoad() {
        navigationItem.title = itinerary.name
        super.viewDidLoad()
        update()
        collectionView.collectionViewLayout = createLayout()
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
                case "FSQ":
                    if let fsqPlace = try? await getFSQPlaceRequest(fsqID: itineraryLine.fsqID).send() {
                        let place = fsqPlace.placeify()
                        model.itineraryLinesPlaces[itineraryLine.ID] = place
                    }
                default:
                    if let place = try? await SinglePlaceRequest(placeID: placeID).send() {
                        model.itineraryLinesPlaces[itineraryLine.ID] = place[0]
                    }
                }
            }
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
            
            updateTask = nil
        }
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return (itineraryLines.count + 1) / 2
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == ((itineraryLines.count + 1) / 2 - 1) && itineraryLines.count % 2 != 0 {
            return 1
        }
        return 2
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlaceBoxItinerary", for: indexPath) as! PlaceBoxCollectionViewCell
        //Place object stored in each instance of ViewModel.Item and can be used to configure the cell
        let i = (indexPath.section * 2) + indexPath.item
        let itLine = itineraryLines[i]
        let place = model.itineraryLinesPlaces[itLine.ID]
        guard let place = place else {return cell}
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
    }
    
    func createLayout() -> UICollectionViewCompositionalLayout {
        
        let placeItemSize1 = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .fractionalHeight(1))
        let placeItem1 = NSCollectionLayoutItem(layoutSize: placeItemSize1)
        placeItem1.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)
        
        let placeItemSize2 = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .fractionalHeight(1))
        let placeItem2 = NSCollectionLayoutItem(layoutSize: placeItemSize2)
        placeItem2.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(140))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [placeItem1, placeItem2])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        
        return UICollectionViewCompositionalLayout(section: section)
    }

    @IBSegueAction func placeSelected(_ coder: NSCoder, sender: UICollectionViewCell?) -> PlaceDetailCollectionViewController? {
        
        guard let cell = sender, let indexPath = collectionView.indexPath(for: cell), let placeBox = collectionView.cellForItem(at: indexPath) as? PlaceBoxCollectionViewCell else { return nil }
        
        let i = (indexPath.section * 2) + indexPath.item
        let itLine = itineraryLines[i]
        let place = model.itineraryLinesPlaces[itLine.ID]
        
        guard let pic = placeBox.placePic.image, let place = place else {return nil}
        
        return PlaceDetailCollectionViewController(coder: coder, place: place, sectionsPlaces: model.placesInOrder, placePic: pic, placeTypeID: place.placeTypeID, cityID: nil)
    }
}
