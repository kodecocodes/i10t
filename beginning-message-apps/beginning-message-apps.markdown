```metadata
author: "By Rich Turton"
number: "5"
title: "Chapter 5: Beginning Message Apps"
section: 2
```
# Chapter 5: Beginning Message Apps

iOS 10 brought some fun features to iMessage – and also opened up the app to third party developers. This means you can create and sell things to use in iMessage such as applications and sticker packs, and unlike other extension points, Messages apps don't need to have a "standard" iOS app to work.

In this chapter, you'll learn how to make a sticker app, which is a great introduction to the Messages framework.

You'll build the sticker pack to start. Next, you'll make a Messages app to provide stickers using some built-in classes. Finally, you'll create a custom sticker app using a collection view.

Ready to get sticky? :]

## Getting started

Sticker packs are the simplest possible iMessage application you can make. So simple, in fact, that you don't need to write any code!

Create a new Xcode project and choose the **iOS\Application\Sticker Pack Application** template:

![bordered width=60%](images/StickerPackTemplate2.png)

Name the project **RWPeeps**, click **Next**, and then **Create**.

The project will likely be one of the simplest Xcode projects you've ever seen! It only contains one thing – a specialized asset catalog named **Stickers.xcstickers**. Within the asset catalog is a place for the app icon and a folder named **Sticker Pack**:

![bordered width=80%](images/StickerPackProject.png)

The resources for this chapter contains a folder called **RWPeepsImages**. Drag images from that folder into the **Sticker Pack** folder:

![bordered width=60%](images/StickersInPlace.png)

You're done! No, seriously – you're done.

Build and run your "app", and you'll see that Xcode now offers you a choice of host applications to run. Select **Messages**, since that's what your sticker pack is designed for:

![bordered width=60%](images/ChooseHostApp.png)

The iOS simulator now contains a working Messages app, where you can view both sides of a conversation. This lets you test and develop Messages apps with ease.

Once the simulator has launched and Messages opens, you'll see an app button at the bottom of the screen:

![bordered iphone](images/MessagesAppButton.png)

Tap the button and wait a second or so; it seems to take some time for the simulator to launch your app. You'll see your stickers are ready to go! Tap any sticker to send it, or tap and hold to "peel" it off and attach to another message:

![bordered iphone](images/StickersStuck.png)

You can use the back button in the navigation bar to switch to the other side of the conversation.

There are a few rules around sticker pack applications:

- The sticker images must be `PNG`, `APNG`, `GIF` or `JPEG` format, and less than `500KB` in size.
- Messages will display all the stickers in a pack at the same size.
- You can choose either small (`100x100`), medium (`136x136`) or large (`206x206`) for the size of your sticker pack.
- You should supplied the images at **3x** resolution _only_.

Once you have recovered from the dizzying excitement of static sticker packs, you're ready to move on to a sticker _application_!

## Creating a sticker application

Sticker apps offer way more functionality beyond sticker packs; instead of relying on a static set of images, you can add custom UI and control the stickers available at runtime.

Next you're going to make a mouth-watering sticker app called **Stickerlicious**, so you can send yummy treats to your friends via iMessage. You'll learn how to create stickers dynamically from code, and you'll also learn how to filter and divide these stickers to help your users quickly find the stickers they're looking for.

Close your **RWPeeps** project if you still have it open, and create a new project in Xcode. Choose the **iOS\Application\iMessage Application** template:

![bordered width=60%](images/MessageAppTemplate2.png)

Name the project **Stickerlicious** and make sure the language is **Swift**. Click **Next**, and then **Create**.

This is another new application template. Here's a quick tour of what you get in the template:

- An application target, named **Stickerlicious** – this is necessary because message applications are actually _extensions_ of standard applications, much like Today extensions. However, with Messages extensions, the parent app doesn't have to do anything and doesn't appear on the home screen. You can safely ignore the application.
- A Messages extension, named **MessagesExtension**. This is what actually runs inside Messages, and is where you'll do all your work.
- Of additional interest inside the Messages extension are a storyboard, an asset catalog, and **MessagesViewController.swift**, which is a subclass of `MSMessagesAppViewController`.
- **Messages.framework**, which contains all of the message-related classes you will need.

Select the **Stickerlicious project** in the Project Navigator, then choose the **MessagesExtension** target. In the **General** tab, verify the **Display Name** is **Stickerlicious**.

All Messages apps live inside a `MSMessagesAppViewController` subclass. `MSMessagesAppViewController` contains several properties and methods of interest when building more complex message apps, but for a dynamic sticker pack, you can ignore all of them.

> **Note**: For a more information on `MSMessagesAppViewController`, see Chapter 6, "Intermediate Message Apps".

For now, open **MessagesViewController.swift** and delete all of the template methods, leaving you with an empty class declaration.

### The sticker browser view controller

The Messages framework contains a pair of classes, `MSStickerBrowserView` and `MSStickerBrowserViewController`, which you can use to display your stickers. Think of them as a pair, like `UITableView` and `UITableViewController`, or `UICollectionView` and `UICollectionViewController`.

`MSMessagesAppViewController` has to be the root view controller of your Messages extension, so to add a sticker browser, you have to embed it as a child view controller.

Open **MainInterface.storyboard** and delete the "Hello World" label from the **Messages View Controller** scene.

In the object library, find a **Container View** and drag it into the scene. With the view selected, add constraints to pin it to all edges of the scene, not relative to the margins:

![bordered width=40%](images/ContainerConstraints1.png)

When the frames are updated, the container view will fill the scene.

Before you can assign a class to the embedded view controller, you need to create it. Make a new file and choose the **iOS\Source\Swift File** template. Name the file **CandyStickerBrowserViewController.swift**.

Delete the contents of the file and replace them with the following:

```swift
import Messages

class CandyStickerBrowserViewController: MSStickerBrowserViewController {

}
```

Switch back to **MainInterface.storyboard** and select the embedded view controller. In the Identity Inspector, change the class to `CandyStickerBrowserViewController`.

Return to **CandyStickerBrowserViewController.swift**. Add the following property to hold the stickers you are going to display:

```swift
var stickers = [MSSticker]()
```

`MSSticker` is the model object representing a Messages Sticker.

Add the following constant above the class declaration to hold an array of image names:

```swift
let stickerNames = ["CandyCane", "Caramel", "ChocolateBar",
  "ChocolateChip", "DarkChocolate", "GummiBear",
  "JawBreaker", "Lollipop", "SourCandy"]
```

These names all correspond to images that have been supplied for you in the starter materials for this chapter. Find the **candy** folder and drag it into the **MessagesExtension** group in Xcode:

![bordered width=40%](images/CandyImageAdded.png)

Add the following extension to **CandyStickerBrowserViewController.swift**, below the class declaration:

```swift
extension CandyStickerBrowserViewController {

  private func loadStickers() {
    stickers = stickerNames.map({ name in
      let url = Bundle.main.urlForResource(name,
        withExtension: "png")!
      return try! MSSticker(
        contentsOfFileURL: url,
        localizedDescription: name)
    })
  }

}
```

This method creates an array of `MSSticker` elements by converting the names supplied in `stickerNames` to URLs. In your own apps, you could create stickers from packaged resources, or files that you have downloaded.

In the main class body, override `viewDidLoad()` as follows and call your new method:

```swift
override func viewDidLoad() {
  super.viewDidLoad()
  loadStickers()
  stickerBrowserView.backgroundColor = #colorLiteral(
    red:  0.9490196078, green: 0.7568627451,
    blue: 0.8196078431, alpha: 1)
}
```

In this method you also set a sweet pink color for the background.

The last step is to set up the data source methods for the sticker browser view. This should be a familiar task if you've ever written a table view or collection view data source.

The protocol `MSStickerBrowserViewDataSource` has two methods; implement them both by adding the following extension:

```swift
//MARK: MSStickerBrowserViewDataSource
extension CandyStickerBrowserViewController {
  override func numberOfStickers(in stickerBrowserView:
    MSStickerBrowserView) -> Int {
    return stickers.count
  }

  override func stickerBrowserView(_ stickerBrowserView:
    MSStickerBrowserView, stickerAt index: Int) -> MSSticker {
    return stickers[index]
  }
}
```

These methods are much simpler than table or collection view data sources; you have a number of stickers, and a sticker for a particular index.

Build and run, and choose to launch into the Messages app. Tap the **Apps** button and you'll need to scroll all the way to the right to find your new app. Wait a moment for the simulator to launch your app, and eventually you'll see the following:

![bordered iphone](images/Stickerlicious1.png)

That's nice, but so far you've only made something that looks _exactly_ like a sticker pack application – just one that took more work!

Don't fret; in the next section you're going to add some additional UI and dynamic features to your app.

### Adding dynamic stickers

You're about to introduce a special **Chocoholic** mode for those _special_ times when only pictures of chocolate will do for ruining – er, sorry – _enhancing_ your iMessage chats. Chocoholic mode will dynamically update the available stickers before your sugar-crazed eyes.

To start, open **MainInterface.storyboard**. Select the container view and use the resizing handle to drag down the top of the view by about 70 points to give yourself some room to work:

![bordered width=60%](images/Chocoholic1.png)

Select the top orange constraint and delete it. Drag a switch and a label into the space you've created, and set the label's text to **Chocoholic Mode**.

Select the label and the switch, then use the **Stack** button to embed them in a horizontal stack view:

![bordered width=60%](images/Chocoholic2.png)

With the stack view selected, change the **Spacing** in the Attributes Inspector to **5**. Using the **Pin** menu, add constraints from the stack view to its top, leading and bottom neighbors:

![bordered width=40%](images/Chocoholic3.png)

Select the switch and set its value to **Off** in the Attributes Inspector. Open the Assistant editor, and make sure it's displaying **MessagesViewController.swift**. Control-drag from the switch into the `MessagesViewController` class to create a new action, called **handleChocoholicChanged** with a sender type of **UISwitch**.

You're done with Interface Builder for now, so you can open **MessagesViewController.swift** in the main editor if you'd like some more elbow room.

Add the following new **Chocoholicable** protocol to the file:

```swift
protocol Chocoholicable {
  func setChocoholic(_ chocoholic: Bool)
}
```

Update the action method you just created above:

```swift
@IBAction func handleChocoholicChanged(_ sender: UISwitch) {
  childViewControllers.forEach({ vc in
    guard let vc = vc as? Chocoholicable else { return }
    vc.setChocoholic(sender.isOn)
  })
}
```

This will pass the chocoholic mode down to any child view controller that is `Chocoholicable`. There aren't any at present, so switch to **CandyStickerBrowserViewController.swift** to make it so.

First, update the declaration of `loadStickers()`:

```swift
private func loadStickers(_ chocoholic: Bool = false) {
```

This lets you pass in the chocoholic mode, with a default value of `false` so the existing call from `viewDidLoad()` remains unaffected.

Next, replace the whole function body with this code:

```swift
stickers = stickerNames.filter( { name in
  return chocoholic ? name.contains("Chocolate") : true
}).map({ name in
  let url = Bundle.main.urlForResource(name,
    withExtension: "png")!
  return try! MSSticker(contentsOfFileURL: url,
    localizedDescription: name)
})
```

This will filter the names to only show chocolate-containing stickers if chocoholic mode is on.

Finally, add the following extension to make `CandyStickerBroswerViewController` conform to `Chocoholicable`:

```swift
extension CandyStickerBrowserViewController: Chocoholicable {
  func setChocoholic(_ chocoholic: Bool) {
    loadStickers(chocoholic)
    stickerBrowserView.reloadData()
  }
}
```

Build and run; now you can fulfill all your sticky, chocolatey messaging needs:

![bordered iphone](images/Chocoholic4.png)

### Creating a custom sticker browser

`MSStickerBrowserView` offers you little scope for customization. To really take control of your sticker app, you'll work with `MSStickerView`. This is the view that powers `MSStickerBrowserView`, and you can use it on its own as well.

It gives you all the sticker functionality – displaying and scaling the stickers, tapping to add to the message, drag and drop – with no extra code. All you need to do is put it on the screen and give it an `MSSticker`.

In this final part of the chapter you will replace the `MSStickerBrowserViewController` subclass with a `UICollectionViewController` subclass which will allow you to divide the stickers up into labelled sections.

In **MainInterface.storyboard**, select the **Candy Sticker Browser** scene and delete it. Drag in a **UICollectionViewController**, then Control-drag from the container view to the collection view controller and choose the **Embed** segue.

Select the **Collection View** in the collection view controller, open the Attributes Inspector and check the **Accessories\Section Header** checkbox.

Open the Size Inspector, and set **Header Size\Height** to **25**. Set the **Min Spacing** and **Section Insets** values to **0**.

Drag a label into the section header, using the guides to position it in the center. With the **Align** button at the bottom of the storyboard, add constraints to pin it to the horizontal and vertical centers of the view:

![bordered width=40%](images/Collection1.png)

Drag in a **Visual Effect View with Blur** from the object library onto the section header. Using the **Pin** button at the bottom of the storyboard, add constraints to pin the view to all sides of the section header, with zero spacing.

Before continuing, make sure the **Label** is displayed _on top of_ the **Visual Effect View**. If not, open the document outline on the left of Interface Builder and place it below the Visual Effect View.

Drag in a plain `UIView` to the collection view cell and, using the same technique, pin it to all edges of the cell. Select the view, and using the Identity Inspector, change the class to **MSStickerView**.

Now you need to create custom subclasses for the section header, collection view cells and view controller.

For the header, create a new file and choose **iOS\Source\Cocoa Touch Class**. Name the class **SectionHeader** and make it a subclass of **UICollectionReusableView**.

For the cell, create a new file and choose **iOS\Source\Cocoa Touch Class** again. Name the class **StickerCollectionViewCell** and make it a subclass of **UICollectionViewCell**.

Add the following `import` statement to the top of **StickerCollectionViewCell.swift**:

```swift
import Messages
```

`MSStickerView` is part of the Messages framework. Since you'll be making an outlet to one of these, the cell needs to know what that class is.

The final new class to create is the view controller. Create a new file and choose **iOS\Source\Cocoa Touch Class** again, name the class **StickerCollectionViewController** and make it a subclass of **UICollectionViewController**.

Replace the templated contents with the following:

```swift
import UIKit
import Messages

class StickerCollectionViewController: UICollectionViewController {
}
```

Switch back to **MainInterface.storyboard** to connect everything up.

First, choose the collection view controller and use the Identity Inspector to set the class to **StickerCollectionViewController**.

Choose the section header (labeled Collection Reusable View in the Document Outline), change its class to **SectionHeader**, and use the Attributes Inspector to set the reuse identifier to **SectionHeader**.

Choose the cell, change its class to **StickerCollectionViewCell**, and set the reuse identifier to **StickerCollectionViewCell**.

Open the Assistant editor, make sure **StickerCollectionViewCell.swift** is displayed, and create a new outlet from the `MSStickerView` inside the cell to the collection view cell subclass. Name it **stickerView**.

Now switch the Assistant editor to **SectionHeader.swift** and create a new outlet from the label in the section header to the `SectionHeader` class file. Name it `label`.

Check the document outline in the storyboard to make sure you haven't missed anything:

![bordered width=40%](images/Collection2.png)

Close the Assistant editor and switch to **StickerCollectionViewController.swift**.

The stickers will be grouped in this view controller using a dictionary instead of an array. Add the following code above the class declaration:

```swift
let stickerNameGroups: [String: [String]] = [
  "Crunchy":   ["CandyCane","JawBreaker","Lollipop"],
  "Chewy":     ["Caramel","GummiBear","SourCandy"],
  "Chocolate": ["ChocolateBar","ChocolateChip","DarkChocolate"]
]
```

Dictionaries aren't great data objects, because you need to remember keys and values. 

To help with this, still above the class declaration, define the following new struct which will form the basis of your model:

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

Just as you did with the sticker browser view controller subclass, you'll need to implement the `loadStickers` method. Add it in an extension as follows:

```swift
extension StickerCollectionViewController {
  // 1
  private func loadStickers(_ chocoholic: Bool = false) {
    // 2
    stickerGroups = stickerNameGroups.filter({ (name, _) in
      // 3
      return chocoholic ? name == "Chocolate" : true
    }).map { (name, stickerNames) in
      // 4
      let stickers: [MSSticker] = stickerNames.map { name in
        let url = Bundle.main.urlForResource(name,
          withExtension: "png")!
        return try! MSSticker(contentsOfFileURL: url,
          localizedDescription: name)
      }
      // 5
      return StickerGroup(name: name, members: stickers)
    }
    // 6
    stickerGroups.sort(isOrderedBefore: { $0.name < $1.name })
  }
}
```

This is quite similar to the previous `loadStickers` method. Here's a breakdown:

1. This takes a chocoholic mode with a default value.
2. Filtering on a dictionary takes a tuple of the key and value. For filtering we can ignore the value; ergo, the presence of  "`_`".
3. The filtering now takes place on the group name, rather than on a substring of the sticker name.
4. There is an additional mapping step to turn the array of names from the dictionary into an array of stickers.
5. You then convert each dictionary entry to a `StickerGroup` struct.
6. Finally, you sory the array of sticker groups by name, since dictionaries don't have a guaranteed ordering.

Modify `viewDidLoad()` as shown below to call your new method and set up a few things:

```swift
override func viewDidLoad() {
  super.viewDidLoad()
  loadStickers()
  if let layout = collectionView?.collectionViewLayout as?
    UICollectionViewFlowLayout {
    layout.sectionHeadersPinToVisibleBounds = true
  }
  collectionView?.backgroundColor = #colorLiteral(
    red:  0.9490196078, green: 0.7568627451,
    blue: 0.8196078431, alpha: 1)
}
```

This uses the nice new feature of `UICollectionViewFlowLayout`, which gives you sticky section headers.

You may have noticed that the sticker browser view you used before managed to fit three columns onto an iPhone 6 in portrait, despite the stickers being 136 points across and the iPhone 6 only being 375 points across. You're going to perform a similar trick and make sure you get _at least_ three columns of stickers.

Add the following extension:

```swift
// MARK: UICollectionViewDelegateFlowLayout
extension StickerCollectionViewController {
  func collectionView(_ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
    let edge = min(collectionView.bounds.width / 3, 136)
    return CGSize(width: edge, height: edge)
  }
}
```

This sets the cells to a square shape with an edge of 136 points _or_ a third of the screen width, whichever is least.

The collection view datasource methods are next. Add the following extension:

```swift
extension StickerCollectionViewController {
  override func numberOfSections(
    in collectionView: UICollectionView) -> Int {
    return stickerGroups.count
  }

  override func collectionView(_ collectionView:
    UICollectionView,
    numberOfItemsInSection section: Int) -> Int {
    return stickerGroups[section].members.count
  }
}
```

The two `.count` methods are simple, thanks to the `StickerGroup` struct you're using as a model object.

The cell configuration method is also straightforward. Add the following code to the extension you just created:

```swift
override func collectionView(_ collectionView: UICollectionView,
  cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
  let cell = collectionView.dequeueReusableCell(
    withReuseIdentifier: "StickerCollectionViewCell",
    for: indexPath) as! StickerCollectionViewCell

  let sticker =
    stickerGroups[indexPath.section].members[indexPath.row]
  cell.stickerView.sticker = sticker

  return cell
}
```

This gets the correct sticker for the section and item and passes it to the sticker view in the cell. That's all you need to get a working sticker view.

Add the final method for the data source extension to populate the section header:

```swift
override func collectionView(_ collectionView: UICollectionView,
  viewForSupplementaryElementOfKind kind: String,
  at indexPath: IndexPath) -> UICollectionReusableView {
  guard kind == UICollectionElementKindSectionHeader else {
    fatalError()
  }

  let header = collectionView.dequeueReusableSupplementaryView(
    ofKind: kind, withReuseIdentifier: "SectionHeader",
    for: indexPath) as! SectionHeader
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

Build and run; your candy neatly separates into sections, so you know just what you're going to get. Perhaps Forrest Gump should have used a collection view? :]

![bordered iphone](images/Collection3.png)

## Where to go from here?

Congratulations! At this point, you know how to make a basic sticker pack ("Look ma, no code!") and how to create a custom user interface for your stickers.

There's much more you can do with Messages beyond sticker packs. In the next chapter, you'll learn how to create custom messages. Specifically, you'll create a cool drawing and guessing game you can play right within Messages!
