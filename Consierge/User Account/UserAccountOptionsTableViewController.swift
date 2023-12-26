//
//  UserAccountOptionsTableViewController.swift
//  Consierge
//
//  Created by Austin McLaughlin on 12/28/23.
//

import UIKit

class UserAccountOptionsTableViewController: UITableViewController {

    var userRole = "Noob"
    
    let logoutIndexPath = IndexPath(row: 0, section: 0)
    let citiesToReview = IndexPath(row: 0, section: 1)
    let placesToReview = IndexPath(row: 1, section: 1)
    let placeEditsToReview = IndexPath(row: 2, section: 1)
    let additionalPhotosToReview = IndexPath(row: 3, section: 1)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getUserRole()
        tableView.delegate = self
    }
    
    func getUserRole() {
        userRole = currentUser.role
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        switch userRole {
        case "Admin":
            return 2
        default:
            print("1 SECTION!!!!!!!!")
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        switch section {
        case 1:
            return 4
        default:
            print("1 ITEM!!!!!!!!")
            return 1
        }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath {
        case citiesToReview:
            let cell = tableView.dequeueReusableCell(withIdentifier: "AdminReview", for: indexPath)
            cell.textLabel?.text = "New Cities"
            return cell
        case placesToReview:
            let cell = tableView.dequeueReusableCell(withIdentifier: "AdminReview", for: indexPath)
            cell.textLabel?.text = "New Places"
            return cell
        case placeEditsToReview:
            let cell = tableView.dequeueReusableCell(withIdentifier: "AdminReview", for: indexPath)
            cell.textLabel?.text = "New Place Edits"
            return cell
        case additionalPhotosToReview:
            let cell = tableView.dequeueReusableCell(withIdentifier: "AdminReview", for: indexPath)
            cell.textLabel?.text = "Additional Photos"
            return cell
        default:
            print("LOGOUT CELL!!!!!!!!")
            let cell = tableView.dequeueReusableCell(withIdentifier: "Logout", for: indexPath)
            return cell
        }
        
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Options"
        default:
            return "Admin Review"
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath {
        case logoutIndexPath:
            //Logout action -> remove all UserDefaults data and return user to the Home Page
            UserDefaults.standard.set(false, forKey: "loggedIn")
            let domain = Bundle.main.bundleIdentifier!
            currentUser = defaultUser
            UserDefaults.standard.removePersistentDomain(forName: domain)
            UserDefaults.standard.synchronize()
            
            let bundle = Bundle(identifier: "com.ALMApps.Concierge-0-4")
            let storyboard = UIStoryboard(name: "Main", bundle: bundle)
            
            let homeController = storyboard.instantiateViewController(identifier: "HomePage")
            (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(homeController)
        case citiesToReview:
            performSegue(withIdentifier: "ReviewCities", sender: nil)
        case placesToReview:
            performSegue(withIdentifier: "ReviewPlaces", sender: nil)
        case placeEditsToReview:
            performSegue(withIdentifier: "ReviewPlaceEdits", sender: nil)
        case additionalPhotosToReview:
            performSegue(withIdentifier: "ReviewAdditionalPhotos", sender: nil)
        default: break
        }
    }
}
