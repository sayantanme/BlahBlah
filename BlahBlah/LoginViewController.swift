//
//  ViewController.swift
//  BlahBlah
//
//  Created by Sayantan Chakraborty on 10/01/17.
//  Copyright © 2017 Sayantan Chakraborty. All rights reserved.
//

import UIKit
import FirebaseAuth
import GoogleSignIn
import FirebaseAuth

class LoginViewController: UIViewController,GIDSignInUIDelegate,GIDSignInDelegate {

    @IBOutlet weak var anonymousButton: UIButton!
    @IBOutlet weak var googSignIn: GIDSignInButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        anonymousButton.layer.borderWidth = 0.5
        anonymousButton.layer.borderColor = UIColor.white.cgColor
        googSignIn.style = .wide
        GIDSignIn.sharedInstance().clientID = "758384767415-me184vqchcgnmh1c4q823vnfob0g89bk.apps.googleusercontent.com";
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print(FIRAuth.auth()?.currentUser)
        FIRAuth.auth()?.addStateDidChangeListener({ (auth:FIRAuth, user:FIRUser?) in
            if user != nil {
                BlahHelper.helper.switchToNavigationController()
            }
        })
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func loginAnonymouslyTapped(_ sender: UIButton) {
        BlahHelper.helper.loginAnonymously()
    }
    
    @IBAction func googleSignInTapped(_ sender: UIButton) {
    }
    
    // MARK: - Google Sign In Delegate methods
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        guard error == nil else {
            print(error.localizedDescription)
            return
        }
        print(user.profile.name)
        BlahHelper.helper.loginWithGoogle(authentication: user.authentication)
    }
}

