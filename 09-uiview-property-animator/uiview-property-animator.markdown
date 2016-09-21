```metadata
author: "By Rich Turton"
number: "9"
title: "Chapter 9: Property Animators"
```

# Chapter 9: Property Animators

If you’ve done any animations in UIKit, you’ve probably used the `UIView` animation methods `UIView.animate(withDuration:animations:)` and friends. 

iOS 10 has introduced a new way to write animation code: using `UIViewPropertyAnimator`. This isn’t a replacement for the existing API, nor is it objectively “better”, but it does give you a level of control that wasn’t possible before.

In this chapter, you’ll learn about the following new features that Property Animators give you access to:

- Detailed control over animation timing curves
- A superior spring animation
- Monitoring and altering of animation state
- Pausing, reversing and scrubbing through animations or even abandoning them part-way through

The fine control over animation timing alone would make a Property Animator an improvement for your existing `UIView` animations. But where they really shine is when you create animations that aren’t just fire-and-forget. 

For example, if you’re animating something in response to user gestures, or if you want the user to be able to grab an animating object and do something else with it, then Property Animators are your new best friend.

## Getting started

Open the **Animalation** project in the starter materials for this chapter. This is a demonstration app which you’ll modify to add extra animation capabilities. There are two view controllers, some animated transition support files, and some utility files. Build and run the project:

![ipad](images/Animalation1.png)

Tap the **Animate** button at the top, and the frog will move to a random position. This happens with a traditional call to `UIView.animate(withDuration:)` in **ViewController.swift**:

```swift
func animateAnimalTo(location: CGPoint) {
  // TODO
  UIView.animate(withDuration: 3) {
    self.imageContainer.center = location
  }
}
```

Watch carefully as the frog moves. It starts slowly, then gets faster, then slows down again before it stops. 

That’s due to the animation’s **timing curve**. `UIView.animate(withDuration:)` uses a built-in timing curve called `curveEaseInOut`, which represents this slow/fast/slow behavior. There are a few other timing curve options provided by Apple, but your choices are quite limited.

Often, you want precise control over an animation's timing curve, and this is one of the features that Property Animators give you. Before we get into the code, here’s a quick explanation of timing curves.

## Timing is everything

Consider a very simple animation, ten seconds in length, where a view moves along a line, from `x = 0` to `x = 10`.

At any given second, how far along the line is the view? The answer to this question is given by the animation’s **timing curve**. The simplest timing curve isn’t curved at all — it’s called the **linear** curve. Animations using the linear curve move along at a constant speed: after 1 second, the view is at position 1. After 2 seconds, position 2, and so on. You could plot this on a graph like so:

![width=40%](images/LinearNoPoints.png)

This doesn’t lead to very fluid or natural-looking animations; in real life, things don’t go from not moving at all to moving at a constant rate, and then suddenly stopping when they get to the end. For that reason, the `UIView` animation API uses an **ease-in, ease-out** timing curve. On a graph, that looks more like this:

![width=40%](images/EasingNoPoints.png)

You can see that for the first quarter or so of the time, your animation doesn’t make much progress. It then speeds up and slows again near the end. To the eye, the animated object accelerates, moves then decelerates and stops. This looks a lot more natural and is what you saw with the frog animation.

`UIView` animations offer you four choices of timing curve: **linear** and **ease-in-ease-out**, which you’ve seen above; **ease-in**, which accelerates at the start but ends suddenly; and **ease-out**, which starts suddenly and decelerates at the end.

`UIViewPropertyAnimator`, however, offers you nearly limitless control over the timing curve of your animations. In addition to the four pre-baked options above, you can supply your own **cubic Bézier timing curve**.

### Cubic Bézier timing curves

Your own cubic _what_ now?

Don’t panic. You’ve been looking at these types of curves already. A cubic Bézier curve goes from point A to point D, while also doing its very best to get near points B and C on the way, like a dog running across the park, being distracted by interesting trees.

Let's review the examples from earlier. In both examples above, point A is in the bottom left and point D is in the top right. With the linear curve, points B and C happen to be in an exact straight line: 

![width=40%](images/Linear.png)

With ease-in-ease-out, point B is directly to the right of point A, and point C is directly to the left of point D. You can imagine the line being pulled from A towards B, then C takes over, then D: 

![width=40%](images/Easing.png)

Finally, here's what the ease-in and ease-out curves look like. With the ease-in curve, point C is directly under point D, and with the ease-out curve, B is under A:

![width=80%](images/EaseInAndEaseOut.png)

But what if you want something custom? You could set up the four points like this and make a custom animation curve:

![width=40%](images/CustomCurve.png)

Here, points B and C are above the top of the graph, so the animation would actually overshoot and then come back to its final position. 

Points B and C in these diagrams are the **control points** of the animation curve. They define the shape of the line as it travels from A to D. 

## Controlling your frog

With that covered, it’s now time to write some code. :]

Open **ViewController.swift** and find `animateAnimalTo(location:)`. Replace the body of the method with this code:

```swift
imageMoveAnimator = UIViewPropertyAnimator(
  duration: 3,
  curve: .easeInOut) {
    self.imageContainer.center = location
}
imageMoveAnimator?.startAnimation()
```

There’s already a property in the starter project to hold the animator, so you create a new Property Animator and assign it. After the Animator is created, you need to call `startAnimation()` to set it running.

> **Note:** Why do you need to assign the Animator to a property? Well, you don’t _need_ to, but one of the major features of Property Animators is that you can take control of the animation at any point, and without holding a reference to it, that’s not possible.

Build and run the project, hit the animate button, and... well, it looks exactly the same. You’ve used the `.easeInOut` timing curve, which is the same as the default curve used for `UIView` animations.

Let’s take a look at a custom timing curve. When frogs jump, they have an explosive burst of acceleration, then they land gently. In terms of timing curves, that looks something like this:

![width=40%](images/FrogJump.png)

You can see the two control points on the diagram. Let's try it out!

Replace the contents of `animateAnimalTo(location:)` with the following:

```swift
let controlPoint1 = CGPoint(x: 0.2, y: 0.8) // B on the diagram
let controlPoint2 = CGPoint(x: 0.4, y: 0.9) // C on the diagram
imageMoveAnimator = UIViewPropertyAnimator(
  duration: 3,
  controlPoint1: controlPoint1,
  controlPoint2: controlPoint2) {
    self.imageContainer.center = location
}
imageMoveAnimator?.startAnimation()
```

The two control points correspond to the labelled points on the diagram as indicated by the comments. The timing curve always runs from `(0, 0)` at **A** to `(1, 1)` at **D**. Build and run and you’ll see that the frog starts to move very quickly and then slows down — exactly as you wanted! 

> **Challenge**: Play around with the control points to see what effects you can get. What happens if any control point coordinate is greater than 1.0, or less than 0.0?

## Spring animations

The level of control over the timing curve goes even further than this. The two initializers you’ve used so far, passing in a curve or control points, are actually convenience initializers. All they do is create and pass on a `UITimingCurveProvider` object. 

`UITimingCurveProvider` is a protocol that provides the relationship between elapsed time and animation progress. Unfortunately, the protocol doesn’t go as far as to let you have _total_ control, but it does give you access to another cool feature: springs!

> **Note**: “Wait!” you cry. “We already had spring animations!” Yes, you did, but they weren’t very customizable. `UIView` spring require a duration, as well as the various parameters describing the spring. To get natural-looking spring animations, you had to keep tweaking the duration value.
>
> Why? Well, imagine an actual spring. If you stretch it between your hands and let go, the duration of the spring’s motion is really a function of the properties of the spring (What is it made of? How thick is it?) and how far you stretched it. Similarly, the duration of the animation should be driven from the properties of the spring, not tacked on and the animation forced to fit.  

Apple has provided an implementation of `UITimingCurveProvider` to create timing curves for springs, called `UISpringTimingParameters`. To use `UISpringTimingParameters` you need to provide three values to describe the spring system:

- The **mass** of the object attached to the spring.
- The **stiffness** of the spring.
- The **damping**; these are any factors that would act to slow down the movement of the system, like friction or air resistance.

The amount of damping applied will give you one of three outcomes: the system can be **under-damped**, meaning it will bounce around for a while before it settles; **critically damped**, meaning it will settle as quickly as possible without bouncing at all; or **over-damped**, meaning it will settle without bouncing, but not quite as quickly.

In most cases, you’ll want a slightly under-damped system — without that, your spring animations won’t look particularly _springy_. But you don’t have to guess at what values to use. The critical damping ratio is 2 times the square root of the product of the mass and stiffness values. You’ll put this into action now.

Replace the contents of `animateAnimalTo(location:)` with the following:

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
imageMoveAnimator = UIViewPropertyAnimator(
  duration: 3,
  timingParameters: parameters)
imageMoveAnimator?.addAnimations {
  self.imageContainer.center = location
}
imageMoveAnimator?.startAnimation()
```

Here’s the breakdown:

1. Create constants for the mass and stiffness values.
2. Derive the critical damping ratio using the formula stated above.
3. Reduce this ratio to give an under-damped spring.
4. Create a spring timing parameters object.
5. Use the designated initializer, passing in the new timing parameters.

Note that since you’re using spring timing parameters, _duration is ignored_. You also have to add the animations separately when using this initializer.

Build and run, and you’ll see the frog move in a more spring-like fashion. 

> **Challenge**: Experiment with the mass and stiffness used in section 1 and the multiplier used in section 3, and see what effect this has on the animation.

> **Note:** If for some reason you don’t find specifying your own spring parameters exciting, there is also a convenience initializer `init(dampingRatio:, initialVelocity:)` for `UISpringTimingParameters` where 1.0 is a critically damped spring and values less than 1.0 will be under-damped.

### Initial velocity

There’s one additional value when you create the spring timing parameters — the initial velocity. This means you can tell the spring system that the object has momentum at the start of the animation — in which case it can make the animation look more natural. 

Build and run the app, and drag the frog around. Notice that when you release the frog, he moves back to where he started. Then try moving the frog quickly, and release your mouse while you're still moving the frog. You’ll see that when you let go, the frog suddenly starts moving in the opposite direction. It doesn’t look quite right: you'd expect the frog to continue moving in the direction you were dragging for a bit before he moves back to the initial point.

The initial velocity is a `CGVector`, measured in units that correspond to the total animation distance — that is, if you are animating something by 100 points, and the object is already moving at 100 points per second, the vector would have a magnitude of 1.0.

You’re going to amend the app so that the velocity of the pan gesture used to move the frog is taken into account in the spring animation. First, change the `animateAnimalTo(location:)` method signature to include a velocity parameter:

```swift
func animateAnimalTo(location: CGPoint,
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
    animateAnimalTo(
      location: imageDragStartPosition,
      initialVelocity: initialVelocity)
  }
  imageDragStartPosition = .none
```

Taking each numbered comment in turn:

1. The pan gesture has a `velocity(in:)` method describing how fast it’s moving measured in points per second. This is returned as a `CGPoint` rather than a `CGVector`, but both structures are very similar.
2. A convenience method included in the starter project calculates the distance in points from the current position to the animation’s end position. This is one “unit” when talking about the animation.
3. Another convenience method uses that distance to convert the gesture velocity into animation units.
4. Finally, the `CGPoint` is converted to a `CGVector` so it can be passed to the animation method.

Build and run and fling the frog about — you will see that the animation takes your initial gesture into account.

## Inspecting in-progress animations

What else can you get out of a Property Animator, besides fancy timing curves? Well, you can query what’s happening at any point in the animation. The Property Animator has the following  properties that tell you what’s happening:

- `state`: This is `.inactive`, `.active` or `.stopped`.
- `isRunning`: This is a `Bool` telling you if the animation is running or not.
- `isReversed`: This is a `Bool` telling you if the animation is reversed or not.

The `state` property is also observable via key-value-observing (KVO). KVO is quite tedious to set up, so that work has been done for you in **ViewController+Observers.swift**. 

Let's try it out. Add this line to the start of `animateAnimalTo(location:initialVelocity:)`:

```swift
removeAnimatorObservers(animator: imageMoveAnimator)
```

And this line just above where you call `startAnimation()`:

```swift
addAnimatorObservers(animator: imageMoveAnimator)
```

These lines link up the segmented control at the bottom of the app to the current state of the animator. Build and run, start an animation and keep an eye on the segmented control. You can see `state` change before your eyes:

![ipad](images/Animalation2.png)

As you explore more features of the Property Animator you’ll see more of these segments light up. This is where Property Animators start to get _really_ interesting!

## Pausing and scrubbing

With `UIView` animations, you set them going and then usually forget about them unless you also added a completion block. With Property Animators, you can reach in at any point during the animation and stop it. You can, for example, use this for animations the user can interrupt by touching the screen. Interactions like this make your users feel incredibly connected to what’s happening in the app.

The Animalation project already has a handler for tapping the image view, but at the moment it doesn’t do anything. In **ViewController.swift**, find `handleTapOnImage(_:)` and add the following code:

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

Here’s the step-by-step breakdown:

1. If there’s no `imageMoveAnimator`, there’s no point in doing anything, so you simply break out of the method.
2. On the provided screen you have a slider, which has currently been hidden. The slider should also be hidden in most cases when the image is tapped, so you set that here.
3. If you’re testing values of an `enum`, it’s almost always better to use a `switch`, even if in this case you’re only interested in one outcome. Remember the possible values are `.active`, `.inactive` and `.stopped`.
4. If the Animator is running, then you pause it, show the slider and set the slider’s value to the `.fractionComplete` value of the animator. `UIKit` currently uses `CGFloat` rather than `Float` in almost all cases, but we’re starting to see a switch in the Apple APIs that favors a simpler syntax such as `Float`. The `UISlider`’s value is one such example, so here you have to convert between `Float` and `CGFloat`.
5. If the Animator _isn’t_ running, you set it off again.

Next, add in the implementation for `handleProgressSliderChanged(_:)`:

```swift
imageMoveAnimator?.fractionComplete = CGFloat(sender.value)
```

This is the reverse of what you did when pausing the animation — the value of the slider is used to set the `.fractionComplete` property of the animator.

Build and run the app and try to tap the frog while it’s moving:

![ipad](images/Animalation3.png)

You can see the slider appear and the animation stop. Moving the slider back and forth moves the frog along its path — but note that it follows the straight point-to-point path, rather than the overshooting and oscillation coming from the spring. That’s because the slider moves the animation along the **progress** axis of those charts from earlier, not the **time** axis.

It’s important to note here that _pausing_ an animation isn’t the same as _stopping_ one. Notice that the **state** indicator stays on `.active` when you’ve paused the animation.

## Stopping

When a Property Animator stops, it ends all animation at the current point and, more importantly, updates the properties of the animated views to match those at the current point. If you’ve ever tried to get in-flight values out of an interrupted `UIView` animation so that you can seamlessly stop it, you’ll be quite excited to read this.

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

Stopping an Animator is, or can be, a two-stage process. Above, you have the standard `guard` checking that the Animator object exists, then a switch on the state:

1. For an active Animator, you tell it to stop. The parameter indicates if the Animator should immediately end and become inactive (`true`), or if it should move to the stopped state and await further instructions (`false`)
2. There’s nothing to do for the inactive state.
3. A stopped Animator should be finished at the current position.

Build and run the project, then do the following:

- Tap the animate button to start the animation.
- Tap the frog to pause the animation.
- Tap the stop button to stop the animation.
- Tap the stop button _again_ to finish the animation.

If you’re feeling a little confused at this point, don’t worry. A Property Animator can be paused, stopped or finished, and those all mean different things:

### Paused

State: `.active`

Running: `true`

This is a running Animator on which you’ve called `pauseAnimation()`. All of the animations are still in play. The animations can be modified, and the Animator can be started again by calling `startAnimation()`.

### Stopped

State: `.stopped`

Running: `false`

This is a running or paused Animator on which you’ve called `stopAnimation(_:)`, passing `false`. All of the animations are removed, and the views that were being animated have their properties updated to the current state as determined by the animation. The completion block has not been called. You can manually finish the animation by calling `finishAnimation(at:)`, passing `.end`, `.start` or `.current`.

### Finished

State: `.inactive`

Running: `false`

This is either an Animator that’s reached the end of its animations naturally; a running Animator on which you’ve called `stopAnimation(_:)`, passing `true`; or a stopped Animator on which you’ve called `finishAnimation(at:)`. Note that you cannot call `finishAnimation(at:)` on anything other than a stopped animator.

The animated views will have their properties set to match the end point of the animation, and the completion block for the Animator will be called.

We haven’t yet discussed completion blocks for Property Animators. They’re a little different to those from `UIView` animations, where you get a `Bool` indicating if the animation was completed or not. One of the main reasons they’re different is because a Property Animator can be run in reverse.

## Reversing

You might be thinking “Why would I ever want to run an animation in reverse?” A good use case is when you’re working with gesture-driven interfaces. Imagine using something like a swipe gesture to dismiss a presented view, where, during the dismiss animation, the user decides not to dismiss it, and swipes back slightly in the other direction. A Property Animator can take all of this into account and run the animation back to the start point, without having to store or recalculate anything.

To demonstrate this in the sample app, you’re going to change the function of the **Animate** button. If you tap it while an animation is running, it’s going to reverse the animation.

In **ViewController.swift** find `handleAnimateButtonTapped(_:)` and replace the implementation with the following:

```swift
if let imageMoveAnimator = imageMoveAnimator, imageMoveAnimator.isRunning {
  imageMoveAnimator.isReversed = !imageMoveAnimator.isReversed
} else {
  animateAnimalToRandomLocation()
}
```

For a running animation, this will toggle the reversed property; otherwise, it will start the animation as before.

Build and run, then tap the animate button — then tap it again. You’ll see the frog return to its original position, but using the spring timing to settle naturally back into place! You can see that the **isReversed** indicator on the screen updates appropriately.

> **Note**: At the time of writing this chapter, there appears to be a bug in Xcode 8 beta 4 where isReversed does not update properly.

You now have three different ways that the animation can end: it can finish normally, you can stop it half way, or you can reverse it to finish where it started. This is useful information to know when you have a completion block on the animation, so you’re now going to add one now.

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

The completion block takes a `UIViewAnimatingPosition` enum as its argument, which tells you what state the Animator was in when it finished.

Build and run the project and try to obtain all three completion block printouts by ending the animation at the end, start or somewhere in the middle.  
For a more practical demonstration of the various states of a completion block, you’re going to add a second animation and run the two of them together.

## Multiple animators

You can add as many changes as you like to a single Property Animator, but it’s also possible to have several Animators working on the same view. You’re going to add a second Animator to run alongside the first, which will change the animal image displayed.

In **ViewController.swift** add the following array of images, before the class declaration of ViewController:

```swift
let animalImages = [
  #imageLiteral(resourceName: "bear"),
  #imageLiteral(resourceName: "frog"),
  #imageLiteral(resourceName: "wolf"),
  #imageLiteral(resourceName: "cat")
]
```

You’ll see the pasted code transform into image literals... how cool is that?

Next, underneath the declaration for `imageMoveAnimator`, add a declaration for the second animator:

```swift
var imageChangeAnimator: UIViewPropertyAnimator?
```

In the extension where `animateAnimalToRandomLocation()` lives, add the following new method:

```swift
func animateRandomAnimalChange() {
  //1
  let randomIndex = Int(arc4random_uniform(UInt32(animalImages.count)))
  let randomImage = animalImages[randomIndex]
  //2
  let duration = imageMoveAnimator?.duration ?? 3.0

  //3
  let snapshot = animalImageView.snapshotView(afterScreenUpdates: false)!
  imageContainer.addSubview(snapshot)
  animalImageView.alpha = 0
  animalImageView.image = randomImage

  //4
  imageChangeAnimator = UIViewPropertyAnimator(
      duration: duration,
      curve: .linear) {
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

Here’s the play-by-play:

1. Select a random destination image from the array you just created.
2. You want the duration of this animation to match that from the move animation. Remember that a spring animation ignores the duration you pass in. Instead, the duration is calculated based on the spring parameters and is available for you to use via the `duration` property.
3. Here you set up the animation: you take a snapshot of the current animal, add that to the image container, make the actual image view invisible and set the new image.
4. Create a new Animator with a linear timing curve (you don’t really want a spring for a fade animation) and within that, fade in the image view and fade out the snapshot for a cross-dissolve effect.
5. When the animation is complete, remove the snapshot.
6. Finally, start the animation.

Add a call to this method in `handleAnimateButtonTapped(_:)`, right after the call to `animateAnimalToRandomLocation()`:

```swift
animateRandomAnimalChange()
```

Build and run and hit the animate button, and you’ll see the image cross-fade while it moves:

![ipad](images/Animalation4.png)

> **Note:** The animal won’t always change. Sometimes the randomly selected animal is the same as the one that’s already there!

If you pause the animation, you’ll see that the cross-fade merrily continues. This might be what you want — it can be handy to have independent animations on the same object. However, for this app, you’re going to sync up the state of the two animators.

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

Change `handleProgressSliderChanged(_:)` to adjust the second Animator by adding this line:

```swift
imageChangeAnimator?.fractionComplete = CGFloat(sender.value)
```

In `handleAnimateButtonTapped(_:)`, after you set the reversed state of the move animator, mirror it for the image change animator:

```swift
imageChangeAnimator?.isReversed = imageMoveAnimator.isReversed
```

Finally, you need to handle the stopping. You’re not going to do quite the same thing here — abandoning the fade animation half way through would look rather odd. In `handleStopButtonTapped(_:)`, after you stop the move animator, simply pause the image change animator:

```swift
imageChangeAnimator?.pauseAnimation()
```

After you finish the move animator in the `.stopped` case, add the following code:

```swift
if let imageChangeAnimator = imageChangeAnimator,
  let timing = imageChangeAnimator.timingParameters {
  imageChangeAnimator.continueAnimation(
    withTimingParameters: timing,
    durationFactor: 0.2)
}
```

`continueAnimation` lets you swap in a brand new timing curve (or spring) and a duration factor, which is used as a multiplier of the original animation duration. You can only do this to a paused animator. This means your fade animation will quickly finish, while the move animation has stopped. This is an example of the great flexibility and control that Property Animators can give you.  

Build and run the app, and try pausing, scrubbing, stopping, finishing (remember to tap “stop” _twice_ to finish) and reversing the animation. You’ll notice a problem when you reverse — the animal disappears! Where’s your doggone frog gone?

Remember what’s happening in the fade animation — a snapshot of the old image is added, the image view is updated and made transparent, then a cross fade happens. In the completion block, the snapshot is removed.

If the animation is reversed, when it “finishes” (i.e. returns to the start), the image view is transparent and the snapshot view is removed, which means you can’t see anything. You need to do different things in the completion block depending on which position the animation ended in.

Go to `animateRandomAnimalChange()` and add the following line before you take the snapshot:

```swift
let originalImage = animalImageView.image
```

This keeps a reference to the original animal, which you’ll need if the animation is reversed. Add the following code to the completion block of the `imageChangeAnimator`:

```swift
if position == .start {
  self.animalImageView.image = originalImage
  self.animalImageView.alpha = 1
}
```

This code restores the alpha and the image as they were before the animation started.

Build and run again, reverse the animation and behold! No more disappearing animals!

## View controller transitions

Property Animators, or to be specific, objects that conform to `UIViewImplicitlyAnimating`, can also be plugged in to your interactive view controller transitions. Previously, you could start an interactive transition, track a gesture, and then hand it off to finish or be canceled by the system — but after that point, the user had no control. When you add Property Animators to the mix, you can switch multiple times between interactive and non-interactive modes, making your users feel really connected to what’s happening on the screen.

Setting up and building interactive transitions is a complex topic outside the scope of this chapter. See [https://www.raywenderlich.com/110536/custom-uiviewcontroller-transitions](https://www.raywenderlich.com/110536/custom-uiviewcontroller-transitions) or our book _iOS Animations By Tutorials_ for an overview. The starter project already contains an interactive transition; you’re going to amend this to make it use Property Animators and become interruptible.

First, take a look at the existing transition. Open **Main.storyboard**, find the **Animals** button on the bottom right of the main view controller and make it visible by unchecking the **Hidden** box. Build and run the project and tap the button:

![ipad bordered](images/Animals1.png)

To dismiss the controller interactively, pull down:

![ipad bordered](images/Animals2.png)

Once you’ve let go, the animation will either return to the top or complete. If you try and grab the screen as it’s disappearing (the transition is super slow to help you with this!), nothing will happen.

To make an interactive transition super-duper interruptibly interactive, there’s a new method to implement on your `UIViewControllerAnimatedTransitioning` object. Open **DropDownDismissAnimator.swift**. This is a standard transition Animator object. Add the following new method:

```swift
func interruptibleAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
  let animator = UIViewPropertyAnimator(
    duration: transitionDuration(using: transitionContext),
    curve: .easeInOut) {
      self.performAnimations(using: transitionContext)
  }
  return animator
}
```

This creates a new Property Animator that simply calls the same animation method, `UIView` animations and all, that is currently used by the transition.

The project is using a subclass of `UIPercentDrivenInteractiveTransition` for the interaction controller for this transition. Percent driven transitions have a new method, `pause()`, which tells the transition context to switch from non-interactive to interactive mode.

You want this to happen when the user starts another pan gesture. Open **DropDownInteractionController.swift** , which is the interaction controller. This class uses a pan gesture to update the progress of the transition, and when the gesture ends, sets it back to non-interactive mode with either `finish()` or `cancel()` depending on the position of the view.

Add two new properties, underneath `isInteractive`:

```swift
var hasStarted = false
var interruptedPercent: CGFloat = 0
```

You will use `hasStarted` to decide if a new pan gesture is the start of a new dismissal, or an attempt to interrupt an ongoing dismissal. If you do interrupt an ongoing dismissal, `interruptedPercent` will be used to make sure the pan gesture’s translation takes the current position of the view into account.

Inside `handle(pan:)`, amend the calculation of `percent`:

```swift
let percent = (translation / pan.view!.bounds.height) + interruptedPercent
```

You’re adding the interrupted percent on here, because if the dismissal was already 50% through when the user touches the screen, that needs to be reflected in the position of the view.

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

If this isn’t the first gesture in the dismissal, the transition is paused and the current percentage is taken from it. The transition must be paused **before** you read the percentage, otherwise you’ll get an inaccurate figure.

Finally, switch over to **AppDelegate.swift** and add the following line to the `animationCleanup` closure created in `animationController(forDismissed:)`:

```swift
interactionController?.hasStarted = false
```

This ensures that the interaction controller is properly reset when the animations are complete.

Build and run the project, show the animals view, then have fun interrupting yourself and wobbling the view up and down!

## Where to go from here?

Congratulations! You’ve had a good exploration of the new powers available to you now that you can use Property Animators! Go forth and fill your apps with interruptible, interactive animations, including an extra level of awesomeness in your view controller transitions.

The WWDC video, 2016 session 216, available at [https://developer.apple.com/videos/play/wwdc2016/216/](https://developer.apple.com/videos/play/wwdc2016/216/) is full of useful information.
