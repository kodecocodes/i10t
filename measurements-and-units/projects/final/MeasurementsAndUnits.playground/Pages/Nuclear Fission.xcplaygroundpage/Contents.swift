//: ## Nuclear Fission
import Foundation
//: Atomic mass unit is approximately the weight of one proton or neutron
let amus = UnitMass(symbol: "amu", converter: UnitConverterLinear(coefficient: 1.661e-27))
//: These are the reactants:
let u235 = Measurement(value: 235.043924, unit: amus)
let neutron = Measurement(value: 1.008665, unit: amus)
let massBefore = u235 + neutron
//: These are the products:
let kr92 = Measurement(value: 91.926156, unit: amus)
let ba141 = Measurement(value: 140.914411, unit: amus)
let massAfter = kr92 + ba141 + (3 * neutron)
//: Function for converting mass to energy, thanks to Einstein:
func emc2(mass: Measurement<UnitMass>) -> Measurement<UnitEnergy> {
  let speedOfLight = Measurement(value: 299792458, unit: UnitSpeed.metersPerSecond)
  let energy = mass.converted(to: .kilograms).value * pow(speedOfLight.value, 2)
  return Measurement(value: energy, unit: UnitEnergy.joules)
}
//: How much mass has been converted to energy for one atom?
let massDifference = massBefore - massAfter
let energy = emc2(mass: massDifference)
//: How many atoms in a given mass of a substance?
func atoms(atomicMass: Double, substanceMass: Measurement<UnitMass>) -> Double {
  let grams = substanceMass.converted(to: .grams)
  let moles = grams.value / atomicMass
  let avogadro = 6.0221409e+23
  return moles * avogadro
}
//: How many atoms in a pound of Uranium-235?
let numberOfAtoms = atoms(atomicMass: u235.value, substanceMass: Measurement(value: 1, unit: .pounds))
//: How much energy would that give in total?
let energyPerPound = energy * numberOfAtoms
//: How many houses at 11,700Wh / year would that power?
let kwh = energyPerPound.converted(to: .kilowattHours)
kwh.value / 11700

//: [Previous](@previous)        [Next](@next)
