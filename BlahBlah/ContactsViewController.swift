//
//  ContactsViewController.swift
//  BlahBlah
//
//  Created by Sayantan Chakraborty on 18/01/17.
//  Copyright © 2017 Sayantan Chakraborty. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

class ContactsTableViewCell: UITableViewCell{
    
    @IBOutlet weak var imgProfilePic: UIImageView!
    @IBOutlet weak var lblDisplayName: UILabel!
    @IBOutlet weak var lblDetail: UILabel!
    
}

class ContactsViewController: UIViewController,UIBarPositioningDelegate,UITableViewDelegate,UITableViewDataSource,UIImagePickerControllerDelegate,UINavigationControllerDelegate {


    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var contactsTblView: UITableView!
    var users = [User]()
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        //fetchLoggedinUserName()
        //self.tabBarController?.tabBar.isHidden = false
        fetchUsers()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let statusBar: UIView = UIApplication.shared.value(forKey: "statusBar") as! UIView
        statusBar.backgroundColor = UIColor.red
        //self.navBar.tintColor = UIColor.red
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.default
    }
    func fetchUsers(){
        
        DispatchQueue.global(qos: .userInitiated).async {
            FIRDatabase.database().reference().child("Users").observe(.childAdded) { (snapshot:FIRDataSnapshot) in
                print(snapshot)
                if let dict = snapshot.value as? [String:AnyObject]{
                    let user = User()
                    user.id = dict["id"] as? String
                    user.name = dict["displayName"] as? String
                    user.profilePic = dict["profileUrl"] as? String
                    user.email = dict["email"] as? String
                    
                    self.users.append(user)
                }
                DispatchQueue.main.async {
                    self.contactsTblView.reloadData()
                }
            }
            
        }
    }
    
    func fetchLoggedinUserName(){
        if let uid = FIRAuth.auth()?.currentUser?.uid{
            FIRDatabase.database().reference().child("Users").child(uid).observeSingleEvent(of: .value, with: { (snap:FIRDataSnapshot) in
                print(snap)
                if let dict = snap.value as? [String:AnyObject]{
                    self.navigationItem.title = dict["displayName"] as? String
                }
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func logOut(_ sender: UIBarButtonItem) {
        do {
            try FIRAuth.auth()?.signOut()
        } catch let error {
            print(error.localizedDescription)
        }
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let loginVC = storyBoard.instantiateViewController(withIdentifier: "TabBarVc")
        let appdel = UIApplication.shared.delegate as! AppDelegate
        appdel.window?.rootViewController = loginVC
    }

    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
    
    @IBAction func profileImage(_ sender: UIBarButtonItem) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        var selectedImagePicker:UIImage?
        if let editeImage = info[UIImagePickerControllerEditedImage] as? UIImage{
            selectedImagePicker = editeImage
        }else if let origImage = info[UIImagePickerControllerOriginalImage] as? UIImage{
            selectedImagePicker = origImage
        }
        
        if let selectedImage = selectedImagePicker{
            sendMedia(photo: selectedImage, video: nil)
            
//           self.navBar.topItem?.rightBarButtonItem = nil
////           let barItem = UIBarButtonItem(image: selectedImage, style: .plain, target: nil, action: #selector(ContactsViewController.profileImage(_:)))
//            
//           let barButton = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
//            barButton.setBackgroundImage(selectedImage, for: .normal)
//            barButton.addTarget(self, action: #selector(ContactsViewController.profileImage(_:)), for: .touchUpInside)
//            //barItem.tintColor = UIColor.black
//            self.navigationItem.rightBarButtonItem? = UIBarButtonItem(customView: barButton)
            
        }
        
        self.dismiss(animated: true, completion: nil)
        
    }
    
    //MARK: Utility
    func sendMedia(photo:UIImage?, video:NSURL?){
        
        if let photo = photo {
            let uploadFirbasepath = "\((FIRAuth.auth()?.currentUser?.uid)!)/\(NSDate.timeIntervalSinceReferenceDate)"
            let data = UIImageJPEGRepresentation(photo, 0.1)
            let metadata = FIRStorageMetadata()
            metadata.contentType = "image/jpg"
            FIRStorage.storage().reference().child(uploadFirbasepath).put(data!, metadata: metadata) { (downMeta, error:Error?) in
                guard error == nil else{
                    print(error?.localizedDescription ?? "no error desc")
                    return
                }
                let fileUrl = downMeta?.downloadURLs?[0].absoluteString
            
                FIRDatabase.database().reference().child("Users").child((FIRAuth.auth()?.currentUser?.uid)!).updateChildValues(["profileUrl":fileUrl!])
            }
        }
        else if let video = video{
            let uploadFirbasepath = "\((FIRAuth.auth()?.currentUser?.uid)!)/\(NSDate.timeIntervalSinceReferenceDate)"
            let data = NSData(contentsOf: video as URL)
            let metadata = FIRStorageMetadata()
            metadata.contentType = "video/mp4"
            FIRStorage.storage().reference().child(uploadFirbasepath).put(data! as Data, metadata: metadata) { (downMeta, error:Error?) in
                guard error == nil else{
                    print(error?.localizedDescription ?? "no error desc")
                    return
                }
                let fileUrl = downMeta?.downloadURLs?[0].absoluteString
//                let newMessage = self.messageRef.childByAutoId()
//                let messageData = ["fileUrl":fileUrl!,"senderID":self.senderId,"senderName":self.senderDisplayName,"MediaType":"VIDEO"] as [String : Any]
//                newMessage.setValue(messageData)
            }
            
        }
    }
    // MARK: - TableView Delegates
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "contactsCell", for: indexPath) as! ContactsTableViewCell
        cell.lblDisplayName?.text = users[indexPath.row].name
        cell.lblDetail.text = users[indexPath.row].email
        let imgUrl = users[indexPath.row].profilePic
        if  !(imgUrl == "") {
            cell.imgProfilePic.loadImageFromImageUrlFromCache(url: imgUrl!)
        }else{
            cell.imgProfilePic?.image = UIImage(named: "trooper")
        }
        cell.imgProfilePic?.layer.cornerRadius = cell.imgProfilePic.bounds.size.width * 0.5
        cell.imgProfilePic?.layer.masksToBounds = false
        cell.imgProfilePic?.clipsToBounds = true
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
//        self.present(chatlog, animated: true, completion: nil)
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.destination is ChatLogCVC {
            let dest = segue.destination as! ChatLogCVC
            let index = self.contactsTblView.indexPathForSelectedRow
            dest.user = users[(index?.row)!]
        }
    }
    

}
