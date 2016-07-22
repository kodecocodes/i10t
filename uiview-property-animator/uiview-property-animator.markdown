```metadata
author: "By Rich Turton"
number: "9"
title: "Chapter 9: Property Animators"
```

# Chapter 9: Property Animators

## Introduction

TODO: Summary of property animator

If you've done any animations in UIKit you've probably used the UIView animation methods (`UIView.animate(withDuration:animations:)` and friends). `UIViewPropertyAnimator` is a new way to write animation code. It isn't a replacement for the existing API, nor is it objectively "better", but it does give you a lot of control that wasn't possible before. 

In this chapter you'll learn about the following new features that property animators give you access to:

- Detailed control over animation timing
- Monitoring and altering of animation state
- Pause, reverse and scrub animations

TODO: Places where using this would make sense

## Getting started

Open the **Animalation** project in the starter materials for this chapter. This is a demonstration app which you'll modify to add extra animation capabilities. There's a single view controller, and some utility files. Build and run the project:

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

If you're feeling a little confused at this point, don't worry. A property animator can be paused, stopped or finished, and those all mean different things. 

* Reversing [Theory]

What this means, how you'd use it

* Animalation: reversing [instruction]

Reverse the animations as in the screencast, 
Impact on completion handlers

* Interruptibility [theory]

What it means, how it benefits an app

* Interruptibility [instruction]

Allow an in-flight update to be taken over by tapping somewhere else, so it smoothly turns to the new destination. Not sure how much of this is out of the box but it wasn't covered in the screencast.

* Working together [Theory and instruction]

Multiple property animators - how to animate multiple things - can do by adding additional animations as well as the multiple animators approach shown in the screencast

morph animal example from the screenshot
  
* Where To Go From Here?

iOS animations by tutorials!!

