//: ## Date Intervals
import Foundation

let today = Date()
let twentyFourHours: TimeInterval = 60 * 60 * 24
let tomorrow = today + twentyFourHours
let overmorrow = tomorrow + twentyFourHours
//: Date intervals can be created in two ways:
let next24Hours = DateInterval(start: today, duration: twentyFourHours)
let nowTillThen = DateInterval(start:today, end: tomorrow)
//: Equality checking is supported:
next24Hours == nowTillThen
//: Comparisons are also supported. Two intervals starting at the same date will be compared on length:
let next48Hours = DateInterval(start: today, end: overmorrow)
next48Hours > next24Hours
//: Intervals starting at different dates will be compared on start date
let allTomorrow = DateInterval(start: tomorrow, end: overmorrow)
allTomorrow > next24Hours
allTomorrow > next48Hours
//: Make an interval to describe a working week:
let calendar = Calendar.current
var components = calendar.components([.year, .weekOfYear], from: Date())
components.weekday = 2
components.hour = 8
let startOfWeek = calendar.date(from: components)!
components.weekday = 6
components.hour = 17
let endOfWeek = calendar.date(from: components)!
let workingWeek = DateInterval(start:startOfWeek, end: endOfWeek)
//: Now make an overlapping interval to describe a holiday:
components.hour = 13
let startOfHoliday = calendar.date(from: components)!
let endOfHoliday = calendar.date(byAdding: .day, value: 14, to: startOfHoliday)!
let holiday = DateInterval(start: startOfHoliday, end: endOfHoliday)
//: `contains` checks if a date is within an interval:
workingWeek.contains(startOfHoliday)
//: `intersects` checks if two intervals overlap:
workingWeek.intersects(holiday)
//: `intersection(with:)` returns an optional interval representing the overlap:
let freedom = workingWeek.intersection(with: holiday)
//: `DateIntervalFormatter` just wraps a date formatter and applies it to the start and end dates of the interval:
let formatter = DateIntervalFormatter()
formatter.dateStyle = .none
formatter.string(from: freedom!)
//: [Previous](@previous)
