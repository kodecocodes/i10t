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
import CoreData

class PotatoTableViewController: UITableViewController {
  
  var resultsController: NSFetchedResultsController<Potato>!
  var context: NSManagedObjectContext!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // 1
    let request: NSFetchRequest<Potato> = Potato.fetchRequest()
    // 2
    let descriptor = NSSortDescriptor(key: #keyPath(Potato.variety), ascending: true)
    // 3
    request.sortDescriptors = [descriptor]
    // 4
    resultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
    // 5
    do {
      resultsController.delegate = self
      try resultsController.performFetch()
    } catch {
      print("Error performing fetch \(error.localizedDescription)")
    }
    
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
      detail.potato = resultsController.object(at: path)
    }
  }
  
  // MARK: - Table view data source
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return resultsController.sections?.count ?? 0
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return resultsController.sections?[section].numberOfObjects ?? 0
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "PotatoCell", for: indexPath)
    configureCell(cell, atIndexPath: indexPath)
    return cell
  }
  
  fileprivate func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
    let potato = resultsController.object(at: indexPath)
    cell.textLabel?.text = potato.variety
    if potato.userRating > 0 {
      cell.detailTextLabel?.text = "\(potato.userRating) / 5"
      cell.setNeedsLayout()
    } else {
      cell.detailTextLabel?.text = ""
    }
  }
  
}

extension PotatoTableViewController: NSFetchedResultsControllerDelegate {
  
  func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    tableView.beginUpdates()
  }
  
  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
    switch type {
    case .delete:
      guard let indexPath = indexPath else { return }
      tableView.deleteRows(at: [indexPath], with: .automatic)
    case .insert:
      guard let newIndexPath = newIndexPath else { return }
      tableView.insertRows(at: [newIndexPath], with: .automatic)
    case .update:
      guard let indexPath = indexPath else { return }
      if let cell = tableView.cellForRow(at: indexPath) {
        configureCell(cell, atIndexPath: indexPath)
      }
    case .move:
      guard let indexPath = indexPath,
        let newIndexPath = newIndexPath else { return }
      tableView.deleteRows(at: [indexPath], with: .automatic)
      tableView.insertRows(at: [newIndexPath], with: .automatic)
    }
  }
  
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    tableView.endUpdates()
  }
  
}
