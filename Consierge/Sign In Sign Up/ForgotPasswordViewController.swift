//
//  ForgotPasswordViewController.swift
//  Consierge
//
//  Created by Austin McLaughlin on 12/27/23.
//

import UIKit

class ForgotPasswordViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var forgottenEmailText: UITextField!
    @IBOutlet var resetButton: UIButton!
    @IBOutlet var emailErr: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailErr.isHidden = true
        resetButton.isEnabled = false
        styleTextFields()
    }
    

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let dest = segue.destination as! SignInViewController
        dest.forgottenEmail = forgottenEmailText.text
    }
    
    func isValidEmail(_ email: String) -> Bool {
        // validate the provided email. users NSPredicate to determine that the format is valid
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }

    @IBAction func forgottenEmailChanged(_ sender: Any) {
        if !(isValidEmail(forgottenEmailText.text ?? "")) {
            resetButton.isEnabled = false
            emailErr.isHidden = false
        } else {
            resetButton.isEnabled = true
            emailErr.isHidden = true
        }
    }
    
    func styleTextFields() {
        //sets shadows for the text fields, sets delegates to enable the return key, and gesture recognizers to dismiss the keyboard
        let textFields = [forgottenEmailText, resetButton]
        for textField in textFields {
            textField?.layer.shadowColor = UIColor.lightGray.cgColor
            textField?.layer.shadowOffset = CGSize(width: 0, height: 1)
            textField?.layer.shadowRadius = 2.0
            textField?.layer.shadowOpacity = 0.5
        }
        
        forgottenEmailText.delegate = self
        
        forgottenEmailText.userActivity?.isEligibleForPrediction = true
        
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tap)
    }
}
