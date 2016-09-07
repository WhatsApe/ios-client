//
//  ChatViewController.swift
//  ChitChat
//
//  Created by Arunas Skirius on 07/09/2016.
//
//

import UIKit
import XMPPFramework
import JSQMessagesViewController
import xmpp_messenger_ios

class ChatViewController: UIViewController, ContactPickerDelegate {
    var recipient: XMPPUserCoreDataStorageObject?
    var firstTime = true

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let recipient = recipient {
            navigationItem.rightBarButtonItems = []
            navigationItem.title = recipient.displayName
        } else {
            navigationItem.title = "New message"
            
            navigationItem.setRightBarButtonItem(UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "addRecipient"), animated: true)
            addRecipient()
        }
        if firstTime {
            firstTime = false
            addRecipient()
        }
    }
    
    func didSelectContact(recipient: XMPPUserCoreDataStorageObject) {
        self.recipient = recipient
        navigationItem.title = recipient.displayName
    }
    
    func addRecipient() {
        let navController = storyboard?.instantiateViewControllerWithIdentifier("contactListNav") as? UINavigationController
        
        let contactController: ContactListTableViewController? = navController?.viewControllers[0] as? ContactListTableViewController
        contactController?.delegate = self
        presentViewController(navController!, animated: true, completion: nil)
    }
    
}
