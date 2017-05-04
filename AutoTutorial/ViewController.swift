//
//  ViewController.swift
//  AutoTutorial
//
//  Created by Tula Ram Subba on 5/3/17.
//  Copyright © 2017 Tula Ram Subba. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import SwiftyPlistManager

class ViewController: UIViewController {
    
    @IBOutlet weak var signInSelector: UISegmentedControl!
    @IBOutlet weak var signInLabel: UILabel!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    
    var isSignIn:Bool = true
    let dataPlistName = "Login"
    let usernameKey = "username"  // plist username key
    let pneStatusKey = "pneStatus"  // push notification enablement status key
    let fcmIdKey = "fcmId"  // plist fcmId key
    var usernameValue:String = ""  // plist username value to post to Sinatra app
    var pneStatusValue:String = ""  // push notification enablement status value to post to Sinatra app
    var fcmIdValue:String = ""  // plist fcmID value to post to Sinatra app
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Initialize plist if present, otherwise copy over Login.plist file into app's Documents directory
        SwiftyPlistManager.shared.start(plistNames: [dataPlistName], logging: false)
        
    }
   
    override func viewDidAppear(_ animated: Bool) {
        
        if FIRAuth.auth()?.currentUser != nil {
            self.performSegue(withIdentifier: "goToHome", sender: self)

        }
    }

    @IBAction func signInSelectorChanged(_ sender: UISegmentedControl) {
        isSignIn = !isSignIn
        
        if isSignIn {
            signInLabel.text = "Sign In"
            signInButton.setTitle("Sign In", for: .normal)
        }
        else {
            signInLabel.text = "Register"
            signInButton.setTitle("Register", for: .normal)
        }
    }
   
    
    @IBAction func signInButtonTapped(_ sender: UIButton) {
        if let email = emailTextField.text, let password = passwordTextField.text {
            
            self.checkPneStatus()
            self.evaluatePlist(self.pneStatusKey, self.pneStatusValue)
            self.evaluatePlist(self.usernameKey, email)
            self.postData()
            
            if isSignIn {
                FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: { (user, error) in
                    if let u = user {
                        self.performSegue(withIdentifier: "goToHome", sender: self)
                        
                    }
                    else {
                        //Error: check error and show message
                    }
                })
            }
            else {
                FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { (user, error) in
                    if let u = user {
                        self.performSegue(withIdentifier: "goToHome", sender: self)
                    }
                })
            }
            
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
    }
 
    // Function to determine push notification enablement status
    func checkPneStatus() {
        let notificationType = UIApplication.shared.currentUserNotificationSettings!.types
        if notificationType == [] {
            pneStatusValue = "0"
            print("notifications are NOT enabled")
        } else {
            pneStatusValue = "1"
            print("notifications are enabled")
        }
    }
    
    // Function to determine if plist is already populated
    func evaluatePlist(_ key:String, _ value:String) {
        
        // Run function to add key/value pairs if plist empty, otherwise run function to update values
        SwiftyPlistManager.shared.getValue(for: key, fromPlistWithName: dataPlistName) { (result, err) in
            if err != nil {
                populatePlist(key, value)
            } else {
                updatePlist(key, value)
            }
        }
    }
    
    // Function to populate empty plist file with specified key/value pair
    func populatePlist(_ key:String, _ value:String) {
        SwiftyPlistManager.shared.addNew(value, key: key, toPlistWithName: dataPlistName) { (err) in
            if err == nil {
                print("-------------> Value '\(value)' successfully added at Key '\(key)' into '\(dataPlistName).plist'")
            }
        }
    }
    
    // Function to update specified key/value pair in plist file
    func updatePlist(_ key:String, _ value:String) {
        SwiftyPlistManager.shared.save(value, forKey: key, toPlistWithName: dataPlistName) { (err) in
            if err == nil {
                print("------------------->  Value '\(value)' successfully saved at Key '\(key)' into '\(dataPlistName).plist'")
            }
        }
    }
    
    // Function to read email key/value pairs out of plist
    func readPlistEmail(_ key:Any) {
        
        // Retrieve value
        SwiftyPlistManager.shared.getValue(for: key as! String, fromPlistWithName: dataPlistName) { (result, err) in
            if err == nil {
                guard let result = result else {
                    print("-------------> The Value for Key '\(key)' does not exists.")
                    return
                }
                print("------------> The value for the emailValue variable is \(usernameValue).")
                usernameValue = result as! String
            } else {
                print("No key in there!")
            }
        }
    }
    
    // Function to read push notification enablement status key/value pairs out of plist
    func readPlistPneStatus(_ key:Any) {
        
        // Retrieve value
        SwiftyPlistManager.shared.getValue(for: key as! String, fromPlistWithName: dataPlistName) { (result, err) in
            if err == nil {
                guard let result = result else {
                    print("-------------> The Value for Key '\(key)' does not exists.")
                    return
                }
                print("------------> The value for the pneStatusValue variable is \(pneStatusValue).")
                pneStatusValue = result as! String
            } else {
                print("No key in there!")
            }
        }
    }
    
    // Function to read fcmID key/value pairs out of plist
    func readPlistFcm(_ key:Any) {
        
        // Retrieve value
        SwiftyPlistManager.shared.getValue(for: key as! String, fromPlistWithName: dataPlistName) { (result, err) in
            if err == nil {
                guard let result = result else {
                    print("-------------> The Value for Key '\(key)' does not exists.")
                    return
                }
                fcmIdValue = result as! String
                print("------------> The value for the fcmIdValue variable is \(fcmIdValue).")
            } else {
                print("No key in there!")
            }
        }
    }
    
    // Function to post email and Firebase token to Sinatra app
    func postData() {
        
        var request = URLRequest(url: URL(string: "https://mm-pushnotification.herokuapp.com/post_id")!)  // test to project Heroku-hosted app
        
        readPlistEmail(usernameKey)  // update usernameValue with plist value
        readPlistPneStatus(pneStatusKey)  // update pneStatusValue with plist value
        readPlistFcm(fcmIdKey)  // update fcmIdValue with plist value
        
        let email = usernameValue
        let pneStatus = pneStatusValue
        let fcmID = fcmIdValue
        let postString = "email=\(email)&pne_status=\(pneStatus)&fcm_id=\(String(describing: fcmID))"
        
        request.httpMethod = "POST"
        request.httpBody = postString.data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {                                                 // check for fundamental networking error
                print("error=\(String(describing: error))")
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(String(describing: response))")
            }
            
            let responseString = String(data: data, encoding: .utf8)
            print("responseString = \(String(describing: responseString))")
        }
        task.resume()
    }
    
}

