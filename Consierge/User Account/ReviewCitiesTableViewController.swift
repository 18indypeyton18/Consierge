//
//  ReviewCitiesTableViewController.swift
//  Concierge 0.1
//
//  Created by Austin McLaughlin on 7/21/23.
//

import UIKit

class ReviewCitiesTableViewController: UITableViewController {
    
    var citiesToReview: [City] = []
    
    var citiesRequestTask: Task<Void, Never>? = nil
    var approveCityRequestTask: Task<Void, Never>? = nil
    var imageRequestTask: Task<Void,Never>? = nil
    deinit {
        imageRequestTask?.cancel()
        approveCityRequestTask?.cancel()
        citiesRequestTask?.cancel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.setEditing(true, animated: false)
        tableView.reloadData()
        
        update()
    }
    
    func update() {
        
        //fetch all cities from the DB, including name, nickname, headerImageURL
        citiesRequestTask?.cancel()
        citiesRequestTask = Task {
            if let cities = try? await CitiesToReviewRequest().send() {
                self.citiesToReview = cities
            } else {
                self.citiesToReview = []
            }
            self.tableView.reloadData()
            citiesRequestTask = nil
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        default:
            return citiesToReview.count
        }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "MassSelect", for: indexPath) as! MassEditTableViewCell
            cell.delegate = self
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "City", for: indexPath) as! CityToReviewTableViewCell
            
            let city = citiesToReview[indexPath.row]
            
            self.imageRequestTask = Task {
                if let image = try? await ImageRequest(path: city.imageURL).send() {
                    cell.cityHeaderImage.image = image
                }
                self.imageRequestTask = nil
            }
            
            cell.cityNameLabel.text = city.name
            cell.cityNicknameLabel.text = city.nickname
            cell.cityLatLonLabel.text = "\(city.latitude), \(city.longitude)"
            
            //set style for the cell - rounded corners and shadows
            cell.cityHeaderImage.layer.cornerRadius = 7.5
            cell.cityHeaderImage.layer.borderWidth = 1.0
            cell.cityHeaderImage.layer.borderColor = UIColor.clear.cgColor
            cell.cityHeaderImage.layer.masksToBounds = true
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return 110
        default:
            return 208

        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        switch indexPath.section {
        case 0:
            return false
        default:
            return true
        }
    }
    
    func approveACity(_ city: City, status: String) {
        var city = city
        city.status = status
        
        approveCityRequestTask = Task {
            let resultValue = try? await ApproveCityRequest(city: city).send()
            
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
            approveCityRequestTask = nil
        }
    }
}

extension ReviewCitiesTableViewController: MassEditTableViewCellDelegate {
    func deselectAllRows() {
        for i in 1...1 {
            let numRows = tableView.numberOfRows(inSection: i)
            if numRows != 0 {
                for j in 0...(numRows - 1) {
                    let iP = IndexPath(row: j, section: i)
                    tableView.deselectRow(at: iP, animated: true)
                }
            }
        }
    }
    
    func selectAllRows() {
        for i in 1...1 {
            let numRows = tableView.numberOfRows(inSection: i)
            if numRows != 0 {
                for j in 0...(numRows - 1) {
                    let iP = IndexPath(row: j, section: i)
                    tableView.selectRow(at: iP, animated: true, scrollPosition: .none)
                }
            }
        }
    }
    
    func approveSelected() {
        let selectedRows: [IndexPath] = tableView.indexPathsForSelectedRows ?? []
        
        if selectedRows == [] {
        } else {
            for i in selectedRows {
                let city = citiesToReview[i.row]
                approveACity(city, status: "Approved")
            }
        }
    }
    
    func rejectSelected() {
        let selectedRows: [IndexPath] = tableView.indexPathsForSelectedRows ?? []
        
        if selectedRows == [] {
        } else {
            for i in selectedRows {
                let city = citiesToReview[i.row]
                approveACity(city, status: "Rejected")
            }
        }
    }
}
