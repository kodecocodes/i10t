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

import CoreData

extension NSPersistentContainer {
  
  func importPotatoes() {
    performBackgroundTask { context in
      let request: NSFetchRequest<Potato> = Potato.fetchRequest()
      do {
        if try context.count(for: request) == 0 {
          // Import some spuds
          sleep(3)
          guard let spudsURL = Bundle.main.url(forResource: "Potatoes", withExtension: "txt") else { return }
          let spuds = try String(contentsOf: spudsURL)
          let spudList = spuds.components(separatedBy: .newlines)
          for spud in spudList {
            let potato = Potato(context: context)
            potato.variety = spud
            potato.crowdRating = Float(arc4random_uniform(50)) / Float(10)
          }
          
          try context.save()
        }
      } catch {
        print("Error importing potatoes: \(error.localizedDescription)")
      }
    }
  }
  
}
