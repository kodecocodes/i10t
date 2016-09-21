/*
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import UserNotifications
import UserNotificationsUI

class NotificationViewController: UIViewController, UNNotificationContentExtension {
  
  @IBOutlet weak var imageView: UIImageView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  func didReceive(_ notification: UNNotification) {
    guard let attachment = notification.request.content.attachments.first
      else { return }
    
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
    if response.actionIdentifier == "star" {
      imageView.showStars()
      let time = DispatchTime.now() +
        DispatchTimeInterval.milliseconds(2000)
      DispatchQueue.main.asyncAfter(deadline: time) {
        completion(.dismissAndForwardAction)
      }
    }
  }
}
