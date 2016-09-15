//
//  SettingsViewController.swift
//  ChitChat
//
//  Created by Ricky Gill on 07/09/2016.
//
//

import UIKit
import XMPPFramework
import xmpp_messenger_ios


class SettingsViewController: UIViewController, UINavigationControllerDelegate {
    
    var myvCard:XMPPvCardTemp?
    let imagePicker  = UIImagePickerController()
    
    @IBOutlet weak var saveProfileButton: UIButton!
    
    @IBOutlet weak var nicknameTextField: UITextField!
    
    @IBOutlet var imageView: UIImageView!
    
    @IBOutlet weak var usernameTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var logoImage: UIImageView!
    
    @IBOutlet weak var validateButton: UIButton!
    
    @IBOutlet weak var NicknameView: UIView!
    
    @IBOutlet weak var registerButton: UIButton!
    
    @IBOutlet weak var selectProfilePictureButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        saveProfileButton.setTitle("Saving...", forState: UIControlState.Disabled)
        registerButton.setTitle("Registering...", forState: UIControlState.Disabled)
        
        let buttons = [saveProfileButton, validateButton, registerButton, selectProfilePictureButton]
        buttons.forEach { (button) -> () in
            button.layer.cornerRadius = 8
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor(red:0.60, green:0.49, blue:0.42, alpha:1.0).CGColor
        }
        
        imagePicker.delegate = self
        _ = UITapGestureRecognizer(target: self, action: #selector(SettingsViewController.DismissKeyboard))
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        OneChat.sharedInstance.xmppvCardTempModule?.addDelegate(self, delegateQueue: dispatch_get_main_queue())
        OneChat.sharedInstance.xmppStream?.addDelegate(self, delegateQueue: dispatch_get_main_queue())
        
        updateViewFields()
        
        if NSUserDefaults.standardUserDefaults().stringForKey(kXMPP.myJID) != "kXMPPmyJID" {
            passwordTextField.text = NSUserDefaults.standardUserDefaults().stringForKey(kXMPP.myPassword)
            let username = NSUserDefaults.standardUserDefaults().stringForKey(kXMPP.myJID)
            guard let unwrappedUsername = username else {
                usernameTextField.text = ""
                return
            }
            usernameTextField.text = unwrappedUsername.componentsSeparatedByString("@")[0]
        }
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        OneChat.sharedInstance.xmppvCardTempModule?.removeDelegate(self)
        OneChat.sharedInstance.xmppStream?.removeDelegate(self)
    }
    
    @IBAction func saveProfile(sender: AnyObject) {
        let newNickname = nicknameTextField.text
        myvCard?.nickname = newNickname
        saveProfileButton.enabled = false
        OneChat.sharedInstance.xmppvCardTempModule?.updateMyvCardTemp(myvCard)
    }
    
    @IBAction func selectPicture(sender: UIButton) {
        myvCard?.nickname = nicknameTextField.text
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .PhotoLibrary
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func validate(sender: AnyObject) {
        if OneChat.sharedInstance.isConnected() {
            OneChat.sharedInstance.disconnect()
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: kXMPP.stopConnection)
            updateViewFields()
        } else if checkInputs() {
            OneChats.self.clearChatsList()
            let username = "\(usernameTextField.text!)@localhost"
            let password = passwordTextField.text!
            
            OneChat.sharedInstance.connect(username: username, password: password) { (stream, error) -> Void in
                if let _ = error {
                    self.displayAlert("Sorry", message: "Username/Password did not match our records")
                    OneChat.sharedInstance.disconnect()
                } else {
                    NSUserDefaults.standardUserDefaults().setBool(false, forKey: kXMPP.stopConnection)
                    self.updateViewFields()
                    self.tabBarController?.selectedIndex = 1
                }
            }
        }
    }
    
    @IBAction func register(sender: UIButton) {
        if checkInputs() {
            OneChats.self.clearChatsList()
            let username = "\(usernameTextField.text!)@localhost"
            let password = passwordTextField.text!
            registerButton.enabled = false
            
            OneChat.sharedInstance.connect(username: username, password: password, completionHandler: { (stream, error) in
                if let _ = error {
                    if stream.supportsInBandRegistration() {
                        do {
                            try stream.registerWithPassword(password)
                        }
                        catch let err {
                            print("unable to register: \(err)")
                            stream.disconnect()
                        }
                    }
                } else {
                    self.updateViewFields()
                    self.tabBarController?.selectedIndex = 1
                }
            })
        }
    }
    
    func DismissKeyboard() {
        if usernameTextField.isFirstResponder() {
            usernameTextField.resignFirstResponder()
        } else if passwordTextField.isFirstResponder() {
            passwordTextField.resignFirstResponder()
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if passwordTextField.isFirstResponder() {
            textField.resignFirstResponder()
            validate(self)
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
    
    func checkInputs() -> Bool {
        if usernameTextField.text!.isEmpty || passwordTextField.text!.isEmpty {
            displayAlert("Sorry", message: "Username/Password cannot be empty")
            return false
        }
        return true
    }
    
    func displayAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
            // do something
        }))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let rect = CGRectMake(0, 0, targetSize.width, targetSize.height)
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        image.drawInRect(rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    func updateViewFields() {
        if OneChat.sharedInstance.isConnected() {
            myvCard = nil
            usernameTextField.hidden = true
            passwordTextField.hidden = true
            NicknameView.hidden = false
            registerButton.hidden = true
            registerButton.enabled = true
            logoImage.hidden = true
            validateButton.setTitle("Disconnect", forState: UIControlState.Normal)
//            validateButton.backgroundColor = UIColor(red:0.58, green:0.14, blue:0.21, alpha:1.0)
//            validateButton.layer.borderColor = UIColor(red:0.18, green:0.68, blue:0.64, alpha:1.0).CGColor
            for controller in (tabBarController?.viewControllers)! {
                controller.tabBarItem.enabled = true
            }
            updateMyvCard()
            updateProfileFields()
        } else {
            usernameTextField.hidden = false
            passwordTextField.hidden = false
            registerButton.hidden = false
            registerButton.enabled = true
            logoImage.hidden = false
            NicknameView.hidden = true
            validateButton.setTitle("Sign In", forState: UIControlState.Normal)
//            validateButton.backgroundColor = UIColor(red:0.44, green:0.70, blue:0.68, alpha:1.0)
//            validateButton.layer.borderColor = UIColor(red:0.60, green:0.49, blue:0.42, alpha:1.0).CGColor
            for controller in (tabBarController?.viewControllers)! {
                controller.tabBarItem.enabled = false
            }
        }
    }
    
    func updateProfileFields() {
        nicknameTextField.text = myvCard?.nickname
        if myvCard?.photo != nil {
            imageView.image = UIImage(data: (myvCard?.photo)!)
        } else {
            imageView.image = nil
        }
    }
    
    func updateMyvCard() {
        if myvCard == nil && OneChat.sharedInstance.xmppvCardTempModule?.myvCardTemp == nil {
            let vCardXML:DDXMLElement = DDXMLElement.init(name: "vCard", xmlns: "vcard-temp")
            myvCard = XMPPvCardTemp.init(fromElement: vCardXML)
        } else if myvCard == nil {
            myvCard = OneChat.sharedInstance.xmppvCardTempModule?.myvCardTemp
        }
    }
    
}

extension SettingsViewController: UIImagePickerControllerDelegate {
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        dismissViewControllerAnimated(true, completion: nil)
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imageView.contentMode = .ScaleAspectFit
            imageView.image = resizeImage(pickedImage, targetSize: CGSize(width: 64, height: 64))
            let myAvatar:NSData = UIImagePNGRepresentation(imageView.image!)!
            myvCard?.photo = myAvatar
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
}

extension SettingsViewController: XMPPStreamDelegate {
    
    func xmppStreamDidRegister(sender: XMPPStream!) {
        NSUserDefaults.standardUserDefaults().setBool(false, forKey: kXMPP.stopConnection)
        updateViewFields()
        tabBarController?.selectedIndex = 1
    }
    
    func xmppStream(sender: XMPPStream!, didNotRegister error: DDXMLElement!) {
        displayAlert("Sorry", message: "Unable to register: \(error.forwardedMessage())")
        OneChat.sharedInstance.disconnect()
        registerButton.enabled = true
    }
    
}

extension SettingsViewController: XMPPvCardTempModuleDelegate {
    
    func xmppvCardTempModuleDidUpdateMyvCard(vCardTempModule: XMPPvCardTempModule!) {
        displayAlert("Success", message: "Your profile has been saved.")
        saveProfileButton.enabled = true
    }
    
    func xmppvCardTempModule(vCardTempModule: XMPPvCardTempModule!, failedToUpdateMyvCard error: DDXMLElement!) {
        displayAlert("Unsuccessful", message: "Your profile has NOT been updated.")
        saveProfileButton.enabled = true
    }

}