//
//  ChatViewController.swift
//  Flash Chat iOS13
//
//  Created by Angela Yu on 21/10/2019.
//  Copyright © 2019 Angela Yu. All rights reserved.
//

import UIKit
import Firebase
import Foundation

class ChatViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextfield: UITextField!
    
    let db = Firestore.firestore()
    
    var messages:[Message] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "⚡️FlashChat"
        navigationItem.hidesBackButton = true
        let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        tableView.dataSource = self
        
        tableView.register(UINib(nibName: "MessageCell", bundle: nil), forCellReuseIdentifier: K.cellIdentifier)
        
        loadMessages()
        
        
        messageTextfield.delegate = self
        
    }
    
    func moveBottom(){
        let endIndex = IndexPath(row: messages.count - 1, section: 0)
        self.tableView.scrollToRow(at: endIndex, at: .bottom, animated: true)
        
        
    }
    
    
    func loadMessages(){
        db.collection(K.FStore.collectionName).order(by: K.FStore.dateField).addSnapshotListener { (QuerySnapshot, Error) in
            self.messages = []
            if let error = Error {
                print("There was error retrieving data from Firestore")
                print(error.localizedDescription)
            }else {
                if let querySnapshot = QuerySnapshot {
                    
                    for document in querySnapshot.documents {
                        let data = document.data()
                        if let sender = data[K.FStore.senderField], let body = data[K.FStore.bodyField] {
                            let message = Message(sender: sender as! String, body: body as! String)
                            self.messages.append(message)
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                                self.moveBottom()
                            }
                        }
                    }
                    
                }
            }
        }
    }
    
    
    @IBAction func sendPressed(_ sender: UIButton) {
        if let sender = Auth.auth().currentUser?.email, let messageBody = messageTextfield.text {
            messageTextfield.text = ""
            db.collection(K.FStore.collectionName).addDocument(data: [
                K.FStore.senderField:sender,
                K.FStore.bodyField:messageBody,
                K.FStore.dateField:Date().timeIntervalSince1970
            ]) { (error) in
                if let e = error {
                    print("Error occured saving data to firestore")
                    print(e.localizedDescription)
                }else {
                    print("Save data to database")
                }
            }
        }
    }
    
    
    
    @IBAction func logoutPressed(_ sender: UIBarButtonItem) {
          let firebaseAuth = Auth.auth()
        do {
          try firebaseAuth.signOut()
            navigationController?.popToRootViewController(animated: true)
        } catch let signOutError as NSError {
          print ("Error signing out: %@", signOutError)
        }
    }
    
}

extension ChatViewController:UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let message = messages[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier, for: indexPath) as! MessageCell
        cell.label.text = message.body
        
        
        if message.sender == Auth.auth().currentUser?.email {
            cell.leftImageView.isHidden = true
            cell.rightImageView.isHidden = false
            cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.lightPurple)
            cell.label.textColor = UIColor(named: K.BrandColors.purple)
        }else {
            cell.leftImageView.isHidden = false
            cell.rightImageView.isHidden = true
            cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.lighBlue)
            cell.label.textColor = UIColor(named: K.BrandColors.blue)
        }
        
        
        return cell
    }
    
    
}


extension ChatViewController:UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let sender = Auth.auth().currentUser?.email, let messageBody = messageTextfield.text {
            messageTextfield.text = ""
            db.collection(K.FStore.collectionName).addDocument(data: [
                K.FStore.senderField:sender,
                K.FStore.bodyField:messageBody,
                K.FStore.dateField:Date().timeIntervalSince1970
            ]) { (error) in
                if let e = error {
                    print("Error occured saving data to firestore")
                    print(e.localizedDescription)
                }else {
                    print("Save data to database")
                }
            }
        }
        return true
    }
}
