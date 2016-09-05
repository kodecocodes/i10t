//
//  PotatoDataStack.swift
//  TaterRater
//
//  Created by Richard Turton on 02/09/2016.
//  Copyright © 2016 Razeware. All rights reserved.
//

import CoreData

var scoreFormatter: NumberFormatter = {
    $0.numberStyle = .decimal
    $0.maximumSignificantDigits = 2
    return $0
}(NumberFormatter())

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
                        potato.crowdRating = Float(arc4random_uniform(50)) / Float(10)
                    }
                    
                    try context.save()
                }
            } catch {
                print("Error importing potatoes: \(error.localizedDescription)")
            }
        }
    }
    
    private var timer: Timer? {
        willSet {
            timer?.invalidate()
        }
    }
    
    func startUpdatingCrowdScores(potato: Potato) {
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) {
            timer in
            self.updateCrowdScores(potatoID: potato.objectID)
        }
    }
    
    func stopUpdatingCrowdScores() {
        timer = nil
    }
    
    private func updateCrowdScores(potatoID: NSManagedObjectID) {
        performBackgroundTask { context in
            do {
                guard let potato = try context.existingObject(with: potatoID) as? Potato else { return }
                let adjustment: Float = arc4random_uniform(2) == 1 ? -0.1 : 0.1
                potato.crowdRating += adjustment
                potato.crowdRating = min(potato.crowdRating, 5)
                potato.crowdRating = max(potato.crowdRating, 0)
                try context.save()
            } catch {
                print("Error updating crowd score: \(error.localizedDescription)")
            }
        }
    }
    
}
