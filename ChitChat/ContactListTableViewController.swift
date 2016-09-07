//
//  ContactListTableViewController.swift
//  ChitChat
//
//  Created by Arunas Skirius on 07/09/2016.
//
//

import UIKit
import XMPPFramework
import xmpp_messenger_ios

class ContactListTableViewController: UIViewController, OneRosterDelegate {
    
    @IBOutlet var tableView: UITableView!
    @IBAction func closeWindow(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        OneRoster.sharedInstance.delegate = self
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        OneRoster.sharedInstance.delegate = nil
    }
    
    func oneRosterContentChanged(controller: NSFetchedResultsController) {
        //Will reload the tableView to reflect roster's changes
        tableView.reloadData()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sections: NSArray? =  OneRoster.buddyList.sections
        
        if section < sections!.count {
            let sectionInfo: AnyObject = sections![section]
            
            return sectionInfo.numberOfObjects
        }
        
        return 0;
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return OneRoster.buddyList.sections!.count
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
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
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell? = tableView.dequeueReusableCellWithIdentifier("OneCellReuse", forIndexPath: indexPath)
        let user = OneRoster.userFromRosterAtIndexPath(indexPath: indexPath)
        
        cell!.textLabel!.text = user.displayName;
        
        if user.unreadMessages.intValue > 0 {
            cell!.backgroundColor = .orangeColor()
        } else {
            cell!.backgroundColor = .whiteColor()
        }
        OneChat.sharedInstance.configurePhotoForCell(cell!, user: user)
        
        return cell!;
    }

    
}
