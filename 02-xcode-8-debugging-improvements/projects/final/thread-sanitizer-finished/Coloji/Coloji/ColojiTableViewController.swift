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



class ColojiTableViewController: UITableViewController {
  
  let colors: [UIColor] = [.gray, .green, .yellow, .brown, .cyan, .purple]
  let emoji = ["💄", "🙋🏻", "👠", "🎒", "🏩", "🎏"]
  let colojiStore = ColojiDataStore()
  let queue = DispatchQueue(label: "com.raywenderlich.coloji.data-load", attributes: .concurrent, target: .none)
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    loadData()
  }
  
  // MARK: - Table view data source
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return colojiStore.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "colojiCell", for: indexPath)
    
    let coloji = colojiStore.colojiAt(indexPath.row)
    
    let cellFormatter = ColojiCellFormatter(coloji: coloji)
    cellFormatter.configureCell(cell)
    
    return cell
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let destVC = segue.destination as? ColojiViewController,
      let selectedIndex = tableView.indexPathForSelectedRow
    {
      destVC.coloji = colojiStore.colojiAt(selectedIndex.row)
    }
  }
}


extension ColojiTableViewController {
  func loadData() {
    let group = DispatchGroup()
    
    for color in colors {
      queue.async(group: group, qos: .background,
                  flags: DispatchWorkItemFlags(), execute: {
                    let coloji = createColoji(color)
                    self.colojiStore.append(coloji)
      })
    }
    
    for emoji in emoji {
      queue.async(group: group, qos: .background,
                  flags: DispatchWorkItemFlags(), execute: {
                    let coloji = createColoji(emoji)
                    self.colojiStore.append(coloji)
      })
    }
    
    group.notify(queue: DispatchQueue.main) {
      self.tableView.reloadData()
    }
  }
}
