//
//  SignInViewController.swift
//  Consierge
//
//  Created by Austin McLaughlin on 12/27/23.
//

import UIKit

class SignInViewController: UIViewController, UITextFieldDelegate {
    
    var passedEmail: String = ""
    var pw: String = ""
    var forgottenEmail: String? = ""
    
    @IBOutlet var userEmail: UITextField!
    @IBOutlet var userPass: UITextField!
    @IBOutlet var signInButton: UIButton!
    @IBOutlet var loginErr: UILabel!
    
    //Create and cancel Task for API to use when user signs in
    var userLoginRequestTask: Task<Void,Never>? = nil
    deinit { userLoginRequestTask?.cancel() }

    override func viewDidLoad() {
        super.viewDidLoad()
        loginErr.isHidden = true
        if passedEmail != "" {
            userEmail.text = passedEmail
            self.navigationItem.setHidesBackButton(true, animated: true)
        }
        styleTextFields()
    }
    

    @IBAction func loginPressed(_ sender: Any) {
        userLogin()
    }
    
    func userLogin() {
        //capture email and password
        let userEmail = userEmail.text;
        let userPass = userPass.text;
        
        //double check that email and password were both entered
        if (userEmail?.isEmpty==true || userPass?.isEmpty==true){return;}
        
        //Cancel and initiate new API task
        userLoginRequestTask?.cancel()
        userLoginRequestTask = Task {
            //send User Login API Request with email & Password
            if let user = try? await UserLoginRequest(userEmail: userEmail!, userPass: userPass!).send() {
                currentUser = user
                UserDefaults.standard.set(true, forKey: "loggedIn")
                UserDefaults.standard.set(user.email, forKey: "email")
                _ = CityGetter().getClosestCity(user: currentUser)
                DispatchQueue.main.async {
                    //Perform Login!
                    self.performLogin()
                }
            } else {
                loginErr.isHidden = false
            }
        }
    }
    
    func performLogin() {
        //segue to main TabController / CitySelectorTVC after a successful Sign in
        let bundle = Bundle(identifier: "com.ALMApps.Consierge")
        let storyboard = UIStoryboard(name: "Main", bundle: bundle)
        
        let mainTabBarController = storyboard.instantiateViewController(identifier: "MainTabBarController")
        
        (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(mainTabBarController)
    }
    
    @IBAction func unwindFromReset(_ sender: UIStoryboardSegue) {
        if let forgottenEmail = forgottenEmail {
            Task {
                if let result = try? await UserResetPWRequest(userEmail: forgottenEmail, resetPW: true).send(){
                    if result["status"] == "Success" {
                        DispatchQueue.main.async {
                            //display message to the user
                            let myAlert = UIAlertController(title: "Reset Sent", message: "Check your email inbox", preferredStyle: UIAlertController.Style.alert)
                            let okAction = UIAlertAction(title: "Okay", style: UIAlertAction.Style.default) { action in
                                self.userEmail.text = forgottenEmail
                            }
                            myAlert.addAction(okAction)
                            self.present(myAlert, animated: true, completion: nil)
                        }
                    } else if result["error"] == "Success" {
                        DispatchQueue.main.async {
                            let myAlert = UIAlertController(title: "Alert", message: result["message"], preferredStyle: UIAlertController.Style.alert)
                            let okAction = UIAlertAction(title: "Okay", style: UIAlertAction.Style.default)
                            myAlert.addAction(okAction)
                            self.present(myAlert, animated: true, completion: nil)
                        }
                    } else {
                        DispatchQueue.main.async {
                            let myAlert = UIAlertController(title: "Alert", message: "unknown error", preferredStyle: UIAlertController.Style.alert)
                            let okAction = UIAlertAction(title: "Okay", style: UIAlertAction.Style.default)
                            myAlert.addAction(okAction)
                            self.present(myAlert, animated: true, completion: nil)
                        }
                    }
                }
            }
        }
    }
    
    func styleTextFields() {
        //sets shadows for the text fields, sets delegates to enable the return key, and gesture recognizers to dismiss the keyboard
        let textFields = [userPass, userEmail, signInButton]
        for textField in textFields {
            
            textField?.layer.shadowColor = UIColor.lightGray.cgColor
            textField?.layer.shadowOffset = CGSize(width: 0, height: 1)
            textField?.layer.shadowRadius = 2.0
            textField?.layer.shadowOpacity = 0.5
        }
        
        self.userEmail.delegate = self
        self.userPass.delegate = self
        
        self.userEmail.userActivity?.isEligibleForPrediction = true
        self.userPass.userActivity?.isEligibleForPrediction = true
        
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tap)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // move to the next field if on the first 4 fields, press Login button if on the password field
        switchBasedNextTextField(textField)
        return true
    }
    
    private func switchBasedNextTextField(_ textField: UITextField) {
        // move to the next field if on the first 4 fields, press Login button if on the password field
        switch textField {
        case userEmail:
            userPass.becomeFirstResponder()
        default:
            userLogin()
        }
    }
}
