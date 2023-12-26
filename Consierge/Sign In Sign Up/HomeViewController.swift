//
//  ViewController.swift
//  Consierge
//
//  Created by Austin McLaughlin on 12/26/23.
//

var currentUser = User(id: 0, firstName: "guest", lastName: "user", email: "GuestUser", latitude: nil, longitude: nil, password: "", username: nil, profPicImageURL: nil, role: "GuestUser", userIdentifier: nil)
let defaultUser = User(id: 0, firstName: "guest", lastName: "user", email: "GuestUser", latitude: nil, longitude: nil, password: "", username: nil, profPicImageURL: nil, role: "GuestUser", userIdentifier: nil)

import UIKit
import GoogleSignIn
import AuthenticationServices
import FBSDKLoginKit

class HomeViewController: UIViewController {
    @IBOutlet var consiergeMan: UIImageView!
    @IBOutlet var consiergeLabel: UILabel!
    @IBOutlet var signInButton: UIButton!
    @IBOutlet var createAccountButton: UIButton!
    @IBOutlet var skipButton: UIButton!
    @IBOutlet var googleSignInButton: GIDSignInButton!
    @IBOutlet var appleSignInPlaceHolder: UIStackView!
    @IBOutlet var facebookSignInPlaceHolder: UIStackView!
    
    //Create and cancel Tasks for API to use when user signs in with Google or Apple
    var newUserRequestTask: Task<Void,Never>? = nil
    var checkUserRequestTask: Task<Void,Never>? = nil
    var checkDefaultCityTask: Task<Void,Never>? = nil
    deinit {
        newUserRequestTask?.cancel()
        checkUserRequestTask?.cancel()
        checkDefaultCityTask?.cancel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        //animate Concierge Man :)
        UIView.animate(withDuration: 0.1, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.1, options: [], animations: {
            self.consiergeMan.transform = CGAffineTransform(scaleX: 0.05, y: 0.05)
        }, completion: nil)
        UIView.animate(withDuration: 3.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.1, options: [], animations: {
            self.consiergeMan.transform = CGAffineTransform.identity
        }, completion: nil)
        
        setupPage()
        stylePage()
    }
    
    func stylePage() {
        consiergeLabel.layer.shadowColor = UIColor.lightGray.cgColor
        consiergeLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        consiergeLabel.layer.shadowRadius = 2.5
        consiergeLabel.layer.shadowOpacity = 0.75
        
        consiergeMan.layer.shadowColor = UIColor.lightGray.cgColor
        consiergeMan.layer.shadowOffset = CGSize(width: 0, height: 2)
        consiergeMan.layer.shadowRadius = 2.5
        consiergeMan.layer.shadowOpacity = 0.75
        
        signInButton.layer.cornerRadius = 15
        signInButton.layer.borderWidth = 1
        signInButton.layer.borderColor = UIColor.systemGray2.cgColor
        signInButton.layer.shadowColor = UIColor.lightGray.cgColor
        signInButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        signInButton.layer.shadowRadius = 2.0
        signInButton.layer.shadowOpacity = 0.75
        createAccountButton.layer.cornerRadius = 15
        createAccountButton.layer.borderWidth = 1
        createAccountButton.layer.borderColor = UIColor.systemGray2.cgColor
        createAccountButton.layer.shadowColor = UIColor.lightGray.cgColor
        createAccountButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        createAccountButton.layer.shadowRadius = 2.0
        createAccountButton.layer.shadowOpacity = 0.75
        skipButton.layer.cornerRadius = 15
        skipButton.layer.borderWidth = 1
        skipButton.layer.borderColor = UIColor.systemGray2.cgColor
        skipButton.layer.shadowColor = UIColor.lightGray.cgColor
        skipButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        skipButton.layer.shadowRadius = 2.0
        skipButton.layer.shadowOpacity = 0.75
        
        googleSignInButton.style = .wide
        //googleSignInButton.colorScheme = .light
        googleSignInButton.layer.shadowColor = UIColor.lightGray.cgColor
        googleSignInButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        googleSignInButton.layer.shadowRadius = 2.0
        googleSignInButton.layer.shadowOpacity = 0.75
        googleSignInButton.layer.cornerRadius = 15
        
        appleSignInPlaceHolder.layer.cornerRadius = 15
        appleSignInPlaceHolder.layer.borderWidth = 1
        appleSignInPlaceHolder.layer.borderColor = UIColor.black.cgColor
        appleSignInPlaceHolder.layer.shadowColor = UIColor.lightGray.cgColor
        appleSignInPlaceHolder.layer.shadowOffset = CGSize(width: 0, height: 1)
        appleSignInPlaceHolder.layer.shadowRadius = 2.0
        appleSignInPlaceHolder.layer.shadowOpacity = 0.75
        
        facebookSignInPlaceHolder.layer.shadowColor = UIColor.lightGray.cgColor
        facebookSignInPlaceHolder.layer.shadowOffset = CGSize(width: 0, height: 1)
        facebookSignInPlaceHolder.layer.shadowRadius = 2.0
        facebookSignInPlaceHolder.layer.shadowOpacity = 0.75
    }
    
    func setupPage() {
        
        //autoLogin if User Defaults are already set
        if UserDefaults.standard.bool(forKey: "loggedIn") && UserDefaults.standard.string(forKey: "email") != "GuestUser" {
            Task {
                if currentUser.email == "GuestUser" {
                    if let user = try? await UserCheckRequest(userEmail: UserDefaults.standard.string(forKey: "email") ?? "").send() {
                        currentUser = user
                    }
                }
            }
            autoLogin()
        }
        
        let appleSignInButton = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
        appleSignInButton.addTarget(self, action: #selector(handleAuthorizationAppleIDButtonPress), for: .touchUpInside)
        self.appleSignInPlaceHolder.addArrangedSubview(appleSignInButton)
        
        let fbLoginButton = FBLoginButton()
        fbLoginButton.translatesAutoresizingMaskIntoConstraints = false
        facebookSignInPlaceHolder.addSubview(fbLoginButton)
        fbLoginButton.layer.cornerRadius = 15
        // Set up constraints
        NSLayoutConstraint.activate([
            fbLoginButton.leadingAnchor.constraint(equalTo: facebookSignInPlaceHolder.leadingAnchor),
            fbLoginButton.trailingAnchor.constraint(equalTo: facebookSignInPlaceHolder.trailingAnchor),
            fbLoginButton.topAnchor.constraint(equalTo: facebookSignInPlaceHolder.topAnchor),
            fbLoginButton.bottomAnchor.constraint(equalTo: facebookSignInPlaceHolder.bottomAnchor)
        ])
        
        if let token = AccessToken.current, !token.isExpired {
            print("User is logged in, do work such as go to next view controller.")
        }
        
        fbLoginButton.permissions = ["public_profile", "email"]
    }
    
    func autoLogin() {
        //Automatically segue to main TabController / CitySelectorTVC. Triggered when UserDefault key 'loggedIn' is true
        let bundle = Bundle(identifier: "com.ALMApps.Consierge")
        let storyboard = UIStoryboard(name: "Main", bundle: bundle)
        
        let mainTabBarController = storyboard.instantiateViewController(identifier: "MainTabBarController")
        
        (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(mainTabBarController)
    }
    
    @IBAction func continueAsGuest(_ sender: Any) {
        //set GuestUser for key email - directs user back to HomePage if they try to click Account tab. Set loggedIn to allow autoLogin in the future.
        UserDefaults.standard.set(true, forKey: "loggedIn")
        currentUser = defaultUser
        autoLogin()
    }
    
    @IBAction func signInWGoogle(_ sender: Any) {
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { signInResult, error in
            guard error == nil else { return }
            guard let signInResult = signInResult else { return }

            let user = signInResult.user

            let email = user.profile?.email
            
            let firstName = user.profile?.givenName
            let lastName = user.profile?.familyName

            let profilePicUrl = user.profile?.imageURL(withDimension: 320)
            if let email = email {
                //start user creation flow: Check if user exists -> (if no) signUpUser -> performLogin
                self.checkUser(email: email, firstName: firstName ?? "", lastName: lastName ?? "", userIdentifier: nil)
            }
            signInResult.user.refreshTokensIfNeeded { user, error in
                guard error == nil else { return }
                guard let user = user else { return }
                
                let idToken = user.idToken
                // Send ID token to backend (example below).
                // https://developers.google.com/identity/sign-in/ios/backend-auth
            }
        }
    }
    
    @objc
    func handleAuthorizationAppleIDButtonPress() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    func checkUser(email: String, firstName: String, lastName: String, userIdentifier: String?) {
        //API call to check for the user's email in the DB - if the user already exists in the DB set defaults and perform login, if the user doesn't yet exist in the DB sign them up and then peform login
        //Cancel and initiate new API task
        checkUserRequestTask?.cancel()
        checkUserRequestTask = Task {
            //UserCheckRequest selects email from DB and returns the results or an error
            if let user = try? await UserCheckRequest(userEmail: email).send() {
                UserDefaults.standard.set(true, forKey: "loggedIn")
                UserDefaults.standard.set(user.email, forKey: "email")
                currentUser = user
                //Perform Login!!
                DispatchQueue.main.async {
                    self.performLogin()
                }
            } else if let userIdentifier = userIdentifier, let user = try? await AppleUserCheckRequest(userIdentifier: userIdentifier).send() {
                currentUser = user
                //Perform Login!!
                DispatchQueue.main.async {
                    self.performLogin()
                }
            } else {
                //user Doesn't yet exist -> sign them up
                signUpUser(firstName: firstName, lastName: lastName, email: email, userIdentifier: userIdentifier)
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
    
    func signUpUser(firstName: String, lastName: String, email: String, userIdentifier: String?) {
        //dummy Password for DB. Real authentication is the user's Google/Apple credential
        let pass = UUID().uuidString
        
        //Initiate user with details from Google/Apple firstname, lastname, and email.
        var user = User(id: 1, firstName: firstName, lastName: lastName, email: email, latitude: 0.0, longitude: 0.0, password: pass, role: "Noob", userIdentifier: userIdentifier)
        //cancel and create new NewUser API request
        newUserRequestTask?.cancel()
        newUserRequestTask = Task {
            if let newUser = try? await NewUserRequest(user: user).send(), newUser["status"] == "Success" {
                //set user defaults
                UserDefaults.standard.set(true, forKey: "loggedIn")
                UserDefaults.standard.set(user.email, forKey: "email")
                user.id = Int(newUser["message"] ?? "0") ?? 0
                currentUser = user
                newUserRequestTask = nil
                DispatchQueue.main.async {
                    //Perform Login!
                    self.performLogin()
                }
            } else {
                //print to console if registration failed
                print("User Registration failed \(user)")
            }
        }
    }
}

//https://developer.apple.com/documentation/authenticationservices/implementing_user_authentication_with_sign_in_with_apple
extension HomeViewController: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        
        switch authorization.credential {
        case let credentials as ASAuthorizationAppleIDCredential:
            //if credentials were able to be captured, pass them to Check User and follow user registration or login flow.
            if let firstName = credentials.fullName?.givenName, let lastName = credentials.fullName?.familyName, let email = credentials.email {
                let userIdentifier = credentials.user
                checkUser(email: email, firstName: firstName, lastName: lastName, userIdentifier: userIdentifier)
                
            } else {
                let userIdentifier = credentials.user
                checkUser(email: "", firstName: "", lastName: "", userIdentifier: userIdentifier)
            }
        case let passwordCredential as ASPasswordCredential:
            
            // Sign in using an existing iCloud Keychain credential.
            let username = passwordCredential.user
            let password = passwordCredential.password
            print("username/password credential -------- unable to handle")
        default:
            print("credentials weren't properly captured - Apple Sign In")
        }
    }
}

extension HomeViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}
