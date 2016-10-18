```metadata
author: "By Jeff Rames"
number: "14"
title: "Chapter 14: Other iOS 10 Topics"
```
  
# Chapter 14: Other iOS 10 Topics

iOS 10 introduced many high profile features such as iMessage apps and SiriKit; it includes major enhancements to user notifications, Core Data, search, photography and numerous other topics that you’ve read about in this book.

But what you _haven’t_ seen are the smaller ways iOS 10 has improved. Every major framework has had notable updates, so regardless of the app you’re working on, you have an opportunity to improve performance, architect better code, or delight your users with new features.

Many of these changes are too small to warrant a chapter of their own, but a few are notable enough that we felt we just had to share them with you. This chapter focuses on three bite-sized iOS 10 topics that many will find useful:

- **Data Source Prefetching**: Improves the responsiveness of your app by kicking off data processing well before a cell displays on the screen.
- **UIPreviewInteraction**: A new protocol that allows for custom interactions via 3D Touch.
- **Haptic Feedback**: An all-new feature tied to new hardware in the iPhone 7 and 7 Plus. The API provides the ability to produce several unique types of feedback.

## Getting started

This chapter is designed a bit differently than others. Each topic gets its own mini chapter, including a high-level introduction with a starter project so you’re ready to dive in. 

This lets you go only as deep as you want on the topics that interest you. Feel free to choose one of these three options:

1. **Start to finish**. The first option is to read from start to finish as you would any other chapter. Each topic works with the same sample project.
2. **Skip ahead.** Alternatively you could skip to any section that interests you and complete it in tutorial fashion. Starter and completed projects are included for each section, so you don’t need to worry about getting up to speed.
3. **Skim**. Finally you could read just the introduction of each section to get a high level understanding of these three topics. You can always return later for a deeper dive of the section.

All sections work with an app called EmojiRater that consists of a collection view displaying various emojis. 

![bordered iphone](./images/emoji-rater.png)

You’ll give the collection view a speed boost in the section on prefetching. You’ll then add the ability to rate emojis during the preview interaction section. Finally, you’ll feel the result of haptic feedback in your app as the user scrolls to the top of the collection view.

## Data source prefetching

In this section, you’ll add data source prefetching to EmojiRater. If you haven’t worked with collection views in the past, you’ll want to check out our UICollectionView Tutorial series first: [bit.ly/2d2njWi](http://bit.ly/2d2njWi)

The folder titled **prefetch-starter** contains the starter project for this section. Open **EmojiRater.xcodeproj** and get ready to super charge your collection view!

Data source prefetching provides a mechanism for preparing data before you need to display it. Consider an app with cells containing remotely housed images. You could drastically reduce the apparent loading delays with a prefetch that kicks off download operations.

A new data source protocol — **UICollectionViewDataSourcePrefetching** — is responsible for prefetching. The protocol defines only two methods:

- **collectionView(_:prefetchItemsAt:)**: This method is passed index paths for cells to prefetch, based on current scroll direction and speed. The items are ordered from most urgent to least, based on when the collection view anticipates needing them. Usually you will write code to kick off data operations for the items in question here.
- **collectionView(_:cancelPrefetchingForItemsAt:)**: An optional method that triggers when you should cancel prefetch operations. It receives an array of index paths for items that the collection view once anticipated, but no longer needs. This might happen if the user changes scroll directions.

For large data sources with content that is time consuming to prepare, implementing this protocol can have a dramatic impact on user experience. Of course, it isn’t magic — it simply takes advantage of down time and guesses what will be needed next. If a user starts scrolling very quickly, or resources become limited, prefetch requests will slow or stop.

>**Note**: Fret not, table view users! If you are using a table view instead of a collection view, you can get similar behavior by implementing the **UITableViewDataSourcePrefetching** protocol. I recommend that you follow along here to learn the general idea behind prefetching, and then check out the API doc for table view specific syntax: [apple.co/2dkSDiw](http://apple.co/2dkSDiw)

### Implementing UICollectionViewDataSourcePrefetching

Take a quick peek at EmojiRater to familiarize yourself with the starter project. In this section, you’ll focus on **EmojiCollectionViewController.swift**, which contains a collection view controller that displays `EmojiCollectionViewCell` objects. These cells currently just display an emoji.

The cells are configured in `collectionView(_:willDisplay:forItemAt:)`, where `loadingOperations` provide the content. `loadingOperations` is a dictionary keyed by `indexPath` with a `DataLoadOperation` value. This value is an `Operation` subclass that loads the emoji content and provides the result in `emojiRating`.

When `collectionView(_:willDisplay:forItemAt:)` is triggered, `DataLoadOperation` objects enqueue with their associated `indexPath`. Notice `collectionView(_:willDisplay:forItemAt:)` attempts to check for an existing operation before kicking one off. Currently that situation won’t occur, because currently the only method that creates operations is `collectionView(_:willDisplay:forItemAt:)`.

Build and run, and scroll around the collection view at a brisk pace. You’ll see a lot of place holder views containing activity indicators as cells first appear.

![bordered iphone](./images/loading-views.png)

The project simulates what you might experience while loading images from a remote location, or retrieving data that requires expensive pre-processing. Open **DataStore.swift** and take a look at `DataLoadOperation` if you’d like to see how. 

This is the `Operation` used for loading `EmojiRating` objects, which consist of an emoji and a rating in strong format. It simply introduces a random delay with a `usleep` before calling the completion handler.

Scrolling around isn’t a user-friendly experience since the cells load so slowly. You’re going to improve this by kicking off data load operations in the prefetcher.

Open **EmojiCollectionViewController.swift** and add the following extension to the bottom of the file:

```swift
extension EmojiCollectionViewController: UICollectionViewDataSourcePrefetching {
  func collectionView(_ collectionView: UICollectionView,
                      prefetchItemsAt indexPaths: [IndexPath]) {
    print("Prefetch: \(indexPaths)")
  }
}
```

The `EmojiCollectionViewController` now conforms to `UICollectionViewDataSourcePrefetching` by implementing the one required method: `collectionView(_:prefetchItemsAt:)`. 

When the collection view anticipates the need for specific cells, it sends this method an array of index paths representing those cells. For now, the method simply prints the passed index paths so you can get a feel for how prefetching works.

Now find `viewDidLoad()` and add the following near the top, just below the call to `super`:

```swift
collectionView?.prefetchDataSource = self
```

This sets `EmojiCollectionViewController` as the `prefetchDataSource` so the collection view can call the newly defined `collectionView(_:prefetchItemsAt:)` as needed.

Build and run and check the console output. Without touching anything in the collection view, you should already see something like this:

```none
Prefetch: [[0, 8], [0, 9], [0, 10], [0, 11], [0, 12], [0, 13]]
```

Cells 0 through 7 present on the initial load, since the iPhone 6s simulator fits 8 cells. The collection view is smart enough to know that the user is at the top of the list, so the only place to go is down. With that in mind, the collection view requests cells 8 through 13, hoping to preload 3 rows. 

Play around a bit, and you’ll notice patterns to the requests made to the prefetcher. Your scroll speed affects the number of cells requested; scrolling faster requests more cells. Your scroll direction, coupled with how close you are to the start or end of the collection, also help determine which cells to prefetch.

Since the upcoming cells don’t yet exist, you can’t configure them. What you _can_ do is tackle the time consuming part of the work: loading the data to be ready when the cells are. You’ll kick off a `DataLoadOperation`; the existing architecture will check for this and load from it when it’s available.

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

The method now kicks off data loader operations for the upcoming data. Here’s a closer look:

1. `indexPaths` is in priority order, with the most urgent item appearing first. You’ll kick off load operations in that order.
2. `loadingOperations` is a dictionary of `DataLoadOperation` objects keyed by `indexPath`. `DataLoadOperation` is a custom operation that loads the emoji and its rating. This code checks to see if an operation already exists for this `indexPath`; if so, it skip the operation with `continue`. 
3. `loadEmojiRating(at:)` creates a `DataLoadOperation` to fetch data for the EmojiRating corresponding to the passed `indexPath.item`. You then add the operation to the `loadingQueue` operation queue, in line with other requests. Finally, you add the new loader to `loadingOperations` using the item’s `indexPath` as a key for easy lookups of operations.

You’re now kicking off loaders as the prefetcher requests them. When a cell is configured, the data source checks the loaders for emojis. This should result in fewer placeholders when the user scrolls.

Build and run, and let the initial cells load. Now slowly scroll the collection view and you’ll notice the majority of cells load immediately:

![bordered iphone](./images/prefetched-cells.png)

Usability is much better, thanks to prefetching.

User behavior can also change suddenly, making prefetched elements obsolete. Consider a user scrolling steadily through a collection, with the prefetcher happily requesting downstream items. If the user suddenly starts scrolling up instead, there are likely to be items in the prefetch queue that won’t be required.

Because upstream items are now more urgent than the downstream ones already in the queue, you’d want to cancel any unnecessary requests. Calling `collectionView(_:cancelPrefetchingForItemsAt:)` with the unneeded downstream indexPaths cancels the associated operations to free up resources.

Add the following to your `UICollectionViewDataSourcePrefetching` extension:

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

Build and run, then scroll around a bit. You won’t notice any difference in behavior, but rest assured any unneeded operations will be canceled. Keep in mind that the algorithm is fairly conservative, so a change in direction doesn’t guarantee operations will be removed — this depends on a number of factors private to Apple's algorithm.

The benefits of prefetching are evident even for a lightweight application like EmojiRater. You can imagine the impact for large collections that take a lot longer to load.

The folder titled **prefetch-final** contains the final project for this section. To learn more about Data Source Prefetching, check out the 2016 WWDC video on UICollectionView here: [apple.co/2cKuW1z](http://apple.co/2cKuW1z)

## UIPreviewInteraction

iOS 9 introduced 3D Touch along with an interaction you (hopefully) know and love — Peek and Pop. 

The Peek (known as Preview to the API) provides a preview of a destination controller, while the Pop (Commit) navigates to the controller. While you can control the content and quick actions displayed with Peek and Pop, you can’t customize the look of the transition or how users interact with it.

In iOS 10, the all new **UIPreviewInteraction** API lets you create custom preview interactions similar in concept to Peek and Pop. A preview interaction consists of up to two interface states that can be accessed by the steadily increasing pressure of a 3D Touch. Unique haptic feedback is provided to signal the end of each state to the user.  

Unlike Peek and Pop, these interactions are not limited to navigation. Preview is the first state; this is where you animate your content and interface into view. Commit is the second state; this is where you allow interaction with the content presented. 

Below is an example of the two states followed by the outcome you’ll implement with EmojiRater:

![width=100%](./images/preview-interaction-example.png)

The preview state slowly fades out the background, focuses on the selected cell and finally places voting controls over the emoji. In the commit state, moving your finger will toggle selection between the two thumbs. Press deeper to commit the rating; the interaction will fade away and the the cell will display the new rating.

To implement this, you need to configure an instance of `UIPreviewInteractionDelegate`; this is an object that receives messages from progress and state transitions.

Here’s a brief overview of the protocol methods:

- **previewInteractionShouldBegin(_:)**: Executes when 3D Touch kicks off a preview. This is where you would do anything required to present the preview, such as configuring an animator.
- **previewInteraction(_:didUpdatePreviewTransition:ended:)**: Executes as the preview state progresses. It receives a value from 0.0 to 1.0, which represents the user’s progress through the state. The `ended` boolean switches to `true` when the preview state completes and the value reaches 1.0.
- **previewInteractionDidCancel(_:)**: Executes when the preview is canceled, either by the user removing their finger before the preview ends, or from an outside interruption like a phone call. The implementation must gracefully dismiss the preview when it receives this message.
- **previewInteraction(_:didUpdateCommitTransition:ended:)**: Executes as the commit state progresses. It works identically to its preview counterpart and takes the same parameters. When this state ends, you must take action based on which control the user force-touched to commit.

You’ll need a 3D Touch capable phone for this section, so have your iPhone 6s or newer at the ready. If you completed the prefetching section, you can continue with that project. If not, the folder titled **previewInteraction-starter** contains the starter project. 

Open **EmojiRater.xcodeproj**, set your development team in the EmojiRater target, and get ready to be strangely judgmental about emojis! :]

### Exploring UIPreviewInteractionDelegate

You’ll start by implementing some `UIPreviewInteractionDelegate` methods and add a bit of logging to learn how they work.

Open **EmojiCollectionViewController.swift** and add the following to the properties at the top of `EmojiCollectionViewController`:

```swift
var previewInteraction: UIPreviewInteraction?
```

`UIPreviewInteraction` objects respond to 3D Touches on their associated view. You’ll create one shortly.

Find `viewDidLoad()` where you create `ratingOverlayView` and add it to the controller’s view. `ratingOverlayView` is responsible for the interaction interface; it creates a background blur and focuses on a single cell, which it then overlays with rating controls.

Find the `if let` that unwraps `ratingOverlayView`, and add the following underneath:

```swift
if let collectionView = collectionView {
  previewInteraction = UIPreviewInteraction(view: collectionView)
  // TODO - set delegate
}
```

`collectionView` is connected to a new `UIPreviewInteraction` to enable the rating interaction for cells. You’ve left a `TODO` here to set a delegate, which you’ll do after configuring one.

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

`EmojiCollectionViewController` now adopts the `UIPreviewInteractionDelegate` protocol and implements its two required methods. For now, you’re printing some info so you can get a better understanding of how collection view calls these methods. One prints progress during the preview state, and the other indicates cancellation of preview.

Head back to `viewDidLoad()`, and replace the `TODO - set delegate` comment with: 

```swift
previewInteraction?.delegate = self
```

Your `EmojiCollectionViewController` is now the `UIPreviewInteractionDelegate`. 3D Touches on the `collectionView` will now trigger the protocol methods you implemented.

Build and run on your device. 3D Touch one of the cells and increase your touch pressure until you feel some haptic feedback. Watch the console and you’ll see something like this:

```none
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

The preview state progresses from 0.0 to 1.0 as you increase pressure. When the progress hits 1.0, `ended` is set to `true` to indicate the preview is complete. Once you remove your finger, you’ll see `"Canceled"`; this comes from `previewInteractionDidCancel(_:)`.

`UIPreviewInteractionDelegate` has two optional methods: one to signify the start of preview, and one to track progress in the commit state.

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

`previewInteractionShouldBegin(_:)` triggers when the preview kicks off. You print a commit message and return `true` to let the preview start. `previewInteraction(:_didUpdateCommitTransition:ended:)` works much like its preview state counterpart.

Build and run, then progress through the preview and commit states while watching the console. You’ll feel one style of haptic feedback when preview completes, and a different style when the commit completes.

```none
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


The `Preview should begin` line indicates `previewInteractionShouldBegin(_:)` triggered as soon as the touch started. Preview progresses as before, followed by a commit in a similar fashion. When complete, the commit progress will be 1.0 and its `ended` property will become `true`.

### Implementing a custom interaction 

Now that you have a better feel for the flow of these delegate calls, you’re just about ready to set up the custom interaction.

First, you’ll build a helper method to associate the cell with an interaction. Add the following method to the bottom of the `UIPreviewInteractionDelegate` extension:

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

The `UIPreviewInteraction` method `location(in:)` returns a CGPoint that identifies the touch position within the passed-in coordinate space. You use this to find the location of the touch in `collectionView`. 

You pass that position to `indexPathForItem(at:)` to get the `indexPath` of the cell. You use `cellForItem(at:)` to obtain the cell with that `indexPath`. Finally, you return the `cell` if successful, or `nil` if not.

It’s time to implement the interaction. Update the contents of `previewInteractionShouldBegin(_:)` to match the following:

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

Here’s what you’re doing above:

1. You pass the `previewInteraction` associated with the touch that started the interaction to `cellFor(previewInteraction:_)`. If unable to retrieve the originating `cell`, you return `false` to prevent the preview from occurring.
2. `ratingOverlayView` is a full screen overlay you’ll use to animate the preview control in place. `beginPreview(forView:)`, included in the starter, prepares a `UIViewPropertyAnimator` on the `ratingOverlayView` to blur the background and focus on the cell involved in the interaction. You then disable collection view scrolling to keep the focus on the interaction. Returning `true` allows the preview to proceed.

Next, you need to handle progress through the preview state. Replace the contents of `previewInteraction(_:didUpdatePreviewTransition:ended:)` with the following:

```swift
ratingOverlayView?.updateAppearance(forPreviewProgress:
  transitionProgress)
```

`updateAppearance(forPreviewProgress:)`, included in the starter, updates the `UIViewPropertyAnimator` object’s `fractionComplete` based on the passed `transitionProgress`. This lets the animation progress in step with the preview interaction. This is a great example of how preview interaction progress indicators work seamlessly with other elements of UIKit for transitions.

Build and run, and press lightly on one of the cells. You’ll see the preview state animate in, but you’ll also notice something weird. Once you lift your finger, or the animation completes, it freezes in place.

![bordered iphone](./images/forzen-animation.png)

Take a quick look at the console. You’ll see `Canceled` in the log — does it make sense now? You started animating in an interface based on interaction, but you didn’t clean up the interface when the interaction ended.

![width=40%](./images/ragecomic-cleanup.png)

You should be cleaning this up in `previewInteractionDidCancel(_:)`. Replace its contents with the following:

```swift
ratingOverlayView?.endInteraction()
collectionView?.isScrollEnabled = true
```

`endInteraction()` in `ratingOverlayView` reverses the animation to bring the view back to its prior state. You also re-enable scrolling on the collection view so that it can function as normal.

Build and run, and test the preview just up to the first tactile feedback. The controls fade in, and fade back out when you cancel the operation. That’s much better!

![width=75%](./images/cancel-working.png)

Something is still off, though. Push through to the second tactile feedback, then tap away — and the animation just disappears. This is because you’ve implemented the optional commit protocol method, but you’re not doing anything with it.
 
Replace the contents of `previewInteraction(_:didUpdateCommitTransition:ended:)` with the following:

```swift
let hitPoint = previewInteraction.location(in: ratingOverlayView!)

if ended {
  // TODO commit new rating
} else {
  ratingOverlayView?.updateAppearance(forCommitProgress:
    transitionProgress, touchLocation: hitPoint)
}
```

This determines where the user is touching `ratingOverlayView`, and stores that touch location in `hitPoint`. You’ll use this to determine how the user is interacting with the control.

If the commit has ended, you need to commit the new rating and dismiss the preview. You’ve added a `TODO` for this action, which you’ll circle back to shortly. 

You call `updateAppearance(forCommitProgress:touchLocation:)` to update the interface if the commit is in progress. This method toggles highlighting of the rating views based on the `hitPoint`. This provides visual feedback to the user on what proceeding with the commit will do.

Build and run, and this time press past the preview haptic feedback and into the commit state. You’ll see the rating views highlight as you move your finger up and down a cell.

![width=35% bordered](./images/commit-rating.png) 

You still haven’t quite reached your goal of rating those wind socks! Committing the rating doesn’t do anything yet, as you need to get back to your TODO.

You’ll first create a new method to handle the final commit input. Add the following method to the end of your extension:

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

`commitInteraction(_:hitPoint:)` locates the EmojiRating associated with the item at `hitPoint` and updates it with the selected rating. Taking a closer look at this code:

1. `completeCommit(at:)` identifies which rating appears on `ratingOverlayView` at the passed `hitPoint` and passes it back as a string (👍 or 👎). In addition, this method animates away the preview interface using the same code that `previewInteractionDidCancel(_:)` does.
2. You get `oldEmojiRating` from the `cell` identified using `cellFor(previewInteraction:)`; if it can’t be found, the guard returns early.
3. You then create `newEmojiRating`, passing in the old emoji and `updatedRating`, then save it to `dataStore`. You also call `updateAppearanceFor(_:)` to update the cell with the new rating. Finally, you re-enable scrolling.

Now you simply need to call this method when the commit is complete. In `previewInteraction(_:didUpdateCommitTransition:ended:)`, replace the `TODO commit new rating` comment with the following:

```swift
commitInteraction(previewInteraction, hitPoint: hitPoint)
```

This calls the method you just created with the necessary parameters.

Build and run, and commit some emoji ratings by doing the following:

1. Slowly press down on a cell until you see the rating view appear and feel the first tactile feedback.
2. Select your rating, and press down harder to commit your choice until you feel the second tactile feedback.

At this point, you will see your vote show up on the cell:

![width=75%](./images/working-commit.png) 

You’ve now implemented both stages of a preview interaction, and acted on the results of the action. This API, along with things like UIKit animations and UIViewController transitions, provide limitless possibilities for 3D Touch initiated interactions. You’ll certainly find more creative ways to rate hamburger emojis with what you’ve learned! :]

The folder titled **previewInteraction-final** contains the final project for this section. To learn more about UIPreviewInteraction, check out the 2016 WWDC video on 3D Touch here: [apple.co/2djvSOA](http://apple.co/2djvSOA)

## Haptic feedback

The iPhone 7 and iPhone 7 Plus have a new Taptic Engine, which provides a wider range of sophisticated haptic feedback. 

Haptic feedback is leveraged throughout iOS 10; new types of feedback signify different actions. For example, there’s a selection feedback haptic that emits when scrolling a picker wheel.

Along with the new hardware, Apple unveiled APIs to allow developers to use the Taptic Engine in their apps. **UIFeedbackGenerator** has three concrete subclasses, each with unique haptic feedback: 

-  **UIImpactFeedbackGenerator** indicates an impact between two user interface elements. For example, you might use this feedback when an animation completes, snapping some object into place against a boundary.
- **UINotificationFeedbackGenerator** indicates a task has completed. For instance, uploading a message or building a new unit in a game might use this feedback. Any action that involves some type of short delay with the need for notification is a good candidate.
- **UISelectionFeedbackGenerator** indicates selection changes. For instance, scrolling through a menu might produce selection feedback each time a new item becomes selected.

Using these generators is dead simple. Below is an example of how to generate impact feedback:

```swift
let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
feedbackGenerator.impactOccurred()
```

Here you create a `UIImpactFeedbackGenerator` with a `heavy` feedback style. The style reflects the weight of objects involved in the impact. Triggering the feedback is as easy as calling `impactOccurred()`.

>**Note**: There are three `UIImpactFeedbackStyle` enum cases: `heavy`, `light` and `medium`. The style is meant to reflect the relative *weight* of objects involved in the collision. As you’d expect, heavy produces the strongest haptic feedback.

In this section, you’ll trigger each of the feedback generators when the collection view in EmojiRater scrolls to the top. To experience it, you’ll need an iPhone 7 or 7 Plus, and about five minutes! :]

If you completed the section on preview interactions, you can continue with that project. If not, the folder titled **haptic-starter** contains the starter project for this section. Open **EmojiRater.xcodeproj**, set your development team for the EmojiRater target, and you’re already halfway done!

### Implementing UIFeedbackGenerator

Open **EmojiCollectionViewController.swift** and add the following method to the `EmojiCollectionViewController` extension indicated with a `UICollectionViewDelegate` mark:

```swift
override func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
  let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
  feedbackGenerator.impactOccurred()
}
```

This code overrides the `scrollViewDidScrollToTop(_:)` method found in `UIScrollViewDelegate`. The method triggers when a user taps the status bar to scroll to the top of the collection view.

You’ve created an instance of `UIImpactFeedbackGenerator` with the `heavy` style feedback; the impact style is appropriate in thie case, since the scrollview hitting the top of its offset results in a visual collision between the collection view content and status bar. You then call `impactOccurred()` to trigger the impact feedback.

Build and run, scroll down a bit in the collection view, and then tap the status bar to return to the top. Once scrolling finishes, you’ll feel the heavy impact feedback. Feel free to experiment with `medium` and `light` `UIImpactFeedbackStyle` to note the difference.

![bordered iphone](./images/tap-status-bar.png)

While `UIImpactFeedbackGenerator` is appropriate for this UI interaction, you’ll swap in swap in the remaining two types to see how they feel as well.

Replace the contents of `scrollViewDidScrollToTop(_:)` with the following:

```swift
let feedbackGenerator = UINotificationFeedbackGenerator()
feedbackGenerator.notificationOccurred(.success)
```

You create a `UINotificationFeedbackGenerator` and trigger it with `notificationOccurred()`. `success` emits feedback that indicates a task succeeded. Other options include `error` and `warning`.

Build and run, scroll down and hit the status bar. You’ll experience a different haptic response, indicating success. Feel free to test again with the other two statuses to get a feel for them.

The last type is `UISelectionFeedbackGenerator`, which is not at all applicable for this interaction, but is still worth a test drive. :]  Replace the contents of `scrollViewDidScrollToTop(_:)` once more with the following:

```swift
let feedbackGenerator = UISelectionFeedbackGenerator()
feedbackGenerator.selectionChanged()
```

`selectionChanged()` triggers `UISelectionFeedbackGenerator` to indicate a new selection event. Unlike the other `UIFeedbackGenerator` classes, it accepts no options and provides only a single type of haptic feedback.

Test it out, make a mental note of the feel. This should be familiar if you’ve set any timers in iOS.

`UIFeedbackGenerator` is a very simple yet important API, as it adds a compelling physical component to the user experience. Apple has started adopting haptics through their own apps, and you’d do well as an early adopter of haptics as well.

>**Note**: Keep in mind that haptic feedback is only available on the iPhone 7 and 7 Plus. Even on those devices, feedback may not occur depending on battery levels, user’s settings, and app status. Haptic feedback is designed to supplement visual indicators, not replace them.

The folder titled **haptic-final** contains the final project for this section. A feedback generator is enabled by default, but the other styles are provided in comments. For more details on `UIFeedbackGenerator`, including best practices, check out the API Reference here: [apple.co/2cVBAW7](http://apple.co/2cVBAW7)

## Where to go from here?

iOS 10 is, by most metrics, a huge release. While it wasn’t anything like the major overhaul of iOS 7, iOS 10 introduced improved and matured features throughout the SDK. Data source prefetching, preview interactions, and haptic feedback are just a few examples of the added niceties.

It’s always a great idea to read through the What’s New in iOS developer notes for iOS 10: [apple.co/2coIGCr](http://apple.co/2coIGCr).

WWDC videos are also a great resource for any APIs or tools that you use in your development, and contain tidbits of information you might not find elsewhere : [apple.co/1YtgQWy](http://apple.co/1YtgQWy)

There’s only one thing left to do...

![width=40%](./images/ios10-the-things.png)