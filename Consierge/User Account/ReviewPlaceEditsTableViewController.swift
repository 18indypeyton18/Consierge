//
//  ReviewPlaceEditsTableViewController.swift
//  Concierge 0.1
//
//  Created by Austin McLaughlin on 7/21/23.
//

import UIKit

class ReviewPlaceEditsTableViewController: UITableViewController {
    
    var placesToReview: [Place] = []
    
    var selectedPlaces: [Int] = []
    
    var placesRequestTask: Task<Void,Never>? = nil
    var approvePlaceRequestTask: Task<Void,Never>? = nil

    @IBOutlet var editBarButtonItem: UIBarButtonItem!
    
    deinit {
        print("ACity Deinit")
        
        placesRequestTask?.cancel()
        approvePlaceRequestTask?.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        update()
        tableView.allowsMultipleSelectionDuringEditing = true
    }
    
    func update() {
        //cancel existing tasks
        placesRequestTask?.cancel()
        
        //get all restaurants, cafes, bars, and activities edits
        placesRequestTask = Task {
            if let places = try? await PlaceEditsToReviewRequest().send(), places.count > 0 {
                self.placesToReview = places
            } else {
                self.placesToReview = []
            }
            self.tableView.reloadData()
            placesRequestTask = nil
        }
    }

    @IBAction func editClicked(_ sender: Any) {
        switch tableView.isEditing {
        case true:
            tableView.setEditing(false, animated: true)
            editBarButtonItem.title = "Edit"
            tableView.reloadData()
        case false:
            tableView.setEditing(true, animated: false)
            editBarButtonItem.title = "Done"
            tableView.reloadData()
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        switch tableView.isEditing {
        case false:
            return 1
        case true:
            return 2
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView.isEditing {
        case false:
            return placesToReview.count
        case true:
            switch section {
            case 0:
                return 1
            default:
                return placesToReview.count
            }
        }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch tableView.isEditing {
        case false:
            let place = placesToReview[indexPath.row]
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "PlaceToReview", for: indexPath) as! PlaceToReviewTableViewCell
            
            cell.imageRequestTask?.cancel()
            cell.imageRequestTask = nil
            cell.fetchImage(imageURL: place.imageURL)
            
            cell.nameLabel.text = place.name
            cell.catNeiLabel.text = "\(place.genre) in \(place.neighborhood)"
            cell.placeID = place.id
            
            return cell
        case true:
            switch indexPath.section {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: "MassSelect", for: indexPath) as! MassEditTableViewCell
                cell.delegate = self
                return cell
            default:
                let place = placesToReview[indexPath.row]
                
                let cell = tableView.dequeueReusableCell(withIdentifier: "PlaceToReview", for: indexPath) as! PlaceToReviewTableViewCell
                
                cell.imageRequestTask?.cancel()
                cell.imageRequestTask = nil
                cell.fetchImage(imageURL: place.imageURL)
                
                cell.nameLabel.text = place.name
                cell.catNeiLabel.text = "\(place.genre) in \(place.neighborhood)"
                cell.placeID = place.id
                
                return cell
            }
        }
    }
    
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch tableView.isEditing {
        case false:
            return "Place Edits To Review"
        case true:
            switch section {
            case 0:
                return "Mass Edit"
            default:
                return "Place Edits to Review"
            }
        }
        
    }
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch tableView.isEditing {
        case false:
            return 205
        case true:
            switch indexPath.section {
            case 0: return 110
            default: return 205
            }
            
        }
    }

    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        switch tableView.isEditing {
        case false:
            return true
        case true:
            switch indexPath.section {
            case 0: return false
            default: return true
            }
        }
    }
    
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    func approveAPlaceEdit(_ place: Place, status: String) {
        guard let place = place as? ConciergePlace else { return }
        print(place.id)
        place.status = status
        place.version += 1
        
        approvePlaceRequestTask = Task {
            let resultValue = try? await ApprovePlaceEditRequest(place: place).send()
            
            DispatchQueue.main.async {
                var myAlert = UIAlertController(title: resultValue?["status"], message: resultValue?["message"], preferredStyle: UIAlertController.Style.alert)
                
                //attempt to capture the restaurant's ID from the Task
                if let _ = resultValue?["ID"] {
                    //Display the result to the user
                    if resultValue?["status"] == "Success" {
                        let okAction = UIAlertAction(title: "Close", style: UIAlertAction.Style.default) { action in
                            //self.uploadIndicator.stopAnimating()
                            self.update()
                        }
                        myAlert.addAction(okAction)
                        self.present(myAlert, animated: true, completion: nil)
                    }
                } else if resultValue?["status"] == "Error" {
                    //Display the failed result to the user and stay on the page
                    let okAction = UIAlertAction(title: "Close", style: UIAlertAction.Style.default)
                    
                    myAlert.addAction(okAction)
                    self.present(myAlert, animated: true, completion: nil)
                } else {
                    //Display the failed result to the user and stay on the page
                    myAlert = UIAlertController(title: "Error", message: "undefined error", preferredStyle: UIAlertController.Style.alert)
                    let okAction = UIAlertAction(title: "Close", style: UIAlertAction.Style.default)
                    
                    myAlert.addAction(okAction)
                    self.present(myAlert, animated: true, completion: nil)
                }
            }
            approvePlaceRequestTask = nil
        }
    }
}

extension ReviewPlaceEditsTableViewController: MassEditTableViewCellDelegate {
    func deselectAllRows() {
        for i in 1...4 {
            print(i)
            let numRows = tableView.numberOfRows(inSection: i)
            print(numRows)
            if numRows != 0 {
                for j in 0...(numRows - 1) {
                    print(j)
                    let iP = IndexPath(row: j, section: i)
                    print(iP)
                    tableView.deselectRow(at: iP, animated: true)
                }
            }
        }
    }
    
    func selectAllRows() {
        for i in 1...4 {
            print(i)
            let numRows = tableView.numberOfRows(inSection: i)
            print(numRows)
            if numRows != 0 {
                for j in 0...(numRows - 1) {
                    print(j)
                    let iP = IndexPath(row: j, section: i)
                    print(iP)
                    tableView.selectRow(at: iP, animated: true, scrollPosition: .none)
                }
            }
        }
    }
    
    func approveSelected() {
        let selectedRows: [IndexPath] = tableView.indexPathsForSelectedRows ?? []
        
        if selectedRows == [] {
            print("0000")
        } else {
            for i in selectedRows {
                let place = placesToReview[i.row]
                approveAPlaceEdit(place, status: "Approved")
            }
        }
    }
    
    func rejectSelected() {
        let selectedRows: [IndexPath] = tableView.indexPathsForSelectedRows ?? []
        
        if selectedRows == [] {
            print("0000")
        } else {
            for i in selectedRows {
                let place = placesToReview[i.row]
                approveAPlaceEdit(place, status: "Rejected")
            }
        }
    }
}
