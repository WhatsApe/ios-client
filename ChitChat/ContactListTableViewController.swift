//
//  ContactListTableViewController.swift
//  ChitChat
//
//  Created by Arunas Skirius on 07/09/2016.
//
//

protocol ContactPickerDelegate {
    func didSelectContact(recipient: XMPPUserCoreDataStorageObject)
}

import UIKit
import XMPPFramework
import xmpp_messenger_ios

class ContactListTableViewController: UITableViewController {
    
    var delegate:ContactPickerDelegate?
    
    @IBAction func closeWindow(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: {})
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        OneRoster.sharedInstance.delegate = self
        OneMessage.sharedInstance.delegate = self
        OneChat.sharedInstance.xmppStream?.addDelegate(self, delegateQueue: dispatch_get_main_queue())
        tableView.reloadData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        OneRoster.sharedInstance.delegate = nil
        OneMessage.sharedInstance.delegate = nil
        OneChat.sharedInstance.xmppStream?.removeDelegate(self)
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sections: NSArray? =  OneRoster.buddyList.sections
        
        if section < sections!.count {
            let sectionInfo: AnyObject = sections![section]
            
            return sectionInfo.numberOfObjects
        }
        
        return 0;
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return OneRoster.buddyList.sections!.count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sections: NSArray? = OneRoster.sharedInstance.fetchedResultsController()!.sections
        
        if section < sections!.count {
            let sectionInfo: AnyObject = sections![section]
            let tmpSection: Int = Int(sectionInfo.name)!
            
            switch (tmpSection) {
            case 0 :
                return "Available"
                
            case 1 :
                return "Away"
                
            default :
                return "Offline"
                
            }
        }
        
        return ""
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell? = tableView.dequeueReusableCellWithIdentifier("OneCellReuse", forIndexPath: indexPath)
        let user = OneRoster.userFromRosterAtIndexPath(indexPath: indexPath)
        
        cell?.imageView?.layer.cornerRadius = 24
        cell?.imageView?.clipsToBounds = true
        
        if user.unreadMessages.integerValue > 0 {
            cell!.textLabel!.text = "( \(user.unreadMessages.intValue) ) \(getUserDisplayName(user))"
        } else {
            cell!.textLabel!.text = getUserDisplayName(user)
        }
        
        cell!.backgroundColor = .whiteColor()
        
        OneChat.sharedInstance.configurePhotoForCell(cell!, user: user)
        
        return cell!;
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        delegate?.didSelectContact(OneRoster.userFromRosterAtIndexPath(indexPath: indexPath))
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue?, sender: AnyObject?) {
        if segue?.identifier == "contact.to.chat" {
            if let controller = segue?.destinationViewController as? ChatViewController {
                self.delegate = controller
            }
        }
    }

    func getUserDisplayName(user: XMPPUserCoreDataStorageObject) -> String {
        if let nickname = OneChat.sharedInstance.xmppvCardTempModule?.vCardTempForJID(user.jid, shouldFetch: false)?.nickname {
            return nickname;
        } else {
            return user.jid.user;
        }
    }
    
}

extension ContactListTableViewController: XMPPStreamDelegate {
    
    func xmppStream(sender: XMPPStream!, didReceivePresence presence: XMPPPresence!) {
        tableView.reloadData()
    }
    
}

extension ContactListTableViewController: OneMessageDelegate {
    
    func oneStream(sender: XMPPStream, didReceiveMessage message: XMPPMessage, from user: XMPPUserCoreDataStorageObject) {
        tableView.reloadData()
    }
    
    func oneStream(sender: XMPPStream, userIsComposing user: XMPPUserCoreDataStorageObject) {
        return
    }
    
}

extension ContactListTableViewController: OneRosterDelegate {
    
    func oneRosterContentChanged(controller: NSFetchedResultsController) {
        //Will reload the tableView to reflect roster's changes
        tableView.reloadData()
    }
    
}