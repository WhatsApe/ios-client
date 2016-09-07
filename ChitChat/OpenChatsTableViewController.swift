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

class OpenChatsTableViewController: UIViewController, OneRosterDelegate {
    
    @IBOutlet var tableView: UITableView!

    var chatList = NSArray()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = 50
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        OneRoster.sharedInstance.delegate = self
        OneChat.sharedInstance.connect(username: kXMPP.myJID, password: kXMPP.myPassword) { (stream, error) -> Void in
            if let _ = error {
                self.performSegueWithIdentifier("One.HomeToSettings", sender: self)
            } else {
                //set up online UI
            }
        }
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
        return OneChats.getChatsList().count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell? = tableView.dequeueReusableCellWithIdentifier("OneCellReuse", forIndexPath: indexPath)
        let user = OneChats.getChatsList().objectAtIndex(indexPath.row) as! XMPPUserCoreDataStorageObject
        
        cell!.textLabel!.text = user.displayName
        
        OneChat.sharedInstance.configurePhotoForCell(cell!, user: user)
        
        cell?.imageView?.layer.cornerRadius = 24
        cell?.imageView?.clipsToBounds = true
        
        return cell!
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
            
    
}