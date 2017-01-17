//
//  ChatViewController.swift
//  BlahBlah
//
//  Created by Sayantan Chakraborty on 11/01/17.
//  Copyright © 2017 Sayantan Chakraborty. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import MobileCoreServices
import AVKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage

class ChatViewController: JSQMessagesViewController {

    var messages = [JSQMessage]()
    var avatarDict = [String:JSQMessagesAvatarImage]()
    var messageRef = FIRDatabase.database().reference().child("Messages")
    let photoCache = NSCache<AnyObject, AnyObject>()
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.senderId = FIRAuth.auth()?.currentUser?.uid
        if FIRAuth.auth()?.currentUser?.displayName == nil {
            self.senderDisplayName = "anonymous"
        }
        else{
            self.senderDisplayName = FIRAuth.auth()?.currentUser?.displayName
        }
        observeMessages()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func logOutTapped(_ sender: UIBarButtonItem) {
        do {
            try FIRAuth.auth()?.signOut()
        } catch let error {
            print(error.localizedDescription)
        }
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let loginVC = storyBoard.instantiateViewController(withIdentifier: "LoginVC") as! LoginViewController
        let appdel = UIApplication.shared.delegate as! AppDelegate
        appdel.window?.rootViewController = loginVC
    }
    func observeUsers(id: String){
        FIRDatabase.database().reference().child("Users").child(id).observe(.value, with: { (snapshot) in
            if let dict = snapshot.value as? [String:AnyObject]{
                self.setUpAvatar(url: dict["profileUrl"] as? String,senderId: id)
            }
        })
        
        
    }
    
    func setUpAvatar(url: String?,senderId: String){
        DispatchQueue.global(qos: .userInitiated).async {
            if url != "" {
                let file = NSURL(string: url!)
                let data = NSData(contentsOf: file as! URL)
                let image = UIImage(data: data as! Data)
                let usrImg = JSQMessagesAvatarImageFactory.avatarImage(with: image, diameter: 30)
                self.avatarDict[senderId] = usrImg
            }else{
                self.avatarDict[senderId] = JSQMessagesAvatarImageFactory.avatarImage(with:UIImage(named:"profileImage"), diameter: 30)
            }
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    
    func observeMessages(){
        messageRef.observe(.childAdded, with: { (snapshot) in
            if let dict = snapshot.value as? [String:AnyObject]{
                let mediaType = dict["MediaType"] as! String
                let senderId = dict["senderID"] as! String
                let senderName = dict["senderName"] as! String
                self.observeUsers(id: senderId)
                
                switch mediaType {
                case "TEXT":
                    let text = dict["text"] as! String
                    self.messages.append(JSQMessage(senderId: senderId, displayName: senderName, text: text))
                    break
                case "PHOTO":
                    
                    var photo = JSQPhotoMediaItem(image: nil)
                    let fileUrl = dict["fileUrl"] as! String
                    
                    if let cachedPhoto = self.photoCache.object(forKey: fileUrl as AnyObject) as? JSQPhotoMediaItem {
                        photo = cachedPhoto
                        self.collectionView.reloadData()
                    }else{
                        
                        DispatchQueue.global(qos: .userInitiated).async {
                            let data = NSData(contentsOf: NSURL(string: fileUrl) as! URL)
                            var picture = UIImage(named: "dummyUser")
                            if data != nil{
                                picture = UIImage(data: data as! Data)
                            }
                            DispatchQueue.main.async {
                                photo?.image = picture
                                self.collectionView.reloadData()
                            }
                        }
                    }
                    
                    self.messages.append(JSQMessage(senderId: self.senderId, displayName: self.senderDisplayName, media: photo))
                    if(self.senderId == senderId){
                        photo?.appliesMediaViewMaskAsOutgoing = true
                    }else{
                        photo?.appliesMediaViewMaskAsOutgoing = false
                    }
                    break
                case "VIDEO":
                    let fileUrl = dict["fileUrl"] as! String
                    let video = NSURL(string: fileUrl)
                    let videoItem = JSQVideoMediaItem(fileURL: video as URL!, isReadyToPlay: true)
                    self.messages.append(JSQMessage(senderId: self.senderId, displayName: self.senderDisplayName, media: videoItem))
                    if(self.senderId == senderId){
                        videoItem?.appliesMediaViewMaskAsOutgoing = true
                    }else{
                        videoItem?.appliesMediaViewMaskAsOutgoing = false
                    }
                    break
                    
                default:
                    print("No mathing type")
                }
                self.collectionView.reloadData()
            }
            
        })
    }

    // MARK: - JSQMessagesViewController methods
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        print("Send button tapped")
//        messages.append(JSQMessage(senderId: self.senderId, displayName: self.senderDisplayName, text: text))
//        collectionView.reloadData()
        let newMessage = messageRef.childByAutoId()
        let messageData = ["text":text,"senderID":senderId,"senderName":senderDisplayName,"MediaType":"TEXT"] as [String : Any]
        newMessage.setValue(messageData)
        self.finishSendingMessage()
    }
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        print("accessory button pressed")
        let actionSheet = UIAlertController(title: "Media Message", message: "Please select a media", preferredStyle: UIAlertControllerStyle.actionSheet)
        
        let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
        let photoLib = UIAlertAction(title: "Photo Library", style: UIAlertActionStyle.default) { (alert:UIAlertAction) in
            self.getMediaFromType(type: kUTTypeImage)
        }
        let vidLib = UIAlertAction(title: "Video Library", style: UIAlertActionStyle.default) { (alert:UIAlertAction) in
            self.getMediaFromType(type: kUTTypeMovie)
        }
        actionSheet.addAction(cancel)
        actionSheet.addAction(photoLib)
        actionSheet.addAction(vidLib)
        self.present(actionSheet, animated: true, completion: nil)
        
    }
    
    func getMediaFromType(type: CFString){
        let mediaPicker = UIImagePickerController();
        mediaPicker.delegate = self
        mediaPicker.mediaTypes = [type as String]
        self.present(mediaPicker, animated: true, completion: nil)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        return cell
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        let bubblefactory = JSQMessagesBubbleImageFactory()
        if message.senderId == self.senderId{
            return bubblefactory?.outgoingMessagesBubbleImage(with: UIColor.black)
        }else {
            return bubblefactory?.incomingMessagesBubbleImage(with: UIColor.green)
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return avatarDict[messages[indexPath.item].senderId]
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {
        let message = messages[indexPath.item]
        if message.isMediaMessage{
            if let mediaItem = message.media as? JSQVideoMediaItem {
                let player = AVPlayer(url: mediaItem.fileURL)
                let playerVC = AVPlayerViewController()
                playerVC.player = player
                self.present(playerVC, animated: true, completion: nil)
            }
        }
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
                let newMessage = self.messageRef.childByAutoId()
                let messageData = ["fileUrl":fileUrl!,"senderID":self.senderId,"senderName":self.senderDisplayName,"MediaType":"PHOTO"] as [String : Any]
                newMessage.setValue(messageData)
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
                let newMessage = self.messageRef.childByAutoId()
                let messageData = ["fileUrl":fileUrl!,"senderID":self.senderId,"senderName":self.senderDisplayName,"MediaType":"VIDEO"] as [String : Any]
                newMessage.setValue(messageData)
            }

        }
    }
}

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pic = info[UIImagePickerControllerOriginalImage] as? UIImage{
            sendMedia(photo: pic, video: nil)
        }
        else if let videoUrl = info[UIImagePickerControllerMediaURL] as? NSURL{
            sendMedia(photo: nil, video: videoUrl)
        }
        self.dismiss(animated: true, completion: nil)
        collectionView.reloadData()
    }
}
