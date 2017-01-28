//
//  MessagesTVC.swift
//  BlahBlah
//
//  Created by Sayantan Chakraborty on 27/01/17.
//  Copyright © 2017 Sayantan Chakraborty. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class ChatsTVC: UITableViewCell{
    
    @IBOutlet weak var imgUser: UIImageView!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblAccessory: UILabel!
    
    @IBOutlet weak var lblTime: UILabel!
    var message: Messages? {
        didSet {
            setUpNameAndImage()
            lblAccessory.text = message?.Text
            if let secs = message?.TimeStamp {
                let timeStampDate = NSDate(timeIntervalSince1970: TimeInterval(secs))
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "hh:mm a"
                lblTime.text = dateFormatter.string(from: timeStampDate as Date)
                
            }
        }
    }
    
    private func setUpNameAndImage(){
            if let id = message?.chatPartnerId(){
            let ref = FIRDatabase.database().reference().child("Users").child(id)
            ref.observeSingleEvent(of: .value, with: { (snapshot) in
                if let dictionary = snapshot.value as? [String:AnyObject]{
                    self.lblName.text = dictionary["displayName"] as! String?
                    
                    if let profileImg = dictionary["profileUrl"] as! String? {
                        self.imgUser.loadImageFromImageUrlFromCache(url: profileImg)
                        self.imgUser?.layer.cornerRadius = self.imgUser.bounds.size.width * 0.5
                        self.imgUser?.layer.masksToBounds = false
                        self.imgUser?.clipsToBounds = true
                        
                    }
                }
            })
        }
    }
}
class MessagesTVC: UITableViewController {

    var messages = [Messages]()
    var messagesDict = [String:Messages]()
    var userToSend: User?
    @IBOutlet var tblViewChats: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        //observeMessages()
        observeUserMessages()
    }
    
    func observeUserMessages(){
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            return
        }
        let ref = FIRDatabase.database().reference().child("user-messages").child(uid)
        ref.observe(.childAdded, with: { (snapshot) in
            let messageId = snapshot.key
            let messagesRef = FIRDatabase.database().reference().child("messages").child(messageId)
            
            messagesRef.observeSingleEvent(of: .value, with: { (msgSnapshot) in
                
                if let dict = msgSnapshot.value as? [String:AnyObject]{
                    let message = Messages()
                    message.SenderFrom = dict["SenderFrom"] as? String
                    message.SenderTo = dict["SenderTo"] as? String
                    message.MessageType = dict["MessageType"] as? String
                    message.TimeStamp = dict["TimeStamp"] as? Int
                    message.ImageUrl = dict["ImageUrl"] as? String
                    message.Text = dict["Text"] as? String
                    //self.messages.append(message)
                    
                    if let toId = message.SenderTo {
                        self.messagesDict[toId] = message
                        
                        self.messages = Array(self.messagesDict.values)
                        self.messages.sort(by: { (m1, m2) -> Bool in
                            return (m1.TimeStamp?.toIntMax())! > (m2.TimeStamp?.toIntMax())!
                        })
                    }
                }
                DispatchQueue.main.async {
                    self.tblViewChats.reloadData()
                }
            })
        })
    }
    
    func observeMessages() {
        let ref = FIRDatabase.database().reference().child("messages")
        ref.observe(.childAdded) { (snapshot:FIRDataSnapshot) in
            if let dict = snapshot.value as? [String:AnyObject]{
                let message = Messages()
                message.SenderFrom = dict["SenderFrom"] as? String
                message.SenderTo = dict["SenderTo"] as? String
                message.MessageType = dict["MessageType"] as? String
                message.TimeStamp = dict["TimeStamp"] as? Int
                message.ImageUrl = dict["ImageUrl"] as? String
                message.Text = dict["Text"] as? String
                //self.messages.append(message)
                
                if let toId = message.SenderTo {
                    self.messagesDict[toId] = message
                    
                    self.messages = Array(self.messagesDict.values)
                    self.messages.sort(by: { (m1, m2) -> Bool in
                        return (m1.TimeStamp?.toIntMax())! > (m2.TimeStamp?.toIntMax())!
                    })
                }
            }
            DispatchQueue.main.async {
                self.tblViewChats.reloadData()
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return messages.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath) as! ChatsTVC
        let message = messages[indexPath.row]
        cell.message = message
        // Configure the cell...

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message = messages[(indexPath.row)]
        guard let chatPartnerId = message.chatPartnerId() else {
            return
        }
        let ref = FIRDatabase.database().reference().child("Users").child(chatPartnerId)
        ref.observeSingleEvent(of: .value, with: { (snap) in
            guard let dict = snap.value as? [String:AnyObject] else{
                return
            }
            let user = User()
            user.id = dict["id"] as? String
            user.name = dict["displayName"] as? String
            user.profilePic = dict["profileUrl"] as? String
            user.email = dict["email"] as? String
            
            self.userToSend = user
            self.performSegue(withIdentifier: "segueToChat", sender: nil)
//            let storyboard = UIStoryboard(name: "Main", bundle: nil)
//            let controller = storyboard.instantiateViewController(withIdentifier: "ChatLogCVC")
//            //self.present(controller, animated: true, completion: nil)
//            if controller is ChatLogCVC {
//                let controller1 = controller as! ChatLogCVC
//                controller1.user = user
//                self.navigationController?.present(controller, animated: true, completion: nil)
//            }
        })

    }
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.destination is ChatLogCVC {
            let dest = segue.destination as! ChatLogCVC
            dest.user = userToSend!
        }
    }
    

}
