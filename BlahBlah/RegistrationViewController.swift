//
//  RegistrationViewController.swift
//  BlahBlah
//
//  Created by Sayantan Chakraborty on 18/01/17.
//  Copyright © 2017 Sayantan Chakraborty. All rights reserved.
//

import UIKit
class RegistrationViewController: UIViewController {
    
    @IBOutlet weak var txtName: UITextField!
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var signUp: UIButton!


    override func viewDidLoad() {
        super.viewDidLoad()
        signUp.layer.borderWidth = 0.5
        signUp.layer.borderColor = UIColor.white.cgColor
        
    }
    
    @IBAction func signUp(_ sender: UIButton) {
        
        guard !(txtName.text! == "" || txtEmail.text == "" || txtPassword.text == "") else {
            let alert = UIAlertController(title: "Error", message: "Need to fill all fields", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        BlahHelper.helper.createUserWithEmailAndPassword(name: txtName.text, email: txtEmail.text, password: txtPassword.text!)
    }
}
