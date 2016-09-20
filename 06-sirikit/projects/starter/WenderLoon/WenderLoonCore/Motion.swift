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

enum MovementStatus {
  case moving
  case waitingForRequest
  case withPassengers
  case enRouteToCollection
  case completed
}

struct MovementState {
  let status: MovementStatus
  let location: CLLocation
}

protocol Moveable: AnyObject {
  func update(movementState: MovementState)
}

protocol Movement {
  var moveable: Moveable { get }
  var eta: Date? { get }
  var childMovement: Movement? { get }
  mutating func beginMovement()
  mutating func cancelMovement()
}

extension Movement {
  func cancelMovement() {
    childMovement?.cancelMovement()
  }
  
  var eta: Date? {
    return childMovement?.eta
  }
}


class HoldingPattern: Movement, Moveable {
  let moveable: Moveable
  let start: CLLocation
  let centre: CLLocation
  let radius: CLLocationDistance = 10_000
  let speed: CLLocationSpeed = 30
  var childMovement: Movement? = .none
  
  init(moveable: Moveable, start: CLLocation, centre: CLLocation) {
    self.moveable = moveable
    self.start = start
    self.centre = centre
  }
  
  func beginMovement() {
    initiateNewRandomPath(from: self.start)
  }
  
  func update(movementState: MovementState) {
    switch movementState.status {
    case .completed:
      // Kick off new random movement
      initiateNewRandomPath(from: movementState.location)
    case .moving:
      // Pass this on
      moveable.update(movementState: MovementState(status: .waitingForRequest, location: movementState.location))
    default:
      break
    }
  }
  
  private func initiateNewRandomPath(from: CLLocation) {
    childMovement = PointToPoint(start: from,
                                   end: centre.randomPointWithin(radius: self.radius),
                                   speed: self.speed,
                                   moveable: self)
    childMovement?.beginMovement()
  }
}

class Journey: Movement, Moveable {
  let moveable: Moveable
  let start: CLLocation
  let pickup: CLLocation
  let end: CLLocation
  let speed: CLLocationSpeed = 50
  var childMovement: Movement? = .none
  
  var currentState: MovementState?
  
  init(moveable: Moveable, start: CLLocation, pickup: CLLocation, end: CLLocation) {
    self.moveable = moveable
    self.start = start
    self.pickup = pickup
    self.end = end
  }
  
  func beginMovement() {
    currentState = MovementState(status: .enRouteToCollection, location: start)
    childMovement = PointToPoint(start: start, end: pickup, speed: speed, moveable: self)
    childMovement?.beginMovement()
  }
  
  func update(movementState: MovementState) {
    guard let currentState = currentState else { return }
    let location = movementState.location
    switch (currentState.status, movementState.status) {
    case (.enRouteToCollection, .moving):
      self.currentState = MovementState(status: .enRouteToCollection, location: location)
    case (.enRouteToCollection, .completed):
      self.currentState = MovementState(status: .withPassengers, location: location)
      childMovement?.cancelMovement()
      childMovement = PointToPoint(start: location, end: end, speed: speed, moveable: self)
      childMovement?.beginMovement()
    case (.withPassengers, .moving):
      self.currentState = MovementState(status: .withPassengers, location: location)
    case (.withPassengers, .completed):
      self.currentState = MovementState(status: .completed, location: location)
    default:
      break
    }
    moveable.update(movementState: self.currentState!)
  }
}

class PointToPoint: Movement {
  let start: CLLocation
  let end: CLLocation
  let speed: CLLocationSpeed
  let moveable: Moveable
  
  var timer: Timer? = .none
  var eta: Date? = .none
  let childMovement: Movement? = .none
  
  init(start: CLLocation, end: CLLocation, speed: CLLocationSpeed, moveable: Moveable) {
    self.start = start
    self.end = end
    self.speed = speed
    self.moveable = moveable
  }
  
  func beginMovement() {
    let startTime = Date()
    let totalDistance = start.distance(from: end)
    let totalTime = totalDistance / self.speed
    eta = startTime.addingTimeInterval(totalTime)
    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (t) in
      let elapsedTime = Date().timeIntervalSince(startTime)
      // Maybe motion is finished
      if elapsedTime > totalTime {
        self.moveable.update(movementState: MovementState(status: .completed, location: self.end))
        t.invalidate()
      } else {
        // Else work out where we are on the straight line
        let lat = (self.end.coordinate.latitude - self.start.coordinate.latitude) * elapsedTime / totalTime + self.start.coordinate.latitude
        let long = (self.end.coordinate.longitude - self.start.coordinate.longitude) * elapsedTime / totalTime + self.start.coordinate.longitude
        let currentLocation = CLLocation(latitude: lat, longitude: long)
        self.moveable.update(movementState: MovementState(status: .moving, location: currentLocation))
      }
    })
  }
  
  func cancelMovement() {
    eta = .none
    timer?.invalidate()
    timer = .none
  }
}
