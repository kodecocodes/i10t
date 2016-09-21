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
import CoreSpotlight

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
  var dataStore: DataStore?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    dataStore = loadDataStore("GreenGrocerSeed")
    
    var dso = window?.rootViewController as? DataStoreOwner
    dso?.dataStore = dataStore
    
    // Style the app
    applyAppAppearance()
    
    // Perform the Core Spotlight indexing
    dataStore?.indexContent()
    
    return true
  }
  
  func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Swift.Void) -> Bool {
    if userActivity.activityType == CSQueryContinuationActionType {
      guard let searchQuery = userActivity.userInfo?[CSSearchQueryString] as? String else {
        return false
      }
      guard let rootVC = window?.rootViewController,
        let tabBarViewController = rootVC as? TabBarViewController else {
          return false
      }
      tabBarViewController.selectedIndex = 0
      
      guard let navController = tabBarViewController.selectedViewController as? UINavigationController else {
        return false
      }
      navController.popViewController(animated: false)
      if let productTableVC = navController.topViewController as? ProductTableViewController {
        productTableVC.search(with: searchQuery)
        return true
      }
    } else if let rootVC = window?.rootViewController,
      let restorable = rootVC as? RestorableActivity
      , restorable.restorableActivities.contains(userActivity.activityType) {
      restorationHandler([rootVC])
      return true
    }
    return false
  }
}

extension AppDelegate {
  fileprivate func loadDataStore(_ seedPlistName: String) -> DataStore? {
    if DataStore.defaultDataStorePresentOnDisk {
      return DataStore()
    } else {
      // Locate seed data
      let seedURL = Bundle.main.url(forResource: seedPlistName, withExtension: "plist")!
      let ds = DataStore(plistURL: (seedURL as NSURL) as URL)
      // Save seed data to the documents directory
      ds.save()
      return ds
    }
  }
}
