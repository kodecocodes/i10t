//: ## Triathlon
import Foundation
//: Create the basic events
let cycleRide = Measurement(value: 25, unit: UnitLength.kilometers)
let swim = Measurement(value: 3, unit: UnitLength.nauticalMiles)
let marathon = Measurement(value: 26, unit: UnitLength.miles)
    + Measurement(value: 385, unit: UnitLength.yards)
//: The unit for marathon is **m**, which is the base unit for `UnitLength`. That's because you added two distances of different `UnitLength` instances together for it.
marathon.unit.symbol
swim.unit.symbol
cycleRide.unit.symbol
//: Find a half-marathon:
let run = marathon / 2
//: Total event distance:
let triathlon = cycleRide + swim + run
//: Let's see that in miles
triathlon.converted(to: .miles)
//: Is the ride longer than the run?
cycleRide > run
//: [Next](@next)
