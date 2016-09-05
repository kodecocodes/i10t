//
//  AppDelegate.swift
//  PotatoRater
//
//  Created by Richard Turton on 31/08/2016.
//  Copyright © 2016 Razeware. All rights reserved.
//

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
                        let potato = Potato(variety: $0)
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
