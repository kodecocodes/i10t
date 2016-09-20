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
import Intents

public extension UIImage {
  public var inImage: INImage {
    return INImage(imageData: UIImagePNGRepresentation(self)!)
  }
}

public extension Driver {
  public var rideIntentDriver: INRideDriver {
    return INRideDriver(personHandle: INPersonHandle(value: name, type: .unknown),
                        nameComponents: .none,
                        displayName: name,
                        image: picture.inImage,
                        rating: rating.toString,
                        phoneNumber: .none)
  }
}

public extension Balloon {
  public var rideIntentVehicle: INRideVehicle {
    let vehicle = INRideVehicle()
    vehicle.location = location
    vehicle.manufacturer = "Hot Air Balloon"
    vehicle.registrationPlate = "B4LL 00N"
    vehicle.mapAnnotationImage = image.inImage
    return vehicle
  }
}
