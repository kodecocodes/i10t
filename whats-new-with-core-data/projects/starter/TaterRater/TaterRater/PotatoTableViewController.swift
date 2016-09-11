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

class PotatoTableViewController: UITableViewController {
  
  var potatoes = [Potato]()
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    
    if segue.identifier == "showPotato" {
      guard
        let sender = sender as? UITableViewCell,
        let path = tableView.indexPath(for: sender),
        let nav = segue.destination as? UINavigationController,
        let detail = nav.topViewController as? PotatoViewController
        else {
          return
      }
      detail.potato = potatoes[path.row]
    }
  }
  
  // MARK: - Table view data source
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return potatoes.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "PotatoCell", for: indexPath)
    configureCell(cell, atIndexPath: indexPath)
    return cell
  }
  
  fileprivate func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
    let potato = potatoes[indexPath.row]
    cell.textLabel?.text = potato.variety
    if potato.userRating > 0 {
      cell.detailTextLabel?.text = "\(potato.userRating) / 5"
      cell.setNeedsLayout()
    } else {
      cell.detailTextLabel?.text = ""
    }
  }
  
}
