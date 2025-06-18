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
    let deleteAccountIndexPath = IndexPath(row: 1, section: 0)
    let citiesToReview = IndexPath(row: 0, section: 1)
    let placesToReview = IndexPath(row: 1, section: 1)
    let placeEditsToReview = IndexPath(row: 2, section: 1)
    let additionalPhotosToReview = IndexPath(row: 3, section: 1)
    let commentsToReview = IndexPath(row: 4, section: 1)
    let tagsToReview = IndexPath(row: 5, section: 1)
    
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
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        switch section {
        case 1:
            return 6
        default:
            return 2
        }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath {
            
        case deleteAccountIndexPath:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Logout", for: indexPath)
            cell.textLabel?.text = "Delete Account"
            cell.textLabel?.textColor = .systemRed
            return cell
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
        case commentsToReview:
            let cell = tableView.dequeueReusableCell(withIdentifier: "AdminReview", for: indexPath)
            cell.textLabel?.text = "Comments"
            return cell
        case tagsToReview:
            let cell = tableView.dequeueReusableCell(withIdentifier: "AdminReview", for: indexPath)
            cell.textLabel?.text = "Tags"
            return cell
        default:
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
            handleLogout()
        case deleteAccountIndexPath:
            confirmAndDeleteAccount()
        case citiesToReview:
            performSegue(withIdentifier: "ReviewCities", sender: nil)
        case placesToReview:
            performSegue(withIdentifier: "ReviewPlaces", sender: nil)
        case placeEditsToReview:
            performSegue(withIdentifier: "ReviewPlaceEdits", sender: nil)
        case additionalPhotosToReview:
            performSegue(withIdentifier: "ReviewAdditionalPhotos", sender: nil)
        case commentsToReview:
            performSegue(withIdentifier: "ReviewComments", sender: nil)
        case tagsToReview:
            performSegue(withIdentifier: "ReviewTags", sender: nil)
        default: break
        }
    }
    
    private func handleLogout() {
        // identical to your existing logout logic :contentReference[oaicite:0]{index=0}&#8203;:contentReference[oaicite:1]{index=1}
        UserDefaults.standard.set(false, forKey: "loggedIn")
        let domain = Bundle.main.bundleIdentifier!
        currentUser = defaultUser
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        profPicture = nil
        userLovedPlaces = []
        askAISuggestedPrompts = []

        let bundle = Bundle(identifier: "com.ALMApps.Consierge")
        let storyboard = UIStoryboard(name: "Main", bundle: bundle)
        let homeController = storyboard.instantiateViewController(identifier: "HomePage")
        (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?
            .changeRootViewController(homeController)
    }
    
    private func confirmAndDeleteAccount() {
        let alert = UIAlertController(
            title: "Confirm Delete",
            message: "Are you sure you want to delete your account? This action cannot be undone.",
            preferredStyle: .alert
        )
        alert.addAction(.init(title: "Cancel", style: .cancel))
        alert.addAction(.init(title: "Delete", style: .destructive) { _ in
            Task {
                do {
                    let resp = try await DeleteAccountRequest(userID: String(currentUser.id)).send()
                    if resp["status"] == "Success" {
                        self.handleLogout()
                    } else {
                        self.showError(resp["message"] ?? "Unknown error")
                    }
                } catch {
                    self.showError(error.localizedDescription)
                }
            }
        })
        present(alert, animated: true)
    }

    private func showError(_ message: String) {
        let err = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        err.addAction(.init(title: "OK", style: .default))
        present(err, animated: true)
    }
}
