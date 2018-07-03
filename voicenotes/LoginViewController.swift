//
//  LoginViewController.swift
//  voicenotes
//
//  Created by Peter Pao-Huang on 5/20/18.
//  Copyright © 2018 Peter Pao-Huang. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

var current_user_session:NSDictionary? = nil

class LoginViewController: UIViewController {

    //Constants
    let login_url = "http://127.0.0.1:3000/api/sessions"
    
    //Outlets

    @IBOutlet weak var textFieldLoginEmail: UITextField!
    @IBOutlet weak var textFieldLoginPassword: UITextField!
    
    //viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        textFieldLoginEmail.text = "peter.paohuang@gmail.com"
        textFieldLoginPassword.text = "falcon"
        
    }
    
    
    //Actions
    @IBAction func loginDidTouch(_ sender: Any) {
        let parameters: Parameters = ["email": textFieldLoginEmail.text!, "password": textFieldLoginPassword.text!]
        
        
        Alamofire.request(
            login_url,
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.default,
            headers:nil).responseJSON {
                (response) in
                
                current_user_session = response.result.value as! NSDictionary?
                if current_user_session == response.result.value as! NSDictionary?
                {
                    let statusCode = response.response?.statusCode
                    if(statusCode == 200){
                        print(current_user_session)
                        self.performSegue(withIdentifier: "LoginToHome", sender: nil)
                    }
                }
                
        }
    }


}
