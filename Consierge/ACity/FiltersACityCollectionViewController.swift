//
//  FiltersACityCollectionViewController.swift
//  Consierge
//
//  Created by Austin McLaughlin on 1/16/24.
//
let BACKGROUND1 = UIColor(red: 0, green: 1, blue: 0.6, alpha: 0.5)
let BACKGROUND2 = UIColor(red: 0, green: 0.6, blue: 1, alpha: 0.5)
let BACKGROUND3 = UIColor(red: 0, green: 0.8, blue: 0.8, alpha: 0.5)
let BACKGROUND4 = UIColor(red: 0.6, green: 0.2, blue: 0.3, alpha: 0.4)
import UIKit

private let reuseIdentifier = "Cell"

class FiltersACityCollectionViewController: UICollectionViewController {
    var numSecs = 5
    var neighborhoods = [Neighborhood]()
    var filteredNeighborhoods = [Neighborhood]()
    var selectedNeighborhood: Neighborhood?
    var categories = [Genre]()
    var filteredCategories = [Genre]()
    var selectedCategory: Genre?
    var tags = [PlaceTag]()
    var filteredTags = [PlaceTag]()
    var selectedTags = [PlaceTag]()
    var selectedTagIndexes = Set<Int>()
    var milesFromUser: Float?
    var cityID: Int?
    var placeTypeID: Int?
    let sliderIP = IndexPath(item: 0, section: 6)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.collectionViewLayout = createLayout()
        collectionView.register(SectionFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "FooterView")
        update()
    }
    
    func update() {
        categories = categories.sorted()
        filteredCategories = categories
        neighborhoods = neighborhoods.sorted()
        filteredNeighborhoods = neighborhoods
        tags = tags.sorted(by: { lhs, rhs in
            return lhs.count > rhs.count
        })
        filteredTags = tags
        getTagIndexes()
    }
    
    func createLayout() -> UICollectionViewCompositionalLayout {
        
        let layout = UICollectionViewCompositionalLayout { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            switch sectionIndex {
            case 0,2,4:
                let itemSize1 = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(75))
                let item1 = NSCollectionLayoutItem(layoutSize: itemSize1)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(75))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item1])
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 15, leading: 5, bottom: 5, trailing: 5)
                
                return section
            case 1,3,5:
                let itemSize = NSCollectionLayoutSize(widthDimension: .estimated(500), heightDimension: .absolute(28))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .estimated(500), heightDimension: .absolute(28))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, repeatingSubitem: item, count: 1)
                
                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .continuous
                section.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 20, bottom: 15, trailing: 20)
                section.interGroupSpacing = 10
                
                let footerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(1))
                let footer = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: footerSize, elementKind: UICollectionView.elementKindSectionFooter, alignment: .bottom)
                section.boundarySupplementaryItems = [footer]
                
                return section
            case 7:
                let itemSize1 = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(45))
                let item1 = NSCollectionLayoutItem(layoutSize: itemSize1)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(45))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item1])
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 15, leading: 5, bottom: 5, trailing: 5)
                
                return section
            default:
                var itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(150))
                
                var groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(150))
                if self.milesFromUser == nil {
                    itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(60))
                    groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(60))
                }
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4)
                
                let footerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(1)) // Adjust the height as needed
                let footer = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: footerSize, elementKind: UICollectionView.elementKindSectionFooter, alignment: .bottom)
                section.boundarySupplementaryItems = [footer]
                
                return section
            }
        }
        return layout
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 8
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        switch section {
        case 1:
            switch selectedNeighborhood == nil {
            case true:
                return filteredNeighborhoods.count
            case false:
                return 1
            }
        case 3:
            switch selectedCategory == nil {
            case true:
                return filteredCategories.count
            case false:
                return 1
            }
        case 5:
            return filteredTags.count
        default:
            return 1
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        switch indexPath.section {
        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FilterLabel", for: indexPath) as! FilterLabelCollectionViewCell
            cell.filterLabel.text = "Neighborhood"
            cell.delegate = self
            cell.filterType = .Neighborhood
            return cell
        case 1:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Filter", for: indexPath) as! FilterCollectionViewCell
            
            switch selectedNeighborhood == nil {
            case true:
                cell.filter.text = filteredNeighborhoods[indexPath.item].name
                cell.layer.borderColor = UIColor.clear.cgColor
                cell.xMarker.isHidden = true
            case false:
                cell.filter.text = selectedNeighborhood?.name
                cell.layer.borderColor = UIColor.black.cgColor
                cell.layer.borderWidth = 1
                cell.xMarker.isHidden = false
            }
            
            cell.styleCell(background: 1)
            return cell
            
        case 2:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FilterLabel", for: indexPath) as! FilterLabelCollectionViewCell
            cell.filterLabel.text = "Category"
            cell.delegate = self
            cell.filterType = .Category
            return cell
            
        case 3:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Filter", for: indexPath) as! FilterCollectionViewCell
            switch selectedCategory == nil {
            case true:
                cell.filter.text = filteredCategories[indexPath.item].name
                cell.layer.borderColor = UIColor.clear.cgColor
                cell.xMarker.isHidden = true
            case false:
                cell.filter.text = selectedCategory?.name
                cell.layer.borderColor = UIColor.black.cgColor
                cell.layer.borderWidth = 1
                cell.xMarker.isHidden = false
            }
            cell.styleCell(background: 2)
            return cell
            
        case 4:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FilterLabel", for: indexPath) as! FilterLabelCollectionViewCell
            cell.filterLabel.text = "Tags"
            cell.delegate = self
            cell.filterType = .Tag
            return cell
            
        case 5:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Filter", for: indexPath) as! FilterCollectionViewCell
            
            switch selectedTagIndexes.contains((indexPath.item)) {
            case false:
                cell.filter.text = filteredTags[indexPath.item].tagName
                cell.styleCell(background: 3)
                cell.layer.borderColor = UIColor.clear.cgColor
                cell.xMarker.isHidden = true
            case true:
                cell.filter.text = filteredTags[indexPath.item].tagName
                cell.layer.borderColor = UIColor.black.cgColor
                cell.layer.borderWidth = 1
                cell.xMarker.isHidden = false
            }
            cell.styleCell(background: 3)
            return cell
        case 7:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ResetFilters", for: indexPath) as! ResetFiltersCollectionViewCell
            cell.delegate = self
            cell.styleCell()
            return cell
        default:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MilesSlider", for: indexPath) as! SliderFilterCollectionViewCell

            if milesFromUser == nil {
                cell.milesLabel.isHidden = true
                cell.milesSlider.isHidden = true
                cell.dropDown.image = UIImage(systemName: "chevron.down")
            } else {
                cell.milesLabel.isHidden = false
                cell.milesSlider.isHidden = false
                cell.dropDown.image = UIImage(systemName: "chevron.up")
            }
            cell.delegate = self
            
            return cell
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionFooter else {
            return UICollectionReusableView()
        }
        let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "FooterView", for: indexPath) as! SectionFooterView
        return footerView
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch indexPath.section {
        case 1:
            if (selectedNeighborhood != nil) {
                selectedNeighborhood = nil
                filteredNeighborhoods = neighborhoods
            } else {
                selectedNeighborhood = filteredNeighborhoods[indexPath.item]
            }
            collectionView.reloadData()
        case 3:
            if (selectedCategory != nil) {
                selectedCategory = nil
                filteredCategories = categories
            } else {
                selectedCategory = filteredCategories[indexPath.item]
            }
            collectionView.reloadData()
        case 5:
            if selectedTagIndexes.contains(indexPath.item) {
                selectedTags.removeAll { tag in
                    tag.tagName == filteredTags[indexPath.item].tagName
                }
                selectedTagIndexes.remove(indexPath.item)
            } else{
                selectedTags.append(filteredTags[indexPath.item])
                selectedTagIndexes.insert(indexPath.item)
            }
            collectionView.reloadData()
        case 6:
            if milesFromUser == nil {
                milesFromUser = 0.1
            } else {
                milesFromUser = nil
            }
            collectionView.reloadSections([6])
        default: break
        }
    }
    
    @IBAction func saveFilters(_ sender: Any) {
        Task {
            if selectedCategory != nil {
                let _ = try? await GenreClickedRequest(genreID: selectedCategory?.ID ?? 0).send()
            }
            if selectedNeighborhood != nil {
                let _ = try? await NeighborhoodClickedRequest(neighborhoodID: selectedNeighborhood?.ID ?? 0).send()
            }
            if selectedTags.count > 0 {
                for selectedTag in selectedTags {
                    let _ = try? await TagClickedRequest(tagName: selectedTag.tagName).send()
                }
            }
        }
        
        performSegue(withIdentifier: "UnwindFromFiltersToACity", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? ACityCollectionViewController {
            guard segue.identifier == "UnwindFromFiltersToACity" else {return}
            if selectedCategory != nil {
                if let _ = dest.filters.firstIndex(of: .categories) {
                } else {
                    dest.filters.append(.categories)
                }
                dest.model.selectedCategory = selectedCategory
            } else {
                if let index = dest.filters.firstIndex(of: .categories) {
                    dest.filters.remove(at: index)
                }
                dest.model.selectedCategory = nil
            }
            
            if !selectedTags.isEmpty {
                if let _ = dest.filters.firstIndex(of: .tags) {
                } else {
                    dest.filters.append(.tags)
                }
                dest.model.selectedTags = selectedTags
                dest.model.selectedTagIndexes = selectedTagIndexes
            } else {
                if let index = dest.filters.firstIndex(of: .tags) {
                    dest.filters.remove(at: index)
                }
                dest.model.selectedTags = nil
                dest.model.selectedTagIndexes = Set<Int>()
            }
            
            if selectedNeighborhood != nil {
                if let _ = dest.filters.firstIndex(of: .neighborhoods) {
                } else {
                    dest.filters.append(.neighborhoods)
                }
                dest.model.selectedNeighborhood = selectedNeighborhood
            } else {
                if let index = dest.filters.firstIndex(of: .neighborhoods) {
                    dest.filters.remove(at: index)
                }
                dest.model.selectedNeighborhood = nil
            }
            
            if milesFromUser != nil {
                dest.filters.append(.distanceFromUser)
                dest.model.milesFilter = milesFromUser
            } else {
                if let index = dest.filters.firstIndex(of: .distanceFromUser) {
                    dest.filters.remove(at: index)
                }
                dest.model.milesFilter = nil
            }
            
            dest.unwindCityID = cityID
            dest.unwindPlaceTypeID = placeTypeID
        }
    }
}

extension FiltersACityCollectionViewController: FilterLabelCollectionViewCellDelegate {
    func addFilter(filter: String, filterType: FilterLabelCollectionViewCell.FilterType?) {
        switch filterType {
        case .Neighborhood:
            let nei = Neighborhood(ID: 0, cityID: 0, name: filter, clicked: 1)
            neighborhoods.append(nei)
            filteredNeighborhoods = neighborhoods
            selectedNeighborhood = nei
        case .Category:
            let cat = Genre(ID: 0, name: filter, placeTypeID: 0, clicked: 1, fsqCategoryCode: 0)
            categories.append(cat)
            filteredCategories = categories
            selectedCategory = cat
        case .Tag:
            let tag = PlaceTag(tagName: filter, count: 0)
            tags.append(tag)
            filteredTags = tags
            selectedTags.append(tag)
        case nil:
            break
        }
        collectionView.reloadData()
    }

    func searchFilters(text: String, filterType: FilterLabelCollectionViewCell.FilterType?) {
        switch filterType {
        case .Neighborhood:
            if text == "" {
                filteredNeighborhoods = neighborhoods
            } else {
                filteredNeighborhoods = neighborhoods.filter({ nei in
                    nei.name.localizedCaseInsensitiveContains(text)
                })
            }
            collectionView.reloadSections(IndexSet(integer: 1))
        case .Category:
            if text == "" {
                filteredCategories = categories
            } else {
                filteredCategories = categories.filter({ cat in
                    cat.name.localizedCaseInsensitiveContains(text)
                })
            }
            collectionView.reloadSections(IndexSet(integer: 3))
        case .Tag:
            if text == "" {
                filteredTags = tags
            } else {
                filteredTags = tags.filter({ tag in
                    tag.tagName.localizedCaseInsensitiveContains(text)
                })
            }
            collectionView.reloadSections(IndexSet(integer: 5))
        case nil:
            break
        }
    }
}

extension FiltersACityCollectionViewController {
    func getTagIndexes() {
        guard selectedTags.isEmpty == false else { return }
        guard selectedTagIndexes.isEmpty == true else {return}
        for (i, tag) in tags.enumerated() {
            if tag.tagName == selectedTags.first?.tagName {
                selectedTagIndexes.insert(i)
            }
        }
    }
}

extension FiltersACityCollectionViewController: SliderFilterCollectionViewCellDelegate {
    func sliderUpdated(miles: Float) {
        milesFromUser = miles
    }
}

extension FiltersACityCollectionViewController: ResetFiltersCollectionViewCellDelegate {
    func reset() {
        selectedNeighborhood = nil
        selectedTags = []
        selectedTagIndexes = []
        selectedCategory = nil
        milesFromUser = nil
        collectionView.reloadData()
    }
}
