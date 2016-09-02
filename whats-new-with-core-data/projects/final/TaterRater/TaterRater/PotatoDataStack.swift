//
//  PotatoDataStack.swift
//  TaterRater
//
//  Created by Richard Turton on 02/09/2016.
//  Copyright © 2016 Razeware. All rights reserved.
//

import CoreData

class PotatoDataStack: NSPersistentContainer {

    func checkAndLoadInitialData() {
        performBackgroundTask { context in
            let request: NSFetchRequest<Potato> = Potato.fetchRequest()
            do {
                if try context.count(for: request) == 0 {
                    // Import some spuds
                    sleep(5)
                    guard let spudsURL = Bundle.main.url(forResource: "Potatoes", withExtension: "txt") else { return }
                    let spuds = try String(contentsOf: spudsURL)
                    let spudList = spuds.components(separatedBy: .newlines)
                    for spud in spudList {
                        let potato = Potato(context: context)
                        potato.variety = spud
                    }
                    
                    let observer: Any? = NotificationCenter.default.addObserver(forName: .NSManagedObjectContextDidSave, object: context, queue: .main) {
                        notification in
                        self.viewContext.mergeChanges(fromContextDidSave: notification)
                    }
                    try context.save()
                    NotificationCenter.default.removeObserver(observer)
                }
            } catch {
                print("Error importing potatoes: \(error.localizedDescription)")
            }
        }
    }

}
