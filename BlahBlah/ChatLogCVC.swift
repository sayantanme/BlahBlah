//
//  ChatLogCVC.swift
//  BlahBlah
//
//  Created by Sayantan Chakraborty on 26/01/17.
//  Copyright © 2017 Sayantan Chakraborty. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

private let reuseIdentifier = "Cell"

class ChatLogCVC: UICollectionViewController,UITextFieldDelegate,UICollectionViewDelegateFlowLayout {

    lazy var inputTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter message.."
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.borderStyle = UITextBorderStyle.roundedRect
        textField.layer.cornerRadius = 15
        textField.delegate = self
        return textField
    }()
    var user = User()
    var messages = [Messages]()
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        self.collectionView!.register(UserMessagesColVC.self, forCellWithReuseIdentifier: reuseIdentifier)
        self.collectionView?.alwaysBounceVertical = true
        // Do any additional setup after loading the view.
        self.navigationController?.navigationBar.tintColor = UIColor.black
        self.navigationItem.title = user.name
        print(user.email ?? "")
        setupNavBar()
        setUpInputComponents()
        observeMessages()
    }
    func observeMessages(){
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            return
        }
        let ref = FIRDatabase.database().reference().child("user-messages").child(uid)
        ref.observe(.childAdded, with: { (snapshot) in
            let messageId = snapshot.key
            let messageRef = FIRDatabase.database().reference().child("messages").child(messageId)
            messageRef.observeSingleEvent(of: .value, with: { (snap) in
                guard let dict = snap.value as? [String:AnyObject] else {
                    return
                }
                let message = Messages()
                message.SenderFrom = dict["SenderFrom"] as? String
                message.SenderTo = dict["SenderTo"] as? String
                message.MessageType = dict["MessageType"] as? String
                message.TimeStamp = dict["TimeStamp"] as? Int
                message.ImageUrl = dict["ImageUrl"] as? String
                message.Text = dict["Text"] as? String
                
                if message.chatPartnerId() == self.user.id{
                    self.messages.append(message)
                    
                    DispatchQueue.main.async {
                        self.collectionView?.reloadData()
                    }
                }
                
            })
        })
    }
    
    func setupNavBar(){
        
        if !(user.profilePic == "") && (user.profilePic != nil){
            let urlRequest = URLRequest(url: URL(string: user.profilePic!)!)
            let session = URLSession(configuration: .default)
            let task = session.dataTask(with: urlRequest) { (data:Data?, response:URLResponse?, error:Error?) in
                guard error == nil else{
                    print(error?.localizedDescription ?? "error from setupNavBar")
                    return
                }
                DispatchQueue.main.async {
                    if let downloadImage = UIImage(data: data!){
                        let sendButton = UIButton(type: .custom)
                        sendButton.setImage(downloadImage , for: .normal)
                        sendButton.frame =  CGRect(x: 0, y: 0, width: 40, height: 40)
                        sendButton.layer.cornerRadius = sendButton.bounds.size.width * 0.5
                        sendButton.clipsToBounds = true
                        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: sendButton)
                    }
                }
            }
            task.resume()
        }
        
    }
    
    func setUpInputComponents(){
        let containerView = UIView()
        
        containerView.backgroundColor = UIColor.white
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        //anchors x,y,w,h
        containerView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        containerView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        containerView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        let sendButton = UIButton(type: .system)
        sendButton.setImage(UIImage(named: "ic_send_2x") , for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(ChatLogCVC.handleSend), for: .touchUpInside)
        containerView.addSubview(sendButton)
        //anchors x,y,w,h
        sendButton.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        sendButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        
        containerView.addSubview(inputTextField)
        //anchors x,y,w,h
        inputTextField.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 8).isActive = true
        inputTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor).isActive = true
        inputTextField.heightAnchor.constraint(equalTo: containerView.heightAnchor,constant: -4).isActive = true
        
        let separatorLine = UIView()    
        separatorLine.backgroundColor = UIColor.black
        separatorLine.translatesAutoresizingMaskIntoConstraints=false
        containerView.addSubview(separatorLine)
        //anchors x,y,w,h
        separatorLine.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        separatorLine.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        separatorLine.widthAnchor.constraint(equalTo: containerView.widthAnchor).isActive = true
        separatorLine.heightAnchor.constraint(equalToConstant: 1).isActive = true

        

    }

    func handleSend(){
        let reference = FIRDatabase.database().reference().child("messages")
        let childRef = reference.childByAutoId()
        let date = Int(NSDate().timeIntervalSince1970)
        let values = ["SenderFrom":FIRAuth.auth()!.currentUser!.uid,"SenderTo":user.id!,"Text":inputTextField.text!,"MessageType":"TEXT","TimeStamp":date,"ImageUrl":""] as [String : Any]
        //childRef.updateChildValues(values)
        
        childRef.updateChildValues(values) { (error, datRef) in
            guard error == nil else  {
                print("From ChatLogCVC:"+(error?.localizedDescription)!)
                return
            }
            let userMessagesRef = FIRDatabase.database().reference().child("user-messages").child(FIRAuth.auth()!.currentUser!.uid)
            
            let messageId = childRef.key
            userMessagesRef.updateChildValues([messageId:1])
            
            let recipientMessagesRef = FIRDatabase.database().reference().child("user-messages").child(self.user.id!)
            recipientMessagesRef.updateChildValues([messageId:1])

        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */
    // MARK: UICollectionViewDelegateFlowLayout 
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 60)
    }
    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return self.messages.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! UserMessagesColVC
    
        // Configure the cell
        cell.textView.text = messages[indexPath.row].Text
        return cell
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}
