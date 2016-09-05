//
//  AppDelegate.swift
//  PotatoRater
//
//  Created by Richard Turton on 31/08/2016.
//  Copyright © 2016 Razeware. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var coreDataStack: PotatoDataStack!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        coreDataStack = PotatoDataStack(name: "TaterRater")
        
        // Delete the store files on first run while we test this
//        if let contents = try? FileManager.default.contentsOfDirectory(at: NSPersistentContainer.defaultDirectoryURL(), includingPropertiesForKeys: nil, options: []) {
//            for url in contents {
//                try? FileManager.default.removeItem(at: url)
//            }
//        }
        
        coreDataStack.loadPersistentStores {
            [unowned self]
            description, error in
            if let error = error {
                print("Error creating persistent stores: \(error.localizedDescription)")
                return
            }
            self.coreDataStack.checkAndLoadInitialData()
        }
        
        coreDataStack.viewContext.automaticallyMergesChangesFromParent = true
        
        if let split = window?.rootViewController as? UISplitViewController {
            if
                let primaryNav = split.viewControllers.first as? UINavigationController,
                let potatoList = primaryNav.topViewController as? PotatoTableViewController {
                potatoList.coreDataStack = coreDataStack
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
