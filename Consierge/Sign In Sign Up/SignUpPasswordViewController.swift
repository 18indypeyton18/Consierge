//
//  SignUpPasswordViewController.swift
//  Consierge
//
//  Created by Austin McLaughlin on 12/27/23.
//

import UIKit

class SignUpPasswordViewController: UIViewController, UITextFieldDelegate {
    
    var email: String? = nil
    var firstName: String? = nil
    var lastName: String? = nil
    var latitude: Double? = nil
    var longitude: Double? = nil

    @IBOutlet var passWErr: UILabel!
    @IBOutlet var passWMatchErr: UILabel!
    @IBOutlet var passWText: UITextField!
    @IBOutlet var confirmPassWText: UITextField!
    
    @IBOutlet var createAcctButton: UIButton!
    
    var newUserRequestTask: Task<Void,Never>? = nil
    deinit { newUserRequestTask?.cancel() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        passWErr.isHidden = true
        passWMatchErr.isHidden = true
        createAcctButton.isEnabled = false
        // Do any additional setup after loading the view.
        styleTextFields()
    }
    
    func nextEnabled() {
        if passWText.text != "" && confirmPassWText.text != "" {
            if !(isValidPassword(passWText.text ?? "")) {
                passWErr.isHidden = false
                if passWText.text != confirmPassWText.text {
                    passWMatchErr.isHidden = false
                } else {
                    passWMatchErr.isHidden = true
                }
                createAcctButton.isEnabled = false
            } else if passWText.text != confirmPassWText.text {
                passWMatchErr.isHidden = false
                passWErr.isHidden = true
                createAcctButton.isEnabled = false
            } else {
                passWErr.isHidden = true
                passWMatchErr.isHidden = true
                createAcctButton.isEnabled = true
            }
        } else {
            createAcctButton.isEnabled = false
        }
    }
    
    func isValidPassword(_ pass: String) -> Bool {
        // validate the provided password. users NSPredicate to determine that the format meets NIST standards
        let passwordRegex = "^(?=.*\\d)(?=.*[a-z])(?=.*[A-Z])[0-9a-zA-Z!@#$%^&*()\\-_=+{}|?>.<,:;~`’]{8,}$"
        NSPredicate(format: "SELF MATCHES %@", passwordRegex).evaluate(with: pass)
        return NSPredicate(format: "SELF MATCHES %@", passwordRegex).evaluate(with: pass)
    }
    
    @IBAction func pwEdited(_ sender: Any) {
        nextEnabled()
    }
    
    @IBAction func createAccount(_ sender: Any) {
        createUserAccount()
    }
    
    func createUserAccount() {
        let pw = passWText.text
        if let email = email, let firstName = firstName, let lastName = lastName, let longitude = longitude, let latitude = latitude, let pw = pw {
            let newUser = User(id: 0, firstName: firstName, lastName: lastName, email: email, latitude: latitude, longitude: longitude, password: pw, role: "Noob")
            newUserRequestTask?.cancel()
            newUserRequestTask = Task {
                if let result = try? await NewUserRequest(user: newUser).send() {
                    if result["status"] == "Success" {
                        //user successfully registered
                        DispatchQueue.main.async {
                            //display message to the user
                            let myAlert = UIAlertController(title: "Alert", message: "User Registration Successful!", preferredStyle: UIAlertController.Style.alert)
                            let okAction = UIAlertAction(title: "Okay", style: UIAlertAction.Style.default) { action in
                                
                                //segue to Login page
                                self.performSegue(withIdentifier: "AccountCreated", sender: nil)
                            }
                            myAlert.addAction(okAction)
                            self.present(myAlert, animated: true, completion: nil)
                        }
                    } else if result["status"] == "error" {
                        //API returned an error - typically the provided email already exists in the DB
                        DispatchQueue.main.async {
                            let myAlert = UIAlertController(title: "Alert", message: result["message"], preferredStyle: UIAlertController.Style.alert)
                            let okAction = UIAlertAction(title: "Okay", style: UIAlertAction.Style.default)
                            myAlert.addAction(okAction)
                            self.present(myAlert, animated: true, completion: nil)
                        }
                    } else {
                        //undefined error with the API request
                        DispatchQueue.main.async {
                            let myAlert = UIAlertController(title: "Alert", message: "unknown error", preferredStyle: UIAlertController.Style.alert)
                            let okAction = UIAlertAction(title: "Okay", style: UIAlertAction.Style.default)
                            myAlert.addAction(okAction)
                            self.present(myAlert, animated: true, completion: nil)
                        }
                    }
                } else {
                    print(newUser)
                    let myAlert = UIAlertController(title: "Alert", message: "unknown error", preferredStyle: UIAlertController.Style.alert)
                    let okAction = UIAlertAction(title: "Okay", style: UIAlertAction.Style.default)
                    myAlert.addAction(okAction)
                    self.present(myAlert, animated: true, completion: nil)
                }
                newUserRequestTask = nil
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //Upon successful registration, segue to the userLogin page to prompt the user to sign in
        //autofill the email text field in that view
        if segue.identifier == "AccountCreated" {
            let signInController = segue.destination as! SignInViewController
            if let email = email {
                signInController.passedEmail = email
            }
        }
    }
    
    func styleTextFields() {
        //sets shadows for the text fields, sets delegates to enable the return key, and gesture recognizers to dismiss the keyboard
        let textFields = [passWText, confirmPassWText, createAcctButton]
        for textField in textFields {
            
            textField?.layer.shadowColor = UIColor.lightGray.cgColor
            textField?.layer.shadowOffset = CGSize(width: 0, height: 1)
            textField?.layer.shadowRadius = 2.0
            textField?.layer.shadowOpacity = 0.5
        }
        
        self.passWText.delegate = self
        self.confirmPassWText.delegate = self
        
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
        case passWText:
            confirmPassWText.becomeFirstResponder()
        default:
            if createAcctButton.isEnabled {
                createUserAccount()
            }
        }
    }
}
