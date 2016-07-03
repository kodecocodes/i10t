```metadata
author: "By Rich Turton"
number: "99"
title: "Chapter 5: Beginning Message Apps"
```
# Chapter 5: Beginning Message Apps

## Introduction

Overview of changes to iMessage, summary of chapter content

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

What do sticker applications offer you above and beyond sticker packs? [TODO finish this part]The chance to customise the UI, 

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
}
```

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


### Making your own sticker browser

(Subject to dropping if it looks like it will be too big) - implement a collection view with sections so you can have some decoration views or something like that - chocolate section etc. 

MSStickerView to give the drag and drop and peeling functionality


