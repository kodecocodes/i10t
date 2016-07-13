```metadata
author: "By Rich Turton"
number: "9"
title: "Chapter 9: Property Animators"
```

# Chapter 9: Property Animators

## Introduction

TODO: Summary of property animator

## Timing is everything

Consider a very simple animation where a view moves along a line, from x = 0 to x = 10. The animation takes 10 seconds. 

At any given second, how far along the line is the view? The answer to this question is given by the animation's **timing curve**. The simplest timing curve isn't curved at all - it's called the **linear** curve. Animations using the linear curve move along at a constant speed - after 1 second, the view is at position 1, after 2 seconds, position 2, and so on. You could plot this on a graph like so:

![width=40%](images/Linear.png)

This doesn't lead to very fluid or natural-seeming animations; things in real life don't go from not moving at all to moving at a constant rate, and then suddenly stopping when they get to the end. For that reason, the `UIView` animation API (`UIView.animate(withDuration:animations:)`) uses an **ease-in, ease-out** timing curve. On a graph, that looks more like this: 

![width=40%](images/Easing.png)

You can see that for the first quarter or so of the time, not much progress is made, then it speeds up, then flattens out again at the end. To the eye the animated object accelerates, moves, then decelerates and stops. This looks a lot more natural.

UIView animations offer you four choices of timing curve: linear and ease-in-ease-out, which you've seen above, **ease-in**, which accelerates at the start but ends suddenly, and **ease-out**, which starts suddenly and decelerates at the end. 

`UIViewPropertyAnimator` offers you almost limitless control over the timing curve of your animations. In addition to the four pre-baked options above, you can supply your own cubic Bézier timing curve. 

Your own cubic _what_ now? 

Don't panic. You've been looking at them already. A cubic Bézier curve goes from point A to point D, while also doing its very best to get near points B and C on the way, like a drunk wandering home past a couple of kebab shops. **TODO: Chris you might want to choose a better analogy :]**

With the two examples above, point A is in the bottom left and point D is in the top right. With the linear curve, points B and C happen to be on the exact straight line. With ease-in-ease-out, point B is below and to the right of the line, point C is above and to the left of it. This psychedelic diagram shows you the effect on the curve of moving points B and C, which are known as the **control points**: 

![width=40%](images/Multiline.png)

The circles represent the control points of the curve, which are varied in the horizontal or vertical direction. The filled circles correspond to the solid lines of the equivalent color, showing variations in the horizontal direction, and the hollow circles to the dashed lines, showing variations in the vertical direction. In the center of the pattern is a straight line, produced when both control points are on the straight path between A and D.

This diagram only shows a small number of the possible curves you can make in this fashion - the take home message is that you can model almost any combination of acceleration, progress and deceleration here. 




--- 
OUTLINE

Title: Property Animators
Prerequisites: UIView animations
Most important concepts: UIViewPropertyAnimator
 
* Introduction

Summary of property animator

* Getting Started [Theory]
    * More powerful timing functions than UIView animations
    * timing curves
    * springs
    * Introduce animalation project 
    * NOTE: a lot of maths theory in the screencast - maybe make the sample app more like a playground where you can see various options side by side? Some diagrams would help too
    
* Animalation one: timing curves [instruction]

Change timing of animation from UIView to property
Experiment with different timing curves, spring with initial velocity from gesture recognizer

* Pausing and Scrubbing [Theory]

What this means, how it benefits apps

* Animalation: pausing and scrubbing  [instruction]

Connect up scrubbing slider

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

