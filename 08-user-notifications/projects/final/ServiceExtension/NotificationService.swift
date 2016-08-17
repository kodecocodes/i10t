//
//  NotificationService.swift
//  ServiceExtension
//
//  Created by Ray Wenderlich on 7/22/16.
//  Copyright © 2016 Razeware. All rights reserved.
//

import UserNotifications
import MobileCoreServices

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
          // 1
          guard let attachmentString = bestAttemptContent
            .userInfo["attachment-url"] as? String,
            let attachmentUrl = URL(string: attachmentString) else { return }
          
          // 2
          let session = URLSession(configuration:
            URLSessionConfiguration.default)
          let attachmentDownloadTask = session.downloadTask(with:
            attachmentUrl, completionHandler: { (url, response, error) in
              if let error = error {
                print("Error downloading: \(error.localizedDescription)")
              } else if let url = url {
                // 3
                let attachment = try! UNNotificationAttachment(identifier:
                  attachmentString, url: url, options:
                  [UNNotificationAttachmentOptionsTypeHintKey: kUTTypePNG])
                bestAttemptContent.attachments = [attachment]
              }
              // 5
              contentHandler(bestAttemptContent)
          })
          // 4
          attachmentDownloadTask.resume()
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
