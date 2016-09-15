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

class ProductTableViewController: UITableViewController, DataStoreOwner {
  
  let searchController = UISearchController(searchResultsController: nil)
  var filteredProducts = [Product]()
  var dataStore: DataStore? {
    didSet {
      tableView.reloadData()
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.estimatedRowHeight = 120
    
    searchController.searchResultsUpdater = self
    searchController.dimsBackgroundDuringPresentation = false
    definesPresentationContext = true
    tableView.tableHeaderView = searchController.searchBar
  }
  
  func search(with searchString: String) {
    searchController.searchBar.text = searchString
    searchController.searchBar.becomeFirstResponder()
  }
  
  var isFilterActive: Bool {
    return (searchController.isActive &&
      searchController.searchBar.text != "")
  }
  
  // MARK: - Table view data source
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if isFilterActive {
      return filteredProducts.count
    } else {
      return dataStore?.products.count ?? 0
    }
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ProductCell", for: indexPath)
    
    var product: Product? = nil
    if isFilterActive {
      product = filteredProducts[indexPath.row]
    } else {
      product = dataStore?.products[(indexPath as NSIndexPath).row]
    }
  
    if let cell = cell as? ProductTableViewCell {
      cell.product = product
    }
    
    return cell
  }
  
  // MARK: - Navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let destVC = segue.destination as? ProductViewController {
      let selectedRow = (tableView.indexPathForSelectedRow as NSIndexPath?)?.row ?? 0
      destVC.product = isFilterActive ? filteredProducts[selectedRow] :
        dataStore?.products[selectedRow]
    }
  }
}

extension ProductTableViewController: UISearchResultsUpdating {
  func updateSearchResults(for searchController: UISearchController) {
    filterContentForSearchText(searchText: searchController.searchBar.text!)
  }
  
  func filterContentForSearchText(searchText: String) {
    guard let dataStore = dataStore else {
      return
    }

    filteredProducts = dataStore.products.filter { product in
      return product.name.lowercased().contains(searchText.lowercased())
    }
    
    tableView.reloadData()
  }
}

extension ProductTableViewController: RestorableActivity {
  override func restoreUserActivityState(_ activity: NSUserActivity) {
    switch activity.activityType {
    case productActivityName:
      if let id = activity.userInfo?["id"] as? String {
        displayVCForProductWithId(id)
      }
      break
    case CSSearchableItemActionType:
      if let id = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String {
        displayVCForProductWithId(id)
      }
      break
    default:
      break
    }
    
    super.restoreUserActivityState(activity)
  }
  
  var restorableActivities: Set<String> {
    return Set([productActivityName, CSSearchableItemActionType])
  }
  
  fileprivate func displayVCForProductWithId(_ id: String) {

    guard let id = UUID(uuidString: id),
      let productIndex = dataStore?.products.index(where: { $0.id == id }) else {
        return
    }
    tableView.selectRow(at: IndexPath(row: productIndex, section: 0), animated: false, scrollPosition: .middle)
    performSegue(withIdentifier: "DisplayProduct", sender: self)
  }
}
