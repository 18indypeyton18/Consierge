//
//  PickItineraryTableViewController.swift
//  Concierge 0.1
//
//  Created by Austin McLaughlin on 8/6/22.
//

import UIKit

protocol PickItineraryTableViewControllerDelegate: AnyObject {
    func pickItineraryTableViewController(_ controller: PickItineraryTableViewController, didSelect itinerary: Itinerary)
}

class PickItineraryTableViewController: UITableViewController {
    weak var delegate: PickItineraryTableViewControllerDelegate?
    
    var selectedItinerary: Itinerary?
    var type: String?
    var city: City?
    var placeImageURL: String?
    var placeSrc: PlaceSource?
    
    struct Model {
        var itineraries = [Itinerary]()
        var userID: Int? = currentUser.id

    }
    
    var model = Model()
    
    var itinerariesRequestTask: Task<Void, Never>? = nil
    
    deinit { itinerariesRequestTask?.cancel() }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    init?(coder: NSCoder, type: String?, city: City?, placeSrc: PlaceSource?) {
        //Initialize view with required Type and City
        self.type = type
        self.city = city
        self.placeSrc = placeSrc
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //fetch the open itineraries for this user in the current city
        update()
        tableView.reloadData()
    }
    
    func update() {
        guard let userID = model.userID else { return }
        itinerariesRequestTask?.cancel()
        itinerariesRequestTask = Task {
            if let itineraries = try? await ItineraryRequest(userID: userID, cityID: city?.cityID ?? 0).send() {
                model.itineraries = itineraries
            } else {
                model.itineraries = []
            }
            
            itinerariesRequestTask = nil
            self.tableView.reloadData()
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // return # of itineraries open + 1 for the new itinerary row
        return (model.itineraries.count + 1)
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row != 0 {
            //if it's not the first row return the itinerary at that index path
            let cell = tableView.dequeueReusableCell(withIdentifier: "ItineraryCell", for: indexPath)
            let itinerary = model.itineraries[(indexPath.row - 1)]
            
            var content = cell.defaultContentConfiguration()
            if let cityName = city?.name {
                content.text = "\(itinerary.name) - \(cityName)"
            } else {
                content.text = "\(itinerary.name)"
            }
            cell.contentConfiguration = content

            return cell
        } else {
            //else: (is the first row) set up the 'New' row
            let cell = tableView.dequeueReusableCell(withIdentifier: "NewItineraryCell", for: indexPath)
            
            var content = cell.defaultContentConfiguration()
            content.text = "New"
            cell.contentConfiguration = content

            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row != 0 {
            //if user selected an existing itinerary
            //send that Itinerary object back to the AddToItinerary view
            let itinerary = model.itineraries[(indexPath.row - 1)]
            selectedItinerary = itinerary
            delegate?.pickItineraryTableViewController(self, didSelect: itinerary)
            tableView.reloadData()
            
            self.navigationController?.popViewController(animated: true)
        } else {
            //Otherwise create a new Itinerary object
            let itinerary = Itinerary(ID: 0, userID: currentUser.id, status: "active", createdDate: Date.now.ISO8601Format(), closedDate: nil, name: "New", cityID: nil, coverImageURL: placeImageURL, coverImageSrc: placeSrc?.rawValue ?? "Concierge")
            selectedItinerary = itinerary
            delegate?.pickItineraryTableViewController(self, didSelect: itinerary)
            tableView.reloadData()
            
            self.navigationController?.popViewController(animated: true)
        }
    }
}
