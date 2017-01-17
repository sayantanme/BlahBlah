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
            self.switchToNavigationController()
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
            self.switchToNavigationController()
        })
    }
    
    func switchToNavigationController(){
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let naviVC = storyBoard.instantiateViewController(withIdentifier: "NaviVC") as! UINavigationController
        let appDel = UIApplication.shared.delegate as! AppDelegate
        appDel.window?.rootViewController = naviVC
    }
}
