//
//  PotatoTableViewController.swift
//  PotatoRater
//
//  Created by Richard Turton on 31/08/2016.
//  Copyright © 2016 Razeware. All rights reserved.
//

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
