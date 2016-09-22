```metadata
author: "By Rich Turton"
number: "11"
title: "Chapter 11: What's New with Core Data"
```
# Chapter 11: What's New with Core Data

You know what nobody likes? Typing boilerplate code. But there's another type of typing nobody likes as well — explicit typing, especially when Swift's implicit typing will do.

The new Core Data updates in iOS 10 involve less of both kinds of typing:

  * **Less typing of boilerplate code** because there are new convenience methods, classes and code generations. 
  * **Less explicit typing** because Generic Fairy Dust™ has been sprinkled over fetch requests and fetched results controllers. The compiler now knows what class of managed object you're dealing with. 

There are also some useful new features at the managed object context and persistent store coordinator level, which may change the way you're structuring your code. 

If the previous two paragraphs made no sense to you, then check out our book _Core Data By Tutorials_  to learn the basics of Core Data first.

If you're already familiar with Core Data, then read on to find out what's new! 

## Getting started

In this chapter, you're going to take an app and convert it to use Core Data, using some of the handy new Core Data features in iOS 10.

The app is TaterRater, which is incredibly handy for creating ratings notes about your favorite varieties of potato. Later, you'll make a greater TaterRater using Core Data. I make no apologies for the fact that that sentence does not sound as good if you don't speak with a British accent. :] 

Open the starter project, build and run, then take a look around. 

![iPhone bordered](images/InitialScreenshot.png)

The app has a split view controller holding a master list and a detail view. The detail view lets you set your own score for a particular variety of potato, view the average score given by the millions of other potato fans worldwide and view your personal potato notes. 

You can edit your notes by bringing up a modal view controller which holds a text view. 

The **Model** group has a text file that holds a list of potato varieties and a single model class in **Potato.swift** which represents the app's model. 

You're going to start by replacing that model class with a Core Data model. 

## An eye to new data models

With the **Model** group selected, choose **File\New\File…**. Select **Data Model** from the **Core Data** group:

![width=60%](images/AddingCoreDataFile.png)

Name the file **TaterRater.xcdatamodeld**. When the model editor opens, add a new entity called **Potato** and the following attributes:

- `crowdRating` of type **Float**
- `notes` of type **String**
- `userRating` of type **Integer 16**
- `variety` of type **String**

The model editor should look like this:

![bordered width=100%](images/PotatoEntityAttributes.png)

The `Potato` entity will replace the `Potato` class that currently exists in the app. You've created and typed the properties to match the existing class, so the existing code will still compile. Delete the **Potato.swift** file from the **Model** group. 

Still in the model editor  open the Data Model Inspector with the **Potato** entity selected. Fill in the **Name** field to say **Potato**, if it's not already.

There are some new options in the **Class** section. Take a look at the **Codegen** field. There are three options here which control how the code for that particular entity will be created:

- **Manual / None**: no files will be created.
- **Class Definition**: a full class definition will be created.
- **Category / Extension**: An extension with the core data attributes declared within will be created.

Choose **Class Definition**: 

![bordered width=40%](images/CDTSettings.png)

Build and run your project. It will crash, but at runtime. Does that surprise you? You removed the **Potato.swift** file and you haven't generated an `NSManagedObject` subclass file yet, but your app built just fine. What's happening?

Xcode now automatically generates the code to implement your subclasses. It puts the generated files into the Derived Data folder for the project, to further underline the idea that you're not supposed to be editing them yourself. It does this every time you change the model file. 

See for yourself what has been created by finding some code that uses your entity. For example, open **AppDelegate.swift**, then Command-click on the `Potato` type to see the class definition: 

```swift
import Foundation
import CoreData

@objc(Potato)
public class Potato: NSManagedObject {

}
```

Back in **AppDelegate.swift**, Command-click on one of the properties, such as `variety`, to see how the properties are implemented:

```swift
import Foundation
import CoreData

extension Potato {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Potato> {
        return NSFetchRequest<Potato>(entityName: "Potato");
    }

    @NSManaged public var crowdRating: Float
    @NSManaged public var notes: String?
    @NSManaged public var userRating: Int16
    @NSManaged public var variety: String?

}
```

> **Note:** If you select **Manual / None** in the model editor, then these files will not be created. If you select **Category / Extension**, only the second file will be created, and you'll have to define the class yourself. If you want the files to be included in your project directly, then choosing **Manual / None** then **Editor\Create NSManagedObject subclass…** will give you the original behavior.

Automatic code generation can make it easier to make changes in your model. However, it does not free you of the responsibility for versioning your model when you make changes to it. Lightweight migration still requires versions.

You've created your model and Xcode has made the implementations for you. But why did the app crash at runtime? The problem lies in the App Delegate, where you are creating a list of model objects based on the list of potato varieties in the text file.

The error given is **Failed to call designated initializer on NSManagedObject class 'Potato'**. At the moment the code tries to create a new potato with a blank initializer: `Potato()`. This doesn't work for managed objects. It's time to set up Core Data for this app and give yourself some context. 

## A stack with a peel

Setting up the Core Data stack used to be quite a bit of work. You'd need to create the model, then a persistent store coordinator, then a managed object context. The code to do that was rather long, and almost exactly the same for each project. 

The new `NSPersistentContainer` class now wraps up all of that tedious work for you, as well as offering some handy new features. 

Open **AppDelegate.swift** and add the following line to the top of the file:

```swift
import CoreData
```

Inside the class definition, add a new property:

```swift
var coreDataStack: NSPersistentContainer!
```

At the start of `application(_:didFinishLaunchingWithOptions:)`, add the following line:

```swift
coreDataStack = NSPersistentContainer(name: "TaterRater")
```

This single line of code retrieves your model using the name you pass in and creates a persistent store coordinator configured with a sensible set of default options. You can change these by setting the `persistentStoreDescriptions` property of the persistent container. These are the properties and settings you'd normally pass to the persistent store coordinator: the URL, migration options and so forth. 

One interesting new option is that you can instruct the persistent container to set up its stores asynchronously. If you have a large data set or a complex migration, then you previously had to do extra work to make sure that migrations didn't block during launching, resulting in the watchdog killing the app off. Now it's a simple setting. 

You can set up asynchronous loading like this, after you've created the persistent container (but don't add this code to the project):

```swift
coreDataStack.persistentStoreDescriptions.first?
  .shouldAddStoreAsynchronously = true
```

For this project you'll leave the setting to its default, which lets the stores be set up synchronously. In most cases this is fine.

Add the following code right after you make the persistent container:

```swift
coreDataStack.loadPersistentStores {
  description, error in
  if let error = error {
    print("Error creating persistent stores: \(error.localizedDescription)")
    fatalError()
  }
}
```

This code creates the SQL files if they aren't there already. It performs any lightweight migrations that may be required. These are the things that normally happen using `addPersistentStore...` on the persistent store coordinator.

Because you haven't told the persistent container to set its stores up asynchronously, this method blocks until the work is complete. With asynchronous setup, execution continues, so you'd have to load some sort of waiting UI at launch, then in the completion block above perform a segue to show your actual UI. The completion block is called on the calling thread. 

Find the line later on in the same method where each `Potato` is created. Replace the empty initializer `let potato = Potato()` with this:

```swift
let potato = Potato(context: coreDataStack.viewContext)
```

This line contains two new Core Data features:

- _Finally_ you can create a managed object subclass just with a context. No more entity descriptions, entity names or casting! 
- The persistent container has a property, `viewContext`, which is a managed object context running on the main queue, directly connected to the persistent store coordinator. You'll learn more about the context hierarchy later. 

Build and run the app now and everything will work exactly as it did before — except now you're using managed objects under the hood. 

Next, you'll change the table view around so that it works with a fetched results controller instead of an array of objects. 

## Frenched russet controllers

Open **PotatoTableViewController.swift**. Import the core data module:

```swift
import CoreData
```

Then add new properties to hold the fetched results controller and the context:

```swift
var resultsController: NSFetchedResultsController<Potato>!
var context: NSManagedObjectContext!
```

Here's another new feature: fetched results controllers are now typed. This means that all of the arrays and objects that you get out of them are of known types. You'll see the benefits of this shortly. 

Add the following code to the end of `viewDidLoad()`:

```swift
// 1
let request: NSFetchRequest<Potato> = Potato.fetchRequest()
// 2
let descriptor = NSSortDescriptor(key: #keyPath(Potato.variety), ascending: true)
// 3
request.sortDescriptors = [descriptor]
// 4
resultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
do {
  try resultsController.performFetch()
} catch {
  print("Error performing fetch \(error.localizedDescription)")
}
```

Here's the breakdown:

1. Here you use the `fetchRequest()` method that is part of the generated managed object subclass code you saw earlier.
   
    Unfortunately this seems to clash with the new, magically typed `fetchRequest()` that has been added to `NSManagedObject`. If you don't use the type annotation, then the compiler doesn't know which method you want to use and will give you an error.

    Hopefully the file generation will be fixed in a future version so that the new method can be used directly. 

2. The new `#keyPath` syntax prevents you from mistyping keys when creating sort descriptors. You should definitely use it.
3. The sort descriptor is added to the fetch request.
4. Creating the fetched results controller and performing the fetch hasn't changed. 

Now replace the implementations of the datasource methods. Change `numberOfSections(in:)` to this:

```swift
return resultsController.sections?.count ?? 0
```

This is unchanged from last year. `sections` is an optional so you need the nil coalescing operator to make sure you always return a valid number.

Change `tableView(_: numberOfRowsInSection:)` to this:

```swift
return resultsController.sections?[section].numberOfObjects ?? 0
```

Again, this is nothing new. You're getting the section info object from the results controller and returning the row count. 

Inside `configureCell(_: atIndexPath:)`, replace the first line with this:

```swift
let potato = resultsController.object(at: indexPath)
```

Notice that you don't need to tell Swift what type of object this is. Because the fetched results controller now has type information, when you say `potato`, the compiler says `Potato`. No need to call the whole thing off.

Make a similar change in `prepare(for: sender:)`. The final line of the method gets the selected object to pass to the detail view controller. Replace that line with this one:

```swift
detail.potato = resultsController.object(at: path)
```

Finally, you can delete the `potatoes` property from the view controller. This will give you an error because you're passing in that property from the app delegate when the app launches. Switch back to **AppDelegate.swift** and change the error line to this:

```swift
potatoList.context = coreDataStack.viewContext
```

Now the table is using the same main thread managed object context that you used to load in the objects. 

Build and run just to confirm that you now have a results-controller driven table view. You'll see a warning about the `potatoes` constant not being used any more — you're going to fix that soon. 

A fetched results controller isn't particularly useful unless it has a delegate. The standard fetched results controller delegate code hasn't changed except for getting slightly shorter due to Swift 3 renaming, so I won't go through the details.

Open **PotatoTableViewController.swift** and add the following extension:

```swift
extension PotatoTableViewController: NSFetchedResultsControllerDelegate {
  
  func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    tableView.beginUpdates()
  }
  
  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, 
    didChange anObject: Any, at indexPath: IndexPath?, 
    for type: NSFetchedResultsChangeType, 
    newIndexPath: IndexPath?) {
    switch type {
    case .delete:
      guard let indexPath = indexPath else { return }
      tableView.deleteRows(at: [indexPath], with: .automatic)
    case .insert:
      guard let newIndexPath = newIndexPath else { return }
      tableView.insertRows(at: [newIndexPath], with: .automatic)
    case .update:
      guard let indexPath = indexPath else { return }
      if let cell = tableView.cellForRow(at: indexPath) {
        configureCell(cell, atIndexPath: indexPath)
      }
    case .move:
      guard let indexPath = indexPath, 
      let newIndexPath = newIndexPath else { return }
      tableView.deleteRows(at: [indexPath], with: .automatic)
      tableView.insertRows(at: [newIndexPath], with: .automatic)
    }
  }
  
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    tableView.endUpdates()
  }
  
}
```

Back up in `viewDidLoad()` assign the result controller's delegate just before you perform the fetch:

```swift
resultsController.delegate = self
```

Build and run again, and change the ratings on some of your favorite potatoes. You'll see the ratings update instantly on the cells if you're running on an iPad, otherwise you'll have to navigate back. That's the power of a fetched results controller. 

![iPad bordered](images/FRCUpdating.png)

Currently the app creates the list of potatoes from scratch every time it launches. One of the main features of Core Data is that it can be used for persistence, so you're going to actually save things now. To demonstrate another new feature, you'll going to offload that initial list creation to a background task. 

## Digging in to the background

Add a new Swift file to the **Model** group, and call it **PotatoTasks.swift**. Add the following code:

```swift
import CoreData

extension NSPersistentContainer {
  
  func importPotatoes() {
    // 1
    performBackgroundTask { context in
      // 2
      let request: NSFetchRequest<Potato> = Potato.fetchRequest()
      do {
        // 3
        if try context.count(for: request) == 0 {
          // TODO: Import some spuds
        }
      } catch {
        print("Error importing potatoes: \(error.localizedDescription)")
      }
    }
  }
}
```

Here's the breakdown: 

1. `performBackgroundTask(_:)` is a built-in method on `NSPersistentContainer` that takes a block with a managed object context as a parameter, does some work with it and then disposes of the context. The context is confined to a private queue. There's also a method to get a background context directly if you want to manage the object yourself.
2. This is the same code to generate a typed fetch request that you've already seen.
3. This is another new method, this time on the context itself. `count(for:)` is a throwing version of `countForFetchRequest(_: error:)`. 

Replace the `TODO:` comment with this code, which is very similar to the code that was used in the app delegate:

```swift
sleep(3)
guard let spudsURL = Bundle.main.url(forResource: "Potatoes", withExtension: "txt") else { return }
let spuds = try String(contentsOf: spudsURL)
let spudList = spuds.components(separatedBy: .newlines)
for spud in spudList {
  let potato = Potato(context: context)
  potato.variety = spud
  potato.crowdRating = Float(arc4random_uniform(50)) / Float(10)
}

try context.save()
```

The `sleep` line is there so that you can pretend you're loading data from a server. At the end of the object creation, the private context is saved. if you didn't do this, everything would be lost as the context is discarded at the end of the block. 

Switch back to **AppDelegate.swift** and in `application(_: didFinishLaunchingWithOptions)` replace all of the code from after the `loadPersistentStores(_:)` call to just before the `return true` statement with this:

```swift
coreDataStack.importPotatoes()

if let split = window?.rootViewController as? UISplitViewController {
  
  if
    let primaryNav = split.viewControllers.first as? UINavigationController,
    let potatoList = primaryNav.topViewController as? PotatoTableViewController {
      potatoList.context = coreDataStack.viewContext
  }
  
  split.delegate = self
  split.preferredDisplayMode = .allVisible
}
```

This code removes all of the potato creation code and calls the new extension method which loads the data in a background queue. Build and run the app and...

![iPhone bordered](images/EmptyPotatoes.png) 

Where are your potatoes? You may have expected them to make their way to the main thread managed object context after the background context saved. Usually, you'd make a background context as a child of the main thread context. But that isn't what `NSPersistentContainer` gives you. 

If you build and run the app again, then you'll see your list. This gives you a clue as to what is happening. 

The previous way to deal with multiple managed object contexts looked a little something like this:

![width=20%](images/OldStackHierarchy.png)

You only had one context that would talk to the persistent store coordinator. Typically that was a background queue context whose only job was to perform saves. Under that was the main thread context, which represented the “truth” of your app. Subsequent background operations or foreground editing contexts would be children of that main thread context. 

This was necessary because the persistent store coordinator and SQL store could not handle multiple readers or writers without having to use locks. In iOS 10, the SQL store has been improved to allow multiple readers and a single writer, and the persistent store coordinator no longer uses locks. This means that a context hierarchy now looks more like this: 

![width=40%](images/NewStackHierarchy.png)

The background contexts that the persistent container gives you talk directly to the persistent store coordinator — they aren't children of the main thread context. The background context adds all of the potatoes, then saves. This is written to the SQL store by the persistent store coordinator. The main thread context has no idea this is happening, unless it is forced to re-run the fetch requests. 

This would have presented a problem in older versions of iOS. You'd have to listen for save change notifications and do the merges yourself, like a savage. Luckily, this is the future. In **AppDelegate.swift**, before the `importPotatoes()` line, add the following code:

```swift
coreDataStack.viewContext.automaticallyMergesChangesFromParent = true
```

This is a new property on `NSManagedObjectContext`, and very useful it is too. Essentially it does all of that merging process for you. If the context is directly beneath the persistent store coordinator, then it will receive updates whenever a sibling context linked to the coordinator saves. If the context is a child context of another context, then it will receive updates whenever the parent context saves.

> **Note:** Because the changes are merged when the parent _saves_, this means that changes don't automatically cascade down. For example, if you had a background task which saved straight to the persistent store, and the view context was merging changes, then those background changes would appear in the view context. However, if the view context itself had a child context, the changes would not cascade down even if the child context was set to automatically merge.  

Delete the app from your simulator or device (because the data is already there) and build and run again. You'll see the empty list of potatoes for a while, then once the background context has done its work, the new data will automatically appear!

## iCloud Core Data gets mashed

Not announced at WWDC was one slightly nasty surprise: all of the symbols and methods associated with iCloud Core Data sync have been removed.

iCloud has always had something of a troubled relationship with Core Data and it seems Apple has finally decided to end it. According to the documentation, the existing methods will still work (for whatever definition of "work" you had before), but it's difficult to recommend starting a new project and relying on iCloud.

Perhaps with this year's changes, the simplification of setup and more convenient code, Apple is positioning Core Data as a more accessible, default choice model layer in your app, and you're supposed to use CloudKit or some other method to sync. There is no “official” guidance on the matter. 

## Where to go from here? 

Our _Core Data By Tutorials_ book is completely updated for iOS 10 and contains much more information about all of the goodies and new features listed here, as well as a solid grounding in what Core Data is, and how it works.   



