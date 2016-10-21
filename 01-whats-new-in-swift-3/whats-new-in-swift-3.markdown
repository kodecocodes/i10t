```metadata
author: "By Rich Turton"
number: "1"
title: "Chapter 1: What’s New in Swift 3"
```
# Chapter 1: What’s New in Swift 3

Swift 3 brings a tremendous set of changes to the language. In fact, the changes are so big, that I hope this is the biggest set of changes we’ll ever see; as developers, we can’t go through this kind of pain again! :]

But on the bright side, the changes do leave you with _much_ nicer code. It finally feels like you’re writing UIKit apps in Swift, rather than forcing a Swift peg into an Objective-C (or even just C) shaped hole. 

If you take a reasonably-sized project written in Swift 2, and let Xcode migrate it to Swift 3, you’re in for a shock. It’s a big bang, and almost everything has changed.

The noisiest part of the upgrade is what Apple refers to as the Grand Renaming. This is a huge review of _all_ of the first-party frameworks, and redefines types and method signatures to match a set of solid naming guidelines. As third-party developers, we’re also encouraged to follow these naming guidelines in our own code.

On top of this, lots of Foundation `NS` types have been swallowed up by more “Swifty” value types, making them clearer to work with and more accessible to non-Apple platforms. 

Some of the low-level C APIs have also been thoroughly worked over, making working with them as simple and expressive as working with native Swift types. 

Finally, there have been some language-level changes to Swift itself, which will probably affect the code you’ve written up to now. 

If you’re new to Swift, congratulations and welcome — it’s a great language. If you’ve got existing Swift code you want to keep working on, get yourself ready for a few days of grunt work. Let’s get started. 

$[=s=]

## The Grand Renaming

The Grand Renaming affects the methods provided by Foundation, UIKit and the other Apple frameworks. Remember that most of these frameworks are probably still written in Objective-C, and up until this point the Swift methods have looked very similar. 

Here’s an example from UIKit, to get a specific cell from a table view. I sneaked in to the code graveyard on a foggy night and exhumed this from the Objective-C family plot:

```objc
UITableViewCell *cell = 
  [tableView cellForRowAtIndexPath: indexPath];
```

Take a close look at this line of code, and look to see if you can find any words that are repeated.

I count two “table views”, three “cells” and two “indexPaths”. Here’s what this same line looks like in Swift 2:

```swift
let cell = tableView.cellForRowAtIndexPath(indexPath)
```

Type inference lets us drop a “table view” and a “cell”, but we still have two “index paths” — because who _doesn’t_ call a temporary local variable holding an index path `indexPath`?

And finally in Swift 3:

```swift
let cell = tableView.cellForRowAt(indexPath)
```

Now, the only repeated word is “cell”, and that’s acceptable, because one of them is a value name, and the other is part of the function. 

This evolution of this method name follows the three key principles guiding the Grand Renaming:

1. **Clarity at the call site**: Method calls should read as much like English sentences as possible.
2. **Assume common patterns and naming conventions**: As in the assumption that the `indexPath` variable would be so named.
3. **Avoid repeated words**: Allowing the “index path” to be removed from the parameter name.

You’ll find that many UIKit and Foundation methods have similarly shrunk. In particular, methods that would name the type of the first argument have had that part of the name removed:

```swift
// Swift 2 definition
prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
// Swift 2 calling code
viewController.prepareForSegue(segue, sender: something)

// Swift 3 definition
prepare(for segue: UIStoryboardSegue, sender: Any?)
// Swift 3 calling code
viewController.prepare(for: segue, sender: something)
```

This highlights another important difference between Swift 2 and Swift 3. The first argument name now appears by default in the signature of a function or method, whereas in Swift 2 (and Objective-C) it was ignored by default. 

```swift
// Function definition:
func engageFluxCapacitor(fluxCapacitor: FluxCapacitor)

// Called in Swift 2:
timeMachine.engageFluxCapacitor(fluxCapacitor)

// Called in Swift 3:
timeMachine.engageFluxCapacitor(fluxCapacitor: fluxCapacitor)
```

When you migrate a project from Swift 2 to Swift 3, Xcode will take care of all of the framework methods for you, but it might make a bit of a mess of your own code. For example, the Swift 3 updater will change the function signature above to this: 

```swift
func engageFluxCapacitor(_ fluxCapacitor: FluxCapacitor)
``` 

The underscore indicates that you don’t wish to use an argument label for the first argument. This is the simplest code change that will allow your project to run using Swift 3. However, the method doesn’t follow the new guidelines. The type of the first argument doesn’t need to form part of the method name, because you can assume that the value you pass in will have a name that makes this obvious. The correct Swift 3 signature of this method would be:

```swift
func engage(_ fluxCapacitor: FluxCapacitor)

// Called like this:
timeMachine.engage(fluxCapacitor)
```

When migrating your existing projects, you’ll have to decide if it’s worth the effort to Grandly Rename your own APIs. The bizarre and continuing lack of refactoring support for Swift in Xcode probably means that for most projects, you probably won’t bother. But for new code, you really should. 

In addition to the three principles above, there are some more specific guidelines to understand, regarding overloading and grammatical rules.

$[=s=]

### Overloading

If you remove the type name from the method name and don’t use a label for the first argument, then you may end up in a situation where you have multiple methods with the same name, that differ only in the type of argument. You should only do this if the methods are doing semantically the same thing.

For example, if you’re adding a single item or multiple items to a list, you could have two `add(_:)` methods, one which takes an array, and one which takes an individual item. That’s fine because they both do the same thing, just with different types.

However, in cases where the methods perform different actions based on the type, you should use the argument label or rename the methods so that it is clear from the call site what is happening. 

For example, consider a `VideoLoader` class. This class could have `VideoRequest` objects which deal with getting video data from the internet, and `VideoOutputHandler` objects which deal with playing the video. 

It isn’t right to have two `add(_:)` methods, one for adding requests, and one for adding output handlers, because those methods are doing completely different things. You should have an `addLoader(_:)` and `addOutput(_:)` method in this case.

### Grammatical rules

The examples in this section will all be methods on a made-up struct called `WordList`, which as you may have guessed, holds a list of words. 

The first rule is that you shouldn’t name the first argument, unless it doesn’t make sense at the call site without it. For example, to get a word at a specific index in the list:

```swift
// Doesn't read like a sentence
let word = wordList.word(1)

// Reads like a sentence
let word = wordList.word(at: 1)

// Function definition:
func word(at index: Int) -> String {
  ...
}
```

If a method has side effects, it should be named with a verb. Side effects are work that is done by a method that affects something other than the return value of that method. So if you had a method that sorted the word list, you’d name it:

```swift
// "Sort" is a verb, the sorting is in-place,
// so it is a side effect.
mutating func sortAlphabetically() {
  ...
}
```   

Value types often have a non-mutating version of any of their mutating methods, which return a new instance of the type with the changes applied. In this case, you should use the **ed/ing** rule to name the method: 

```swift
// sortED
func sortedAlphabetically() -> WordList {
  ...
}
``` 

When “ed” doesn’t make sense, you can use “ing”. Here’s another mutating / non-mutating pair: 

```swift
// Remove is a verb
mutating func removeWordsContaining(_ substring: String) {
  ...
}

// RemovING
func removingWordsContaining(_ substring: String) -> WordList {
  ...
}
```

The final grammatical rule relates to `Bool` properties. These should be prefixed with `is`:

```swift
var isSortedAlphabetically: Bool
```

## Foundation value types

Many Foundation types have now adapted value semantics rather than reference semantics in Swift 3. What does that mean? 

Value types are types that can be identified by their _value_. As the simplest example, an `Int` of `1` can be considered identical to any other `Int` of `1`. When you assign a value type to another variable, the properties are copied: 

```swift
var oneNumber = 1
var anotherNumber = oneNumber
anotherNumber += 1
// oneNumber will still be 1
```

Swift structs are all value types. 

Reference types are identified by _what they are_. You might have two friends named Mic, but they are different people. When you assign a reference type to another variable, they share the reference: 

```swift
class Person {
  var name: String
}

let person1 = Person(name: "Ray")
let person2 = person1 
person2.name = "Mic"
// person1.name is also Mic
```

Swift classes are all reference types.

Value and reference types both have their advantages and disadvantages. This isn’t the place to get into that argument, but the only value types available in Objective-C were structs and primitives, which had no functionality beyond holding information. 

This limitation meant that anything with any functionality became a class, and was therefore a reference type. The main problem with reference types is that you have no idea who else is also holding a reference, and what they might do with it. 

Immutability or mutability in Foundation types was implemented by having two separate classes, like `NSString` and `NSMutableString`. Anything that holds a mutable reference type property runs the risk of the meaning of that property being changed by something else that shares the reference. This is the source of a lot of hard-to-detect bugs, and it’s why experienced Objective-C programmers do things like declare `NSString` properties as `copy`. 

In Swift 3, lots of Foundation classes are now wrapped in Swift value types. You can declare immutability or mutability by using `var` or `let` declarations. This was already the case with the `String` type, but now it has gone much further. In most cases, this is indicated by a disappearing `NS` prefix: `NSDate` is now `Date`, and so on.

What’s happening under the hood is quite interesting. You might be panicking about copies of objects being made all over the place and eating up all of your memory, but this doesn’t happen. These value type wrappers use a mechanism called _copy on write_. 

Copy on write means that the underlying reference type is shared between everything that cares about it, _until something tries to change it_. At that point, a new copy is made, just for the thing that made the changes, with the new values applied. This optimization lets you get the benefits of value and reference types at the same time :]

> **Note**: For more details on value vs. reference types in Swift, check out our free tutorial on the subject: [bit.ly/2eeZuNG](http://bit.ly/2eeZuNG)

$[=s=]

## Working with C APIs

If you’ve spent much time developing iOS apps, there are two C APIs you’ve probably encountered: Grand Central Dispatch (GCD) and Core Graphics. Like all C APIs, they are notable by their use of free functions (meaning, top-level functions rather than methods defined on instances or classes).  

Free functions are no fun, because they are essentially all in a massive bucket. Autocomplete can do nothing to help you. To counter these problems, free functions all end up with long, wordy names that include identifying text (everything relating to a core graphics context begins with `CGContext`, for example), and you need to pass in the basic values you’re working with (like the graphics context) to every single operation. This results in code that is tedious to read and tedious to write.

Here’s some great news: As of Swift 3, you will no longer realize you’re dealing with C! 

### Grand Central Dispatch

Here’s how you create a dispatch queue in Swift 3:

```swift
let queue = DispatchQueue(
  label: "com.razeware.my-queue", 
  qos: .userInitiated)
```

And here’s how you add some work to it:

```swift
queue.async {
  print("Hello from my serial queue!")
}
```

All of the `dispatch_whatever_whatever()` functions have now been beautifully gift-wrapped in the Dispatch framework, giving you a much nicer interface for dealing with GCD. It looks like native Swift code now, making it easier to read, write, and blend in with the rest of your codebase. 

A common GCD use case is to send some work off to the main queue, for example when you’ve completed work on a background thread and want to update the UI. That’s done like this: 

```swift
DispatchQueue.main.async {
  print("Hello from the main queue!")
}
```

Dispatching work after a delay is now much easier as well. You used to need a magic incantation involving nanoseconds, now you can do this:

```swift
DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
  print("It's five seconds later!")
}
```

### Core Graphics

Core Graphics is a very useful framework, particularly in these days of multiple scale-factor, multiple screen size support. It can often be easier to draw some of your assets in code than supply and update 15 PNG files of the same image. But the Core Graphics code is written in C, and it used to look pretty clunky. Now, it’s kind of nice. 

Consider transforms. When creating beautiful animations or transitions, you often want to stack up several transitions, such as a scale, a translation and a rotation. In Swift 3, you can do this:

```swift
let transform = CGAffineTransform.identity
  .scaledBy(x: 0.5, y: 0.5)
  .translatedBy(x: 100, y: 100)
  .rotated(by: .pi / 4)
```

If you’re not doing the screaming face emoji in real life right now, then you’ve probably never written `CGAffineTransform` code before. It gets better! When dealing with a `CGContext`, there are a variety of things you can set on the context to affect the next lot of drawing you could do — the stroke color, shadow offset and so forth. That code now looks like this: 

```swift
let rectangle = CGRect(x: 5, y: 5, width: 200, height: 200)

context.setFillColor(UIColor.yellow.cgColor)
context.setStrokeColor(UIColor.orange.cgColor)
context.setLineWidth(10)

context.addEllipse(in: rectangle)
context.drawPath(using: .fillStroke)
```

Just like with GCD, all of the nasty old free functions have been transformed into sensible methods. 

## Language feature changes

In addition to the naming style and rule changes you’ve learned about, there are also several changes to features in the language.

### Increment operators

Increment operators are gone. No more `counter++` for you! Why is this? The main reason seems to be that they are ambiguous. What’s the value of `currentCount` or `nextCount` in this sample?

```swift
var counter = 1
let currentCount = counter++
let nextCount = ++counter
counter++ // Expression result is unused! 
```

If, like me, you can never remember which order these things happen in, now you don’t have to. The most popular use of these operators was in “C-style for loops”, and you’ll never guess what’s happened to them.

### C-Style for loops

Also gone! A C-Style for-loop was written like this:

```swift
for var i = 0; i < 10; i++ {
  print(i)
}
```

Good riddance. Look at all those semicolons, all that cruft. Replace with:

```swift
for i in 0..<10 {
  print(i)
```

Or, if you’re iterating through a collection, a `for...in` loop, which you really should have been using anyway.

### Currying syntax

If you’re one of the few people who actually understood the Swift currying syntax (or one of the even fewer people who actually used it) you might be upset by this one, and you’ve probably already followed the proposal and comments and know the new way of doing things. If you’ve never used it, congratulations, you don’t have to unlearn anything! 

That’s all the main things that have gone from the language. Now, onto the new stuff, which is much more fun. 

### Key paths

This is a super addition to the language. Key paths and key-value coding are somewhat frowned upon because they introduce what’s called “stringly typed” code, where you use literal strings to access properties. However they can be extremely useful, for example when setting up key value observers or creating predicates.

Swift 3 offers a safe, compile-time verified way to get a key path. It works like this: 

```swift
class TimeMachine: NSObject {
  var currentYear = 2016
}

let timeMachine = TimeMachine()
timeMachine.value(forKey: #keyPath(TimeMachine.currentYear))
// gives 2016
```

$[=s=]

This works with autocomplete as well. The `#keyPath` expression is converted into a `String`. Because of the way key-value coding works, this technique can only be used on classes, and furthermore only on those properties that are implemented using the Objective-C runtime. In practical terms, this means that any classes inheriting from `NSObject` are fine, and any “pure” swift classes must have the property marked as `dynamic`: 

```swift
class TimeMachine {
  dynamic var currentYear = 2016
  var destinationYear = 1985
}

#keyPath(TimeMachine.currentYear) // "currentYear"
#keyPath(TimeMachine.destinationYear) // Error
```

Key-value coding doesn’t work on non-`NSObject` classes anyway, so key paths aren’t as useful for these types of objects.

### Access control

Swift 2 had `public`, `internal` (the default, so you didn’t see that one often) and `private` modifiers that controlled the visibility of your code across files and modules. 

In Swift 3 the meaning of `public` and `private` have changed, and there are two new access control keywords, `open` and `fileprivate`. Here’s a quick summary:

- `open`: The code is visible from anywhere, and `open` classes can be subclassed from anywhere.
- `public`: The code is visible from anywhere, but classes can only be subclassed within the same module.
- `internal`: The code is visible from anywhere within the module
- `fileprivate`: The code is visible from anywhere within the file.
- `private`: The code is only visible from within the enclosing declaration.

The single largest impact this will have on your code is that anything you’d marked as `private`, but accessed within an extension in the same file, will now not compile until you change the declaration: 

```swift
class PotatoListViewController: UIViewController {
  private var potatoes: [Potato]
  ...
}

extension PotatoListViewController: PotatoSelectionDelegate {
  func didDelete(_ potato: Potato) {
    potatoes.remove(potato)
  }
}
```

In the example above, `potatoes` is not accessible in the extension. If the variable is declared as `fileprivate` instead, then it will be accessible. This redefinition of an existing, commonly used keyword, coupled with the fact that extensions are encouraged as a way of dividing up functionality within a file, means that when you migrate to Swift 3 you will spend a lot of time correcting access control issues like this. 

The difference between `open` and `public` is mainly of interest to framework developers. The use of `open` indicates that you have explicitly considered and encouraged inheritance of the classes included in your framework. So far, all UIKit and Foundation classes are `open`.

The remainder of this section talks about changes to existing language features. 

### Enums

An enum case is an instance, and instances should begin with lower case letters. That’s now a standard, and all of the framework enums have been amended to match: 

```swift
// Swift 2
label.textAlignment = .Center
// Swift 3
label.textAlignment = .center
```

There’s also an inconsistency with enums that has been removed. There used to be a little quirk whereby you didn’t need to use a leading period when dealing with a case _inside_ the definition of an enum: 

```swift
// Swift 2
enum Size {
  case Big
  case Little
  case Tiny
  
  var isSmall: Bool {
    switch self {
      case Big: return false
      case .Little: return true
      case .Tiny: return false
    }
  }
}

let size = Size.Big
switch size {
  case Big: // Illegal
  case .Little: ...
  case .Tiny: ...
}
```

Note that `Big` doesn’t have a leading period. Inside an enum, this was optional, outside it was not. Now, you have to use the leading period. Also, as per the previous change, it would be `.big`.

### Closures

Closures are objects; you can store them as properties. Closure are objects; you can pass them as function parameters. Closures also retain anything that is captured within them. 

These three statements mean that there can be interesting memory management issues when dealing with closures that are passed as function parameters. 

If you pass a closure to a function, how do you know what that function is going to do with it? Will the closure be executed before the function call returns, or will it be stored somewhere to be executed later? 

In Swift 2, the default assumption was that closures passed as parameters were _escaping_, that is to say, they could be stored away and executed later after the function had returned. The majority of UIKit methods that take closures (like the animations parameter of a UIView animation method) are escaping, which is why you have to use `self` inside them all the time. If a function guaranteed that a closure was discarded after the function had returned, you could mark it as `@noescape` and the compiler could make sensible decisions about it. 

In Swift 3, that assumption has reversed. Now, all closures passed in to functions are assumed to be non-escaping unless explicitly marked otherwise. This has meant a lot of work on the UIKit and Foundation end, and if you’ve written code which takes a completion block and stores it away somewhere, you’ll need to add the `@escaping` notation to it:

```swift
func doSomethingWith(_ this: Thing, then: @escaping (Thing) -> ()) {
  self.completion = then
  ... do stuff in the background ...
}
```

The migrator should either fix this for you, or offer it as a change. It tries to detect if additional references to the closure are made within the function body. 

This also means that you don’t have to put `self` in closure bodies by default anymore:

```swift
func doSomething(_ then: () -> ()) {
    // do something
    then()
}
    
// Swift 2
doSomething {
	self.finished = true
}

// Swift 3
doSomething {
	finished = true
}
```

## Where to go from here? 

I hope this chapter gave you a quick introduction to what’s new in Swift 3 and helps make your code migration a little bit easier.

The most important aspect of all of this is the Grand Renaming. There is a full and detailed explanation of the naming guidelines at [https://swift.org/documentation/api-design-guidelines/](https://swift.org/documentation/api-design-guidelines/), which is really worth reading, so that you ensure that your future code follows these guidelines. 

Swift is an open source language! To review proposed and implemented changes to Swift, or to submit your own, visit [https://github.com/apple/swift-evolution](https://github.com/apple/swift-evolution). All of the changes discussed in this chapter are discussed in far greater detail on that repo. 