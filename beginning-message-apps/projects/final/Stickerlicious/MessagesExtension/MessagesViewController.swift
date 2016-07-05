//
//  MessagesViewController.swift
//  MessagesExtension
//
//  Created by Richard Turton on 03/07/2016.
//  Copyright © 2016 Razeware. All rights reserved.
//

import UIKit
import Messages

class MessagesViewController: MSMessagesAppViewController {
    
@IBAction func handleChocoholicChanged(_ sender: UISwitch) {
    for vc in childViewControllers {
        if let vc = vc as? Chocoholicable {
            vc.setChocoholic(sender.isOn)
        }
    }
}
}

protocol Chocoholicable {
    func setChocoholic(_ chocoholic: Bool)
}
