```metadata
number: "I"
title: "Introduction"
```

# Introduction

Each year at WWDC, Apple introduces brand new tools and APIs for iOS developers. This year, iOS 10 and Xcode 8 has brought a lot of new goodies to play with!

First, iOS 10 brought some fun features to Messages – and also opened up the app to third party developers. First, developers can now create and sell sticker packs - simple, but sure to be popular. Second, developers can go deeper and create fully interactive message experiences. For example, you could create a simple drawing guessing game right within Messages - in fact, you'll learn how to do that in this book.

Second, iOS 10 brings a feature long wished for by developers - the ability to integrate with Siri! If your app fits into a limited number of categories, you can create a new Intents Extension to handle voice requests by users in your own apps. Regardless of your app's category, you can also use the new iOS 10 speech recognizer within your own apps.

Third, Xcode 8 represents a significant new release. It ships with Swift 3, which has a number of syntax changes that will affect all developers. In addition. Xcode comes with a number of great new debugging tools to help you diagnose memory and threading issues.

And that's just the start - iOS 10 is chock-full of new content and changes that every developer should know about. Gone are the days when every 3rd-party developer knew everything there is to know about the OS. The sheer size of iOS can make new releases seem daunting. That's why the Tutorial Team has been working really hard to extract the important parts of the new APIs, and to present this information in an easy-to-understand tutorial format. This means you can focus on what you want to be doing — building amazing apps!

$[=s=]

Get ready for your own private tour through the amazing new features of iOS 10. By the time you're done, your iOS knowledge will be completely up-to-date and you'll be able to benefit from the amazing new opportunities in iOS 10.

Sit back, relax and prepare for some high quality tutorials!

## Early Access

By purchasing this book early, you get early access to this book while it is in development.

Since this book is still in early access, not all chapters are ready at this point. This second early access release has the 11/14 chapters ready (compatible with Xcode 8.0):

* Chapter 2, Xcode 8 Debugging Improvements
* Chapter 3, Xcode 8 Source Editor Extensions
* Chapter 4, Beginning Message Apps
* Chapter 5, Intermediate Message Apps
* Chapter 6, SiriKit
* Chapter 7, Speech Recognition
* Chapter 8, User Notifications
* Chapter 9, Property Animators
* Chapter 10, Measurements and Units
* Chapter 11, What's New with Core Data
* Chapter 13, What's New with Search

You may wish to wait until all chapters are ready before reading the book, to get an optimal reading experience, or check out the iOS 10 screencasts which we are releasing, which this book is based on.

But if you want a head start or a sneak peek of what's coming, that's what this early access release is for - we hope you enjoy!

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

## How to use this book

This book can be read from cover to cover, but we don't recommend using it this way unless you have a lot of time and are the type of person who just "needs to know everything". (It's okay; a lot of our tutorial team is like that, too!)

Instead, we suggest a pragmatic approach — pick and choose the chapters that interest you the most, or the chapters you need immediately for your current projects. Most chapters are self-contained, so you can go through the book in a non-sequential order.

Looking for some recommendations of important chapters to start with? Here's our suggested Core Reading List: 

- Chapter 1, "What's New in Swift 3"
- Chapter 2, "Xcode 8 Debugging Improvements"
- Chapter 4, "Beginning Message Apps"
- Chapter 5, "Intermediate Message Apps"
- Chapter 6, "SiriKit"
- Chapter 8, "User Notifications"

That covers the "Big 6" topics of iOS 10; from there you can dig into other topics of particular interest to you. 

## Book source code and forums

This book comes with the Swift source code for each chapter – it's shipped with the PDF. Some of the chapters have starter projects or other required resources, so you'll definitely want them close at hand as you go through the book.

We've also set up an official forum for the book at [raywenderlich.com/forums](http://www.raywenderlich.com/forums). This is a great place to ask questions about the book, discuss making apps with iOS 10 in general, share challenge solutions, or to submit any errors you may find.

## Book Updates

Great news: since you purchased the PDF version of this book, you'll receive free updates of the content in this book!

The best way to receive update notifications is to sign up for our weekly newsletter. This includes a list of the tutorials published on raywenderlich.com in the past week, important news items such as book updates or new books, and a few of our favorite developer links. You can sign up here:

* [www.raywenderlich.com/newsletter](http://www.raywenderlich.com/newsletter)

## License

By purchasing _iOS 10 by Tutorials_, you have the following license:

- You are allowed to use and/or modify the source code in _iOS 10 by Tutorials_ in as many apps as you want, with no attribution required.
- You are allowed to use and/or modify all art, images, or designs that are included in _iOS 10 by Tutorials_ in as many apps as you want, but must include this attribution line somewhere inside your app: "Artwork/images/designs: from the _iOS 10 by Tutorials_ book, available at [www.raywenderlich.com](http://www.raywenderlich.com)".
- The source code included in _iOS 10 by Tutorials_ is for your own personal use only. You are NOT allowed to distribute or sell the source code in _iOS 10 by Tutorials_ without prior authorization.
- This book is for your own personal use only. You are NOT allowed to sell this book without prior authorization, or distribute it to friends, co-workers, or students; they must to purchase their own copy instead.

All materials provided with this book are provided on an "as is" basis, without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose and non-infringement. In no event shall the authors or copyright holders be liable for any claim, damages or other liability, whether in an action of contract, tort or otherwise, arising from, out of or in connection with the software or the use or other dealings in the software.

All trademarks and registered trademarks appearing in this guide are the property of their respective owners.

## Acknowledgments

We would like to thank many people for their assistance in making this possible:

- __Our families:__ For bearing with us in this crazy time as we worked all hours of the night to get this book ready for publication!
- __Everyone at Apple:__ For developing an amazing operating system and set of APIs, for constantly inspiring us to improve our apps and skills, and for making it possible for many developers to have their dream jobs!
- __And most importantly, the readers of raywenderlich.com — especially you!__ Thank you so much for reading our site and purchasing this book. Your continued readership and support is what makes all of this possible!


