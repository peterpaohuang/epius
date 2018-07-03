//
//  SignupViewController.swift
//  voicenotes
//
//  Created by Peter Pao-Huang on 5/20/18.
//  Copyright © 2018 Peter Pao-Huang. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class SignupViewController: UIViewController {

    //Constants
    let signup_url = "http://127.0.0.1:3000/api/users"
    
    //Outlets
    @IBOutlet weak var textFieldSignupEmail: UITextField!
    @IBOutlet weak var textFieldSignupPassword: UITextField!
    @IBOutlet weak var textFieldSignupPasswordconfirmation: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    //Actions
    
    @IBAction func signupDidTouch(_ sender: Any) {
        let parameters: Parameters = [
            "user":
                ["email": textFieldSignupEmail.text!, "password": textFieldSignupPassword.text!, "password_confirmation": textFieldSignupPasswordconfirmation.text!]
        ]
        
        
        Alamofire.request(
            signup_url,
            method: .post,
            parameters: parameters,
            headers:nil).responseJSON {
                (response) in
                print(response.result.value!)
                if let current_user_session = response.result.value as! NSDictionary?
                {
                    let statusCode = response.response?.statusCode
                    print(statusCode!)
                    if(statusCode == 201){
                        print(current_user_session)
                        self.performSegue(withIdentifier: "SignupToHome", sender: nil)
                    }
                    
                }
                
        }
    }


    // MARK: - Navigation


}
