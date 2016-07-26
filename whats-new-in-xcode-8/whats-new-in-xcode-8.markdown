
```metadata
author: "By Jeff Rames"
number: "10"
title: "Chapter 10: User Notifications"
```
  
# Chapter 2: Xcode 8 Debugging Improvements

Xcode 8 adds some powerful updates to your debugging toolbox. Some of the most challenging runtime issues in development—race conditions and memory leaks—can now be automatically identified in the Issue navigator with runtime tools. The already excellent View Debugger has also gained some polish, and makes runtime debugging of constraints easier than ever.

This chapter will cover three tools:

- **View Debugging** allows you to visualize your layouts and see constraint definitions at runtime. Xcode 8 introduces warnings for constraint conflicts along with other convenience features.
- **Thread Sanitizer** is an all new runtime tool that alerts you to threading issues.
- **Memory Graph Debugger** provides visualization of your app's memory graph at a point in time and flags leaks in the Issue navigator.

In this chapter, you'll be playing the role of a senior developer at *Nothin' But Emojis LLC*, where you spend your days cranking out mind blowing emoji related products for iOS. Today you're assisting the boss' nephew—Ray Nooberlich—with a highly anticipated product called Coloji that lets users view curated colors and emojis.

Ray is a bit new—arguably too new to be the primary resource on such an important project. As you help him get the app up and running, you'll find these new tools invaluable for debugging peculiar runtime issues.

TODO: prerequisites?

##Getting Started

The design specifications for Coloji indicate a master detail design. The master is a table view with cells displaying colojis, which can be colors or emojis. The detail view for color colojis shows the selected color in full screen. For emojis, it shows a large view of the emoji centered in the view.

Below is a preview of what the finished project will look like:
TODO: Add screenshot showing master and detail view with an arrow from one of the cells

Here's the problem—it's going to be a while before you get something in good shape from Ray. Here's a rundown of issues you'll face, and what tools you'll be able to use to resolve them: 

1. You'll initially notice the memory footprint of Coloji continues to grow during use. You'll use the new Memory Graph Debugger to clean this up.
2. In his next attempt, you'll use the View Debugger to determine why the table view cells aren't loading anymore. Then you'll leverage the run time constraint debugger while creating the mysteriously missing emoji detail view.
3. You'll run into a newly introduced race condition and use Thread Sanitizer to hunt it down.

You just received a pull request from Ray with what he hopes is the completed project. Open **Coloji.xcodeproj** in the **memory-debugging** folder and take a look at what he pushed. Here are some notes on the most important pieces:

* **ColojiTableViewController.swift** manages the table view, backed by data stored in `colojiStore` (defined in **ColojiDataStore.swift**). The store is populated with colors and then emojis in `loadData()`.
* **Coloji.swift** has code used to configure the cells, which are built in **ColojiTableViewCell.swift**. It also generates the data source objects.
* **ColojiViewController.swift** controls the detail view, which displays the color or emoji.

Build and run, scroll around a bit, and select a few cells. So far, it seems to match the requirements and there are no obvious issues. But this is Ray, so you're going to dig a little deeper before you approve the pull request.

Open the Debug navigator and select **Memory** to display the Memory Report. Note the memory in use by Coloji under the Usage Comparison view. In Coloji, start scrolling the table view up and down, and you'll see the memory usage growing.

![width=100% bordered](./images/memory-usage-growth.png)

It's pretty clear Coloji is leaking memory somewhere in this table view. What a great opportunity to check out Memory Graph Debugging!


--TODO: this chunk is from the prior version.  May be able to reuse some of it--

In the past, your best bet was the Allocations instrument. It's still an option, but it is resource intensive and requires a lot of manual analysis.

With Xcode 8, the Memory Graph Debugger has taken a lot of the work out of finding a memory leak. The tool not only lets you visually explore all objects in memory when it is invoked, but it also flags occurrences of issues like leaks.  [TODO: Does it actually flag more than just leaks?]



Build and run...and wait a while. The first issue becomes immediately evident, as it takes approximately one second to load, which is a lifetime for a user waiting to explore colors and emojis.

Try selecting a few cells, some at the top and some at the bottom, and you'll see several empty detail views and a few with background colors. This is because the emoji detail views are not yet implemented. t's not looking pretty.

TODO: Add screenshot showing master and detail view with an arrow from one of the cells

You already know there is an issue with the code that lays out the table view cells and a problem with slow startup time. Here's a quick rundown of all of the issues you're about to face, and the plan to tackle them:


--TODO: end chunk of stuff you might be able to use elsewhere ---

##Memory Graph Debugging

It's pretty clear Coloji is leaking memory somewhere in this table view. In the past, your best bet was the Allocations or Leaks instruments. They are still an option, but are resource intensive and require a lot of manual analysis.

The Memory Graph Debugger has taken a lot of the work out of finding leaks. It not only helps you visualize your memory usage graph, but it even automatically flags potential leaks.

When you trigger the debugger, you're able to view and filter the heap in the Debug navigator. Knowing what objects currently exist is the first step in identifying a leak—if you see something there that shouldn't be, you know to dig deeper. 

After you find an object that shouldn't exist, the next step is understanding why it exists. The memory graph debugger allows you to view root analysis graphs that show the relation between all objects. When you select an object from the navigator, you can quickly view its root analysis graph to understand what references are keeping it around.

On top of this, the tool also flags occurrences of potential leaks and displays them in a manner similar to compiler warnings. The warnings can take you straight to the associated memory graph as well as a backtrace. Finding leaks has never been this easy!

TODO: Add a reference cycle graph—if I can figure out how to create one.  Might want to add some other graphics here but I don't want to duplicate stuff in the main text too much.

###Finding the Leak

It's time to check these tools out firsthand to see what is causing Coloji to leak.

Build and run and scroll the table view around a bit. Then, select the **Debug Memory Graph** button on the Debug bar.

![width=40% bordered](./images/memory-graph-debugger-button.png)

First, check out the Debug navigator where you'll see a list of all objects in the heap, by object type. 

![width=40% bordered](./images/debug-navigator-memory-graph.png)

There sure are a lot of `ColojiCellFormatter`s (173 in this case) and `ColojiLabel`s (181 here) in the heap. The amount you see will vary based on how much you scrolled the table, but anything over about 8 is a red flag. The `ColojiCellFormatter` should only exist while the cell is being configured, and there should only be one `ColojiLabel` per visible cell. 
TODO: Maybe there should only be a single formatter.  Check this after it's fixed and correct above text. 

This alone gives you a good idea that there is a leak somewhere in cell creation. But the Memory Graph Debugger has gone a bit further by providing a warning label right next to memory addresses of `ColojiCellFormatter` instances. To investigate the warning, select the warning icon in the activity viewer in the workspace toolbar.

![width=90% bordered](./images/activity-viewer.png)

> **Note**: You can alternatively select the Issue navigator directly in from the Navigator pane.

This will take you to the Issue navigator, where a few memory leaks are flagged with multiple instances of each. Be sure that you have **Runtime** issues selected in the toggle if they weren't already. 

![width=90% bordered](./images/leak-issues-navigator.png)

Select one of the instances of a `ColojiCellFormatter` leak, and you'll see a graph appear in the editor. This graph illustrates a retain cycle, where the `ColojiCellFormatter` references a Swift capture context (a closure) and the closure has a reference to the `ColojiCellFormatter`.

![width=40% bordered](./images/retain-cycle-graph.png)

The next step is to get to the code in question. It's most likely related to the closure, so select **Swift capture context** in the graph and open the Memory Inspector in the Utilities pane.

![width=40% bordered](./images/backtrace-not-available.png)

The backtrace would be a lot more helpful if it was actually there. It's off by default, because it does add some notable overhead, and will conflict with other tools. You only want it on when you're actively using it. 

Fortunately, it's easy to enable malloc stack logging. Select **Coloji** from your schemes, and then click **Edit Scheme**:

![width=30% bordered](./images/edit-scheme.png)

In the scheme editor, select the Run action on the left, then the Diagnostics tab at the top. Under Logging, check **Malloc Stack** and then choose **Live Allocations Only**—this requires fewer resources and still retains the logging you need while in the Memory Debugger. Now select **Close**.

![width=90% bordered](./images/enable-malloc-stack.png)

Build and run again, scroll the table a bit, and enter the Memory Debugger. As before, navigate to the Issue navigator and select one of the `ColojiCellFormatter` leaks. 

In the graph, select the **Swift capture context** and this time you should see a backtrace in the Memory inspector in the Utilities pane. Source you don't have access to will be dimmed, so just a few lines will be active. Hover over the line where `tableView(_:cellForRowAt:)` is being called and click the jump indicator that appears.

![width=40% bordered](./images/backtrace-jump-to-code.png)

This brings you to the following line in **ColojiTableViewController.swift**:

```swift
cellFormatter.configureCell(cell)
```

There's nothing obviously wrong here. A `ColojiCellFormatter` is defined on the prior line, and this line uses it to configure the current cell. Command click on configureCell and you'll be taken to the following lazy property declaration:

```swift
lazy var configureCell: (UITableViewCell) -> () = {
  cell in
  if let colojiCell = cell as? ColojiTableViewCell {
    colojiCell.coloji = self.coloji
  }
}
```

`configureCell` is initialized with a closure which should start your retain cycle senses tingling. You'll notice a strong reference to self (`self.coloji`) in the closure. This means `ColojiCellFormatter` retains a reference to `configureCell` and vice versa—a classic retain cycle which leads to the type of leak the Memory Debugger pointed you to.

To fix it, change the `cell in` line to:

```swift
[unowned self] cell in
```

You've specified an unowned reference to self via the capture list, removing the strong reference to `ColojiCellFormatter`. This breaks the retain cycle. Build and run, restart the Memory Debugger, and get back into the Issue navigator to confirm the leak warnings are gone.

![width=40% bordered](./images/cleared-memory-leaks.png)

###Improving Memory Usage

The leaks are gone, but you might have noticed another issue in the Debug navigator. There are quite a few `ColojiLabel`s hanging around in the heap, while you only need one per visible cell. It depends on how many times you've loaded the cell, but note the count of labels in this example:

![width=40% bordered](./images/extra-coloji-labels.png)

Select a few instances of `ColojiLabel` from the Debug navigator, and you'll see varying graphs as the state of objects associated with each instance change over time. In all cases, however, you should see the ColojiLabel is tied to a `ColojiTableViewCell`:

![width=80% bordered](./images/coloji-label-graph.png)

On the graph, select the ColojiLabel and then the top active line in the backtrace. This should take you to `addLabel(coloji:)` in **ColojiTableViewCell.swift**, where the ColojiLabel is created. The contents of the method looks like this:

```swift
let label = ColojiLabel()
label.coloji = coloji
label.translatesAutoresizingMaskIntoConstraints = false
contentView.addSubview(label)
NSLayoutConstraint.activate(
  [label.leadingAnchor.constraint(equalTo:
    contentView.leadingAnchor),
   label.bottomAnchor.constraint(equalTo:
    contentView.bottomAnchor),
   label.trailingAnchor.constraint(equalTo:
    contentView.trailingAnchor),
   label.topAnchor.constraint(equalTo:
    contentView.topAnchor)
  ])
``` 

This creates a new `ColojiLabel`, provides it with the passed `coloji` for formatting, and places it in the cell's `contentView`. The problem is that this code is called every time a cell is passed a coloji, which happens every time a new cell appears. The end result is that a new label is created and placed on the cell every time a cell appears.

The solution is to create a single ColojiLabel per cell, and update its contents when the cell is reused. First, add the following property to the top of ColojiTableViewCell:

```swift
private let label = ColojiLabel()
```

Here you initialize a label that will be retained by the cell and updated when content changes.

Next, modify the contents of `addLabel(coloji:)` to match the following:

```swift
label.coloji = coloji
if(label.superview == .none) {
  label.translatesAutoresizingMaskIntoConstraints = false
  contentView.addSubview(label)
  NSLayoutConstraint.activate([
    label.leadingAnchor.constraint(equalTo:
      contentView.leadingAnchor),
    label.bottomAnchor.constraint(equalTo:
      contentView.bottomAnchor),
    label.trailingAnchor.constraint(equalTo:
      contentView.trailingAnchor),
    label.topAnchor.constraint(equalTo:
      contentView.topAnchor)
    ])
}
```

Rather than initializing a label here, the `label` property is used. It is provided the passed `coloji`, just as before, which tells the cell to update with the content. To avoid the label being added to the cell repeatedly, you've wrapped the code that places it in a check that ensures it only happens the first time.

Build and run, scroll the table a bit, enter the Memory Debugger and return to the Debug navigator. You should now see only one `ColojiLabel` on the heap per cell. 

![width=40% bordered](./images/coloji-label-fixed.png)

Now it's time to walk Ray through the changes, and trust that he'll get it right in the next push.  What could go wrong?

##Thread Sanitizer 

Well, something went wrong. Open **Coloji.xcodeproj** in the **thread-sanitizer** folder to see what Ray sent over after fixing the memory issues.

Build and run, and while the memory issues were resolved, you're now seeing something new. The cells aren't loading in order, and some of them are even missing. Each time you run different cells appear in different order, but here's a look at one attempt:

![iPhone bordered](./images/coloji-race-condition.png)

Only three cells loaded, and they appear to be a random selection. Open **ColojiTableViewController.swift** and take a look up top at the properties that drive the data source:

```swift
let colors = [UIColor.gray(), UIColor.green(), UIColor.yellow(),
              UIColor.brown(), UIColor.cyan(), UIColor.purple()]
let emoji = ["💄", "🙋🏻", "👠", "🎒", "🏩", "🎏"]
```

It seems the latest run displayed the second to last color, and the last two emojis—it doesn't make much sense. Now is a good time to check what Ray has done with the code for loading data. Take a look at `loadData()` and you'll see it contains the following:

```swift
// 1
let group = DispatchGroup()

// 2
for color in colors {
  queue.async(group: group, qos: .background,
              flags: DispatchWorkItemFlags(), execute: {
    let coloji = createColoji(color: color)
    self.colojiStore.append(coloji: coloji)
  })
}

for emoji in emoji {
  queue.async(group: group, qos: .background,
              flags: DispatchWorkItemFlags(), execute: {
    let coloji = createColoji(emoji: emoji)
    self.colojiStore.append(coloji: coloji)
  })
}

// 3
group.notify(queue: DispatchQueue.main) {
  self.tableView.reloadData()
}
```

This code is doing the following:

1. `group` is a dispatch group created to manage the order of asynchronous operations.
2. For each color and emoji in the arrays you just reviewed, an asynchronous operation is kicked off on a `background` thread. Inside, it creates a `coloji` from the color or emoji and then appends it to the store. These are all queued up together in the same `group` so that they can complete as a group.
3. The `notify` kicks off when all the asynchronous operations complete, based on the `group`. When this is done, the table reloads to display the new colojis.

It looks like Ray was trying to improve efficiency by letting the coloji data store operations run concurrently. Concurrency and random results together are a very strong indicator that there is a race condition at play.

Fortunately, the new Thread Sanitizer makes it easy to track down race conditions. Like the Memory Graph and View Debuggers, it provides runtime feedback right in the Issue navigator. It looks like this:

![width=40% bordered](./images/tsan-issue-navigator-preview.png)

After years of frantically digging through code in your problem area looking for issues that might cause a race—this tool is a life saver. One of the toughest issues in development refined down to a warning in the Issue navigator!

![width=30% bordered](./images/horrible-mistake.png)

It's important to note that Thread Sanitizer only works in the simulator. This is contrary to how you've probably been debugging race conditions, where a device is the better choice. Threading issues often behave differently on devices versus the simulator due to timing and speed differences of their different processors.

However, the sanitizer can detect races even when they don't occur on a given run, as long as the operations involved in the race are kicked off. Thread sanitizer does this by monitoring the way competing threads access data. If sees the opportunity for a race, a warning is provided.

Using Thread Sanitizer is as simple as turning it on, running your app in the simulator, and exercising the code where a race might exist. For this reason, it works well along with unit testing, and should ideally be run on a regular basis.

###Using Thread Sanitizer

Edit the **Coloji** scheme, select the build action and select the Diagnostics tab. If **Malloc Stack** is still checked from your Memory Debugging, uncheck it as it cannot be enabled while running the Thread Sanitizer. Now check **Thread Sanitizer** and then select **Close**.

![width=90% bordered](./images/enable-thread-sanitizer.png)

Build and run. As soon as the table view loads, 

* Intro  [Theory]
  * Review the dispatch group code that loads colors & emojis
  * Describe the assumption that the issue is a race condition
  * High level overview of the thread sanitizer
* Using Thread Sanitizer [Instruction]

  hunt down the race condition by looking at runtime threading issues
* Fixing the Race Condition [Instruction]

  Fix the race, verifying the results via build & run as well as sanitizer 
<<<<<<< HEAD
##View Debugging

With great trepidation, you notice another pull request from Ray—open **Coloji.xcodeproj** in the **view-debugging** folder to see it. Build and run, and navigate around a bit. It's tough to tell if the threading was fixed yet, because now the cells and detail views are completely blank!

![width=70%](./images/empty-view.png)

The View Debugger is a great tool to investigate where the views went, and that's where you'll start.

Prior versions of the view debugger already displayed run time constraints of your views in the size inspector. The biggest improvement in Xcode 8 View Debugger is that you can also see warnings, similar to what you see at design time in interface builder. Because the table view constraints were all done in code, this new feature allows you to view constraint warnings where you previously could not.

TODO: (only if room) Show a generic warning in the inspector

There are plenty of more subtle enhancements as well. In the debug navigator, you can now filter the view hierarchy by memory address, class name or even super class name. From the Object inspector, you can jump straight to a view class. Debug snapshots are also much faster—70% faster by Apple's metrics.

It's time to try out a few of these new features while determining what happened to the cell content.

###Debugging the Cell

First, open **ColojiTableViewCell.swift** to get an idea of how the layout of the cell is defined. You'll see a setter for the `coloji` property that calls `addLabel(coloji:)` which places a `ColojiLabel` in the content view using Auto Layout to position it. In this same file, you can see `ColojiLabel` is a UILabel subclass that sets its background color for color cells and provides an emoji as text in emoji cells.

Since you don't see the ColojiLabel, the only view that should be in the cell's content view, that's a good place to focus your questions. Is the label actually in the content view? If so, what size is it and where does it sit within the content view?

Build and run, and stay on the blank table view. Now select the **Debug View Hierarchy** button in the Debug bar.

![width=40% bordered](./images/view-debugger-debug-bar.png)

In the Debug navigator, enter **ColojiLabel** in the filter. This will show the view hierarchy leading to each label. Here you're able to confirm that the `ColojiLabel` is inside the content view (`UITableViewCellContentView`) of the cell (`ColojiTableViewCell`).

![width=50% bordered](./images/view-deubber-filter.png)

> **Note**: You can also try filtering for **UILabel**, and you'll see your ColojiLabels as well as the UILabel in the navigation bar. The ability to filter by parent class is a very useful new feature for complex layouts.

Select any of the labels, and take a look at the Size inspector. In the Constraints section, you'll be able to see all of the currently active constraints for the label. Looking over the constraints—you'll immediately see something is not right:

![height=35% bordered](./images/label-constraint-zeroes.png)

A 0 height and width certainly explains an invisible label! It's time to check the code to see what has gone wrong with the code that sets the constraints.

To quickly jump to the view's code, switch to the Object inspector. For public classes, an annotation will be present next to the **Class Name** allowing you to jump directly to the source. Because ColojiLabel is private, you won't see it.

Back in the debug navigator, move up the label's hierarchy a bit until you get to the public **ColojiTableViewCell**, which happens to reside in the same file as the label. In the Object inspector, you'll now be able to click the annotation to jump right to the source for this class.

![width=30% bordered](./images/source-jump.png)

Now inside **ColojiTableViewCell.swift**, find `addLabel(coloji:)` where the `label` is added to the `contentView` and constrained to its parent. It looks like this:

```swift
let label = ColojiLabel()
label.coloji = coloji
contentView.addSubview(label)
NSLayoutConstraint.activate([
  label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
  label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
  label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
  label.topAnchor.constraint(equalTo: contentView.topAnchor)
  ])
```

There aren't any constraints here that set the height or width of the `label` that explain what you're seeing at runtime.

But, something else may have caught your eye. Auto Layout is being used, yet this is missing the vital setting to prevent autoresizing masks from being converted into constraints. The zeroed label size is exactly the type of behavior you might hit in such a case, so it seems you've found your culprit.

Add the following line, right after the label definition in `addLabel(coloji:)`:

```swift
label.translatesAutoresizingMaskIntoConstraints = false
```

Build and run, check out the table view, and you'll see you're back in business.

![iPhone bordered](./images/working-tableview-cells.png)

Not so fast—it appears Ray has struck again! The cells and color detail views look fine, but emoji detail views aren't vertically centered anymore. 

TODO: code at this point will just be missing the Y centering constraint
![iPhone bordered](./images/emoji-vertically-off-center.png)

###Runtime Constraint Debugging

Missing constraints at runtime are the View Debugger's time to really shine. With an emoji detail view presented, select Debug View Hierarchy again. Once the debugger renders, select the Issue navigator and **Runtime** toggle and you'll see something like this:

![width=30% bordered](./images/layout-issue-warning.png)

Select the warning and then go to the Size inspector to get a bit more context about the vertical layout. You'll see the same type of info you get during design time in interface builder, but now at runtime!

![width=30% bordered](./images/size-inspector-constraint-warning.png) 

It's pretty easy to see why the vertical layout is ambiguous. The height of the label is defined, but it has no Y position.

Open **ColojiViewController.swift** and find `layoutFor(emoji:)`, where the label constraints are defined. Modify the array passed to `NSLayoutConstraint.activate` so that it looks like this:

```swift
NSLayoutConstraint.activate([
  emojiLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
  emojiLabel.widthAnchor.constraint(equalTo: view.widthAnchor),
  emojiLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
  ])
```

You've added a constraint that equates the `centerYAnchor` of the `emojiLabel` with that of the `view`. With this and height created from the intrinsic content size of the label, you now have a full set of vertical constraints.

Build and run, select an emoji from the table, and the emoji is back to being centered on the detail view.

![width=30% bordered](./images/vertically-centered-emoji.png)

In the past, if you created or modified your constraints automatically, you were pretty much on your own with runtime issues. You had to dig through often confusing console logs and study your constraint code without much direction. Layout issue warnings in the view debugger have changed all this, bringing the ease of design time constraint warnings to runtime.

Having fixed these last couple of issues, it's just a simple matter of sending the feedback to Ray and getting Coloji out the door. What could go wrong?
  
##Static Analyzer Enhancements [Reference]
(this will get dumped if length is an issue)
About a paragraph about each of these.  I'll put in some screenshots, but won't tie this into Coloji.

* Localizability
* Instance Cleanup
* Nullability

##Where to Go From Here?
* WWDC Videos
* RW View Debugger tutorial (noted that not a ton has changed)




