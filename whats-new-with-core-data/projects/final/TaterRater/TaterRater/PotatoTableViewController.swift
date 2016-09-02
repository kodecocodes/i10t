//
//  PotatoTableViewController.swift
//  PotatoRater
//
//  Created by Richard Turton on 31/08/2016.
//  Copyright © 2016 Razeware. All rights reserved.
//

import UIKit
import CoreData

class PotatoTableViewController: UITableViewController {

    @IBAction func wtf(_ sender: AnyObject) {
        tableView.reloadData()
    }
    var coreDataStack: NSPersistentContainer!
    var resultsController: NSFetchedResultsController<Potato>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let request: NSFetchRequest<Potato> = Potato.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "variety", ascending: true)]
        resultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: coreDataStack.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        do {
            resultsController.delegate = self
            try resultsController.performFetch()
        } catch {
            print("Fetch failed \(error.localizedDescription)")
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
        return resultsController.sections?.count ?? 1
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
            guard let indexPath = indexPath, let newIndexPath = newIndexPath else { return }
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
}
