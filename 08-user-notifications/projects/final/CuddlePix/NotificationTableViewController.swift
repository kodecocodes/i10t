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

class NotificationTableViewController: UITableViewController {
  
  var tableSectionProviders = [NotificationTableSection : TableSectionProvider]()
  
  @IBAction func handleRefresh(_ sender: UIRefreshControl) {
    loadNotificationData {
      DispatchQueue.main.async(execute: {
        self.tableView.reloadData()
        sender.endRefreshing()
      })
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    UNUserNotificationCenter.current()
      .requestAuthorization(options: [.alert, .sound]) {
        (granted, error) in
        if granted {
          self.loadNotificationData()
        } else {
          print(error?.localizedDescription)
        }
    }
    
    NotificationCenter.default.addObserver(self, selector: #selector(handleNotificationReceived), name: userNotificationReceivedNotificationName, object: .none)
  }
}


// MARK: - Table view data source
extension NotificationTableViewController {
  override func numberOfSections(in tableView: UITableView) -> Int {
    return tableSectionProviders.count
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    guard let notificationTableSection = NotificationTableSection(rawValue: section),
      let sectionProvider = tableSectionProviders[notificationTableSection] else { return 0 }
    
    return sectionProvider.numberOfCells
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    var cell = tableView.dequeueReusableCell(withIdentifier: "standardCell", for: indexPath)
    
    guard let tableSection = NotificationTableSection(rawValue: indexPath.section),
      let sectionProvider = tableSectionProviders[tableSection],
      let cellProvider = sectionProvider.cellProvider(at: indexPath.row)
      else { return cell }
    
    cell = cellProvider.prepare(cell: cell)
    
    return cell
  }
  
  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    guard let notificationTableSection = NotificationTableSection(rawValue: section),
      let sectionProvider = tableSectionProviders[notificationTableSection]
      else { return .none }
    
    return sectionProvider.name
  }
  
  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return NotificationTableSection(rawValue: indexPath.section) == .some(.pending)
  }
  
  override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
    return NotificationTableSection(rawValue: indexPath.section) == .some(.pending) ? .delete : .none
  }
  
  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    
    guard let section =
      NotificationTableSection(rawValue: indexPath.section)
      , editingStyle == .delete && section == .pending else { return }
    
    // 2
    guard let provider = tableSectionProviders[.pending]
      as? PendingNotificationsTableSectionProvider else { return }
    
    let request = provider.requests[indexPath.row]
    
    // 3
    UNUserNotificationCenter.current()
      .removePendingNotificationRequests(withIdentifiers:
        [request.identifier])
    loadNotificationData(callback: {
      self.tableView.deleteRows(at: [indexPath], with: .automatic)
    })
    
  }
}

// MARK: - Table refresh handling
extension NotificationTableViewController {
  func handleNotificationReceived(_ notification: Notification) {
    loadNotificationData()
  }
  
  func loadNotificationData(callback: (() -> ())? = .none) {
    let group = DispatchGroup()
    
    // 1
    let notificationCenter = UNUserNotificationCenter.current()
    let dataSaveQueue = DispatchQueue(label:
      "com.raywenderlich.CuddlePix.dataSave")
    
    // 2
    group.enter()
    // 3
    notificationCenter.getNotificationSettings { (settings) in
      let settingsProvider = SettingTableSectionProvider(settings:
        settings, name: "Notification Settings")
      // 4
      dataSaveQueue.async(execute: {
        self.tableSectionProviders[.settings] = settingsProvider
        group.leave()
      })
    }
    
    group.enter()
    notificationCenter.getPendingNotificationRequests { (requests) in
      let pendingRequestsProvider =
        PendingNotificationsTableSectionProvider(requests:
          requests, name: "Pending Notifications")
      dataSaveQueue.async(execute: {
        self.tableSectionProviders[.pending] = pendingRequestsProvider
        group.leave()
      })
    }
    group.enter()
    notificationCenter.getDeliveredNotifications { (notifications) in
      let deliveredNotificationsProvider =
        DeliveredNotificationsTableSectionProvider(notifications:
          notifications, name: "Delivered Notifications")
      dataSaveQueue.async(execute: {
        self.tableSectionProviders[.delivered]
          = deliveredNotificationsProvider
        group.leave()
      })
    }
    
    group.notify(queue: DispatchQueue.main) {
      if let callback = callback {
        callback()
      } else {
        self.tableView.reloadData()
      }
    }
  }
}

// MARK: - ConfigurationViewControllerDelegate
extension NotificationTableViewController: ConfigurationViewControllerDelegate {
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let destVC = segue.destination as? ConfigurationViewController {
      destVC.delegate = self
    }
  }
  
  func configurationCompleted(newNotifications new: Bool) {
    if new {
      loadNotificationData()
    }
    _ = navigationController?.popViewController(animated: true)
  }
}
