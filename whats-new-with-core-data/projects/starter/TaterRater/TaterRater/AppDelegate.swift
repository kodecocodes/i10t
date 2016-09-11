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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    
    if let split = window?.rootViewController as? UISplitViewController {
      
      if
        let primaryNav = split.viewControllers.first as? UINavigationController,
        let potatoList = primaryNav.topViewController as? PotatoTableViewController,
        let spudsURL = Bundle.main.url(forResource: "Potatoes", withExtension: "txt") {
        do {
          let spuds = try String(contentsOf: spudsURL)
          let spudList = spuds.components(separatedBy: .newlines)
          let potatoes: [Potato] = spudList.map {
            let potato = Potato()
            potato.variety = $0
            potato.crowdRating = Float(arc4random_uniform(50)) / Float(10)
            return potato
          }
          potatoList.potatoes = potatoes
        } catch {
          print("Error generating potato list \(error.localizedDescription)")
        }
      }
      
      split.delegate = self
      split.preferredDisplayMode = .allVisible
      
    }
    
    return true
  }
}

extension AppDelegate: UISplitViewControllerDelegate {
  func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
    return true
  }
}
