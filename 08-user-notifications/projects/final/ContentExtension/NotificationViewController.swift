//
//  NotificationViewController.swift
//  ContentExtension
//
//  Created by Ray Wenderlich on 7/22/16.
//  Copyright © 2016 Razeware. All rights reserved.
//

import UIKit
import UserNotifications
import UserNotificationsUI

class NotificationViewController: UIViewController, UNNotificationContentExtension {
  
  @IBOutlet weak var imageView: UIImageView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any required interface initialization here.
  }

  func didReceive(_ notification: UNNotification) {
    // 1
    guard let attachment = notification.request.content.attachments.first
      else { return }
    // 2
    if attachment.url.startAccessingSecurityScopedResource() {
      let imageData = try? Data.init(contentsOf: attachment.url)
      if let imageData = imageData {
        imageView.image = UIImage(data: imageData)
      }
      attachment.url.stopAccessingSecurityScopedResource()
    }
  }
  
  internal func didReceive(_ response: UNNotificationResponse,
                  completionHandler completion:
    @escaping (UNNotificationContentExtensionResponseOption) -> Void) {
    // 1
    if response.actionIdentifier == "star" {
      imageView.showStars()
      let time = DispatchTime.now() +
        DispatchTimeInterval.milliseconds(2000)
        DispatchQueue.main.asyncAfter(deadline: time) {
        // 2
        completion(.dismissAndForwardAction)
      }
      // 3
    } else if response.actionIdentifier == "dismiss" {
      completion(.dismissAndForwardAction)
    }
  }

}
