```metadata
author: "By Rich Turton"
number: "99"
title: "Chapter 5: Beginning Message Apps"
```
# Chapter 5: Beginning Message Apps

## Introduction

iMessage has been given some "fun" new features in iOS 10, and has also been opened up to third party developers. You can make and sell applications and sticker packs, and unlike other extension points, Messages apps don't need to have a "standard" iOS app to go with them. 

Message apps can interact directly with the ongoing conversation, which you'll learn more about in the next chapter. In this chapter you will learn about making your own sticker apps, which are a great introduction to the Messages framework. You'll start by building a sticker pack, then you'll make a Messages app which provides stickers using some built-in classes, and finally you'll make a fully custom sticker app using a collection view. 

Are you ready to get sticky?

## Sticker Packs

Sticker packs are the simplest possible iMessage application you can make. In fact, they are so simple, you don't even need to write any code! 

Create a new Xcode project and choose the **iOS > Application > Sticker Pack Application** template:

![bordered width=60%](images/StickerPackTemplate.png)

Call the project **RWPeeps**. 

The project that is created is probably one of the simplest Xcode projects you've ever seen! It only contains one thing - a specialised asset catalog, called **Stickers.xcstickers**. Within the asset catalog is a place for the app icon, and a folder called **Sticker Pack**:

![width=60%](images/StickerPackProject.png)

In the resources for this chapter is a zip file, **RWPeepsImages.zip**. Unzip this file and drag the images into the **Sticker Pack** folder:

![bordered width=60%](images/StickersInPlace.png)

And you're done!

Build and run your "app", and you'll see a new option - Xcode offers you a choice of host applications to run. Select **Messages**, since that's what your stickers are for:

![bordered width=60%](images/ChooseHostApp.png)

The iOS simulator now contains a working messages app, where you can view both sides of a conversation. This is so you can test and develop messages apps easily. 

When the simulator launches and Messages opens up, you'll see an app button at the bottom of the screen: 

![iphone](images/MessagesAppButton.png)

Tap the button and wait a second or so (it seems to take some time for the simulator to launch your app) and you'll see your stickers ready to go! Tap one to send it, or tap and hold to "peel" it off and attach to another message: 

![iphone](images/StickersStuck.png)

You can use the back button in the navigation bar to switch to the other side of the conversation. 

There are a few rules around sticker pack applications:

- The sticker images must be PNG, APNG, GIF or JPEG format, and less than 500KB
- Messages app displays all of the stickers in a pack at the same size
- You can choose small (100 x 100), medium (136 x 136) or large (206 x 206) for your sticker pack's size.
- The images should be supplied at 3x resolution _only_. 

Once you have recovered from the dizzying excitement of static sticker packs, you're ready to move on to a sticker _application_! 

## Sticker applications

What do sticker applications offer you above and beyond sticker packs? You can add custom UI and control the stickers available at runtime, instead of relying on a static set of images. 

You're going to make a mouth-watering sticker app called **Stickerlicious**, so you can send yummy treats to your friends via iMessage. You'll learn how to create stickers dynamically in code instead of having a static set of images, and how to filter and divide these stickers to help your users get to the stickers they want quickly. 

### Getting started

Open Xcode and create a new project. Choose the **iOS > Application > Messages Application** template:

![bordered width=60%](images/MessageAppTemplate.png)

Call the project **Stickerlicious** and make sure the language is **Swift**.

This is another new application template. Here's a quick tour of what you get:

- An application target, called **Stickerlicious** - this is necessary because message applications are actually _extensions_ of standard applications, in the same way that today extensions work. However, with Messages extensions, the parent app doesn't have do anything and doesn't appear on the home screen. You can ignore the application. 
- A messages extension, called **MessagesExtension**. This is what actually runs inside Messages, and is where you'll do all your work. 
- Of interest inside the messages extension is a storyboard, an asset catalog and **MessagesViewController.swift**, which is a subclass of `MSMessagesAppViewController`.
- **Messages.framework**, which contains all of the message-related classes you will need.

Select the **Stickerlicious project** in the Project Navigator, then choose the **MessagesExtension** target. In the **General** tab, change the **Display Name** to **Stickerlicious**. 

### MSMessagesAppViewController

All messages apps live inside a `MSMessagesAppViewController` subclass. It contains several properties and methods of interest when building more complex message apps, but for a dynamic sticker pack, you can ignore all of them. 

Open **MessagesViewController.swift** and delete all of the template methods, leaving you with an empty class declaration. 

For a deep dive into `MSMessagesAppViewController`, see **Chapter 6 - Intermediate Message Apps**. 

### Sticker browser view controllers

The Messages framework contains a pair of classes, `MSStickerBrowserView` and `MSStickerBrowserViewController`, which you can use to display your stickers. Think of them as a pair, like `UITableView` and `UITableViewController`, or `UICollectionView` and `UICollectionViewController`. 

The `MSMessagesAppViewController` has to be the root view controller of your messages extension, so to add a sticker browser, you have to embed it as a child view controller. 

Open **MainInterface.storyboard** and delete the "Hello World" label from the **Messages View Controller** scene. 

In the object library, find a **Container View** and drag it into the scene. With the view selected, add constraints to pin it to all edges of the scene, not relative to the margins:

![bordered width=40%](images/ContainerConstraints1.png)

When the frames are updated the container view will fill the scene.

Before you can assign a class to the embedded view controller, you need to create it. Make a new file and choose the **iOS > Source > Swift File** template. Call the file **CandyStickerBrowserViewController.swift**.

Delete the contents of the file and replace with the following:

```swift
import Messages

class CandyStickerBrowserViewController: MSStickerBrowserViewController {
    
}
```

Switch back to **MainInterface.storyboard** and select the embedded view controller. In the identity inspector, change the class to `CandyStickerBrowserViewController`.

Return to **CandyStickerBrowserViewController.swift**. Add a property to hold the stickers you are going to display: 

```swift
var stickers = [MSSticker]()
```

`MSSticker` is the model object representing a Messages Sticker. Above the class definition, add a constant to hold an array of image names:

```swift
let stickerNames = ["CandyCane", "Caramel", "ChocolateBar", "ChocolateChip", "DarkChocolate", "GummiBear", "JawBreaker", "Lollipop", "SourCandy"]
```

These names all correspond to images that are supplied for you in the starter materials to this chapter. Find **candy.zip**, unzip it and drag the folder into the **MessagesExtension** group in Xcode:

![bordered width=40%](images/CandyImageAdded.png)

In **CandyStickerBrowserViewController.swift**, add the following extension: 
 
```swift
extension CandyStickerBrowserViewController {
  
  private func loadStickers() {
    stickers = stickerNames.map({ name in
      let url = Bundle.main().urlForResource(name, withExtension: "png")!
      return try! MSSticker(contentsOfFileURL: url, localizedDescription: name)
    })
  }
  
}
```

This method creates an array of `MSSticker`s by converting the names supplied into URLs. In your own apps you could create stickers from packaged resources, or files that you have downloaded. 

In the main class body, override `viewDidLoad()` and call your new method:

```swift
override func viewDidLoad() {
  super.viewDidLoad()
  loadStickers()
  stickerBrowserView.backgroundColor = #colorLiteral(red: 0.9490196078, green: 0.7568627451, blue: 0.8196078431, alpha: 1)
}
```

In this method you also set a sweet pink color for the background. 

The final thing that is required is to set up the data source methods for the sticker browser view. This should be very familiar if you've ever written a table view or collection view data source. The protocol `MSStickerBrowserViewDataSource` has two methods, implement them both by adding this extension:

```swift
//MARK: MSStickerBrowserViewDataSource
extension CandyStickerBrowserViewController {
  override func numberOfStickers(in stickerBrowserView: MSStickerBrowserView) -> Int {
    return stickers.count
  }
  
  override func stickerBrowserView(_ stickerBrowserView: MSStickerBrowserView, stickerAt index: Int) -> MSSticker {
    return stickers[index]
  }
}
```

The methods are much simpler than table or collection view data sources - there's a number of stickers, and a sticker for a particular index. 

Build and Run, choosing the Messages app to launch into. When you tap the "Apps" button you will need to scroll all the way to the right to find your new app. You'll then need to wait a little while for the simulator to launch it, then you'll see the following:

![phone](images/Stickerlicious1.png)

That's nice, but so far you've made something that looks exactly like a sticker pack application, only it was much more work. In the next stage you're going to add some additional UI and dynamic features! 

### Dynamic Stickers

In this section you're going to introduce a special **Chocoholic** mode for those special times when only pictures of chocolate will do for ruining, sorry, "enhancing" your iMessage chats. 

Chocoholic mode will update the available stickers before your sugar-crazed eyes.

To start, open **MainInterface.storyboard**. Select the container view and use the resizing handle to drag the top of it down by about 70 points, to give yourself some space to work:

![bordered width=60%](images/Chocoholic1.png)

Select the top orange constraint and delete it. Drag in a switch and a label in the space you've created, and set the label's text to **Chocoholic Mode**. 

Select the label and the switch, then use the **Stack** button to embed them in a horizontal stack view:

![bordered width=60%](images/Chocoholic2.png)

With the stack view selected, change the **Spacing** in the attributes inspector to **5**. Using the **Pin** menu, add constraints from the stack view to its top, leading and bottom neighbors:

![bordered width=40%](images/Chocoholic3.png)

Select the switch and set its value to **Off** in the attributes inspector. Open the Assistant Editor, and make sure it is displaying **MessagesViewController.swift**. Control-drag from the switch into the `MessagesViewController` class to create a new action, called **handleChocoholicChanged** with a sender type of **UISwitch**. 

You're done with interface builder for now, so you can open **MessagesViewController.swift** in the main editor if you'd like some more room.

Add a new protocol to the file called **Chocoholicable**:

```swift
protocol Chocoholicable {
  func setChocoholic(_ chocoholic: Bool)
}
```

Update the action method you just added:

```swift
@IBAction func handleChocoholicChanged(_ sender: UISwitch) {
  for vc in childViewControllers {
    if let vc = vc as? Chocoholicable {
      vc.setChocoholic(sender.isOn)
    }
  }
}
```

This will pass down the chocoholic mode to any child view controller that is `Chocoholicable`. Currently, none of them are, so switch to **CandyStickerBrowserViewController.swift** to make it so. 

First, update the declaration of `loadStickers()`:

```swift
private func loadStickers(_ chocoholic: Bool = false) {
```

This allows you to pass in the chocoholic mode, with a default value of `false` so the existing call from `viewDidLoad()` is unaffected.

Insert a `filter` before the existing `map` of the sticker names array. Replace the whole function body with this code:

```swift
stickers = stickerNames.filter( { name in
  if chocoholic {
    return name.contains("Chocolate")
  } else {
    return true
  }
}).map({ name in
  let url = Bundle.main.urlForResource(name, withExtension: "png")!
  return try! MSSticker(contentsOfFileURL: url, localizedDescription: name)
})
```

This will filter the names to only show chocolate-containing stickers, if chocoholic mode is on. 

Finally, make `CandyStickerBroswerViewController` conform to `Chocoholicable` by adding this extension:

```swift
extension CandyStickerBrowserViewController: Chocoholicable {
  func setChocoholic(_ chocoholic: Bool) {
    loadStickers(chocoholic)
    stickerBrowserView.reloadData()
  }
}
```

Build and run, and fulfil all of your sticky, chocolatey needs:

![iphone](images/Chocoholic4.png)

### A fully custom sticker browser

`MSStickerBrowserView` offers you very little scope for customization. To really take control of your sticker app, there is `MSStickerView`. This is the view that is used to power `MSStickerBrowserView`, and you can use it on its own as well.

It gives you all of the sticker functionality - displaying and scaling the stickers, tapping to add to the message, drag and drop - with no extra code. All you need to do is put it on the screen and give it an `MSSticker`. 

In this final part of the tutorial you will replace the `MSStickerBrowserViewController` subclass with a `UICollectionViewController` subclass which will allow you to divide the stickers up into labelled sections.

In **MainInterface.storyboard**, select the **Candy Sticker Browser** scene and delete it. Drag in a **UICollectionViewController**, then control-drag from the container view to the collection view controller and choose the **Embed** segue. 

Select the **Collection View** in the collection view controller, open the **Attributes Inspector** and check the **Accessories / Section Header** checkbox.

Open the **Size Inspector** set the **Header Size > Height** to 25. Set the **Min Spacing** and **Section Insets** values to zero. 

Drag a label into the section header, using the guides to position it in the center. With the **Align** button at the bottom of the storyboard, add constraints to pin it to the horizontal and vertical centers of the view: 

![bordered width=40%](images/Collection1.png)

Drag in a **Visual Effect View with Blur** from the object library onto the section header. Using the **Pin** button at the bottom of the storyboard, add constraints to pin the view to all sides of the section header, with zero spacing.

Drag in a plain `UIView` to the collection view cell and, using the same technique, pin it to all edges of the cell. Select the view and, using the **Identity Inspector**, change the class to **MSStickerView**.

Now you need to create custom subclasses for the section header, collection view cells and view controller. 

For the header, create a new file and choose **iOS > Source > Cocoa Touch Class**. Call the class **SectionHeader** and make it a subclass of **UICollectionReusableView**. 

For the cell, create a new file and choose *iOS > Source > Cocoa Touch Class** again. Call the class **StickerCollectionViewCell** and make it a subclass of **UICollectionViewCell**. In the file that is generated, add the following import statement at the top:

```swift
import Messages
```

`MSStickerView` is part of the Messages framework, and you are going to make an outlet to one, so the cell needs to know what that class is. 

The final new class to create is the view controller. Choose the same new file template, calling the class **StickerCollectionViewController** and making it a subclass of **UICollectionViewController**. Replace the template contents with this:

```swift
import UIKit
import Messages

class StickerCollectionViewController: UICollectionViewController {
}
```

Switch back to **MainInterface.storyboard** to connect everything up. 

First, choose the collection view controller and set the class to **StickerCollectionViewController** in the Identity Inspector. 

Choose the section header and change the class to **SectionHeader**, and the reuse identifier (in the Attributes Inspector) to **SectionHeader**.

Choose the cell and change the class to **StickerCollectionViewCell**, and the reuse identifier to **StickerCollectionViewCell**. 

Open the assistant editor, making sure **StickerCollectionViewCell.swift** is displayed, and make a new outlet from the `MSStickerView` inside the cell to the collection view cell subclass. Call it **stickerView**. 

Now make the assistant editor display **SectionHeader.swift** and make a new outlet from the label in the section header to the `SectionHeader` class file. Call it `label`. 

That was a lot of work! Check the document outline in the storyboard to make sure you haven't missed anything:

![bordered width=40%](images/Collection2.png)

Close the assistant editor and switch to **StickerCollectionViewController.swift**. 

The stickers are going to be grouped in this view controller, so instead of using an array, you'll use a dictionary. Add the following code above the class definition:

```swift
let stickerNameGroups: [String: [String]] = [
  "Crunchy": ["CandyCane", "JawBreaker", "Lollipop"],
  "Chewy": ["Caramel", "GummiBear", "SourCandy"],
  "Chocolate": ["ChocolateBar", "ChocolateChip", "DarkChocolate"]
]
```

Dictionaries aren't great data objects, because you need to remember keys and values. Define a new struct which will form the basis of your model:

```swift
struct StickerGroup {
  let name: String
  let members: [MSSticker]
}
```

Inside the `StickerCollectionViewController` class, add a property to hold the model:

```swift
var stickerGroups = [StickerGroup]()
```

Just as you did with the sticker browser view controller subclass, you'll need a `loadStickers` method. Add it in an extension: 

```swift
extension StickerCollectionViewController {
  // 1
  private func loadStickers(_ chocoholic: Bool = false) {
    // 2
    stickerGroups = stickerNameGroups.filter({ (name, _) in
      if chocoholic {
        // 3
        return name == "Chocolate"
      } else {
        return true
      }
    }).map { (name, stickerNames) in
      // 4
      let stickers: [MSSticker] = stickerNames.map { name in
        let url = Bundle.main.urlForResource(name, withExtension: "png")!
        return try! MSSticker(contentsOfFileURL: url, localizedDescription: name)
      }
      // 5
      return StickerGroup(name: name, members: stickers)
    }
    // 6
    stickerGroups.sort(isOrderedBefore: { $0.name < $1.name })
  }
}
```

It's quite similar to the previous `loadStickers` method. Here's a breakdown: 
1. It takes a chocoholic mode with a default value
2. Filtering on a dictionary takes a tuple of the key and value, for filtering we can ignore the value.
3. The filtering takes place on the group name rather than a substring of the sticker name.
4. There is an additional mapping step to turn the array of names from the dictionary into an array of stickers.
5. Each dictionary entry is converted to a `StickerGroup` struct.
6. Finally, the array of sticker groups is sorted by name, since dictionaries don't have a guaranteed ordering.

Call your new method, and do some other setup, from `viewDidLoad()`:

```swift
override func viewDidLoad() {
  super.viewDidLoad()
  loadStickers()
  if let layout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
    layout.sectionHeadersPinToVisibleBounds = true
  }
  collectionView?.backgroundColor = #colorLiteral(red: 0.9490196078, green: 0.7568627451, blue: 0.8196078431, alpha: 1)
}
```

This uses the nice new feature of `UICollectionViewFlowLayout` which gives you sticky section headers :]

You may have noticed that the sticker browser view you used before managed to fit three columns onto an iPhone 6 in portrait, despite the stickers being 136 points across and the iPhone 6 only being 375 points across. You're going to perform a similar trick and make sure you get at least three columns of stickers. Add the following extension:

```swift
// MARK: UICollectionViewDelegateFlowLayout
extension StickerCollectionViewController {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
    let edge = min(collectionView.bounds.width / 3, 136)
    return CGSize(width: edge, height: edge)
  }
}
```

This sets the cells to a square with an edge of 136 points, or a third of the screen width, whichever is lower.

The collection view datasource methods are next. Add the following extension:

```swift
extension StickerCollectionViewController {
  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return stickerGroups.count
  }
  
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return stickerGroups[section].members.count
  }
}
```

The two "count" methods are simple, thanks to the `StickerGroup` struct you are using as a model object. 

The cell configuration method is also straightforward. Add the following code to the extension you just created:

```swift
override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
  let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StickerCollectionViewCell", for: indexPath) as! StickerCollectionViewCell
  
  let sticker = stickerGroups[indexPath.section].members[indexPath.row]
  cell.stickerView.sticker = sticker
  
  return cell
}
```

This gets the correct sticker for the section and item, and passes it to the sticker view in the cell. That's all you need to do to get a working sticker view.

The final method for the data source extension is to populate the section header:

```swift
override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
  guard kind == UICollectionElementKindSectionHeader else { fatalError() }
  
  let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "SectionHeader", for: indexPath) as! SectionHeader
  header.label.text = stickerGroups[indexPath.section].name
  return header
}
```

You're almost done. The last thing to add is to make the view controller `Chocoholicable`. Add the following extension, which will look almost identical to the one you used for the sticker browser view controller:

```swift
extension StickerCollectionViewController: Chocoholicable {
  func setChocoholic(_ chocoholic: Bool) {
    loadStickers(chocoholic)
    collectionView?.reloadData()
  }
}
```

Build and run, and your candy is neatly separated into sections, so you know just what you're going to get. Perhaps Forrest Gump should have used a collection view?

![iphone](images/Collection3.png)

## Where to go from here? 

**Chapter 6** takes you further into the Messages framework - you'll learn how to create custom messages and interact with the current conversation by creating a drawing and guessing game which you can play within Messages!
