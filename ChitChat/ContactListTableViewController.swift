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

class ContactListTableViewController: UITableViewController, OneRosterDelegate {
    
    var delegate:ContactPickerDelegate?
    
    @IBAction func closeWindow(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: {})
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        OneRoster.sharedInstance.delegate = self
        tableView.reloadData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        OneRoster.sharedInstance.delegate = nil
    }
    
    func oneRosterContentChanged(controller: NSFetchedResultsController) {
        //Will reload the tableView to reflect roster's changes
        tableView.reloadData()
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
        
        if let nickname = OneChat.sharedInstance.xmppvCardTempModule?.vCardTempForJID(user.jid, shouldFetch: false)?.nickname {
            cell!.textLabel!.text = nickname;
        } else {
            cell!.textLabel!.text = user.displayName;
        }
        
        if user.unreadMessages.intValue > 0 {
            cell!.backgroundColor = .orangeColor()
        } else {
            cell!.backgroundColor = .whiteColor()
        }
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


    
}
