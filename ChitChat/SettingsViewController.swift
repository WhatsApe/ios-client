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


class SettingsViewController: UIViewController, XMPPvCardTempModuleDelegate, UIImagePickerControllerDelegate,  UINavigationControllerDelegate, XMPPStreamDelegate {
    
    @IBOutlet weak var saveProfileButton: UIButton!
    @IBOutlet weak var nicknameTextField: UITextField!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBAction func saveProfile(sender: AnyObject) {
        let newNickname = nicknameTextField.text
        let myvCard = OneChat.sharedInstance.xmppvCardTempModule?.myvCardTemp
        myvCard?.nickname = newNickname
        let myImage = imageView.image!
        let myAvatar:NSData = UIImagePNGRepresentation(myImage)!
        myvCard?.photo = myAvatar
        saveProfileButton.setTitle("Saving...", forState: UIControlState.Disabled)
        saveProfileButton.enabled = false
        OneChat.sharedInstance.xmppvCardTempModule?.updateMyvCardTemp(myvCard)
    }
    @IBOutlet var imageView: UIImageView!
    
    let imagePicker  = UIImagePickerController()
    
    @IBAction func selectPicture(sender: UIButton) {
        let myvCard = OneChat.sharedInstance.xmppvCardTempModule?.myvCardTemp
        myvCard?.nickname = nicknameTextField.text
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .PhotoLibrary
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        dismissViewControllerAnimated(true, completion: nil)
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imageView.contentMode = .ScaleAspectFit
            imageView.image = resizeImage(pickedImage, targetSize: CGSize(width: 64, height: 64))
            let myAvatar:NSData = UIImagePNGRepresentation(imageView.image!)!
            OneChat.sharedInstance.xmppvCardTempModule?.myvCardTemp.photo = myAvatar
        }
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
        OneChat.sharedInstance.xmppStream?.addDelegate(self, delegateQueue: dispatch_get_main_queue())
        if OneChat.sharedInstance.isConnected() {
            usernameTextField.hidden = true
            passwordTextField.hidden = true
            NicknameView.hidden = false
            registerButton.hidden = true
            updateUserFields()
            validateButton.setTitle("Disconnect", forState: UIControlState.Normal)
        } else if NSUserDefaults.standardUserDefaults().stringForKey(kXMPP.myJID) != "kXMPPmyJID" {
            doneButton.enabled = false
            registerButton.hidden = false
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
        OneChat.sharedInstance.xmppStream?.removeDelegate(self)
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
        if OneChat.sharedInstance.isConnected() {
            OneChat.sharedInstance.disconnect()
            doneButton.enabled = false
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: kXMPP.stopConnection)
            usernameTextField.hidden = false
            passwordTextField.hidden = false
            registerButton.hidden = false
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
                    OneChat.sharedInstance.disconnect()
                } else {
                    self.NicknameView.hidden = false
                    self.doneButton.enabled = true
                    self.registerButton.hidden = true
                    self.tabBarController?.selectedIndex = 1
                }
            }
        }
    }
    
    @IBOutlet weak var registerButton: UIButton!
    @IBAction func register(sender: UIButton) {
        if checkInputs() {
            let username = "\(usernameTextField.text!)@localhost"
            let password = passwordTextField.text!
            registerButton.setTitle("Registering...", forState: UIControlState.Disabled)
            registerButton.enabled = false
            
            OneChat.sharedInstance.connect(username: username, password: password, completionHandler: { (stream, error) in
                if let _ = error {
                    print("Attempting registration for username \(OneChat.sharedInstance.xmppStream!.myJID.bare)")
                    debugPrint(stream.myJID)
                    if stream.supportsInBandRegistration() {
                        do {
                            try stream.registerWithPassword(password)
                        }
                        catch let err {
                            print("unable to register: \(err)")
                        }
                    }
                } else {
                    self.NicknameView.hidden = false
                    self.doneButton.enabled = true
                    self.registerButton.hidden = true
                    self.tabBarController?.selectedIndex = 1
                }
            })
        }
    }
    
    func xmppStreamDidRegister(sender: XMPPStream!) {
        self.tabBarController?.selectedIndex = 1
        print("Registration successful")
        registerButton.enabled = true
    }
    
    func xmppStream(sender: XMPPStream!, didNotRegister error: DDXMLElement!) {
        print("Error registering: \(error)")
        let alertController = UIAlertController(title: "Sorry", message: "Unable to register: \(error)", preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
            // do something
        }))
        self.presentViewController(alertController, animated: true, completion: nil)
        OneChat.sharedInstance.disconnect()
        registerButton.enabled = true
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
        saveProfileButton.enabled = true
    }
    
    func xmppvCardTempModule(vCardTempModule: XMPPvCardTempModule!, failedToUpdateMyvCard error: DDXMLElement!) {
        displayAlert("Unsuccessful", message: "Your profile has NOT been updated.")
        saveProfileButton.enabled = true
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
        
    func updateUserFields() {
        let myvCard = OneChat.sharedInstance.xmppvCardTempModule?.myvCardTemp
        nicknameTextField.text = myvCard?.nickname
        if myvCard?.photo != nil {
            imageView.image = UIImage(data: (myvCard?.photo)!)
        } else {
            imageView.image = nil
        }
    }
    
}