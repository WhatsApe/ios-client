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


class SettingsViewController: UIViewController, XMPPvCardTempModuleDelegate, UIImagePickerControllerDelegate,  UINavigationControllerDelegate {
    
    @IBOutlet weak var nicknameTextField: UITextField!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBAction func saveProfile(sender: AnyObject) {
        let newNickname = nicknameTextField.text
        let myvCard = OneChat.sharedInstance.xmppvCardTempModule?.myvCardTemp
        myvCard?.nickname = newNickname
        OneChat.sharedInstance.xmppvCardTempModule?.updateMyvCardTemp(myvCard)        
    }
    @IBOutlet var imageView: UIImageView!
    
    let imagePicker  = UIImagePickerController()
    
    @IBAction func selectPicture(sender: UIButton) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .PhotoLibrary
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imageView.contentMode = .ScaleAspectFit
            imageView.image = pickedImage
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        // Do any additional setup after loading the view, typically from a nib.
        let tap = UITapGestureRecognizer(target: self, action: #selector(SettingsViewController.DismissKeyboard))
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        OneChat.sharedInstance.xmppvCardTempModule?.addDelegate(self, delegateQueue: dispatch_get_main_queue())
        if OneChat.sharedInstance.isConnected() {
            usernameTextField.hidden = true
            passwordTextField.hidden = true
            NicknameView.hidden = false
            validateButton.setTitle("Disconnect", forState: UIControlState.Normal)
            let myvCard = OneChat.sharedInstance.xmppvCardTempModule?.myvCardTemp
            nicknameTextField.text = myvCard?.nickname
        } else if NSUserDefaults.standardUserDefaults().stringForKey(kXMPP.myJID) != "kXMPPmyJID" {
            doneButton.enabled = false
            passwordTextField.text = NSUserDefaults.standardUserDefaults().stringForKey(kXMPP.myPassword)
            let username = NSUserDefaults.standardUserDefaults().stringForKey(kXMPP.myJID)
            guard let unwrappedUsername = username else {
                print("error getting username")
                usernameTextField.text = ""
                return
            }
            usernameTextField.text = unwrappedUsername.componentsSeparatedByString("@")[0]
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        OneChat.sharedInstance.xmppvCardTempModule?.removeDelegate(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    
    @IBOutlet weak var usernameTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var validateButton: UIButton!
    
    @IBOutlet weak var NicknameView: UIView!
    
    @IBAction func validate(sender: AnyObject) {
//        let this = self
        if OneChat.sharedInstance.isConnected() {
            OneChat.sharedInstance.disconnect()
            doneButton.enabled = false
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: kXMPP.stopConnection)
            usernameTextField.hidden = false
            passwordTextField.hidden = false
            validateButton.setTitle("Validate", forState: UIControlState.Normal)
            NicknameView.hidden = true
        } else if checkInputs() {
            OneChats.self.clearChatsList()
            NSUserDefaults.standardUserDefaults().setBool(false, forKey: kXMPP.stopConnection)
            OneChat.sharedInstance.connect(username: self.usernameTextField.text! + "@localhost", password: self.passwordTextField.text!) { (stream, error) -> Void in
                if let _ = error {
                    let alertController = UIAlertController(title: "Sorry", message: "Username/Password did not match our records", preferredStyle: UIAlertControllerStyle.Alert)
                    alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                        // do something
                    }))
                    self.presentViewController(alertController, animated: true, completion: nil)
                } else {
                    self.NicknameView.hidden = false
                    self.doneButton.enabled = true
                    self.tabBarController?.selectedIndex = 1
                }
            }
        }
    }
    
    @IBAction func done(sender: AnyObject) {
        self.tabBarController?.selectedIndex = 1
    }
    
    func checkInputs() -> Bool {
        if usernameTextField.text!.isEmpty || passwordTextField.text!.isEmpty {
            let alertController = UIAlertController(title: "Sorry", message: "Username/Password cannot be empty", preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                // do something
            }))
            self.presentViewController(alertController, animated: true, completion: nil)
            return false
        }
        return true
    }
    
    func xmppvCardTempModuleDidUpdateMyvCard(vCardTempModule: XMPPvCardTempModule!) {
        displayAlert("Success", message: "Your profile has been saved.")
    }
    
    func xmppvCardTempModule(vCardTempModule: XMPPvCardTempModule!, failedToUpdateMyvCard error: DDXMLElement!) {
        displayAlert("Unsuccessful", message: "Your profile has NOT been updated.")
    }
    
    func displayAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
            // do something
        }))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
}