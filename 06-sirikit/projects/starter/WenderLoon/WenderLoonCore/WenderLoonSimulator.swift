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

import Foundation
import CoreLocation

let people = [("Ray", 4), ("Mic", 1), ("Vicki", 5), ("Brian", 3)]
let balloonImageNames = (1...4).map { "balloon-\($0)" }
let buckinghamPalace = CLLocation(latitude: 51.500833, longitude: -0.141944)

public class WenderLoonSimulator {
  let balloons: [Balloon]
  
  public init(renderer: WenderLoonRenderer? = .none) {
    let balloonImages = balloonImageNames.map { UIImage(named: $0, in: Bundle(for: WenderLoonCore.self), compatibleWith: .none)! }
    self.balloons = zip(people, balloonImages).map { (person, balloonImage) in
      let driver = Driver(name: person.0, picture: UIImage(named: person.0, in: Bundle(for: WenderLoonCore.self), compatibleWith: .none)!, rating: Rating(rawValue: person.1)!)
      return Balloon(driver: driver,
                     image: balloonImage,
                     location: buckinghamPalace.randomPointWithin(radius: 10_000),
                     movementCallback: { (balloon, location) in
        renderer?.balloon(balloon, didMoveTo: location)
      })
    }
  }
}

extension WenderLoonSimulator {
  func closestAvailableBalloon(location: CLLocation) -> Balloon? {
    return balloons.filter { $0.availableForPickup }
      .sorted { $0.location.distance(from: location) < $1.location.distance(from: location) }
      .first
  }
  
  public func requestRide(pickup: CLLocation, dropoff: CLLocation) -> Balloon? {
    guard let balloon = closestAvailableBalloon(location: pickup) else { return .none }
    
    if balloon.requestTrip(pickup: pickup, dropoff: dropoff) {
      return balloon
    }
    return .none
  }
  
  public func checkNumberOfPassengers(_ number: Int) -> Bool {
    return (1...4).contains(number)
  }
  
  public func pickupWithinRange(_ pickup: CLLocation) -> Bool {
    if let closestBalloon = closestAvailableBalloon(location: pickup) {
      return closestBalloon.location.distance(from: pickup) < 50000
    }
    return false
  }
  
}

extension WenderLoonSimulator {
  static public func imageForDriver(name: String) -> UIImage? {
    return UIImage(named: name, in: Bundle(for: WenderLoonCore.self), compatibleWith: .none)
  }
  static public func imageForBallon(driverName: String) -> UIImage? {
    let simulator = WenderLoonSimulator(renderer: nil)
    return (simulator.balloons.filter { $0.driver.name == driverName }).first?.image
  }
}

public protocol WenderLoonRenderer {
  func balloon(_ balloon: Balloon, didMoveTo location: CLLocation)
}


private class WenderLoonCore {
    
}

