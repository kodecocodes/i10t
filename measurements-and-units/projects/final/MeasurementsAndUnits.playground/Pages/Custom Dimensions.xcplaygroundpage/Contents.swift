//: ## Custom Dimensions

import Foundation
//: A new length unit, extending `UnitLength`:
extension UnitLength {
  class var chains: UnitLength {
    return UnitLength(symbol: "ch",
                      converter: UnitConverterLinear(coefficient: 20.1168))
  }
}
//: Works just like the built-in ones:
let cricketPitch = Measurement(value: 1, unit: UnitLength.chains)

cricketPitch.converted(to: .baseUnit())
cricketPitch.converted(to: .furlongs)
(80 * cricketPitch).converted(to: .miles)
//: A new converter, for logarithmic relationships:
class UnitConverterLogarithmic: UnitConverter, NSCopying {
  let coefficient: Double
  let logBase: Double
  
  init(coefficient: Double, logBase: Double) {
    self.coefficient = coefficient
    self.logBase = logBase
  }
  
  func copy(with zone: NSZone? = nil) -> Any {
    return self
  }
  
  override func baseUnitValue(fromValue value: Double) -> Double {
    return coefficient * log(value) / log(logBase)
  }
  
  override func value(fromBaseUnitValue baseUnitValue: Double) -> Double {
    return exp(baseUnitValue * log(logBase) / coefficient)
  }
}
//: A new Dimension subclass to represent ratio measurements
class UnitRatio: Dimension {
  class var decibels: UnitRatio {
    return UnitRatio(symbol: "dB", converter: UnitConverterLinear(coefficient: 1))
  }
  
  class var amplitudeRatio: UnitRatio {
    return UnitRatio(symbol: "", converter: UnitConverterLogarithmic(coefficient: 20, logBase: 10))
  }
  
  class var powerRatio: UnitRatio {
    return UnitRatio(symbol: "", converter: UnitConverterLogarithmic(coefficient: 10, logBase: 10))
    
  }
  
  override class func baseUnit() -> UnitRatio {
    return UnitRatio.decibels
  }
}

let doubleVolume = Measurement(value: 2, unit: UnitRatio.powerRatio)
doubleVolume.converted(to: .decibels)

let upTo11 = Measurement(value: 1.1, unit: UnitRatio.powerRatio)
upTo11.converted(to: .decibels)

//: [Previous](@previous)        [Next](@next)
