//
//  TabBarController.swift
//  ChitChat
//
//  Created by Alwin Solanky on 12/09/2016.
//
//

import UIKit

class TabBarController : UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        selectedIndex = 1
        
        tabBar.items?.forEach({ (item) -> () in
            item.image = item.selectedImage?.jsq_imageMaskedWithColor(UIColor.whiteColor())
        })
        
    }
}
