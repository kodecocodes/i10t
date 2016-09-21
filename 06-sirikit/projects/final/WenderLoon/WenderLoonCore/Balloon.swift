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

public class Balloon {
  public let driver: Driver
  public let image: UIImage
  let movementCallback: (Balloon, CLLocation) -> ()
  var state: MovementState
  var currentMovement: Movement?
  let regionCentre: CLLocation
  
  var location: CLLocation {
    return state.location
  }
  
  var availableForPickup: Bool {
    return state.status == .waitingForRequest
  }
  
  public var etaAtNextDestination: Date {
    return currentMovement?.eta ?? Date()
  }
  
  init(driver: Driver, image: UIImage, location: CLLocation, movementCallback: @escaping (Balloon, CLLocation) -> ()) {
    self.driver = driver
    self.image = image
    self.movementCallback = movementCallback
    self.state = MovementState(status: .waitingForRequest, location: location)
    self.regionCentre = location
    beginHoldingPattern()
  }
  
  func requestTrip(pickup: CLLocation, dropoff: CLLocation) -> Bool {
    if !availableForPickup { return false }
    
    currentMovement = Journey(moveable: self, start: location, pickup: pickup, end: dropoff)
    currentMovement?.beginMovement()
    return true
  }
}

extension Balloon: Moveable {
  func update(movementState: MovementState) {
    self.state = movementState
    movementCallback(self, location)
    
    if movementState.status == .completed {
      beginHoldingPattern()
    }
  }
  
  fileprivate func beginHoldingPattern() {
    currentMovement = HoldingPattern(moveable: self, start: location, centre: regionCentre)
    currentMovement?.beginMovement()
  }
}

extension Balloon: Hashable {
  public var hashValue: Int {
    return image.hashValue
  }
}

public func ==(lhs: Balloon, rhs: Balloon) -> Bool {
  return lhs.image == rhs.image
}


