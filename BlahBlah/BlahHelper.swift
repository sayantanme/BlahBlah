//
//  BlahHelper.swift
//  BlahBlah
//
//  Created by Sayantan Chakraborty on 12/01/17.
//  Copyright © 2017 Sayantan Chakraborty. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth
import GoogleSignIn
import FirebaseDatabase

class BlahHelper {
    static let helper = BlahHelper()
    
    
    func loginAnonymously() {
        
        FIRAuth.auth()?.signInAnonymously(completion: { (anonymousUser:FIRUser?, error:Error?) in
            guard error == nil else{
                print(error!.localizedDescription)
                return
            }
            print("uid:\(anonymousUser?.uid)")
            let newUser = FIRDatabase.database().reference().child("Users").child(anonymousUser!.uid)
            newUser.setValue(["displayName":"anonymous","id":"\((anonymousUser?.uid)!)","profileUrl":"","email":""])
            self.switchToAppNavigationController()
        })
        
    }
    
    func createUserWithEmailAndPassword(name: String?, email: String?, password: String) {
        
        FIRAuth.auth()?.createUser(withEmail: email!, password: password, completion: { (user:FIRUser?, error:Error?) in
            guard error == nil else{
                print(error!.localizedDescription)
                return
            }
            
            let newUser = FIRDatabase.database().reference().child("Users").child(user!.uid)
            newUser.setValue(["displayName":name,"id":"\((user?.uid)!)","profileUrl":"","email":email,"password":password])
            self.switchToAppNavigationController()

        })
    }
    
    func loginWithUsernameAndPassword(email: String, password: String){
        FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: { (user:FIRUser?, error:Error?) in
            guard error == nil else{
                print(error!.localizedDescription)
                return
            }
            self.switchToAppNavigationController()
        })
        
    }
    
    func loginWithGoogle(authentication:GIDAuthentication) {
        let credential = FIRGoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken);
        
        FIRAuth.auth()?.signIn(with: credential, completion: { (user:FIRUser?, error:Error?) in
            guard error == nil else{
                print(error!.localizedDescription)
                return
            }
            print(user?.displayName! ?? "no name")
            print(user?.email! ?? "no email")
            let newUser = FIRDatabase.database().reference().child("Users").child(user!.uid)
            newUser.setValue(["displayName":"\((user?.displayName)!)","id":"\((user?.uid)!)","profileUrl":"\((user?.photoURL)!)","email":"\((user?.email)!)"])
            self.switchToAppNavigationController()
        })
    }
    
    func switchToNavigationController(){
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let naviVC = storyBoard.instantiateViewController(withIdentifier: "NaviVC") as! UINavigationController
        let appDel = UIApplication.shared.delegate as! AppDelegate
        appDel.window?.rootViewController = naviVC
    }
    
    func switchToAppNavigationController(){
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let naviVC = storyBoard.instantiateViewController(withIdentifier: "appNavigation") as! UITabBarController
        let appDel = UIApplication.shared.delegate as! AppDelegate
        appDel.window?.rootViewController = naviVC
    }
}
