//
//  ChatLogController.swift
//  ChatApp-Swift-And-Firebase
//
//  Created by Surya on 9/29/17.
//  Copyright © 2017 Surya. All rights reserved.
//

import UIKit
import Firebase

class ChatLogController: UICollectionViewController,UITextFieldDelegate,UICollectionViewDelegateFlowLayout{
    
    let cellId = "CellID"
    var messages = [Message]()
    
    var user : User? {
        didSet {
            navigationItem.title = user?.name
            observeMessage()
        }
    }
    
    lazy var inputTextField: UITextField = {
        let inputTf = UITextField()
        inputTf.placeholder = "Enter Message ....."
        inputTf.translatesAutoresizingMaskIntoConstraints = false
        inputTf.delegate = self
        inputTf.backgroundColor = UIColor.clear
        return inputTf
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.backgroundColor = UIColor.white
        collectionView?.contentInset = UIEdgeInsetsMake(8, 0, 58, 0)
        collectionView?.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 50, 0)
        collectionView?.alwaysBounceVertical = true
        collectionView?.register(ChatMessageCell.self, forCellWithReuseIdentifier: cellId)
        setUpInputComponents()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setUpInputComponents() {
        let containerview = UIView()
        containerview.translatesAutoresizingMaskIntoConstraints = false
        containerview.backgroundColor = UIColor.white
        view.addSubview(containerview)
        
        containerview.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        containerview.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        containerview.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        containerview.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        let separatorView = UIView()
        separatorView.backgroundColor = UIColor.lightGray
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        containerview.addSubview(separatorView)
        
        separatorView.leftAnchor.constraint(equalTo: containerview.leftAnchor).isActive = true
        separatorView.rightAnchor.constraint(equalTo: containerview.rightAnchor).isActive = true
        separatorView.topAnchor.constraint(equalTo: containerview.topAnchor).isActive = true
        separatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        let sendButton = UIButton(type: .system)
        sendButton.setTitle("Send", for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        containerview.addSubview(sendButton)
        
        sendButton.rightAnchor.constraint(equalTo: containerview.rightAnchor, constant: -20).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: sendButton.intrinsicContentSize.width).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: containerview.centerYAnchor).isActive = true
        sendButton.heightAnchor.constraint(equalTo: containerview.heightAnchor).isActive = true
        
        containerview.addSubview(inputTextField)

        inputTextField.leftAnchor.constraint(equalTo: containerview.leftAnchor, constant: 20).isActive = true
        inputTextField.centerYAnchor.constraint(equalTo: containerview.centerYAnchor).isActive = true
//        inputTf.widthAnchor.constraint(equalToConstant: containerview.frame.size.width - sendButton.frame.size.width).isActive = true
        inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor, constant: 10).isActive = true
        inputTextField.heightAnchor.constraint(lessThanOrEqualTo: containerview.heightAnchor).isActive = true
    }
    
    func handelSend() {
        let ref = FIRDatabase.database().reference().child("messages")
        let childRef = ref.childByAutoId()
        let toId = user!.id!
        let fromId = FIRAuth.auth()!.currentUser!.uid
        let timeStamp = NSNumber.init(value: Date().timeIntervalSince1970)
        let values = ["text":inputTextField.text!, "toId":toId, "fromId":fromId, "timeStamp":timeStamp] as [String : Any]
        childRef.updateChildValues(values)
        
        childRef.updateChildValues(values) { (error, ref) in
            if error != nil {
                print(error!)
                return
            }
            
            self.inputTextField.text = nil
            
            let userMessageRef = FIRDatabase.database().reference().child("user-messages").child(fromId)
            let messageId = childRef.key
            userMessageRef.updateChildValues([messageId: 1])
            
            let recipentUserMessageRef = FIRDatabase.database().reference().child("user-messages").child(toId)
            recipentUserMessageRef.updateChildValues([messageId: 1])
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handelSend()
        textField.resignFirstResponder()
        return true
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ChatMessageCell
        let messages = self.messages[indexPath.item]
        cell.textView.text = messages.text
        
        setUpCell(cell: cell, messages: messages)
        cell.bubbleWidthAnchor?.constant = estimatedHeightBasedOnText(text: messages.text!).width + 32
        
        return cell
    }
    
    private func setUpCell(cell: ChatMessageCell, messages: Message){
        
        if let profileImageUrl = self.user?.profileImageUrl {
            cell.profileImageView.loadImagesUsingCacheWithUrlString(urlString: profileImageUrl)
        }
        
        if messages.fromId == FIRAuth.auth()?.currentUser?.uid {
            cell.bubbleView.backgroundColor = UIColor.init(r: 0, g: 137, b: 249)
            cell.textView.textColor = UIColor.white
            cell.profileImageView.isHidden = true
            cell.bubbleViewRightAnchor?.isActive = true
            cell.bubbleViewLeftAnchor?.isActive = false
        }else {
            cell.bubbleView.backgroundColor = UIColor.init(r: 240, g: 240, b: 240)
            cell.textView.textColor = UIColor.black
            cell.profileImageView.isHidden = false
            cell.bubbleViewRightAnchor?.isActive = false
            cell.bubbleViewLeftAnchor?.isActive = true
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 80
        if let text = messages[indexPath.row].text {
            height = estimatedHeightBasedOnText(text: text).height + 20
        }
        
        return CGSize.init(width: view.frame.width, height: height)
    }
    
    private func estimatedHeightBasedOnText(text: String) -> CGRect{
       let size = CGSize.init(width: 200, height: 1000)
       let option = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
       return NSString.init(string: text).boundingRect(with: size, options: option, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 16)], context: nil)
    }
    
    func observeMessage() {
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            return
        }
        let userMessageRef = FIRDatabase.database().reference().child("user-messages").child(uid)
        userMessageRef.observe(.childAdded, with: { (snapshot) in
            let messageId = snapshot.key
            let messagesRef = FIRDatabase.database().reference().child("messages").child(messageId)
            messagesRef.observeSingleEvent(of: .value, with: { (snapshot) in
                guard let dict = snapshot.value as? [String: AnyObject] else {
                    return
                }
                let message = Message()
                message.setValuesForKeys(dict)
                if message.chatPartnerId() == self.user?.id {
                    self.messages.append(message)
                    DispatchQueue.main.async {
                        self.collectionView?.reloadData()
                    }
                }
            }, withCancel: nil)
        }, withCancel: nil)
    }

}
