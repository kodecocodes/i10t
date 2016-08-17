```metadata
author: "By Rich Turton"
number: "10"
title: "Chapter 10: Measurements and Units"
```
# Chapter 10: Measurements and Units

You’ve probably written code like this:

```swift
let distance: CGFloat // Distance is in miles
```

When dealing with real-world units in code, it’s easy just to use one of the built-in numeric types and try to remember all the places you’re supposed to use units along with the number, like the following:

```swift
distanceLabel.text = "\(distance) miles"
```

But that’s not quite correct if there’s only one mile, or if the mile has a lot of decimal places, so you’d have to add even more code to counter this. Then it doesn’t localize properly, so you add some _more_ code. Then people want to see their distances in kilometers, so you add a preference and some conversion logic.

If this is a familiar story, you’re in luck. The Foundation framework has some exciting new additions this year for solving exactly these problems. You’re going to learn about `Measurement` and `Unit`, and how they allow you to do the following:

- Get rid of fiddly conversions
- Use strongly typed values that prevent, for example, from using yards when you meant Kelvin
- Show values to the user in terms they understand
- Get all this power for your _own_ measurements and units.

Another exciting addition to Foundation this year is the date interval — a period from one `Date` to another. Again, this represents a problem that is commonly solved by having to write a lot of code that you probably don’t test (admit it), and you almost certainly don’t test for international users. Date intervals and the associated date interval formatter will make your life easier when you need to work with dates — and let’s face it, dates are hard, so all help is welcome!

To get started, you’re going to learn about two new types that will make a _measurable_ improvement to your code. :]

## Measurement and Unit

The `Measurement` struct doesn’t sound like much; it has two properties, a `value`, which is a `Double`, and a `unit`, which is a `Unit`. `Unit` is even more minimal — all it has is a `symbol`, which is just a `String`.

This minimal implementation gives you some benefits. Given a `Measurement`, you’d know right away what its units were, and be able to format it for display using the symbol that comes with the unit. But the real power of the system comes from two things:

- The `Unit` subclasses that are included with Foundation
- The use of generics to associate a particular `Measurement` with a given `Unit`

First, the `Unit` subclasses. Foundation gives you the `Dimension` subclass to represent units that have a dimension, such as length or temperature. Dimensions have a base unit and a converter that can interpret the value to and from the base unit. It’s an abstract class, which means you’re expected to subclass it to make your own dimensions. A wide variety are already included in Foundation.

As an example, there is a `UnitLength` class. This is a subclass of `Dimension` used to represent lengths or distances. The base unit is the meter, which is the SI unit for length.

>**Note**: SI stands for Système International, the internationally agreed system of measurements. Readers from the US, brace yourselves for learning that you are measuring almost everything “incorrectly”. :]

`UnitLength` has over 20 class variables which are instances of `UnitLength`. Each one has a different converter so that it can be translated to and from meters.

`UnitLength.meters`, for example, has a converter that does nothing, because the unit is already in the base unit. `UnitLength.miles` will have a converter that knows that there are around 0.000621371 miles per meter.

When you create a `Measurement`, you give it a value and a unit. That unit becomes a generic constraint on the measurement. Knowing that a measurement is associated with a particular `Unit` means that Swift won’t let you do things with two measurements that don’t use the same unit, and it means that you _can_ do useful things with measurements that do — like math.

## I want to ride my bicycle

A triathlon is a fun event if your idea of fun is spending all day hurting. The annual raywenderlich.com team triathlon event is particularly fun. There’s a 25km bike ride, a swim of 3 nautical miles and a half marathon.

Open a new playground to get started. The bike ride and swim are pretty easy to make:

```swift
let cycleRide = Measurement(value: 25,
  unit: UnitLength.kilometers)
let swim = Measurement(value: 3,
  unit: UnitLength.nauticalMiles)
```

A marathon is 26 miles, 385 yards. This awkward number comes from the 1908 London Olympics, where the organiz ers planned a course of 26 miles, then had to add an extra bit so that the race would finish neatly in front of the Royal Box. Do you know what 26 miles, 385 yards is in “Decimal miles”? I don’t, and now, I don’t have to.

To create a measurement of a marathon, add the following to the playground:

```swift
let marathon = Measurement(value: 26, unit: UnitLength.miles)
  + Measurement(value: 385, unit: UnitLength.yards)
```

Notice that you’ve been able to add these measurements together, even though one is in miles and the other is in yards. That’s because the units are all `UnitLength`. The final value of `marathon` is in the base unit, because that’s the only result that makes sense when adding two different instances together. Add the following code to the playground to take a look at the units in use:

```swift
marathon.unit.symbol
swim.unit.symbol
cycleRide.unit.symbol
```

The results sidebar shows the units in use for each measurement: meters, nautical miles, and kilometers. Find the length of a half-marathon like this:

```swift
let run = marathon / 2
```

Then you can get the total distance covered in the triathlon like this:

```swift
let triathlon = cycleRide + swim + run
```

As you might expect, `triathlon` shows up in the results sidebar in meters, which isn’t particularly useful. Generics can help you here. `Measurement` instances with a `Unit` subclassing `Dimension` have a useful extra feature: they can convert to other units, or be converted to other units. To see the triathlon total in miles, add this line:

```swift
triathlon.converted(to: .miles)
```

The results sidebar will now show you 32.096 miles and change.

In addition to mathematical operations, you can also compare measurements of the same `Unit`. To find out if the cycle ride is longer than the run, you can do this:

```swift
cycleRide > run
```

It’s true: A 25km cycle ride is longer than running a half marathon. Which would you rather do?

If all of this exercise has left you feeling short of energy, the next section should help.

## Uranium Fever

You’ve almost certainly heard of Einstein’s equation **E = mc²**. It states that the energy (**E**) contained in a mass (**m**) is equal to the mass multiplied by the square of the speed of light (**c**). In this equation, energy is measured in joules, mass in kilograms, and the speed of light in meters per second.

Light is really rather fast — 299,792,458 meters per second. This suggests that everything contains huge amounts of energy. Perhaps luckily, that energy is quite hard to release.

One way to convert mass into energy is nuclear fission. The type commonly used in nuclear power stations works a little like this (it’s a bit more complicated in reality, but you’re not here to get a nuclear physics degree):

- Uranium-235 gets hit by a neutron
- Uranium-235 absorbs the neutron and briefly becomes Uranium-236
- Then it breaks apart into Krypton-92, Barium-141 and three more neutrons
- Those neutrons carry on to hit more Uranium-235...

> **Note:** If you _do_ have a nuclear physics degree, congratulations on your change of career, but please don’t get upset about errors or simplifications in this chapter.

You’re going to do some calculations in the playground to work out what is happening in this reaction.

First of all, you’re going to define a unit to deal with atomic masses. Atoms aren’t very heavy things on their own, and physicists use _Atomic Mass Units_ to talk about them. One atomic mass unit is approximately the mass of a proton or neutron, and is approximately 1.661 x 10 to the -27th power kilograms. That’s quite a small number.

Add the following code to the playground to create this instance of `UnitMass`:

```swift
let amus = UnitMass(symbol: "amu",
  converter: UnitConverterLinear(coefficient: 1.661e-27))
```

This is your first custom unit. You’ll look at converters in more detail later on, but for now, understand that you’re saying you’ve got a new way of representing mass, and you’ve specified how your new way relates to the base unit for `UnitMass`, which is the kilogram.

Add measurements to describe the elements that go in to the nuclear reaction:

```swift
let u235 = Measurement(value: 235.043924, unit: amus)
let neutron = Measurement(value: 1.008665, unit: amus)
let massBefore = u235 + neutron
```

Now add measurements to describe the products of the fission reaction:

```swift
let kr92 = Measurement(value: 91.926156, unit: amus)
let ba141 = Measurement(value: 140.914411, unit: amus)
let massAfter = kr92 + ba141 + (3 * neutron)
```

`massAfter` is less than `massBefore`. What’s happened? It’s been converted to energy! You can use **E = mc²** to find out how much energy.

This function uses Einstein’s equation to convert mass into energy:

```swift
func emc2(mass: Measurement<UnitMass>) -> Measurement<UnitEnergy> {
  let speedOfLight = Measurement(value: 299792458,
    unit: UnitSpeed.metersPerSecond)
  let energy = mass.converted(to: .kilograms).value *
    pow(speedOfLight.value, 2)
  return Measurement(value: energy, unit: UnitEnergy.joules)
}
```

> **Note:** In the calculation you have to use the `value` of the measurement. That’s because relationships between different dimensions (like mass and speed) aren’t yet defined in Foundation. For example, you can’t divide a `UnitLength` by a `UnitDuration` and get a `UnitSpeed`.

Find out how much energy is released in the fission of a single Uranium-235 atom like this:

```swift
let massDifference = massBefore - massAfter
let energy = emc2(mass: massDifference)
```

That gives you a very small number of joules. You don’t run a nuclear reactor with a single atom of uranium, though; you use a rod or some pellets of the stuff. So how much energy is contained in a given weight of uranium?

The first step is to do a little chemical calculation. You want to find out how many atoms of uranium are in a given mass. That’s done by this function:

```swift
func atoms(atomicMass: Double, substanceMass: Measurement<UnitMass>) -> Double {
  let grams = substanceMass.converted(to: .grams)
  let moles = grams.value / atomicMass
  let avogadro = 6.0221409e+23
  return moles * avogadro
}
```

This formula uses a special number called Avogadro’s number which defines the number of atoms in a _mole_, which is in turn approximately the number of amus that weigh one gram. Don’t worry too much about understanding the formula, but note that you can pass in any `UnitMass` you like and get a value out of the other end.

Use this function to get the number of atoms in 1 lb of uranium, then multiply that by the value you obtained earlier for the energy released by a single atom:

```swift
let numberOfAtoms = atoms(atomicMass: u235.value, substanceMass: Measurement(value: 1, unit: .pounds))
let energyPerPound = energy * numberOfAtoms
```

The number has now gone from a meaninglessly small number to a meaninglessly large one. Let’s do a final calculation to give it some context. The average American home uses 11,700 kWh (kilowatt hours) of electricity per year. `UnitEnergy` has you covered:

```swift
let kwh = energyPerPound.converted(to: .kilowattHours)
kwh.value / 11700
```

You should come up with a number close to 766. A pound of uranium can power 766 American homes for a year!

In the results sidebar in the playground, the numbers are often displayed with lots of decimal places or exponentials. In the next section, you’re going to take control of presenting your measurements with `MeasurementFormatter`.

## Measure for MeasurementFormatter

`MeasurementFormatter` is a `Formatter` subclass just like `DateFormatter` and `NumberFormatter`. It can take a lot of the work out of presenting your measurements to the user, as it will automatically use the preferred units for the user’s locale.

> **Note:** Unlike date and number formatters, measurement formatters are one-way. You can’t use them to take a string like "1 kWh" and turn it into a `Measurement`.

## It’s getting hot in here

Open a new playground to start exploring measurement formatters.

Create a measurement representing a pleasantly warm Northern European summer’s day:

```swift
let temperature = Measurement(value: 24, unit: UnitTemperature.celsius)
```

Now, create a measurement formatter and use it to get a string from the measurement:

```swift
let formatter = MeasurementFormatter()
formatter.string(from: temperature)
```

Because the locale in playgrounds is the US by default, your sensible measurement has been changed into “nonsense units” that only one country in the world understands. Fix that by setting a more sensible locale:

```swift
formatter.locale = Locale(identifier: "en_GB")
formatter.string(from: temperature)
```

Measurement formatter has a property, `UnitOptions`, which acts as a sort of grab bag of random options which didn’t really fit elsewhere. There are only three options in there, one of which specifically relates to temperature.

Add these lines:

```swift
formatter.unitOptions = .temperatureWithoutUnit
formatter.string(from: temperature)
```

This tells the formatter to skip the letter indicating the temperature scale. This option also stops the formatter changing the scale to match the locale, as that would be hopelessly confusing. Check by changing the locale back:

```swift
formatter.locale = Locale(identifier: "en_US")
formatter.string(from: temperature)
```

The second unit option you can specify tells the formatter not to change the units you’ve passed in. Add the following lines to see this in action:

```swift
formatter.unitOptions = .providedUnit
formatter.string(from: temperature)
```

You’ll see that the formatter is using Celsius again, even though it is still in the US locale.

The third option doesn’t relate to temperatures. You’ll look at that in the next section.

## I would walk 500 miles

Remember earlier, when you added miles to yards to nautical miles to kilometers, and the answer was given in meters? The number of meters was quite high, and to present a meaningful value to the user you would have to have a conversion step to a more sensible unit, and you may need to write code to determine what that more sensible unit should be. Measurement formatters can do this for you, for some kinds of units.

Add the following code to the playground:

```swift
let run = Measurement(value: 20000, unit: UnitLength.meters)
formatter.string(from: run)
```

The formatter gives you `20,000 m` as the result; the formatter you’re using has a locale of the US, but is set to use the provided unit. Now add these lines:

```swift
formatter.unitOptions = [.naturalScale, .providedUnit]
formatter.string(from: run)
```

Now you get a more sensible `20 km`. `.naturalScale` works together with `.providedUnit` to stay within the measurement system given by the measurement, but to move up and down through related units:

```swift
let speck = Measurement(value: 0.0002, unit: UnitLength.meters)
formatter.string(from: speck)
```  

This gives you a value in mm.

The `unitStyle` option on the formatter will tell it to present the full names or abbreviations of units where possible:

```swift
formatter.unitStyle = .long
formatter.string(from: run)
```

The default value is `.medium`, which prints the symbol of the unit in use. There is currently no public API to provide extended or shorter names or symbols for your own units.

The final aspect of a measurement formatter you can customize is the way the numbers themselves are presented. What do we know that’s good at formatting numbers? A number formatter!

You can create a number formatter and give it to the measurement formatter:

```swift
let numberFormatter = NumberFormatter()
numberFormatter.numberStyle = .spellOut
formatter.numberFormatter = numberFormatter
formatter.string(from: run)
```

This gives you the result `twenty kilometers`.

Up next, you’re going to learn how to go beyond the units provided to you by Foundation.

## (Custom) Dimension

The base class for units is `Unit`. This is an abstract class, designed for subclassing. Foundation comes with a single subclass, `Dimension`, which is _also_ an abstract class. There are lots of subclasses of `Dimension`, each one of which represents a specific quantifiable _thing_, like length or area or time. The base unit for the dimension is defined at the class level — there is a class function, `baseUnit()`, which returns the instance used as the base unit.

Instances feature a symbol and a converter for translating to and from the base unit. Again, Foundation loads each `Dimension` subclass with class variables giving you pre-made common units.

This is a little complicated to understand. Here’s a diagram to clarify things:

![width=80%](images/UnitHierarchy.png)

To instantiate a `Dimension` or one of its subclasses, you pass in a symbol and a converter. The converter, as its name suggests, is responsible for converting the value of the unit back and forth from the base unit specified at class level.

The converter has to be a subclass of `UnitConverter`, which, in a pattern that should be familiar by now, is an abstract superclass. There is one subclass provided — `UnitConverterLinear` — which allows linear conversion between units.

Most things you measure start at zero; zero miles is zero meters is zero furlongs. This means that a simple coefficient (multiplication factor) is good enough for most conversions.

Some things, like temperature, are a little more complicated. When people were inventing temperature scales, they had no concept of absolute zero, so they placed zero somewhere sensible (when water freezes) or somewhere silly (the temperature of equal parts ice and salt). To cope with these situations you need a constant as well as the coefficient.

`UnitConverterLinear` is created with a coefficient and a constant; the constant has a default value of zero. When you made the `amus` `UnitMass` instance, you used a linear converter. You’re going to look at an example in more detail now.

## Chain of fools

It seems like in Olde England when people would have a thing that needed measuring, they would look around them, pick the first thing they saw and use that as a unit. Hence we have poppyseed, finger, hand, foot, rod, chain, and many more.

As you probably know, a chain is 20.1168 meters. So, you could create a unit to use in measurements like this:

```swift
let chains = UnitLength(symbol: "ch",
  converter: UnitConverterLinear(coefficient: 20.1168))
```

This is similar to the code you used earlier when creating `amus`. However, the chain is such a useful unit of measure, you want it to be available everywhere, just like the meter or the mile. To do this, you create an extension on `UnitLength` and add a new class variable. Add the following code to a new playground:

```swift
extension UnitLength {
  class var chains: UnitLength {
    return UnitLength(symbol: "ch",
      converter: UnitConverterLinear(coefficient: 20.1168))
  }
}
```

You can then use this unit just like any other. A cricket pitch is one chain from wicket to wicket:

```swift
let cricketPitch = Measurement(value: 1, unit: UnitLength.chains)
```

This works just like any of the built-in units. You can do a few conversions:

```swift
cricketPitch.converted(to: .baseUnit())
cricketPitch.converted(to: .furlongs)
(80 * cricketPitch).converted(to: .miles)
```

This gives the values you’d expect; a chain is 20.1168 meters, as you’ve defined, and in a rare occurrence of the number 10 in Imperial measurements, a chain is 0.1 furlongs. There are 8 furlongs in a mile, so 80 chains, give or take a bit of rounding, is a mile.  

So to get a fully-qualified extra unit added to any dimension, all you need to do is provide a class variable, and all that needs to have is a symbol and a converter. Go and sing a few verses of Unchained Melody to celebrate, but don’t get too carried away — the next part is a little more complicated.

## Turning it up to 11

You’ll probably have heard of **decibels** (dB), associated with how loud things are. The decibel is actually a measure of the _ratio_ of two values, and not only that, it’s done on a logarithmic scale.

Decibels are used to measure changes in amplitude or power. Because of the logarithmic scale, they allow you to talk about quite large changes and still use sensible numbers. For example, a doubling of power is approximately 3dB, but increasing power by a factor of 1 million is only 60dB.

Converting between power ratios and decibels is therefore not possible with the linear unit converter, because the relationship between the two is not linear. You’re going to make a new subclass of `UnitConverter` to express this relationship, and a new `Dimension` subclass to hold your units.

> **Note:** Don’t worry too much about following or understanding the math in this example. The idea is to learn about creating a new dimension and a new converter.

First, the converter. Make a new subclass of `UnitConverter` in your playground:

```swift
// 1
class UnitConverterLogarithmic: UnitConverter, NSCopying {
  // 2
  let coefficient: Double
  let logBase: Double
  // 3
  init(coefficient: Double, logBase: Double) {
    self.coefficient = coefficient
    self.logBase = logBase
  }
  // 4
  func copy(with zone: NSZone? = nil) -> AnyObject {
    return self
  }
}
```

Here’s the breakdown:

1. You’re subclassing `UnitConverter`. Subclasses must also implement `NSCopying`, though that isn’t currently mentioned in the documentation.
2. These are the two properties needed to perform logarithmic conversions. A coefficient and a log base.
3. This is the initializer which allows you to set the two properties
4. This is the implementation required for `NSCopying`. Your class is immutable, so you can just return `self`.

There are two methods you must override to make a working converter to convert to and from the base unit. These calculations are the standard methods for dealing with logarithms; it isn’t important for the chapter that you follow the math. Add the following methods to your converter class:

```swift
override func baseUnitValue(fromValue value: Double) -> Double {
  return coefficient * log(value) / log(logBase)
}

override func value(fromBaseUnitValue baseUnitValue: Double) -> Double {
  return exp(baseUnitValue * log(logBase) / coefficient)
}
```

These two methods allow your converter to convert measurements to and from the base unit. That’s your unit converter done. Now for the `Dimension` subclass. The thing you’re measuring is a ratio, so you’re going to call the subclass `UnitRatio`. Add the following code to the playground:

```swift
class UnitRatio: Dimension {

  class var decibels: UnitRatio {
    return UnitRatio(symbol: "dB",
      converter: UnitConverterLinear(coefficient: 1))
    }

  override class func baseUnit() -> UnitRatio {
    return UnitRatio.decibels
  }
}
```

This has created a new `Dimension` subclass. There’s a single instance, `decibels`. This is set up just like the `chains` that you added to `UnitLength`. Decibels is going to be the base unit, so to “convert” it doesn’t need to do any work, since the linear converter with a coefficient of 1 will do the job.

The class method `baseUnit()` has to be implemented for all `Dimension` subclasses. This just returns the `decibels` class variable.

Now you can add the two ratios that can be converted to decibels — amplitude and power. Add the following class variables to `UnitRatio`:

```swift
class var amplitudeRatio: UnitRatio {
  return UnitRatio(symbol: "", converter:
    UnitConverterLogarithmic(coefficient: 20, logBase: 10))
}

class var powerRatio: UnitRatio {
  return UnitRatio(symbol: "", converter:
    UnitConverterLogarithmic(coefficient: 10, logBase: 10))
}
```

Now you’re ready to use your new dimension. To double the volume of something, that’s a power ratio of 2. Add this code to create that measurement, and convert it to decibels:

```swift
let doubleVolume = Measurement(value: 2, unit: UnitRatio.powerRatio)
doubleVolume.converted(to: .decibels)
```

That’s approximately three decibels, which is what you expected from the introduction to this section.

To take your amp “up to 11” from 10 is a power ratio of 1.1:

```swift
let upTo11 = Measurement(value: 1.1, unit: UnitRatio.powerRatio)
upTo11.converted(to: .decibels)
```

That’s only 0.4dB. Doesn’t sound quite as impressive, does it?

You’ve covered a lot of theory here — congratulations! From tiring sports to rocking out, via a spot of nuclear physics. But you’re not done. If you need a holiday after all that, the next section will help you out.

## 24 Hours From Tulsa

Any app that deals with dates probably has to deal with date intervals as well. You might be dealing with events that have start and end times. How do you display that event? How do you do calculations and comparisons between events?

All of this was possible to write yourself, but it was easy to get wrong. `DateInterval` and `DateIntervalFormatter` are here to help.

A `DateInterval` has a start `Date` and a duration, so it represents a specific _period_ of time, in the same way a `Date` represents a specific _point_ in time.

You can create a date interval in two ways: either with a start date and a duration, or with a start date and end date. You can’t make an interval with an end date before the start date.

In a new playground page, add this code:

```swift
let today = Date()
let twentyFourHours: TimeInterval = 60 * 60 * 24
let tomorrow = today + twentyFourHours
let overmorrow = tomorrow + twentyFourHours

let next24Hours = DateInterval(start: today, duration: twentyFourHours)
let nowTillThen = DateInterval(start: today, end: tomorrow)
```

This sets up some useful dates and then creates two date intervals using each method. They both represent the same period of time, and you can test this equality:

```swift
next24Hours == nowTillThen
```

This code evaluates to `true`. You can perform other comparisons between intervals as well:

```swift
let next48Hours = DateInterval(start: today, end: overmorrow)
next48Hours > next24Hours //true
```

If date intervals start at the same time, the longest interval counts as the larger of the two.

```swift
let allTomorrow = DateInterval(start: tomorrow, end: overmorrow)
allTomorrow > next24Hours //true
allTomorrow > next48Hours //true
```

If two date intervals start at different times, the one with the latest start date is larger, and the lengths of the intervals are not compared.

There are more useful methods on `DateInterval`. Add this code to the playground to create an interval covering a normal working week:

```swift
// 1
let calendar = Calendar.current
var components = calendar.dateComponents([.year, .weekOfYear],
  from: Date())
// 2
components.weekday = 2
components.hour = 8
let startOfWeek = calendar.date(from: components)
// 3
components.weekday = 6
components.hour = 17
let endOfWeek = calendar.date(from: components)
// 4
let workingWeek = DateInterval(start: startOfWeek,
  end: endOfWeek)
```

Here’s the breakdown:

1. Get a reference to the current calendar and then get the year and week components of the current date.
2. Set the weekday to `Monday` and the hour to `8` and use this to create 8am on Monday. Note that this is the correct way to work with dates. Adding time intervals will let you down when you happen to fall across a daylight savings change!
3. Set the weekday to `Friday` and the hour to `17` to make 5pm on Friday. Cocktail time!
4. Create a date interval with those two dates.

It turns out you’ve won a surprise holiday! It’s two weeks long, and it starts right now! (“Now” being 1pm on Friday. You have to allow a little poetic license here because you could be following this chapter at any point in the week, but the code has to work the same way!).

Add this code to represent your holiday:

```swift
components.hour = 13
let startOfHoliday = calendar.date(from: components)!
let endOfHoliday = calendar.date(byAdding: .day,
  value: 14, to: startOfHoliday)!
let holiday = DateInterval(start: startOfHoliday,
  end: endOfHoliday)
```

This creates the 1pm on Friday date, adds 14 days to get the end date, and makes a new interval.

You can find out if the holiday start date falls within the working week like this:

```swift
workingWeek.contains(startOfHoliday) //true
```

You can find out if the holiday and the working week intersect each other like this:

```swift
workingWeek.intersects(holiday) //true
```

And, most excitingly, you can see exactly how much of the working week you’re missing out on by going on your holiday:

```swift
let freedom = workingWeek.intersection(with: holiday)
```

This gives you a date interval beginning at 1pm on Friday and ending at 5pm. The method returns an optional; if the two intervals don’t intersect, you get `.none` back.

You may have noticed that these date intervals are tricky to read in the results bar of the playground. You can change that with `DateIntervalFormatter`.

`DateIntervalFormatter` isn’t too exciting; you configure it just like a `DateFormatter`, and it then applies the format to the start and end dates of the interval and puts a hyphen in between them. But it does save you having to do that step yourself.

Add the following code to the playground:

```swift
let formatter = DateIntervalFormatter()
formatter.dateStyle = .none
formatter.string(from: freedom!)
```

You knew the freedom interval only covered part of a day, so it made sense to hide the dates from the formatter. The options available for date interval formatters are the same as those for date formatters, so if you can use date formatters, you’re all set.

## Where to go from here?

The classes covered in this chapter aren’t going to give your users mind-blowing new features, nor do they deal with particularly exciting or shiny things. But what they _do_ give you is rock-solid, useful functionality, and give you more time to spend working on what makes your app unique. That’s what Foundation is there for, after all: for you to build on top of!
