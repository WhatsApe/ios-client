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

class ChatViewController: JSQMessagesViewController, ContactPickerDelegate, OneMessageDelegate {
    var recipient: XMPPUserCoreDataStorageObject?
    var messages = NSMutableArray()
    var firstTime = true

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        OneMessage.sharedInstance.delegate = self
        
        if let recipient = recipient {
            navigationItem.rightBarButtonItems = []
            
            if let nickname = OneChat.sharedInstance.xmppvCardTempModule?.vCardTempForJID(recipient.jid, shouldFetch: false)?.nickname {
                navigationItem.title = nickname;
            } else {
                navigationItem.title = recipient.displayName;
            }
            
            self.messages = OneMessage.sharedInstance.loadArchivedMessagesFrom(jid: recipient.jidStr)
            self.collectionView?.reloadData()
        } else {
            navigationItem.title = "New message"
            
            navigationItem.setRightBarButtonItem(UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(ChatViewController.addRecipient)), animated: true)
            
            if firstTime {
                firstTime = false
                addRecipient()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.backgroundColor = UIColor(red:0.96, green:0.98, blue:0.98, alpha:1.0)
        
        if OneChat.sharedInstance.isConnected() {
            self.senderId = OneChat.sharedInstance.xmppStream?.myJID.bare()
            self.senderDisplayName = OneChat.sharedInstance.xmppStream?.myJID.bare()
        }
        self.inputToolbar!.contentView!.leftBarButtonItem!.hidden = true
        self.collectionView!.collectionViewLayout.springinessEnabled = false
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        OneMessage.sharedInstance.delegate = nil
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if recipient != nil {
            recipient?.unreadMessages = NSNumber.init(int: 0)
        }
    }
    
    func didSelectContact(recipient: XMPPUserCoreDataStorageObject) {
        self.recipient = recipient
        navigationItem.title = recipient.displayName
        if !OneChats.knownUserForJid(jidStr: recipient.jidStr) {
            OneChats.addUserToChatList(jidStr: recipient.jidStr)
        } else {
            messages = OneMessage.sharedInstance.loadArchivedMessagesFrom(jid: recipient.jidStr)
            finishReceivingMessageAnimated(true)
        }
    }
    
    func addRecipient() {
        let navController = storyboard?.instantiateViewControllerWithIdentifier("contactListNav") as? UINavigationController
        
        let contactController: ContactListTableViewController? = navController?.viewControllers[0] as? ContactListTableViewController
        contactController?.delegate = self
        presentViewController(navController!, animated: true, completion: nil)
    }
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        let fullMessage = JSQMessage(senderId: OneChat.sharedInstance.xmppStream?.myJID.bare(), senderDisplayName: OneChat.sharedInstance.xmppStream?.myJID.bare(), date: NSDate(), text: text)
        messages.addObject(fullMessage)
        
        if let recipient = recipient {
            OneMessage.sendMessage(text, to: recipient.jidStr, completionHandler: { (stream, message) -> Void in
                JSQSystemSoundPlayer.jsq_playMessageSentSound()
                self.finishSendingMessageAnimated(true)
            })
        }
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        let message: JSQMessage = self.messages[indexPath.item] as! JSQMessage
        
        return message
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message: JSQMessage = self.messages[indexPath.item] as! JSQMessage
        
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        
        let outgoingBubbleImageData = bubbleFactory.outgoingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleLightGrayColor())
        let incomingBubbleImageData = bubbleFactory.incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleGreenColor())
        
        if message.senderId == self.senderId {
            return outgoingBubbleImageData
        }
        
        return incomingBubbleImageData
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        let message: JSQMessage = self.messages[indexPath.item] as! JSQMessage
        
        if message.senderId == self.senderId {
            if let photoData = OneChat.sharedInstance.xmppvCardAvatarModule?.photoDataForJID(OneChat.sharedInstance.xmppStream?.myJID) {
                let senderAvatar = JSQMessagesAvatarImageFactory.avatarImageWithImage(UIImage(data: photoData), diameter: 30)
                return senderAvatar
            } else {
                let senderAvatar = JSQMessagesAvatarImageFactory.avatarImageWithUserInitials("SR", backgroundColor: UIColor(white: 0.85, alpha: 1.0), textColor: UIColor(white: 0.60, alpha: 1.0), font: UIFont(name: "Helvetica Neue", size: 14.0), diameter: 30)
                return senderAvatar
            }
        } else {
            if let photoData = OneChat.sharedInstance.xmppvCardAvatarModule?.photoDataForJID(recipient!.jid!) {
                let recipientAvatar = JSQMessagesAvatarImageFactory.avatarImageWithImage(UIImage(data: photoData), diameter: 30)
                return recipientAvatar
            } else {
                let recipientAvatar = JSQMessagesAvatarImageFactory.avatarImageWithUserInitials("SR", backgroundColor: UIColor(white: 0.85, alpha: 1.0), textColor: UIColor(white: 0.60, alpha: 1.0), font: UIFont(name: "Helvetica Neue", size: 14.0)!, diameter: 30)
                return recipientAvatar
            }
        }
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        if indexPath.item % 10 == 0 {
            let message: JSQMessage = self.messages[indexPath.item] as! JSQMessage
            return JSQMessagesTimestampFormatter.sharedFormatter().attributedTimestampForDate(message.date)
        }
        
        return nil;
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        let message: JSQMessage = self.messages[indexPath.item] as! JSQMessage
        
        if message.senderId == self.senderId {
            return nil
        }
        
        if indexPath.item - 1 > 0 {
            let previousMessage: JSQMessage = self.messages[indexPath.item - 1] as! JSQMessage
            if previousMessage.senderId == message.senderId {
                return nil
            }
        }
        
        return nil
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        return nil
    }
    
    // Mark: UICollectionView DataSource
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.messages.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell: JSQMessagesCollectionViewCell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell
        let msg: JSQMessage = self.messages[indexPath.item] as! JSQMessage
        
        if !msg.isMediaMessage {
            if msg.senderId == self.senderId {
                cell.textView!.textColor = UIColor.blackColor()
                cell.textView!.linkTextAttributes = [NSForegroundColorAttributeName:UIColor.blackColor(), NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue]
            } else {
                cell.textView!.textColor = UIColor.whiteColor()
                cell.textView!.linkTextAttributes = [NSForegroundColorAttributeName:UIColor.whiteColor(), NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue]
            }
        }
        
        return cell
    }
    
    // Mark: JSQMessages collection view flow layout delegate
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        if indexPath.item % 10 == 0 {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        
        return 0.0
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        let currentMessage: JSQMessage = self.messages[indexPath.item] as! JSQMessage
        if currentMessage.senderId == self.senderId {
            return 0.0
        }
        
        if indexPath.item - 1 > 0 {
            let previousMessage: JSQMessage = self.messages[indexPath.item - 1] as! JSQMessage
            if previousMessage.senderId == currentMessage.senderId {
                return 0.0
            }
        }
        
        return kJSQMessagesCollectionViewCellLabelHeightDefault
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        return 0.0
    }

    func oneStream(sender: XMPPStream, didReceiveMessage message: XMPPMessage, from user: XMPPUserCoreDataStorageObject) {
        if (self.isViewLoaded() && self.view.window != nil) {
            user.unreadMessages = NSNumber.init(int: 0)
        }
        if message.isChatMessageWithBody() {
            JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
            
            if let msg: String = message.elementForName("body")?.stringValue() {
                if let from: String = message.attributeForName("from")?.stringValue() {
                    let message = JSQMessage(senderId: from, senderDisplayName: from, date: NSDate(), text: msg)
                    messages.addObject(message)
                    
                    self.finishReceivingMessageAnimated(true)
                }
            }
        }
    }
    
    func oneStream(sender: XMPPStream, userIsComposing user: XMPPUserCoreDataStorageObject) {
        self.showTypingIndicator = !self.showTypingIndicator
        self.scrollToBottomAnimated(true)
    }
    
}
