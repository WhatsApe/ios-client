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
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if identifier == "chat.to.add" {
            if !OneChat.sharedInstance.isConnected() {
                let alert = UIAlertController(title: "Attention", message: "You have to be connected to start a chat", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                
                self.presentViewController(alert, animated: true, completion: nil)
                
                return false
            }
        }
        return true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue?, sender: AnyObject?) {
        if segue?.identifier == "chats.to.chat" {
            if let controller = segue?.destinationViewController as? ChatViewController {
                if let cell: UITableViewCell? = sender as? UITableViewCell {
                    let user = OneChats.getChatsList().objectAtIndex(tableView.indexPathForCell(cell!)!.row) as! XMPPUserCoreDataStorageObject
                    controller.recipient = user
                }
            }
        }
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