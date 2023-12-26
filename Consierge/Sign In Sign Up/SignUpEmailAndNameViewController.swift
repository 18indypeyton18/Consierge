//
//  SignUpEmailAndNameViewController.swift
//  Consierge
//
//  Created by Austin McLaughlin on 12/27/23.
//

import UIKit

class SignUpEmailAndNameViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet var emailText: UITextField!
    @IBOutlet var firstNameText: UITextField!
    @IBOutlet var lastNameText: UITextField!
    
    @IBOutlet var nextButton: UIButton!
    @IBOutlet var emailErr: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nextButton.isEnabled = false
        emailErr.isHidden = true
        styleTextFields()
    }
    
    
    @IBSegueAction func segueToSignUpLocation(_ coder: NSCoder) -> SignUpLocationViewController? {
        
        let email = emailText.text ?? ""
        let firstName = firstNameText.text ?? ""
        let lastName = lastNameText.text ?? ""
        
        return SignUpLocationViewController(coder: coder, email: email, firstName: firstName, lastName: lastName)
    }
    
    func nextEnabled() {
        if emailText.text != "" && firstNameText.text != "" && lastNameText.text != "" {
            if !(isValidEmail(emailText.text ?? "")) {
                emailErr.isHidden = false
                nextButton.isEnabled = false
            } else {
                emailErr.isHidden = true
                nextButton.isEnabled = true
            }
        }
    }
    
    
    @IBAction func textFieldChanged(_ sender: Any) {
        nextEnabled()
    }
    
    func isValidEmail(_ email: String) -> Bool {
        // validate the provided email. users NSPredicate to determine that the format is valid
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    func styleTextFields() {
        //sets shadows for the text fields, sets delegates to enable the return key, and gesture recognizers to dismiss the keyboard
        let textFields = [emailText, firstNameText, lastNameText, nextButton]
        for textField in textFields {
            
            textField?.layer.shadowColor = UIColor.lightGray.cgColor
            textField?.layer.shadowOffset = CGSize(width: 0, height: 1)
            textField?.layer.shadowRadius = 2.0
            textField?.layer.shadowOpacity = 0.5
        }
        
        self.emailText.delegate = self
        self.firstNameText.delegate = self
        self.lastNameText.delegate = self
        
        self.emailText.userActivity?.isEligibleForPrediction = true
        self.firstNameText.userActivity?.isEligibleForPrediction = true
        self.lastNameText.userActivity?.isEligibleForPrediction = true
        
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
        case emailText:
            firstNameText.becomeFirstResponder()
        case firstNameText:
            lastNameText.becomeFirstResponder()
        default:
            if nextButton.isEnabled {
                performSegue(withIdentifier: "segueToSignUpLocation", sender: nil)
            }
        }
    }
}
