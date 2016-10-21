```metadata
number: "I"
title: "Introduction"
```

# Introduction

Each year at WWDC, Apple introduces brand new tools and APIs for iOS developers. This year, iOS 10 and Xcode 8 has brought a lot of new goodies to play with!

First, iOS 10 brought some fun features to Messages — and also opened up the app to third party developers. First, developers can now create and sell sticker packs — simple, but sure to be popular. Second, developers can go deeper and create fully interactive message experiences. For example, you could create a simple drawing guessing game right within Messages — in fact, you'll learn how to do that in this book.

Second, iOS 10 brings a feature long wished for by developers — the ability to integrate with Siri! If your app fits into a limited number of categories, you can create a new Intents Extension to handle voice requests by users in your own apps. Regardless of your app's category, you can also use the new iOS 10 speech recognizer within your own apps.

Third, Xcode 8 represents a significant new release. It ships with Swift 3, which has a number of syntax changes that will affect all developers. In addition. Xcode comes with a number of great new debugging tools to help you diagnose memory and threading issues.

And that's just the start. iOS 10 is chock-full of new content and changes that every developer should know about. Gone are the days when every 3rd-party developer knew everything there is to know about the OS. The sheer size of iOS can make new releases seem daunting. That's why the Tutorial Team has been working really hard to extract the important parts of the new APIs, and to present this information in an easy-to-understand tutorial format. This means you can focus on what you want to be doing — building amazing apps!

$[=s=]

Get ready for your own private tour through the amazing new features of iOS 10. By the time you're done, your iOS knowledge will be completely up-to-date and you'll be able to benefit from the amazing new opportunities in iOS 10.

Sit back, relax and prepare for some high quality tutorials!

## What you need

To follow along with the tutorials in this book, you'll need the following:
- __A Mac running OS X Yosemite or later.__ You'll need this to be able to install the latest version of Xcode.
- __Xcode 8.0 or later.__ Xcode is the main development tool for iOS. You'll need Xcode 8.0 or later for all tasks in this book. You can download the latest version of Xcode 8 beta on Apple's developer site here: [apple.co/2asi58y](https://developer.apple.com/develop/)
- __One or more devices (iPhone, iPad, or iPod Touch) running iOS 10 or later.__ Most of the chapters in the book let you run your code on the iOS 10 Simulator that comes with Xcode. However, a few chapters later in the book require one or more physical iOS devices for testing.
  
Once you have these items in place, you'll be able to follow along with every chapter in this book. 

## Who this book is for

This book is for intermediate or advanced iOS developers who already know the basics of iOS and Swift development but want to learn about the new APIs, frameworks, and changes in Xcode 8 and iOS 10. 

- __If you are a complete beginner to iOS development__, we recommend you read through _The iOS Apprentice, Fifth Edition_ first. Otherwise this book may be a bit too advanced for you.
- __If you are a beginner to Swift__, we recommend you read through either _The iOS Apprentice, Fifth Edition_ (if you are a complete beginner to programming), or _The Swift Apprentice, Second Edition_ (if you already have some programming experience) first.

If you need one of these prerequisite books, you can find them on our store here:

* [www.raywenderlich.com/store](http://www.raywenderlich.com/store)

As with raywenderlich.com, all the tutorials in this book are in Swift.

## What's in store

Here’s a quick summary of what you’ll find in each chapter:

**1. Chapter 1, What's New in Swift 3**: Swift 3 represents the biggest change to the language since it was first introduced. Read this chapter for a quick overview of what's new!

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

**2. Chapter 2, Xcode 8 Debugging Improvements**: Learn about the powerful new debugging tools in Xcode 8, including the new Thread Sanitizer and Memory Graph Debugger.

![width=50%](/images/malloc-example.png)

**3. Chapter 3, Xcode 8 Source Editor Extensions**: Learn how to integrate your own text tools into the Xcode UI by creating a fun ASCII art extension.

![width=70%](/images/successful-figlet-test.png)

**4. Chapter 4, Beginning Message Apps**: Learn how to create your own sticker pack for Messages — with a custom user interface.

![iphone bordered](/images/Chocoholic4.png)

**5. Chapter 5, Intermediate Message Apps**: Learn how to create your own sticker pack for Messages — with a custom user interface.

![iphone bordered](/images/MessageReady-281x500.png)

$[=s=]

**6. Chapter 6, SiriKit**: Learn how to integrate Siri into your app and process voice commands as you build a Uber clone for hot air balloons.

![iphone](/images/CustomUI1-564x500.png)

**7. Chapter 7, Speech Recognition**: Learn how to transcribe live or pre-recorded audio from over 50 languages and use that data in your app.

![iphone-landscape bordered](/images/intro-teaser-image-650x366.png)

$[=s=]

**8. Chapter 8, User Notifications**: Learn how to use the new iOS 10 User Notifications framework, and create Notification Content extensions and Notification Service app extensions.

![iphone bordered](/images/content-extension-presented.png)

**9. Chapter 9, UIView Property Animator**: Learn about a new way of animating in iOS 10, which allows you to easily pause, reverse, and scrub through animations part-way through.

![ipad-landscape](/images/Animalation3.png)

**10. Chapter 10, Measurements and Units**: Learn about some new Foundation classes that help you work with measurements and units in an easy and type-safe way.

```swift
let cycleRide = Measurement(value: 25, unit: UnitLength.kilometers)
let swim = Measurement(value: 3, unit: UnitLength.nauticalMiles)
let marathon = Measurement(value: 26, unit: UnitLength.miles)
    + Measurement(value: 385, unit: UnitLength.yards)
```

**11. Chapter 11, What's New with Core Data**: Learn how the new convenience methods, classes, code generation and other new features in Core Data will make your life easier.

![width=50%](/images/OldStackHierarchy.png)

**12. Chapter 12, What's New with Photography**: Learn how to capture and edit live photos, and make use of other photography advancements.

![iphone bordered height=35%](/images/LivePhotoCapture.png)

$[=s=]

**13. Chapter 13, What’s New with Search**: Learn how to tie your app into the Core Search Spotlight API and perform deep searches using your app, and how to surface your app to respond to location-based searches as well.

![width=80%](/images/location-feature-preview-650x316.png)

**14. Chapter 14, Other iOS 10 Topics**: Make your apps more responsive with prefetching, make custom interactions with 3D touch, and add haptic feedback to your apps.

![width=80%](/images/preview-interaction-example.png)

## How to use this book

This book can be read from cover to cover, but we don't recommend using it this way unless you have a lot of time and are the type of person who just “needs to know everything”. (It's okay; a lot of our tutorial team is like that, too!)

Instead, we suggest a pragmatic approach — pick and choose the chapters that interest you the most, or the chapters you need immediately for your current projects. Most chapters are self-contained, so you can go through the book in a non-sequential order.

Looking for some recommendations of important chapters to start with? Here's our suggested Core Reading List: 

- Chapter 1, “What's New in Swift 3”
- Chapter 2, “Xcode 8 Debugging Improvements”
- Chapter 4, “Beginning Message Apps”
- Chapter 5, “Intermediate Message Apps”
- Chapter 6, “SiriKit”
- Chapter 8, “User Notifications”

That covers the “Big 6” topics of iOS 10; from there you can dig into other topics of particular interest to you. 

## Book source code and forums

This book comes with the Swift source code for each chapter — it's shipped with the PDF. Some of the chapters have starter projects or other required resources, so you'll definitely want them close at hand as you go through the book.

We've also set up an official forum for the book at [raywenderlich.com/forums](http://www.raywenderlich.com/forums). This is a great place to ask questions about the book, discuss making apps with iOS 10 in general, share challenge solutions, or to submit any errors you may find.

## Book updates

Great news: since you purchased the PDF version of this book, you'll receive free updates of the content in this book!

The best way to receive update notifications is to sign up for our weekly newsletter. This includes a list of the tutorials published on raywenderlich.com in the past week, important news items such as book updates or new books, and a few of our favorite developer links. You can sign up here:

* [www.raywenderlich.com/newsletter](http://www.raywenderlich.com/newsletter)

$[=s=]

## License

By purchasing _iOS 10 by Tutorials_, you have the following license:

- You are allowed to use and/or modify the source code in _iOS 10 by Tutorials_ in as many apps as you want, with no attribution required.
- You are allowed to use and/or modify all art, images, or designs that are included in _iOS 10 by Tutorials_ in as many apps as you want, but must include this attribution line somewhere inside your app: “Artwork/images/designs: from the _iOS 10 by Tutorials_ book, available at [www.raywenderlich.com](http://www.raywenderlich.com)”.
- The source code included in _iOS 10 by Tutorials_ is for your own personal use only. You are NOT allowed to distribute or sell the source code in _iOS 10 by Tutorials_ without prior authorization.
- This book is for your own personal use only. You are NOT allowed to sell this book without prior authorization, or distribute it to friends, co-workers, or students; they must to purchase their own copy instead.

All materials provided with this book are provided on an “as is” basis, without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose and non-infringement. In no event shall the authors or copyright holders be liable for any claim, damages or other liability, whether in an action of contract, tort or otherwise, arising from, out of or in connection with the software or the use or other dealings in the software.

All trademarks and registered trademarks appearing in this guide are the property of their respective owners.

## Acknowledgments

We would like to thank many people for their assistance in making this possible:

- __Our families:__ For bearing with us in this crazy time as we worked all hours of the night to get this book ready for publication!
- __Everyone at Apple:__ For developing an amazing operating system and set of APIs, for constantly inspiring us to improve our apps and skills, and for making it possible for many developers to have their dream jobs!
- __And most importantly, the readers of raywenderlich.com — especially you!__ Thank you so much for reading our site and purchasing this book. Your continued readership and support is what makes all of this possible!

$[=s=]

## About the cover

The clownfish, also known as the anemonefish, lives inside the sea anemone in a symbiotic arrangement. The tentacles of the anemone protect the clownfish from other predators, while the clownfish eats the parasites that would otherwise attack the anemone. It's a lot like being an iOS developer: Apple creates great environments for our apps, and iOS developers create amazing apps (and file annoying Radar bug reports) for those environments. There's nothing fishy about that! :]


