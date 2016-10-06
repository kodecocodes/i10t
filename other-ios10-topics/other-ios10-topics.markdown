```metadata
author: "By Jeff Rames"
number: "14"
title: "Chapter 14: Other iOS 10 Topics"
```
  
# Chapter 14: Other iOS 10 Topics

iOS 10 introduces many high profile features like iMessage apps and SiriKit. It includes major enhancements to user notifications, Core Data, search, photography and numerous other topics covered in this book.

What you haven't read about yet are the smaller ways iOS 10 has improved life for users and developers. Every major framework has had notable updates. Regardless of what type of app you're working on, there are opportunities to improve performance, architect better code, or delight your users with new features.

Many of these changes are too small to warrant a chapter of their own, but a few are notable enough we just had to share. This chapter focuses on three bite sized iOS 10 topics that many will find useful:

- **Data Source Prefetching** makes table and collection view controllers more responsive by providing opportunity to kick off data processing well before a cell is presented.
- **UIPreviewInteraction** is a new protocol that allows for custom interactions via 3D Touch.
- **Haptic Feedback** is an all feature tied to new hardware in the iPhone 7 and 7 Plus. The API provides the ability to produce several unique types of feedback.

Not interested in all of these? We have you covered! In the next section you'll learn how this chapter is organized to allow skipping around.

## Getting started

This chapter is designed a bit differently than others. Each topic gets its own mini chapter, including a high level introduction with a starter project so you're ready to dive in. 

This allows you to get the level of detail you want on the topics that interest you. Feel free to:

- Read from start to finish as you would any other chapter. Each topic works with the same sample project.
- Skip to any section that interests you and complete it in tutorial fashion. Starter and completed projects are included for each section, so you don't need to worry about getting up to speed.
- Read just the introduction of each section to get a high level understanding of these three topics. You can always return later for a deeper dive of the section!

All sections work with an app called EmojiRater that consists of a collection view displaying various emojis. 

![bordered iphone](./images/emoji-rater.png)

The collection view gets a speed boost in the section on prefetching. It gains the ability to rate emojis during the preview interaction section. In the final section, haptic feedback is added and fired when the user scrolls to the top of the collection view.

The section below kicks off data source prefetching. But what's next is completely up to you!

## Data source prefetching

Data source prefetching provides a mechanism for preparing data before it needs to be displayed. Consider an app with cells containing remotely housed images. Perceived loading delays could be drastically reduced with a prefetch that kicks off download operations.

A new data source protocol - **UICollectionViewDataSourcePrefetching** - is responsible for prefetching. The protocol defines only two methods:

- **collectionView(_:prefetchItemsAt:)** is called with an array of index paths representing data that will be required soon based on current scroll direction and speed. The items are ordered from most urgent to least based on when the collection view anticipates needing them. Data operations for the items in question should be kicked off here.
- **collectionView(_:cancelPrefetchingForItemsAt:)** is an optional method that triggers when you should cancel prefetch operations. It receives an array of index paths for items that the collection view once anticipated, but no longer needs. This might happen if the user changes scroll directions.

For large data sources with content that is time consuming to prepare, implementing this protocol can have a dramatic impact on user experience. Of course, it isn't magic - it simply takes advantage of down time and guesses at what will be needed next. If a user starts scrolling very quickly, or resources are otherwise limited, prefetch requests will slow or stop.

>**Note**: Fret not table view users! **UITableViewDataSourcePrefetching** works exactly like this, but for table view controllers. You can follow along here to learn how to use it, and then check out the API doc for table view syntax: [apple.co/2dkSDiw](http://apple.co/2dkSDiw)

In this section, you'll add data source prefetching to EmojiRater. If you haven't worked with collection views in the past, you'll want to check out our UICollectionView Tutorial series first: [bit.ly/2d2njWi](http://bit.ly/2d2njWi)

The folder titled **prefetch-starter** contains the starter project for this section. Open **EmojiRater.xcodeproj** and get ready to super charge your a collection view!

### Implementing UICollectionViewDataSourcePrefetching

First, take a quick peek at EmojiRater to familiarize yourself with the starter. In this section, you'll focus on **EmojiCollectionViewController.swift**, which contains a collection view controller that displays `EmojiCollectionViewCell` objects. These cells currently just display an emoji.

The cells are configured in `collectionView(_:willDisplay:forItemAt:)`, where `loadingOperations` provide the content. `loadingOperations` is a dictionary keyed by `indexPath` with a `DataLoadOperation` value. This value is an `Operation` subclass that loads the emoji content and provides the result in `emojiRating`.

When `collectionView(_:willDisplay:forItemAt:)` is triggered, `DataLoadOperation` objects get enqueued with their associated `indexPath`. Notice `collectionView(_:willDisplay:forItemAt:)` attempts to check for an existing operation before kicking one off. Currently that situation won't occur, because operations are only created here, but you'll soon change that.

Build and run, and scroll around the collection view at a brisk pace. You'll see a lot of place holder views with activity indicators as cells first appear.

![bordered iphone](./images/loading-views.png)

>**Note**: The project simulates what you might experience with images loaded from a remote location, or requiring expensive pre-processing. Open **DataStore.swift** and take a look at `DataLoadOperation` if you'd like to see how. 
>
>This is the `Operation` used for loading `EmojiRating` objects, which consist of an emoji and a rating in strong format. It simply introduces a random delay with a `usleep` before calling the completion handler.

With such slow loading cells, scrolling around is not a friendly user experience. You're going to improve this by kicking off data load operations in the pre-fetcher.

Open **EmojiCollectionViewController.swift** and add the following extension at the bottom of the file:

```swift
extension EmojiCollectionViewController: UICollectionViewDataSourcePrefetching {
  func collectionView(_ collectionView: UICollectionView,
                      prefetchItemsAt indexPaths: [IndexPath]) {
    print("Prefetch: \(indexPaths)")
  }
}
```

The `EmojiCollectionViewController` now conforms to `UICollectionViewDataSourcePrefetching` by implementing the sole required method, `collectionView(_:prefetchItemsAt:)`. 

When the collection view anticipates the need for specific cells, it sends this method an array of index paths representing those cells. For now, the method simply prints the passed index paths so you can get a feel for how pre-fetching works.

Now find `viewDidLoad()` and add the following near the top, just below the call to `super`:

```swift
collectionView?.prefetchDataSource = self
```

This sets `EmojiCollectionViewController` as the `prefetchDataSource`, allowing the collection view to call the newly defined `collectionView(_:prefetchItemsAt:)` as needed.

Build and run and check the console output. Without touching anything in the collection view, you should already see something like this:

```
Prefetch: [[0, 8], [0, 9], [0, 10], [0, 11], [0, 12], [0, 13]]
```

In this case, cells 0 through 7 were presented on the initial load, as the iPhone 6s simulator fit 8 cells. The collection view is smart enough to know that, being at the top, the only place the user has to go is down. With that in mind, it requests cells 8 through 13, hoping to pre-load 3 rows.

Play around a bit, and you'll notice patterns to what requests the pre-fetcher receives. Your scroll speed impacts how many cells are requested at a time - the faster you scroll, the more cells get requested per call. And as you might expect, your scroll direction or proximity to the start or end of the collection determine which cells are upcoming.

Since the upcoming cells don't exist yet, you can't configure them. What you can do is tackle the time consuming part of the work - loading the data so it's ready when the cells are needed. You'll do this by kicking off a `DataLoadOperation`, which the existing architecture will check for and load from when available.

Change the contents of `collectionView(_:prefetchItemsAt:)` to the following:

```swift
// 1
for indexPath in indexPaths {
  // 2
  if let _ = loadingOperations[indexPath] {
    continue
  }
  // 3
  if let dataLoader = dataStore.loadEmojiRating(at: indexPath.item) {
    loadingQueue.addOperation(dataLoader)
    loadingOperations[indexPath] = dataLoader
  }
}
```

The method now kicks off data loader operations for the upcoming data. Here's a closer look:

1. The `indexPaths` array is in priority order, with the most urgent item appearing first. You'll kick off load operations in that order.
2. `loadingOperations` is a dictionary of `DataLoadOperation` objects keyed by `indexPath`. `DataLoadOperation` is a custom Operation that loads the emoji and its rating. This code checks to see if an operation already exists for this `indexPath`, and skips over it with a `continue` if so. 
3. `loadEmojiRating(at:)` creates a `DataLoadOperation` to fetch data for the EmojiRating corresponding to the passed `indexPath.item`. The operation then gets added to the `loadingQueue` operation queue, in line with other requests. The new loader is added to `loadingOperations` using the item's `indexPath` as a key. This allows easy lookups of operations from the data source.

Putting it together - you're now kicking off loaders as the pre-fetcher requests them. When a cell is configured, the data source checks the loaders for emojis. This should result in fewer placeholders when the user scrolls.

Build and run, and let the initial cells load. Now slowly scroll the collection view and you'll notice the majority of cells load immediately upon display.

![bordered iphone](./images/prefetched-cells.png)

Usability is drastically improved thanks to pre-fetching.

Of course, kicking off requests based on predictions of future behavior can backfire. Consider a user steadily scrolling down in a collection, and the pre-fetcher accordingly requesting downstream items. If the user suddenly starts scrolling up instead, there are likely to be items in the pre-fetch queue that won't be required.

Because upstream items are now more urgent than the downstream ones already in the queue, it would be ideal to cancel the unneeded requests. This is why `collectionView(_:cancelPrefetchingForItemsAt:)` exists. In the case described, it would get called with the unneeded downstream indexPaths, and the associated operations would be canceled to free up resources.

Add the following in your `UICollectionViewDataSourcePrefetching` extension:

```swift
func collectionView(_ collectionView:
  UICollectionView, cancelPrefetchingForItemsAt indexPaths:
  [IndexPath]) {
  for indexPath in indexPaths {
    if let dataLoader = loadingOperations[indexPath] {
      dataLoader.cancel()
      loadingOperations.removeValue(forKey: indexPath)
    }
  }
}
```

If a loading operation exists for a passed `indexPath`, this code cancels it and then deletes it from `loadingOperations`.

Build and run, then scroll around a bit. You won't notice any difference in behavior, because at most unneeded operations will be canceled. Keep in mind that the algorithm is fairly conservative, so a change in direction won't guarantee cancel triggers - it depends on a number of factors.

The benefits of prefetching are evident even for a light weight application with limited content like EmojiRater. For apps loading large collections that require a lot of time to load, this feature will have an enormous impact!

The folder titled **prefetch-final** contains the final project for this section. To learn more about Data Source Prefetching, check out the 2016 WWDC video on UICollectionView here: [apple.co/2cKuW1z](http://apple.co/2cKuW1z)

## UIPreviewInteraction

iOS 9 introduced 3D Touch along with an interaction you know and love - Peek and Pop. The Peek (known as Preview to the API) provides a preview of a destination controller, while the Pop (Commit) navigates to the controller. While you can control the content and quick actions displayed with Peek and Pop, you can't customize the look of the transition or how users interact with it.

In iOS 10, the all new **UIPreviewInteraction** API allows you to create custom preview interactions similar in concept to Peek and Pop. Generically, a preview interaction consists of up to two interface states accessed by steadily increasing pressure of a 3D Touch. Unique haptic feedback is provided to signal the end of each state to the user.  

These interactions are not limited to navigation, as Peek and Pop is. Preview is the first state, and is where you animate your content and interface into view. The commit state occurs next, and is where you allow interaction with the presented content. 

Below is an example of the two states followed by the outcome you'll implement with EmojiRater.

![width=100%](./images/preview-interaction-example.png)

The preview state slowly fades out the background and focuses on the selected cell, finally placing thumb controls over the emoji. In the commit state, moving your finger will toggle selection between the two thumbs. Once you press deeper to commit the rating, the interaction fades away and the the cell displays the new rating.

To implement this, you need to configure a `UIPreviewInteractionDelegate` - an object that receives messages as progress and state transitions occur. Let's take a look at the protocol methods to get a bit more clarity on how it works:

- **previewInteractionShouldBegin(_:)** is called when 3D Touch kicks off a preview. This is where you'd start preparations for presenting the preview - such as configuring an animator.
- **previewInteraction(_:didUpdatePreviewTransition:ended:)** is called as the preview state progresses. It receives a value from 0.0 to 1.0 representing the user's progress through the state. The `ended` boolean switches to `true` when the value reaches 1.0 and the preview state completes.
- **previewInteractionDidCancel(_:)** is called when the preview is canceled - either by the user removing their finger before it ends, or from an interruption like a phone call. When this message is received, the implementation must gracefully dismiss the preview.
- **previewInteraction(_:didUpdateCommitTransition:ended:)** is called as the commit state progresses. It works identically to its preview counterpart in terms of the parameters it receives. When this state ends, action must be taken based on whatever control the user force touched to commit.

You'll need a 3D Touch capable phone for this section - so have your iPhone 6s or newer at the ready. If you completed the pre-fetching section, you can continue with that project. If not, the folder titled **previewInteraction-starter** contains the starter project. 

Open **EmojiRater.xcodeproj**, set your development team in the EmojiRater target, and get ready to be strangely judgmental about emojis! :]

### Exploring UIPreviewInteractionDelegate

You'll start off getting a feel for how `UIPreviewInteractionDelegate` methods get called by implementing them with some logging.

Open **EmojiCollectionViewController.swift** and add the following to the properties at the top of `EmojiCollectionViewController`:

```swift
var previewInteraction: UIPreviewInteraction?
```

`UIPreviewInteraction` objects are responsible for responding to 3D Touches on their associated view. You'll create one shortly.

Find `viewDidLoad()` where `ratingOverlayView` is created and added to the controller's view. `ratingOverlayView` is responsible for the interaction interface. It creates a background blur and focuses on a single cell, which it overlays with rating controls.

Find the `if let` that unwraps `ratingOverlayView`, and add the following at the bottom:

```swift
if let collectionView = collectionView {
  previewInteraction = UIPreviewInteraction(view: collectionView)
  // TODO - set delegate
}
```

`collectionView` is connected to a new `UIPreviewInteraction` to enable the rating interaction for cells. You've left a `TODO` here to set a delegate, which you'll do after configuring one.

Add the following extension at the end of the file:

```swift
extension EmojiCollectionViewController: UIPreviewInteractionDelegate {
  func previewInteraction(_ previewInteraction:
    UIPreviewInteraction, didUpdatePreviewTransition
    transitionProgress: CGFloat, ended: Bool) {
    print("Preview: \(transitionProgress), ended: \(ended)")
  }

  func previewInteractionDidCancel(_ previewInteraction:
    UIPreviewInteraction) {
    print("Canceled")
  }
}
```

`EmojiCollectionViewController` now adopts the `UIPreviewInteractionDelegate` protocol and implements its two required methods. For now, you're printing some info so you can get a better understanding of how collection view calls these methods. One prints progress during the preview state, and the other indicates cancellation of preview.

Head back to `viewDidLoad()`, and replace the `TODO - set delegate` comment with: 

```swift
previewInteraction?.delegate = self
```

Your `EmojiCollectionViewController` is now the `UIPreviewInteractionDelegate`. 3D Touches on the `collectionView` will now trigger the protocol methods you implemented.

Build and run on your device. 3D touch one of the cells and watch the console as you increase your touch pressure, up until you feel haptic feedback. It should look something like this:

```xml
Preview: 0.0, ended: false
Preview: 0.0970873786407767, ended: false
Preview: 0.184466019417476, ended: false
Preview: 0.271844660194175, ended: false
Preview: 0.330097087378641, ended: false
Preview: 0.378640776699029, ended: false
Preview: 0.466019417475728, ended: false
Preview: 0.543689320388349, ended: false
Preview: 0.631067961165048, ended: false
Preview: 0.747572815533981, ended: false
Preview: 1.0, ended: true
Canceled
```

The preview state progresses from 0.0 to 1.0 as you increase pressure. When the progress hits 1.0, `ended` is set to `true` - indicating preview has completed. Once you remove your finger, you'll see *Canceled*, indicating a call to `previewInteractionDidCancel(_:)`.

You probably recall `UIPreviewInteractionDelegate` also has two optional methods - one to signify the start of preview and one to track progress in the commit state. With your plans for EmojiRater, both will come in handy, so let's test them out! 

Add the following to the bottom of the `UIPreviewInteractionDelegate` extension:

```swift
func previewInteractionShouldBegin(_ previewInteraction:
  UIPreviewInteraction) -> Bool {
  print("Preview should begin")
  return true
}

func previewInteraction(_ previewInteraction:
  UIPreviewInteraction, didUpdateCommitTransition
  transitionProgress: CGFloat, ended: Bool) {
  print("Commit: \(transitionProgress), ended: \(ended)")
}
```

`previewInteractionShouldBegin(_:)` triggers when the preview kicks off. You print that this is happening, and return `true` to allow the preview to begin. `previewInteraction(:_didUpdateCommitTransition:ended:)` works identically to its preview state counterpart, and you've implemented similar prints here.

Build and run, then progress through the preview and commit states while watching the console. You'll feel one style of haptic feedback when preview completes, and then another when commit does.

```xml
Preview should begin
Preview: 0.0, ended: false
Preview: 0.567567567567568, ended: false
Preview: 1.0, ended: true
Commit: 0.0, ended: false
Commit: 0.252564102564103, ended: false
Commit: 0.340009067814572, ended: false
Commit: 0.487818348221377, ended: false
Commit: 0.541819501609486, ended: false
Commit: 0.703165992497785, ended: false
Commit: 0.902372307312938, ended: false
Commit: 1.0, ended: true
```

The *Preview should begin* line indicates `previewInteractionShouldBegin(_:)` was triggered as soon as the touch started. Preview progresses as before, followed by commit in a similar fashion. When complete, the commit progress is 1.0 and its `ended` property becomes `true`.

### Implementing a custom interaction 

Now that you have a better feel for the flow of these delegate calls, you're just about ready to set up the custom interaction.

First, you'll build a helper method to get the cell associated with an interaction. Add the following method to the bottom of the `UIPreviewInteractionDelegate` extension:

```swift
func cellFor(previewInteraction: UIPreviewInteraction)
  -> UICollectionViewCell? {
  if let indexPath = collectionView?
    .indexPathForItem(at: previewInteraction
      .location(in: collectionView!)),
    let cell = collectionView?.cellForItem(at: indexPath) {
    return cell
  } else {
    return nil
  }
}
```

`cellFor(previewInteraction:_)` takes a `UIPreviewInteraction` and returns the `UICollectionViewCell` where it originated.

The `UIPreviewInteraction` method `location(in:)` returns a CGPoint that identifies touch position within the passed coordinate space. You use this to find the location of the touch in `collectionView`. 

You pass that position to `indexPathForItem(at:)` to get the `indexPath` of the cell. You use `cellForItem(at:)` to obtain the cell with that `indexPath`. Finally, you return the `cell` if successful or nil if not.

It's time to implement the interaction, and the beginning seems like a good place to start! :]  Update the contents of `previewInteractionShouldBegin(_:)` to match the following:

```swift
// 1
guard let cell = cellFor(previewInteraction:
  previewInteraction) else {
  return false
}

// 2
ratingOverlayView?.beginPreview(forView: cell)
collectionView?.isScrollEnabled = false
return true
```

Here's more detail on what you're doing now:

1. You pass the `previewInteraction` associated with the touch that started the interaction to `cellFor(previewInteraction:_)`. If unable to retrieve the originating `cell`, you return `false` to prevent the preview from occurring.
2. `ratingOverlayView` is a full screen overlay you'll use to animate the preview control in place. `beginPreview(forView:)`, included in the starter, prepares a `UIViewPropertyAnimator` on the `ratingOverlayView` to blur the background and focus on the cell involved in the interaction. Scrolling of the collection view is then disabled to keep focus on the interaction. Returning `true` allows the preview to proceed.

Next, you need to handle progress through the preview state. Replace the contents of `previewInteraction(_:didUpdatePreviewTransition:ended:)` with the following:

```swift
ratingOverlayView?.updateAppearance(forPreviewProgress:
  transitionProgress)
```

`updateAppearance(forPreviewProgress:)`, included in the starter, updates the `UIViewPropertyAnimator` object's `fractionComplete` based on the passed `transitionProgress`. This causes the animation to progress in step with the preview interaction's process. This is a great example of how preview interaction progress indicators work seamlessly with other elements of UIKit for transitions.

Build and run, and press lightly on one of the cells. You'll see the preview state animate in, but you'll also notice something weird. Once you lift your finger, or the animation completes - it freezes in place.

![bordered iphone](./images/forzen-animation.png)

Take a quick look at the console. You'll see the app logging *Canceled*, and this should start to make sense. You started animating in an interface based on interaction, but you didn't clean up the interface when the interaction ended.

![width=40%](./images/ragecomic-cleanup.png)

The main purpose of the `previewInteractionDidCancel(_:)` method is to do this very clean up. Replace its contents with the following:

```swift
ratingOverlayView?.endInteraction()
collectionView?.isScrollEnabled = true
```

The `endInteraction()` method in `ratingOverlayView` reverses the animation to bring the view back to its prior state. Scrolling is also reenabled on the collection view so that it can function as normal.

Build and run, and test preview again - in other words, only up until the first tactile feedback. Now you'll be able to fade in the controls, and they fade back out when the operation is canceled. Much better!

![width=75%](./images/cancel-working.png)

You might have noticed something is still off. If you push through to the second tactile feedback, then tap away, the animation just disappears. This is because you've implemented the optional commit protocol method, but you're not doing anything with it.
 
A control that doesn't do anything is about as useful as a windsock emoji! :] So replace the contents of `previewInteraction(_:didUpdateCommitTransition:ended:)` with the following:

```swift
let hitPoint = previewInteraction.location(in: ratingOverlayView!)

if ended {
  // TODO commit new rating
} else {
  ratingOverlayView?.updateAppearance(forCommitProgress:
    transitionProgress, touchLocation: hitPoint)
}
```

This first determines where the user is touching `ratingOverlayView` and stores it in `hitPoint`. You'll use this to determine how the user is interacting with the control.

If the commit has ended, you need to commit the new rating and dismiss the preview. You've added a `TODO` for this that you'll circle back to shortly. 

`updateAppearance(forCommitProgress:touchLocation:)` is called to update the interface if the commit is in progress. This method toggles highlighting of the rating views based on the `hitPoint`. This provides visual feedback to the user on what proceeding with the commit would do.

Build and run, and this time press past the preview haptic feedback and into the commit state. You'll see the rating views highlight as you move your finger between the top and bottom of a cell.

![width=35% bordered](./images/commit-rating.png) 

But you still haven't quite reached your goal of rating those wind socks! Committing the rating doesn't do anything yet, as you need to get back to your TODO.

You'll create a new method to handle the final commit input first. Add the following method at the end of your extension:

```swift
func commitInteraction(_ previewInteraction:
  UIPreviewInteraction, hitPoint: CGPoint) {
  
  // 1
  let updatedRating = ratingOverlayView?
    .completeCommit(at: hitPoint)
  
  // 2
  guard let cell = cellFor(previewInteraction:
    previewInteraction) as? EmojiCollectionViewCell,
    let oldEmojiRating = cell.emojiRating else {
      return
  }
  
  // 3
  let newEmojiRating = EmojiRating(emoji: oldEmojiRating.emoji,
                                   rating: updatedRating!)
  dataStore.update(emojiRating: newEmojiRating)
  cell.updateAppearanceFor(newEmojiRating)
  collectionView?.isScrollEnabled = true
}
```

`commitInteraction(_:hitPoint:)` locates the EmojiRating associated with the item at `hitPoint`, and updates it with whichever rating was just selected. Here's a closer look at the code that does this:

1. `completeCommit(at:)` identifies which rating appears on `ratingOverlayView` at the passed `hitPoint` and passes it back as a string (👍 or 👎). In addition, this method animates the preview interface away, with the same code `previewInteractionDidCancel(_:)` leverages.
2. The `oldEmojiRating` is pulled from the `cell` identified using `cellFor(previewInteraction:)`. This is needed for updating, and if it can't be found, the guard returns early.
3. `newEmojiRating` is created using the old emoji and the `updatedRating`, then saved to the `dataStore`. `updateAppearanceFor(_:)` is called to update the cell with the new rating. Scrolling is then re-enabled.

Now you just need to call this method when the commit is complete. In `previewInteraction(_:didUpdateCommitTransition:ended:)` replace the `TODO commit new rating` comment with the following:

```swift
commitInteraction(previewInteraction, hitPoint: hitPoint)
```

This calls the method you just created with the necessary parameters.

Now build and run, and commit some emoji ratings. You'll now be able to select a thumbs up or down, feel the tactile feedback when it commits, and see your vote show up on the cell.

![width=75%](./images/working-commit.png) 

You've now implemented both stages of a preview interaction, and acted on the results of the action. This API, along with things like UIKit animations and UIViewController transitions provide limitless possibilities for 3D Touch initiated interactions. You'll certainly find more creative ways to rate hamburger emojis with what you've learned! :]

The folder titled **previewInteraction-final** contains the final project for this section. To learn more about UIPreviewInteraction, check out the 2016 WWDC video on 3D Touch here: [apple.co/2djvSOA](http://apple.co/2djvSOA)

## Haptic feedback

Apple introduced two new devices in September 2016 - the iPhone 7 and iPhone 7 Plus - that use a new Taptic Engine. The new engine provides a wider range of more sophisticated haptic feedback. 

Haptic feedback has been leveraged throughout iOS 10, where new types of feedback signify different actions. For example, there is a selection feedback that emits when scrolling a picker wheel.

Along with the new hardware, Apple unveiled APIs to allow developers to use it in their apps. **UIFeedbackGenerator** has three concrete subclasses, each with unique haptic feedback. Here they are: 

- Supplemented by visuals, **UIImpactFeedbackGenerator** indicates an impact has occurred between two user interface elements. For example, you might use this feedback when an animation completes, snapping some object into place against a boundary.
- **UINotificationFeedbackGenerator** indicates a task has completed. For instance, uploading a message or building a new unit in a game might use this feedback. Any action that involves some type of short delay with the need for notification is a good candidate.
- **UISelectionFeedbackGenerator** indicates selection changes. For instance, scrolling through a menu might produce selection feedback each time a new item becomes selected.

Using these generators is dead simple. Below is an example of how to generate impact feedback:

```swift
let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
feedbackGenerator.impactOccurred()
```

Here a `UIImpactFeedbackGenerator` is created with a `heavy` feedback style. The style reflects the weight of objects involved in the impact. Triggering the feedback is as easy as calling `impactOccurred()`.

>**Note**: There are three `UIImpactFeedbackStyle` enum cases: heavy, light and medium. The style is meant to reflect the relative *weight* of objects involved in the collision. As you'd expect, heavy produces the strongest haptic feedback.

Both haptic feedback and 3D Touch were designed to add another dimension to iOS. Apple has set the stage for adoption of these features by embracing them throughout iOS and their own apps. With the ease of implementation, it makes a lot of sense to take the cue and add haptic feedback to your feature list. 

In this section, you'll trigger each of the feedback generators when the collection view in EmojiRater scrolls to the top. To experience it, you'll need an iPhone 7 or 7 Plus, and about five minutes! :]

If you completed the section on preview interactions, you can continue with that project. If not, the folder titled **haptic-starter** contains the starter project for this section. Open **EmojiRater.xcodeproj**, set your development team for the EmojiRater target, and you're already halfway done!

### Implementing UIFeedbackGenerator

Open **EmojiCollectionViewController.swift** and the following method to the `EmojiCollectionViewController` extension indicated with a `UICollectionViewDelegate` mark:

```swift
override func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
  let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
  feedbackGenerator.impactOccurred()
}
```

This code overrides the `scrollViewDidScrollToTop(_:)` method found in `UIScrollViewDelegate`, which your collection view implements. The method triggers when a user taps the status bar to scroll to the top of the collection view.

A `UIImpactFeedbackGenerator` is created with the `heavy` style feedback. Impact feedback is suitable here, as the scrollview hitting the top of its offset results in a visual collision between the collection view content and status bar. `impactOccurred()` is called to trigger the impact feedback.

Build and run, scroll down a bit in the collection view, and then tap the status bar to return to the top. Once scrolling finishes, you'll feel the heavy impact feedback. Feel free to experiment with `medium` and `light` `UIImpactFeedbackStyle` to note the difference in feel.

![bordered iphone](./images/tap-status-bar.png)

While `UIImpactFeedbackGenerator` is the most logical for this interaction, you're going to swap in the remaining two types to experience their feel.

Replace the contents of `scrollViewDidScrollToTop(_:)` with the following:

```swift
let feedbackGenerator = UINotificationFeedbackGenerator()
feedbackGenerator.notificationOccurred(.success)
```

A `UINotificationFeedbackGenerator` is created and then triggered with `notificationOccurred()`. `success` plays feedback that indicates a task succeeded. Other options include `error` and `warning`, all with unique feedback that users will eventually become accustomed to with use.

Build and run, scroll down and hit the status bar. You'll experience a different haptic response, indicating success. Feel free to test again with the other two statuses to get a feel for them.

The last type is `UISelectionFeedbackGenerator`, which is not at all applicable for this scroll, but is worth a test drive :]  Replace the contents of `scrollViewDidScrollToTop(_:)` once more with the following:

```swift
let feedbackGenerator = UISelectionFeedbackGenerator()
feedbackGenerator.selectionChanged()
```

The `UISelectionFeedbackGenerator` is triggered by `selectionChanged()` to indicate a new selection has occurred. Unlike the other `UIFeedbackGenerator` classes, it accepts no options and provides only a single type of haptic feedback.

Test it out, and once again make a mental note of the feel. This should be familiar if you've set any timers in iOS.

`UIFeedbackGenerator` is a very simple API, but an important one. As users become more accustomed to this additional dimension in interface feedback, you'll benefit if your apps follow Apple's lead!

>**Note**: Keep in mind that haptic feedback is only available on the iPhone 7 and 7 Plus. Even on those devices, feedback may not occur depending on battery levels, user's settings, and app status. Haptic feedback is designed to supplement visual indicators, in great part for these reasons.

The folder titled **haptic-final** contains the final project for this section. A feedback generator is enabled by default, but the other styles are provided in comments. For more details on `UIFeedbackGenerator`, including best practices, check out the API Reference here: [apple.co/2cVBAW7](http://apple.co/2cVBAW7)

## Where to go from here

iOS 10 is, by most metrics, a huge release. While it wasn't anything like the major overhaul of iOS 7, it has notably improved or matured features throughout the SDK. Data source prefetching, preview interactions, and haptic feedback are just a few examples of the added niceties not covered in prior chapters.

If you haven't already, it's always a great idea to read through the What's New in iOS developer notes. Here they are for iOS 10: [apple.co/2coIGCr](http://apple.co/2coIGCr). You'll undoubtedly pick up a gem or two that will improve your code or enhance your app.

This likely goes without saying, but the same is true of watching WWDC videos on any APIs or tools you work with. They are great places to pick up little tidbits of wisdom you may not see elsewhere: [apple.co/1YtgQWy](http://apple.co/1YtgQWy)

There's only one thing left to do...

![width=40%](./images/ios10-the-things.png)