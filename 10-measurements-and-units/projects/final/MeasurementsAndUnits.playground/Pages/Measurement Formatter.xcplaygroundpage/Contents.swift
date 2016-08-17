//: ## Measurement Formatters
import Foundation

let temperature = Measurement(value: 24, unit: UnitTemperature.celsius)
let formatter = MeasurementFormatter()
//: The default locale for a playground is `en_US`, so this result is in Fahrenheit:
formatter.string(from: temperature)
//: Move to a country with a sensible measurement system:
formatter.locale = Locale(identifier: "en_GB")
formatter.string(from: temperature)
//: This option stops the formatter from indicating the temperature unit:
formatter.unitOptions = .temperatureWithoutUnit
formatter.string(from: temperature)
//: `.temperatureWithoutUnit` prevents the formatter from changing temperature scales based on locale:
formatter.locale = Locale(identifier: "en_US")
formatter.string(from: temperature)
//: This option stops the formatter from changing units to a locally preferred variant:
formatter.unitOptions = .providedUnit
formatter.string(from: temperature)
//: The third `unitOption` doesn't work with temperatures.
let run = Measurement(value: 20000, unit: UnitLength.meters)
formatter.string(from: run)
//: Provided Unit keeps it in the metric system, natural scale gives it permission to move up and down:
formatter.unitOptions = [.naturalScale, .providedUnit]
formatter.string(from: run)
let speck = Measurement(value: 0.0002, unit: UnitLength.meters)
formatter.string(from: speck)
//: Unit style controls how the unit is displayed
formatter.unitStyle = .long
formatter.string(from: run)
//: You can also take control of the way the numbers themselves are displayed:
let numberFormatter = NumberFormatter()
numberFormatter.numberStyle = .spellOut
formatter.numberFormatter = numberFormatter
formatter.string(from: run)

//: [Previous](@previous)        [Next](@next)
