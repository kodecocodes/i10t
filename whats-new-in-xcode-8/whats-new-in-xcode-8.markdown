# Chapter 2: Xcode 8 Debugging Improvements

* Introduction

##Getting Started [Instruction]
  
  * Download and introduce starter (Combo of Sam’s projects that has the threading issue, the auto layout issue, and the memory leaks - so it starts as a slow loading empty tableview)
  * Point out issues that need to be debugged and intro the corresponding tools very high level

##View Debugging
  * Intro [Theory]
    * What's new - run time constraint problem debugging, new view hierarchy filtering options
  * Debugging the Cell [Instruction]

    Determine why the cells are not displaying using the view debugger showing filtering and ‘jump to class’
  * Fixing the layout [Instruction] (this may be collapsed into the prior section)
    
    This is just instruction on fixing the autolayout, which will be brief
  * Adding the Detail View [Instruction]
  
   This is where we add a large emoji display for a detail view.  As in the screencast, we’ll originally leave off vertical constraints so it doesn’t work properly
  * Runtime Constraint Debugging [Instruction]

    debug the vertical centering issue with runtime debugging, then fix it

##Thread Sanitizer 
(I plan to have the async code already in the starter—which differs from the screencast—but may have users add this if this is too short)

* Intro  [Theory]
  * Review the dispatch group code that loads colors & emojis
  * Describe the assumption that the issue is a race condition
  * High level overview of the thread sanitizer
* Using Thread Sanitizer [Instruction]

  hunt down the race condition by looking at runtime threading issues
* Fixing the Race Condition [Instruction]

  Fix the race, verifying the results via build & run as well as sanitizer 
##Memory Graph Debugging
* Intro [Theory]
  * Memory graph explorer and runtime issue tool
  * Describe use case for Debugger (compare to Profiler)
* Finding the Leak [Instruction]
  * Demonstrate memory issue with Coloji
  * Here we’ll use Memory Graph Debugger to identify the issue
* Fixing the Leak [Instruction]
* Improving Memory Usage [Instruction]

  Uncover and look at need to reuse UILabels in the tableview cells

##Where to Go From Here?
* WWDC Videos
* RW View Debugger tutorial (noted that not a ton has changed)




