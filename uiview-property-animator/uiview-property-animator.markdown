```metadata
author: "By Rich Turton"
number: "9"
title: "Chapter 9: Property Animators"
```

# Chapter 9: Property Animators

## Introduction

If you've done any animations in UIKit you've probably used the UIView animation methods (`UIView.animate(withDuration:animations:)` and friends). `UIViewPropertyAnimator` is a new way to write animation code. It isn't a replacement for the existing API, nor is it objectively "better", but it does give you a lot of control that wasn't possible before. 

In this chapter you'll learn about the following new features that property animators give you access to:

- Detailed control over animation timing curves
- A superior spring animation
- Monitoring and altering of animation state
- Pause, reverse and scrub animations or abandon them part-way through

The fine control over animation timing alone would make a property animator an improvement for your existing UIView animations, but where they really shine is when you are creating animations that aren't just fire-and-forget. If you're animating something in response to user gestures, or if you want the user to be able to grab an animating object and do something else with it, then property animators are your new best friend. 

## Getting started

Open the **Animalation** project in the starter materials for this chapter. This is a demonstration app which you'll modify to add extra animation capabilities. There are two view controllers, some animated transition support files, and some utility files. Build and run the project:

![ipad](images/Animalation1.png)

If you tap the **Animate** button at the top, the frog will move to a random position. Nothing else happens - yet.

Watch carefully as the frog moves. Can you see that it starts slowly, then gets faster, then slows down again before it stops? That is controlled by the animation's **timing curve**. Fine control over the timing curve is one of the features that property animators give you. Before we get into the code, here's a quick explanation of timing curves. 

## Timing is everything

Consider a very simple animation where a view moves along a line, from x = 0 to x = 10. The animation takes 10 seconds. 

At any given second, how far along the line is the view? The answer to this question is given by the animation's **timing curve**. The simplest timing curve isn't curved at all - it's called the **linear** curve. Animations using the linear curve move along at a constant speed - after 1 second, the view is at position 1, after 2 seconds, position 2, and so on. You could plot this on a graph like so:

![width=40%](images/Linear.png)

This doesn't lead to very fluid or natural-seeming animations; things in real life don't go from not moving at all to moving at a constant rate, and then suddenly stopping when they get to the end. For that reason, the `UIView` animation API uses an **ease-in, ease-out** timing curve. On a graph, that looks more like this: 

![width=40%](images/Easing.png)

You can see that for the first quarter or so of the time, not much progress is made, then it speeds up, then flattens out again at the end. To the eye the animated object accelerates, moves, then decelerates and stops. This looks a lot more natural, and is what you're seeing right now with the frog.

UIView animations offer you four choices of timing curve: linear and ease-in-ease-out, which you've seen above, **ease-in**, which accelerates at the start but ends suddenly, and **ease-out**, which starts suddenly and decelerates at the end. 

`UIViewPropertyAnimator` offers you almost limitless control over the timing curve of your animations. In addition to the four pre-baked options above, you can supply your own cubic Bézier timing curve. 

Your own cubic _what_ now? 

Don't panic. You've been looking at them already. A cubic Bézier curve goes from point A to point D, while also doing its very best to get near points B and C on the way, like a drunk wandering home past a couple of kebab shops. **TODO: Chris you might want to choose a better analogy :]**

With the two examples above, point A is in the bottom left and point D is in the top right. With the linear curve, points B and C happen to be on the exact straight line. With ease-in-ease-out, point B is below and to the right of the line, point C is above and to the left of it. This rather beautiful diagram shows you the effect on the curve of moving points B and C, which are known as the **control points**: 

![width=40%](images/Multiline.png)

The circles represent the control points of the curve, which are varied in the horizontal or vertical direction. The filled circles correspond to the solid lines of the equivalent color, showing variations in the horizontal direction, and the hollow circles to the dashed lines, showing variations in the vertical direction. In the center of the pattern is a straight line, produced when both control points are on the straight path between A and D.

This diagram only shows a small number of the possible curves you can make in this fashion - the take home message is that you can model almost any combination of acceleration, progress and deceleration here. 

## Take control of your frog

Open **ViewController.swift** and find `animateAnimalTo(location:)`. You can see that this method currently uses a standard UIView animation to move the animal. Replace the body of the method with this code:

```swift
imageMoveAnimator = UIViewPropertyAnimator(duration: 3, curve: .easeInOut) {
  self.imageContainer.center = location
}
imageMoveAnimator?.startAnimation()
```

There's already a property in the starter project to hold the animator, so you create a new property animator and assign it. After the animator is created, you need to call `startAnimation()` to set it running. 

> **Note:** Why do you need to assign the animator to a property? Well, you don't _need_ to, but one of the major features of property animators is that you can take control of the animation at any point, and without holding a reference to it, that's not possible. 

Build and run the project, hit the animate button, and... well, it looks exactly the same. You've used the `.easeInOut` timing curve, which is the same as the default curve used for UIView animations. 

Let's take a look at a custom timing curve. When frogs jump, they have an explosive burst of acceleration, then they land gently. In terms of timing curves, that looks like this:

![width=40%](images/FrogJump.png)

You can see the two control points on the diagram. You create a property animator with a custom timing curve like this. Replace the initializer above with this code:

```swift
let controlPoint1 = CGPoint(x: 0.2, y: 0.8)
let controlPoint2 = CGPoint(x: 0.4, y: 0.9)
imageMoveAnimator = UIViewPropertyAnimator(duration: 3,
  controlPoint1: controlPoint1, controlPoint2:  controlPoint2) {
```

The two control points are those shown on the diagram above - the timing curve runs from (0, 0) to (1, 1). Build and run now and you'll see that the frog starts the move very quickly and then slows down. Play around with the control points to see what effects you can get - what happens if any control point coordinate is greater than 1.0, or less than 0.0? 

## Springtime!

The level of control over the timing curve goes even further than this. The two initializers you've used so far (passing in a curve or control points) are actually convenience initializers. All they do is create and pass on a `UITimingCurveProvider` object. This is a protocol that provides the relationship between elapsed time and animation progress. Unfortunately the protocol doesn't go so far as to let you have _total_ control, but it does give you access to another cool feature: springs!

> **Note**: Wait!, I hear you cry. We already had spring animations! You did, but they weren't very good. UIView spring animations make you supply a duration, as well as the various parameters describing the spring. This meant that to get natural-looking spring animations you had to keep tweaking the duration value. 
> 
> Why is this? Well, imagine an actual spring. If you stretch it between your hands and let go, the time it takes for the spring to bounce back into shape comes entirely from the properties of the spring (what is it made of? How thick is it?) and how far you stretched it. The duration of the animation should be driven from the properties of the spring, not tacked on and the animation forced to fit into it.  

A spring system is described by three factors:

- The **mass** of the object attached to the spring
- The **stiffness** of the spring
- The **damping** - any factors that would act to slow down the movement of the system, like friction or air resistance

The amount of damping applied will give you one of three outcomes. The system can be **under-damped**, meaning it will bounce around for a while before it settles, **critically damped**, meaning it will settle as quickly as possible without bouncing at all, or **over-damped**, meaning it will settle without bouncing but not quite as quickly. 

In most cases you will want a slightly under-damped system - without that your spring animations won't look particularly springy. But you don't have to guess at what values to use. The critical damping ratio is 2 times the square root of the product of the mass and stiffness values. You'll put this into action now. Replace the contents of `animateAnimalTo(location:)` with the following:

```swift
//1
let mass: CGFloat = 1.0
let stiffness: CGFloat = 10.0
//2
let criticalDamping = 2 * sqrt(mass * stiffness)
//3
let damping = criticalDamping * 0.5
//4
let parameters = UISpringTimingParameters(
  mass: mass,
  stiffness: stiffness,
  damping: damping,
  initialVelocity: .zero)
//5
imageMoveAnimator = UIViewPropertyAnimator(duration: 3, timingParameters: parameters)
imageMoveAnimator?.addAnimations {
  self.imageContainer.center = location
}
imageMoveAnimator?.startAnimation()
```

> **Note:** If for some reason you don't find specifying your own spring parameters exciting, there is also a convenience initializer `init(dampingRatio:, initialVelocity:)` for `UISpringTimingParameters` where 1.0 is a critically damped spring and values less than 1.0 will be under-damped.

Here's the breakdown:

1. Create constants for the mass and stiffness values
2. Derive the critical damping ratio
3. Reduce this ratio to give an under-damped spring
4. Create a spring timing parameters object
5. Use the designated initializer, passing in the new timing parameters. Note that, because you're using spring timing parameters, the duration is ignored. You also have to add the animations separately when using this initializer.

Build and run and you'll see the frog move in a more springy way. Experiment with the multiplier used in line 3 above and see what effects this has on the animation. 

There's one additional value when you create the spring timing parameters - the initial velocity. This allows you to tell the spring system if the object being moved in the animation is already moving - in which case it can make the animation look more natural. In the running app, you can drag the frog around and when you release it, it will move back to where it started. If you do this quite quickly, you'll see that when you let go the frog suddenly starts moving in the opposite direction, so it doesn't look quite right. 

The initial velocity is a `CGVector`, measured in units that correspond to the total animation distance - that is, if you are animating something by 100 points, and the object is already moving at 100 points per second, the vector would have a magnitude of 1.0. 

You're going to amend the app so that the velocity of the pan gesture used to move the frog is taken into account in the spring animation. First, change the `animateAnimalTo(location:)` method signature to include a velocity parameter:

```swift
private func animateAnimalTo(location: CGPoint,
                             initialVelocity: CGVector = .zero) {
```

Use this value instead of `.zero` when making the timing parameters:

```swift
initialVelocity: initialVelocity)
```

Now find `handleDragImage(_:)`. Replace the body of the `.ended:` case with the following code:

```swift
case .ended:
  if let imageDragStartPosition = imageDragStartPosition {
    //1
    let animationVelocity = sender.velocity(in: view)
    //2
    let animationDistance = imageContainer.center.distance(toPoint: imageDragStartPosition)
    //3
    let normalisedVelocity = animationVelocity.normalise(weight: animationDistance)
    //4 
    let initialVelocity = normalisedVelocity.toVector
    animateAnimalTo(location: imageDragStartPosition, initialVelocity: initialVelocity)
  }
  imageDragStartPosition = .none
```

1. The pan gesture has a `velocity(in:)` method describing how fast it is moving. This is measured in points per second. This is returned as a `CGPoint` rather than a `CGVector`, but both structures are very similar.
2. A convenience method included in the starter project calculates the distance in points from the current position to the animation's end position. This is one "unit" when talking about the animation.
3. Another convenience method uses that distance to convert the gesture velocity into animation units
4. Finally the `CGPoint` is converted to a `CGVector` so it can be passed to the animation method.

Build and run and fling the frog about - you will see that the motion of your gesture is taken into account in the animation! 

> TODO: This is buggy in beta 3 - it doesn't take the Y component into account.

## Every move you make, I'll be watching you

What else can you get out of a property animator, besides fancy timing curves? Well, you can query or observe what's happening at any point in the animation. The property animator has the following  properties that tell you what's happening:

- `state`: This is `.inactive`, `.active` or `.stopped`. 
- `isRunning`: This is a `Bool` telling you if the animation is running or not.
- `isReversed`: This is a `Bool` telling you if the animation is reversed or not.

These properties are all observable via key-value-observing (KVO). KVO is quite tedious to set up, so that work has been done for you in the **ViewController+Observers.swift** file. All you need to do is add this line to the start of `animateAnimalTo(location:)`:

```swift
removeAnimatorObservers(animator: imageMoveAnimator)
```

And this line just above where you call `startAnimation()`:

```swift
addAnimatorObservers(animator: imageMoveAnimator)
```

These lines link up the segmented controls at the bottom of the app to the current state of the animator. Build and run, start an animation, and keep an eye on the segmented controls. You can see the `state` and `isRunning` change before your eyes:

![ipad](images/Animalation2.png)

As you explore more features of the property animator you'll see more of these segments light up. This is where property animators start to get _really_ interesting!

## Pausing and scrubbing

With UIView animations you set them going and then usually forget about them unless you also added a completion block. With property animators, you can reach in at any point in the animation and stop it. You can use this for animations that the user can interrupt by touching the screen. Interactions like this make your user feel really connected to what is happening in the app. 

Animalation already has a handler for tapping the image view, but at the moment it doesn't do anything. In **ViewController.swift**, find `handleTapOnImage(_:)` and add the following code:

```swift
//1
guard let imageMoveAnimator = imageMoveAnimator else {
  return
}
//2
progressSlider.isHidden = true
//3
switch imageMoveAnimator.state {
case .active:
  if imageMoveAnimator.isRunning {
    //4
    imageMoveAnimator.pauseAnimation()
    progressSlider.isHidden = false
    progressSlider.value = Float(imageMoveAnimator.fractionComplete)
  } else {
  	//5
    imageMoveAnimator.startAnimation()
  }
default:
  break
}
```

Here's the step-by-step breakdown:

1. If there's no imageMoveAnimator, there's no point doing anything.
2. The slider should be hidden in most cases when the image is tapped, so that gets set here.
3. If you're testing values of an enum, it's always better to use a switch, even if in this case you're only interested in one outcome. Remember the possible values are `.active`, `.inactive` and `.stopped`.
4. If the animator is running, then here you pause it, show the slider, and set the slider's value to the `.fractionComplete` value of the animator. You have to convert between `Float` and `CGFloat` for this, which is as far as I know the only place in UIKit where a `Float` property is used. 
5. If the animator _isn't_ running, you set it off again. 

Also add in the implementation for `handleProgressSliderChanged(_:)`:

```swift
imageMoveAnimator?.fractionComplete = CGFloat(sender.value)
```
 
This is the reverse of what you did when pausing the animation - the value of the slider is used to set the `.fractionComplete` property of the animator.

Build and run the app and try to tap on the frog while it is moving:

![ipad](images/Animalation3.png)

You can see the slider appear, the **isRunning** segment change value, and the animation stop. Moving the slider back and forth moves the frog along its path - but note that it follows the straight point-to-point path, rather than the overshooting and oscillation coming from the spring - the slider is moving the animation along the **progress** axis of those charts from earlier, not the **time** axis.

It's important to note here that _pausing_ an animation isn't the same as _stopping_ one. Notice that the **state** indicator stays on `.active` when you've paused the animation. 

## Stopping

When a property animator stops, it ends all animation at the current point and, more importantly, updates the properties of the animated views to match those at the current point. If you've ever tried to get in-flight values out of an interrupted UIView animation so that you can seamlessly stop it, you'll be quite excited to read this. 

Inside `handleTapOnImage(_:)`, add the following line at the end of the method:

```swift
stopButton.isHidden = progressSlider.isHidden
```

This will show or hide the stop button in sync with the progress slider. 

Find `handleStopButtonTapped(_:)` and replace the comment with the following implementation:

```swift
guard let imageMoveAnimator = imageMoveAnimator else {
  return
}
switch imageMoveAnimator.state {
//1
case .active:
  imageMoveAnimator.stopAnimation(false)
//2
case .inactive:
  break
//3
case .stopped:
  imageMoveAnimator.finishAnimation(at: .current)
}
```

Stopping an animator is, or can be, a two-stage process. Here's the breakdown of what's happening above. There's the standard guard that the animator exists, then a switch on the state: 

1. For an active animator, you tell it to stop. The parameter indicates if the animator should immediately end and become inactive (`true`), or if it should move to the stopped state and await further instructions (`false`). 
2. There's nothing to do for the inactive state
3. A stopped animator should be finished at the current position. 

Build and run the project then do the following:

- Tap the animate button to start the animation
- Tap the frog to pause the animation
- Tap the stop button to stop the animation
- Tap the stop button _again_ to finish the animation.

If you're feeling a little confused at this point, don't worry. A property animator can be paused, stopped or finished, and those all mean different things: 

### Paused

State: `.active`, Running: `true`. 

This is a running animator that you've called `pauseAnimation()` on. All of the animations are still in play. The animations can be modified, and the animator can be started again by calling `startAnimation()`.

### Stopped

State: `.stopped`, Running: `false`.

This is a running or paused animator that you've called `stopAnimation(_:)` on, passing `false`. All of the animations are removed, and the views that were being animated have their properties updated to the current state as determined by the animation. The completion block has not been called. You can finish the animation by calling `finishAnimation(at:)`, passing `.end`, `.start` or `.current`. 

### Finished

State: `.inactive`, Running: `false`.

This is an animator that's got to the end of its animations naturally, or a running animator that you've called `stopAnimation(_:)` on, passing `true`, or a stopped animator that you've called `finishAnimation(at:)` on (you can't call `finishAnimation(at:)` on anything other than a stopped animator). 

The animated views will have their properties set to match the end point of the animation. The completion block for the animator will be called. 

We haven't discussed completion blocks for property animators yet. They're a little different to those from UIView animations, where you get a `Bool` indicating if the animation was completed or not. One of the main reasons they're different is because a property animator can be run in reverse. 

## Reversing

Why would you want to run an animation in reverse? It's all related to making gesture-driven interfaces. Imagine something like a swipe gesture to dismiss a presented view, then the user decides not to dismiss it and swipes back slightly in the other direction. A property animator can take all of this into account and run the animation back to the start point, without you having to store or recalculate anything. 

To demonstrate this in the sample app, you're going to change the function of the **Animate** button. If you tap it while an animation is running, it's going to reverse the animation. 

In **ViewController.swift** find `handleAnimateButtonTapped(_:)` and replace the implementation with the following:

```swift
if let imageMoveAnimator = imageMoveAnimator, imageMoveAnimator.isRunning {
  imageMoveAnimator.isReversed = !imageMoveAnimator.isReversed
} else {
  animateAnimalToRandomLocation()
}
```

For a running animation, this will toggle the reversed property, otherwise it will start the animation as before. 

Build and run and tap the animate button, then tap it again - you'll see the frog return to its original position, but still using the spring timing to settle naturally back into place! You can see that the **isReversed** indicator on the screen updates.

> TODO: This doesn't update in beta 3

You now have three different ways that the animation can end - it can finish normally, you can stop it half way, or you can reverse it and it finishes where it started. This is useful information to know when you have a completion block on the animation, so you're going to add one now.

In `animateAnimalTo(location: initialVelocity:)`, add the following code after you call `addAnimations(_:)`:

```swift
imageMoveAnimator?.addCompletion { position in
  switch position {
  case .end: print("End")
  case .start: print("Start")
  case .current: print("Current")
  }
}
```

The completion block takes a `UIViewAnimatingPosition` enum as its argument, which tells you the state of the animator when it finished.

Build and run the project and try to obtain all three completion block printouts by ending the animation at the end, start or somewhere in the middle.  

For a more practical demonstration of the various states of a completion block, you're going to add a second animation and run the two of them together.

## Multiple animators

You can add as many changes as you like to a single property animator, but it's also possible to have several animators working on the same view. You're going to add a second animator to run alongside the first, which will change the animal image displayed.

In **ViewController.swift** add the following array of images, before the class declaration of ViewController:

```swift
let animalImages = [#imageLiteral(resourceName: "bear"), #imageLiteral(resourceName: "frog"), #imageLiteral(resourceName: "wolf"), #imageLiteral(resourceName: "cat")]
```

You'll see the pasted code transform into image literals... how cool is that? 

Next, underneath the declaration for `imageMoveAnimator`, add a declaration for the second animator:

```swift
var imageChangeAnimator: UIViewPropertyAnimator?
```

In the extension where `animateAnimalToRandomLocation()` is, add the following new method:

```swift
private func animateRandomAnimalChange() {
  //1
  let randomImage = animalImages[Int(arc4random_uniform(UInt32(animalImages.count)))]
  //2
  let duration = imageMoveAnimator?.duration ?? 3.0
  
  //3
  let snapshot = animalImageView.snapshotView(afterScreenUpdates: false)!
  imageContainer.addSubview(snapshot)
  animalImageView.alpha = 0
  animalImageView.image = randomImage
  
  //4
  imageChangeAnimator = UIViewPropertyAnimator(duration: duration, curve: .linear) {
    self.animalImageView.alpha = 1
    snapshot.alpha = 0
  }
  
  //5
  imageChangeAnimator?.addCompletion({ (position) in
    snapshot.removeFromSuperview()
  })
  
  //6
  imageChangeAnimator?.startAnimation()
}
```

Here's the play-by-play:

1. Select a random destination image from the array you just created
2. You want the duration of this animation to match that from the move animation. Remember how with a spring animation, the duration you pass in is ignored? What happens instead is that the duration is calculated based on the spring parameters, and is available for you to use via the `duration` property. 
3. Here you set up the animation - take a snapshot of the current animal, add that to the image container, make the actual image view invisible and set the new image.
4. Create a new animator with a linear timing curve (you don't really want a spring for a fade animation!) and within that, fade in the image view and fade out the snapshot for a cross-dissolve effect
5. When the animation is complete, remove the snapshot
6. Start the animation

Add a call to this method in `handleAnimateButtonTapped(_:)`, right after the call to `animateAnimalToRandomLocation()`:

```swift
animateRandomAnimalChange()
``` 

Build and run and hit the animate button, and you'll see the image cross-fade while it moves:

![ipad](images/Animalation4.png)

> **Note:** The animal won't always change. Sometimes the randomly selected animal is the same as the one that's already there! 

If you pause the animation, you'll see that the cross-fade merrily continues. This might be what you want - it can be handy to have independent animations on the same object. However, you're going to sync up the state of the two animators. 

Find `handleTapOnImage(_:)` and where you pause or start `imageMoveAnimator`, do the same to `imageChangeAnimator`:

```swift
case .active:
  if imageMoveAnimator.isRunning {
    imageMoveAnimator.pauseAnimation()
    imageChangeAnimator?.pauseAnimation()
    progressSlider.isHidden = false
    progressSlider.value = Float(imageMoveAnimator.fractionComplete)
  } else {
    imageMoveAnimator.startAnimation()
    imageChangeAnimator?.startAnimation()
  }
```

Change `handleProgressSliderChanged(_:)` to adjust the second animator by adding this line:

```swift
imageChangeAnimator?.fractionComplete = CGFloat(sender.value)
```

In `handleAnimateButtonTapped(_:)`, after you set the reversed state of the move animator, mirror it for the image change animator:

```swift
imageChangeAnimator?.isReversed = imageMoveAnimator.isReversed
```

Finally, handle the stopping. You're not going to do quite the same here - abandoning the fade animation half way through would look rather odd. In `handleStopButtonTapped(_:)`, after you stop the move animator, just pause the image change animator:

```swift
imageChangeAnimator?.pauseAnimation()
```

After you finish the move animator, add this code:

```swift
if let imageChangeAnimator = imageChangeAnimator,
  let timing = imageChangeAnimator.timingParameters {
  imageChangeAnimator.continueAnimation(withTimingParameters: timing,
                                        durationFactor: 0.2)
}
```

`continueAnimation` allows you to swap in a brand new timing curve (or spring) and a duration factor, which is used as a multiplier of the original animation duration. You can only do this to a paused animator. This means your fade animation will quickly finish, while the move animation has stopped. This is an example of the great flexibility and control that property animators can give you.  

Build and run the app and try pausing, scrubbing, stopping, finishing (remember to tap "stop" _twice_ to finish) and reversing the animation. You'll notice a problem when you reverse - the animal disappears! Where's your doggone frog gone?

Remember what's happening in the fade animation - a snapshot of the old image is added, the image view is updated and made transparent, then a cross fade happens. In the completion block the snapshot is removed. 

If the animation is reversed, when it "finishes" (i.e. gets back to the start), the image view is transparent and the snapshot view is removed - that means you can't see anything. You need to do different things in the completion block depending on the position the animation ended in. 

Go to `animateRandomAnimalChange()` and add the following line before you take the snapshot:

```swift
let originalImage = animalImageView.image
```

This keeps a reference to the original animal, which you'll need if the animation is reversed. Add the following code to the completion block:

```swift
if position == .start {
  self.animalImageView.image = originalImage
  self.animalImageView.alpha = 1
}
```

This code restores the alpha and the image as they were before the animation started.

Build and run again, reverse the animation and behold! No more disappearing animals! 

## View Controller Transitions

Property animators, or to be specific, objects that conform to `UIViewImplicitlyAnimating`, can also be plugged in to your interactive view controller transitions. Previously, you could start an interactive transition, track a gesture, and then hand it off to finish or be cancelled by the system - but after that point, the user had no control. When you add property animators to the mix you can switch multiple times between interactive and non-interactive modes, making your users feel really connected to what's happening on the screen. 

Setting up and building interactive transitions is a complex topic outside the scope of this tutorial. See [https://www.raywenderlich.com/110536/custom-uiviewcontroller-transitions](https://www.raywenderlich.com/110536/custom-uiviewcontroller-transitions) or our iOS Animations By Tutorials book for an overview. The project already contains an interactive transition, you're going to amend this to make it use property animators and become interruptible.

First, take a look at the existing transition. Open **Main.storyboard**, find the **Animals** button on the bottom right of the main view controller and make it visible by unchecking the **Hidden** box. Build and run the project and tap the button:

![ipad bordered](images/Animals1.png)

To dismiss the controller interactively, pull down:

![ipad bordered](images/Animals2.png)

Once you've let go, the animation will either return to the top, or complete. If you try and grab the screen as it's disappearing (the transition is super slow to help you with this!), nothing will happen. 

To make an interactive transition super duper interruptibly interactive, there's a new method to implement on your `UIViewControllerAnimatedTransitioning` object. Open **DropDownDismissAnimator.swift**. This is a standard transition animator object. Add the following new method:

```swift
func interruptibleAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
  let animator = UIViewPropertyAnimator(duration: transitionDuration(using: transitionContext), curve: .easeInOut) {
    self.performAnimations(using: transitionContext)
  }
  return animator
}
``` 

This creates a new property animator that simply calls the same animation method, UIView animations and all, that is currently used by the transition. 

The project is using a subclass of `UIPercentDrivenInteractiveTransition`for the interaction controller for this transition. Percent driven transitions have a new method, `pause()`, which tells the transition context to switch from non-interactive to interactive mode. 

You want this to happen when the user starts another pan gesture. Open **DropDownInteractionController.swift** , which is the interaction controller. This class uses a pan gesture to update the progress of the transition, and when the gesture ends, sets it back to non-interactive mode with either `finish()` or `cancel()` depending on the position of the view. 

Add two new properties, underneath `isInteractive`:

```swift
var hasStarted = false
var interruptedPercent: CGFloat = 0
```

You will use `hasStarted` to decide if a new pan gesture is the start of a new dismissal, or an attempt to interrupt an ongoing dismissal. If you do interrupt an ongoing dismissal, `interruptedPercent` will be used to make sure the pan gesture's translation takes the current position of the view into account. 

Inside `handle(pan:)`, amend the calculation of `percent`:

```swift
let percent = (translation / pan.view!.bounds.height) + interruptedPercent
```

You're adding the interrupted percent on here, because if the dismissal was already 50% through when the user touches the screen, that needs to be reflected in the position of the view. 

Inside the same method, replace the `.began` case in the switch statement with the following code:

```swift
case .began:
  if !hasStarted {
    hasStarted = true
    isInteractive = true
    interruptedPercent = 0
    viewController?.dismiss(animated: true, completion: nil)
  } else {
    pause()
    interruptedPercent = percentComplete
  }
```

If this isn't the first gesture in the dismissal, the transition is paused and the current percentage is taken from it. The transition must be paused **before** you read the percentage, otherwise you'll get an inaccurate figure. 

Finally, switch over to **AppDelegate.swift** and add the following line to the `animationCleanup` closure created in `animationController(forDismissed:)`:

```swift
interactionController?.hasStarted = false
```

This ensures that the interaction controller is properly reset when the animations are complete. 

Build and run the project, show the animals view, then have fun interrupting yourself and wobbling the view up and down! 
 
## Where To Go From Here?

Congratulations! You've had a good exploration of the new powers available to you now that you can use property animators! Go forth and fill your apps with interruptible, interactive animations, including an extra level of awesome in your view controller transitions. 

There's a lot more detail on property animators in our excellent book, **iOS Animations By Tutorials**! Check it out! The WWDC video, 2016 session 216, available at [https://developer.apple.com/videos/play/wwdc2016/216/](https://developer.apple.com/videos/play/wwdc2016/216/) is also full of useful information. 
