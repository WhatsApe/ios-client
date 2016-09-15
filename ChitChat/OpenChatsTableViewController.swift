//
//  OpenChatsTableViewController.swift
//  ChitChat
//
//  Created by Ricky Gill on 07/09/2016.
//
//

import UIKit
import XMPPFramework
import xmpp_messenger_ios

class OpenChatsTableViewController: UITableViewController {
    
    var delegate:ContactPickerDelegate?
    var chatList = NSArray()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = 50
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        OneRoster.sharedInstance.delegate = self
        OneMessage.sharedInstance.delegate = self
        if !NSUserDefaults.standardUserDefaults().boolForKey(kXMPP.stopConnection) {
            OneChat.sharedInstance.connect(username: kXMPP.myJID, password: kXMPP.myPassword) { (stream, error) -> Void in
                if let _ = error {
                    self.tabBarController?.selectedIndex = 2
                } else {
                    //set up online UI
                }
            }
        } else if !OneChat.sharedInstance.isConnected() {
            self.tabBarController?.selectedIndex = 2
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        OneRoster.sharedInstance.delegate = nil
        OneMessage.sharedInstance.delegate = nil
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue?, sender: AnyObject?) {
        if segue?.identifier == "chats.to.chat" {
            if let controller = segue?.destinationViewController as? ChatViewController {
                self.delegate = controller
            }
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        delegate?.didSelectContact(OneChats.getChatsList()[indexPath.row] as! XMPPUserCoreDataStorageObject)
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return OneChats.getChatsList().count
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell? = tableView.dequeueReusableCellWithIdentifier("OneCellReuse", forIndexPath: indexPath)
        let user = OneChats.getChatsList().objectAtIndex(indexPath.row) as! XMPPUserCoreDataStorageObject
        
        OneChat.sharedInstance.configurePhotoForCell(cell!, user: user)
        
        cell?.imageView?.layer.cornerRadius = 24
        cell?.imageView?.clipsToBounds = true
        
        if user.unreadMessages.integerValue > 0 {
            cell!.textLabel!.text = "( \(user.unreadMessages.intValue) ) \(getUserDisplayName(user))"
        } else {
            cell!.textLabel!.text = getUserDisplayName(user)
        }
        
        return cell!
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.1
    }
    
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func getUserDisplayName(user: XMPPUserCoreDataStorageObject) -> String {
        if let nickname = OneChat.sharedInstance.xmppvCardTempModule?.vCardTempForJID(user.jid, shouldFetch: false)?.nickname {
            return nickname;
        } else {
            return user.jid.user;
        }
    }
    
}

extension OpenChatsTableViewController: OneMessageDelegate {
    
    func oneStream(sender: XMPPStream, didReceiveMessage message: XMPPMessage, from user: XMPPUserCoreDataStorageObject) {
        tableView.reloadData()
    }
    
    func oneStream(sender: XMPPStream, userIsComposing user: XMPPUserCoreDataStorageObject) {
        return
    }
    
}

extension OpenChatsTableViewController: OneRosterDelegate {
    
    func oneRosterContentChanged(controller: NSFetchedResultsController) {
        tableView.reloadData()
    }
    
}