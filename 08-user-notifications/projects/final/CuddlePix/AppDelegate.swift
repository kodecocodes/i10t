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

let userNotificationReceivedNotificationName = Notification.Name("com.raywenderlich.CuddlePix.userNotificationReceived")
let newCuddlePixCategoryName = "newCuddlePix"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    configureUserNotifications()
    application.registerForRemoteNotifications()
    return true
  }
  
  func configureUserNotifications() {
    let starAction = UNNotificationAction(identifier:
      "star", title: "🌟 star my cuddle 🌟 ", options: [])
    let category =
      UNNotificationCategory(identifier: newCuddlePixCategoryName,
                             actions: [starAction],
                             intentIdentifiers: [],
                             options: [])
    
    UNUserNotificationCenter.current()
      .setNotificationCategories([category])
  }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler:
    @escaping (UNNotificationPresentationOptions) -> Void) {
    NotificationCenter.default.post(name:userNotificationReceivedNotificationName, object: .none)
    
    completionHandler(.alert)
  }
  
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler
    completionHandler: @escaping () -> Void) {
    print("Response received for \(response.actionIdentifier)")
    completionHandler()
  }
}

extension AppDelegate {
  func application(_ application: UIApplication,
                   didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("Registration for remote notifications failed")
    print(error.localizedDescription)
  }
  
  func application(_ application: UIApplication,
                   didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    print("Registered with device token: \(deviceToken.hexString)")
  }
}
