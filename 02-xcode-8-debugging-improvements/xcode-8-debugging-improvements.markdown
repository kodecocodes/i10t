
```metadata
author: "By Jeff Rames"
number: "2"
title: "Chapter 2: Xcode 8 Debugging Improvements"
```

# Chapter 2: Xcode 8 Debugging Improvements

Xcode 8 adds some powerful updates to your debugging toolbox. Race conditions and memory leaks — some of the most challenging issues to diagnose when developing an app — can now be automatically identified in the Issue navigator with runtime tools. The already excellent View Debugger has also gained some polish and makes runtime debugging of constraints easier than ever.

This chapter will cover three major debugging improvements in Xcode 8:

- The **View Debugger** lets you visualize your layouts and see constraint definitions at runtime. Although this has been around since Xcode 6, Xcode 8 introduces some handy new warnings for constraint conflicts and other great convenience features.
- The **Thread Sanitizer** is an all new runtime tool in Xcode 8 that alerts you to threading issues — most notably, potential race conditions.
- The **Memory Graph Debugger** is also brand new to Xcode 8. It provides visualization of your app’s memory graph at a point in time and flags leaks in the Issue navigator.

In this chapter, you’ll be playing the role of a senior developer at Nothin’ But Emojis LLC, where you spend your days cranking out mind-blowing emoji-related products for iOS. Today you’re assisting the boss’ nephew — Ray Nooberlich — with a highly anticipated product named Coloji that lets users view curated colors and emojis.

Ray is a bit new; arguably, too new to be the primary resource on such an important project. As you help him get the app up and running, you’ll find these new tools invaluable for debugging the tricky runtime issues he throws your way.

If you’ve not used the View Debugger before, you may want to brush up with *View Debugging in Xcode 6* at [raywenderlich.com/98356](https://www.raywenderlich.com/98356). The other tools are brand new, so just bring your desire to crush bugs!

## Getting started

The design specifications for Coloji indicate a master-detail interface. The master is a table view with cells displaying colojis, which consist of colors and emojis. The detail view for color colojis shows the selected color in full screen. For emojis, it shows a large view of the emoji centered in the view.

Below is a preview of what the finished project will look like:

![width=80%](./images/final-project-screenshot.png)

The problem is that it will be a while before you get any code in good shape from Ray Nooberlich. He means well, and he’s trying — but, I mean, look at the picture below. This could easily be the featured image for the “Newbie” entry on Wikipedia:

![width=50%](./images/ray-by-faud.jpeg)

Here’s a rundown of the issues you’ll face, and which tools you’ll use to solve them:

1. **Memory leak.** First, the memory footprint of Coloji continues to grow during use. You’ll use the new Memory Graph Debugger to clean this up.
2. **View bug.** Next, the table view cells don’t load anymore. You’ll use the View Debugger to figure out why.
3. **Auto Layout Constraint bug.** Then you'll encounter a mysteriously absent emoji detail view. You'll use the run time constraint debugger to flush out this bug.
4. **Race condition.** Finally, a race condition has reared its ugly head. You’ll use Thread Sanitizer to hunt it down and fix it for good.

## Investigating the project

Imagine you’ve just received a pull request from Ray with what he hopes is the completed project. Open **Coloji.xcodeproj** in the **memory-debugger-starter** folder and take a look at what he pushed. Here are some notes on the most important pieces of the project:

* **ColojiTableViewController.swift** manages the table view, whose data source is loaded with colors and emojis in `loadData()`. The data source is managed by `colojiStore` defined in **ColojiDataStore.swift**.
* **Coloji.swift** contains code used to configure the cells, which are defined and constructed in **ColojiTableViewCell.swift**. It also generates the data source objects.
* **ColojiViewController.swift** controls the detail view, which displays the color or emoji.

Build and run, scroll around a bit, and drill through to some detail views. You might occasionally notice a cell’s content change to a different coloji briefly when you select it, which implies there might be duplicate labels present on a cell:

![iphone bordered](./images/content-change.png)

Because this would have impacts on memory usage, you’ll start by checking out the Memory Report as you use the app.

With the project still running, open the Debug navigator and select **Memory** to display the Memory Report. Note the memory in use by Coloji under the **Usage Comparison** view. In Coloji, start scrolling the table view up and down, and you’ll see the memory usage growing.

![width=90% bordered](./images/memory-usage-growth.png)

Some of this could definitely be duplicate labels — but the rate at which it’s climbing implies there might be more going on. Right now, you’re going with the suspicion of duplicate labels and a likely memory leak. What a perfect opportunity to check out Memory Graph Debugging!

## Memory Graph debugging

In the past, your best bets for tracking unnecessary allocations and leaks were the Allocations or Leaks instruments. They can still be useful, but they are resource-intensive and require a lot of manual analysis.

The Memory Graph Debugger has taken a lot of the work out of finding leaks and memory usage problems. It does this without the learning curve of Instruments.

When you trigger the Memory Graph Debugger, you’re able to view and filter objects in the heap in the Debug navigator. This brings your attention to objects you didn’t expect to see — for instance, duplicate labels.

Additionally, knowing what objects currently exist is the first step in identifying a leak. If you see something there that shouldn’t be, you’ll know to dig deeper.

After you find an object that shouldn’t exist, the next step is to understand how it came into being. When you select an object in the navigator, it will reveal a root analysis graph that shows that object’s relation to all associated objects. This provides you with a picture of what references are keeping your object around.

Below is an example of a root analysis graph focused on the `ColojiDataStore`. Among other things, you can easily see that `ColojiTableViewController` retains the `ColojiDataStore` via a reference named `colojiStore`. This matches up with what you may have seen when reviewing the source.

![width=100%](./images/colojiDataStore-memory-graph.png)

On top of this, the tool also flags occurrences of potential leaks and displays them in a manner similar to compiler warnings. The warnings can take you straight to the associated memory graph as well as a backtrace. Finding leaks has never been this easy!

### Finding the leak

It’s time to look at the Memory Graph Debugger to see what’s causing the growing memory usage in Coloji.

Build and run if you aren't already, and scroll the table view around a bit. Then, select the **Debug Memory Graph** button on the Debug bar.

![width=50% bordered](./images/memory-graph-debugger-button.png)

First, check out the Debug navigator where you’ll see a list of all objects in the heap, by object type.

![width=50% bordered](./images/debug-navigator-memory-graph.png)

In this example, you see 173 instances of `ColojiCellFormatter` and 181 instances of `ColojiLabel` in the heap. The number you’ll see will vary based on how much you scrolled the table, but anything over the number of visible cells on your table view is a red flag. The `ColojiCellFormatter` should only exist while the cell is being configured, and there should only be one `ColojiLabel` per visible cell.

The duplicate `ColojiLabel` instances are likely the reason you saw an unrelated cell appear under the one you selected. Seeing all these occurrences lends support to your theory that labels were placed on top of older ones, rather than being reused. You’ll dig into that further in just a moment — there’s something even _more_ interesting going on here.

You should see a purple warning label to the right of each `ColojiCellFormatter` instance memory address. To investigate the warning, select the warning icon in the activity viewer in the workspace toolbar.

![width=100% bordered](./images/activity-viewer.png)

> **Note**: Alternatively, you can select the Issue navigator directly from the Navigator pane.

This will take you to the Issue navigator, where a few memory leaks are flagged with multiple instances. Be sure that you have **Runtime** issues selected in the toggle if they weren’t already.

![width=50% bordered](./images/leak-issues-navigator.png)

Select one of the instances of a `ColojiCellFormatter` leak:

![width=30% bordered](./images/select-instance.png)

Then and you’ll see a graph appear in the editor. This graph illustrates a retain cycle, where the `ColojiCellFormatter` references `Closure captures`, that is, a closure, and the closure has a reference to the `ColojiCellFormatter`.

![width=60% bordered](./images/retain-cycle-graph-2.png)

The graphs may vary slightly among instances, but all will show the core retain cycle. In some cases, you may see a triangle-like graph: 

![width=50% bordered](./images/malloc-example.png)

Ultimately, the point of interest is the arrow pointing both ways, including a retain in both directions.

The next step is to get to the code in question. Select **Closure captures** from the graph and open the Memory Inspector in the Utilities pane.

![width=50% bordered](./images/backtrace-not-available.png)

The backtrace would be a lot more helpful if it was actually there. It’s turned off by default because it does add some notable overhead and might conflict with other tools. You only want it on when you’re actively using it.

Fortunately, it’s easy to enable malloc stack logging. Select **Coloji** from your schemes and then click **Edit Scheme**:

![width=25% bordered](./images/edit-scheme.png)

In the scheme editor, select the Run action on the left, then the Diagnostics tab at the top. Under Logging, check **Malloc Stack** and then choose **Live Allocations Only**: this requires fewer resources and still retains the logging you need while in the Memory Debugger. Now select **Close**.

![width=100% bordered](./images/enable-malloc-stack.png)

Build and run again, scroll the table a bit, and enter the Memory Debugger. As before, go to the Issue navigator and select one of the `ColojiCellFormatter` leaks.

In the graph, select **Closure captures**, and this time you should see a backtrace in the Memory Inspector. The source code you don’t have access to will be dimmed and inactive, and only a few lines will appear as active. Hover over the line where `tableView(_:cellForRowAt:)` is called and click the **jump indicator** that appears.

![width=60% bordered](./images/backtrace-jump-to-code.png)

This brings you to the following line in **ColojiTableViewController.swift**:

```swift
cellFormatter.configureCell(cell)
```

There’s nothing obviously wrong here. A `ColojiCellFormatter` is defined on the prior line, and this line uses it to configure the current cell. **Command-click** on `configureCell` and you’ll be taken to the following lazy property declaration:

```swift
lazy var configureCell: (UITableViewCell) -> () = {
  cell in
  if let colojiCell = cell as? ColojiTableViewCell {
    colojiCell.coloji = self.coloji
  }
}
```

`configureCell` is initialized with a closure which should make your retain cycle senses tingle. You’ll notice a strong reference to self (`self.coloji`) in the closure. This means `ColojiCellFormatter` retains a reference to `configureCell` and vice versa — a classic retain cycle which leads to the type of leak the Memory Debugger pointed you to.

To fix it, change the line reading `cell in` to the following:

```swift
[unowned self] cell in
```

You’ve specified an unowned reference to self via the capture list, removing the strong reference to `ColojiCellFormatter`. This breaks the retain cycle.

Build and run, restart the Memory Debugger, and navigate back to the Issue navigator to confirm the leak warnings are gone.

![width=50% bordered](./images/cleared-memory-leaks.png)

You just identified and tracked down a leak with just a few clicks. Feels pretty good, doesn’t it?

### Improving memory usage

The leaks are gone, but you still have that peculiar issue with random labels appearing behind any cells you select. You probably recall seeing many instances of `ColojiLabel` hanging around in the heap, while you’d only expect one per visible cell. The exact number of instances depends on how many times you’ve loaded cells, but note the 44 labels in the example heap below:

![width=50% bordered](./images/extra-coloji-labels.png)

Build and run, and start the Memory Debugger if it’s not already running.

Select a few instances of `ColojiLabel` from the Debug navigator, and you’ll see varying graphs as the state of objects associated with each instance change over time. In all cases, however, you should see the `ColojiLabel` is tied to a `ColojiTableViewCell`:

![width=90% bordered](./images/coloji-label-graph.png)

Select a `ColojiTableViewCell` on the graph, and you’ll see its memory address in the Memory Inspector (it can also be found in bread crumbs above the graph):

![width=50% bordered](./images/graph-item-memory-address.png)

If you select a few different `ColojiLabel` graphs from the Debug navigator and verify the address of the associated `ColojiTableViewCell`, you’ll eventually notice some overlap. This further confirms the theory that duplicate labels are being placed on each cell.

On the graph, select the **ColojiLabel** and then select the top active line in the backtrace:

![width=50% bordered](./images/select-this-line-backtrace.png)

This should take you to `addLabel(coloji:)` in **ColojiTableViewCell.swift**, where you create the `ColojiLabel`. The contents of the method looks like this:

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

This creates a new `ColojiLabel`, provides it with the passed-in `coloji` for formatting, and places it in the cell’s `contentView`. The problem is that this code is called every time a cell is passed a coloji. The end result is that _every single time_ a new cell appears, this code creates a brand-new label and places it on the cell — just as you suspected!

The solution is to create a single `ColojiLabel` per cell and update its contents when the cell is reused. First, add the following property to the top of `ColojiTableViewCell`:

```swift
private let label = ColojiLabel()
```

Here you initialize a label that will be retained by the cell and updated when content changes.

Next, modify the contents of `addLabel(coloji:)` to match the following:

```swift
label.coloji = coloji
if label.superview == .none {
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

Rather than initializing a new label every time here, you use the `label` property instead, and simply update its displayed coloji. To avoid the label being added to the cell repeatedly, you wrap that bit of code in a check that ensures it only adds the label the first time through.

Build and run, scroll the table a bit, and tap a few cells. You should no longer see a flicker of some other `ColojiLabel` when a cell is selected.

Enter the Memory Debugger and return to the Debug navigator. Now you’ll only see one `ColojiLabel` on the heap per cell, confirming this bug has been exterminated!

![width=60% bordered](./images/coloji-label-fixed.png)

Now that you’ve found the bug, you walk Ray through the changes, trusting he’ll get it right in the next push. What could possibly go wrong?

## Thread Sanitizer

Well, something went wrong. Open **Coloji.xcodeproj** in the **thread-sanitizer-starter** folder to see what Ray sent over after fixing the memory issues.

Build and run, and while the memory issues were resolved, you’re now seeing something new. There’s missing data, and you’re only seeing a random sample of cells. Each time you run, different cells may appear, but here’s a look at one attempt:

![iPhone bordered](./images/coloji-race-condition.png)

Only three cells loaded, and they appear to be a random selection. Open **ColojiTableViewController.swift** and take a look up top at the properties that drive the data source:

```swift
let colors: [UIColor] = [.gray, .green, .yellow, .brown, .cyan, .purple]
let emoji = ["💄", "🙋🏻", "👠", "🎒", "🏩", "🎏"]
```

It seems the latest run displayed the second-to-last color and the last two emojis. That doesn’t make much sense. Now is a good time to check what Ray did to the code that loads the data. Take a look at `loadData()` in the extension and you’ll see it contains the following:

```swift
// 1
let group = DispatchGroup()

// 2
for color in colors {
  queue.async(
    group: group,
    qos: .background,
    flags: DispatchWorkItemFlags(),
    execute: {
      let coloji = createColoji(color: color)
      self.colojiStore.append(coloji: coloji)
  })
}

for emoji in emoji {
  queue.async(
    group: group,
    qos: .background,
    flags: DispatchWorkItemFlags(),
    execute: {
      let coloji = createColoji(emoji: emoji)
      self.colojiStore.append(coloji: coloji)
  })
}

// 3
group.notify(queue: DispatchQueue.main) {
  self.tableView.reloadData()
}
```

The code above does the following:

1. `group` is a dispatch group created to manage the order of tasks added to it.
2. For each color and emoji in the arrays you just reviewed, this code kicks off an asynchronous operation on a `background` thread. Inside, the operation creates a `coloji` from the color or emoji and then appends it to the store. These are all queued up together in the same `group` so that they can complete together.
3. The `notify` kicks off when all the asynchronous `group` operations complete. When this is done, the table reloads to display the new colojis.

It looks like Ray was trying to improve efficiency by letting the coloji data store operations run concurrently. Concurrent code, coupled with random results, is a strong indicator a race condition is at play.

Fortunately, the new Thread Sanitizer makes it easy to track down race conditions. Like the Memory Graph and View Debuggers, it provides runtime feedback right in the Issue navigator.

$[=s=]

Here’s an example of what it looks like (note this will not appear for you yet):

![width=60% bordered](./images/tsan-issue-navigator-preview.png)

One of the toughest bugs to squash in development has been refined down to a single warning in the Issue navigator! This tool will surely save a lot of headaches.

![width=40%](./images/horrible-mistake.png)

It’s important to note that Thread Sanitizer only works in the simulator. This is contrary to how you’ve probably debugged race conditions in the past, where the device has usually been the better choice. Threading issues often behave differently on devices than they do in the simulator due to processor timing and speed differences.

However, the sanitizer can detect races even when they don’t occur on a given run, as long as the operations involved in the race kick off. Thread Sanitizer does this by monitoring how competing threads access data. If Thread Sanitizer sees the opportunity for a race condition, it flags a warning.

Using Thread Sanitizer is as simple as turning it on, running your app in the simulator and exercising the code where a race might exist. For this reason, it works well alongside unit testing, and ideally, should be run on a regular basis.

In this section, you’re focusing on race conditions as they are the most common use case for Thread Sanitizer. But the tool can do much more, such as flag thread leaks, the use of uninitiated mutexes and unlocks happening on the wrong thread.

### Detecting thread conflicts

There’s basically only one step to use Thread Sanitizer: enable it.

Edit the **Coloji** scheme, select the Run action and select the Diagnostics tab. If **Malloc Stack** is still checked from your Memory Debugging, uncheck it as it can’t be enabled while running the Thread Sanitizer. Now check **Thread Sanitizer** and then select **Close**.

![width=90% bordered](./images/enable-thread-sanitizer.png)

>**Note**: You can also check **Pause on issues** under Thread Sanitizer to have execution pause each time a race is detected. Although you won’t do this in this chapter, this will break on the problem line and display a message describing the issue.

Build and run. As soon as the table view loads, Thread Sanitizer will start notifying you of threading issues via the workspace toolbar and the Issue navigator. Open the Issue navigator, ensure you have **Runtime** selected, and you should see a number of data races on display.

The following image focuses on a single data race. In it, you can see a read operation on thread 6 is at odds with a write on thread 13. Each of these operations shows a stack trace, where you’ll see they conflicted on a line within `append()` inside `ColojiDataStore`:

![width=90% bordered](./images/thread-sanitizer-issues.png)

Select `ColojiDataStore.append(coloji : Coloji) -> ()` in either trace, and you’ll be taken straight to the problematic code in the editor:

```swift
data = data + [coloji]
```

`data` is an array of `Coloji` objects. The above line appends a new `coloji` to the array. It’s not thread-safe since there is nothing to prevent two threads from attempting this read/write operation at the same time. That’s why Thread Sanitizer identified a situation where one thread was reading at the same time another was writing.

A simple solution to this to create a `DispatchQueue` and use it to execute operations on this data serially.

Still in **ColojiDataStore.swift**, add the following property at the top of `ColojiDataStore`:

```
let dataAccessQueue = DispatchQueue(label: "com.raywenderlich.coloji.datastore")
```

You’ll use the serial queue `dataAccessQueue` to control access to the data store array. The label is simply a unique string used to identify this queue.

Now, replace the three methods in this class with the following:

```swift
func colojiAt(index: Int) -> Coloji {
  return dataAccessQueue.sync {
    return data[index]
  }
}

func append(coloji: Coloji) {
  dataAccessQueue.async {
    self.data = self.data + [coloji]
  }
}

var count: Int {
  return dataAccessQueue.sync {
    return data.count
  }
}
```

You’ve wrapped each data access call in a queue operation to ensure no operation can happen concurrently. Note that `colojiAt(index:)` and `count` are run synchronously, because the caller is waiting on them to return data. `append(coloji:)` is done asynchronously, because it doesn’t need to return anything.

Build and run, and you should see all your colojis appear:

![iPhone bordered](./images/coloji-threading-issue-fixed-screenshot.png)

The order can vary since your data requests run asynchronously, but all the cells make it to the data source. Looks like you may have solved the issue.

To further confirm you’ve solved the race conditions, take a look at the Issue navigator where you should see 0 issues:

![width=40% bordered](./images/fixed-race-condition-issue-navigator.png)

Congratulations — you chased down a race condition by simply checking a box! Now it’s just a matter of sending a politely-worded feedback report to Ray, and surely, _surely_ that will be the end of Ray’s issues.

## View debugging

According to your Apple Watch, your pulse has climbed to 120 beats per minute after seeing the next pull request from Ray. Open **Coloji.xcodeproj** in the **view-debugging-starter** folder to see how Ray made out with his race condition fixes.

Build and run, then navigate around a bit. It’s tough to tell if the threading issue was fixed because the cells are now completely blank! There are functional color detail views, but the emojis are way at the top, obstructed by the navigation bar. Sigh.

![width=70%](./images/empty-view.png)

The View Debugger is a great tool to investigate each of these issues. You’ll start with the blank cells.

Prior versions of the View Debugger already displayed run time constraints of your views in the Size Inspector. The biggest improvement in the View Debugger under Xcode 8 is that you can now see constraint warnings, similar to those you see at design time in Interface Builder. Below is an example of such a warning in the Size Inspector:

![width=50%](./images/runtime-constraint-warning.png)

Because the table view constraints in Coloji are all set in code, the only way you could view constraint warnings before Xcode 8 was via difficult-to-discern console output. These new visual constraint warnings will make debugging constraint issues in Coloji much easier.

There are plenty more subtle enhancements as well. In the Debug navigator, you can now filter the view hierarchy by memory address, class name or even super class name. From the Object Inspector, you can jump straight to a view class. Debug snapshots are also much faster — 70% faster, according to Apple.

It’s time to try out a few of these new features as you determine what happened to the cell content and emoji detail view.

### Debugging the cell

First, open **ColojiTableViewCell.swift** to see how the layout of the cell is defined.

You’ll see a setter for the `coloji` property that calls `addLabel(coloji:)`, passing the newly set coloji. `addLabel(coloji:)` sets the cell’s `ColojiLabel` with the given coloji. If the label is not already on the cell’s `contentView`, this code places it there and positions it with Auto Layout.

In this same file, you can see the definition of `ColojiLabel` which is a UILabel subclass. When it gets set, as `addLabel(coloji:)` does, it uses the provided coloji either to color its background or to set its text with the emoji.

Since you don’t see the `ColojiLabel`, the only view that should be in the cell’s content view, that’s a good place to focus your questions. Is the label actually in the content view? If so, what size is it and where does it sit within the content view?

Build and run, and stay on the blank table view. Now select the **Debug View Hierarchy** button in the Debug bar.

![width=50% bordered](./images/view-debugger-debug-bar.png)

In the Debug navigator, enter **ColojiLabel** in the filter. This will show the view hierarchy leading to each label. Here you’re able to confirm that the `ColojiLabel` is inside the content view (`UITableViewCellContentView`) of the cell (`ColojiTableViewCell`).

![width=80% bordered](./images/view-deubber-filter.png)

> **Note**: You can also try filtering for **UILabel**, and you’ll see all the `ColojiLabel` as well as the UILabel in the navigation bar. The ability to filter by parent class is a very useful new feature for complex layouts.

Select any of the labels, and take a look at the Size Inspector. In the Constraints section, you’ll see all the currently active constraints for the label. Looking over the constraints, you’ll notice immediately that something looks wrong:

![width=50% bordered](./images/label-constraint-zeroes.png)

A 0 height and width certainly explains an invisible label! It’s time to investigate what has gone wrong with the code that sets the constraints.

With a `ColojiLabel` still selected, switch to the Object Inspector in the Utilities pane. For public classes, an annotation will be present next to the **Class Name** allowing you to jump directly to the source. Because ColojiLabel is private, you won’t see it.

Back in the debug navigator, move up the label’s hierarchy a bit until you get to the public **ColojiTableViewCell**, which happens to reside in the same file as the label. In the Object Inspector, you’ll now be able to click the annotation to jump right to the source for this class.

![width=40% bordered](./images/source-jump.png)

Now inside **ColojiTableViewCell.swift**, find `addLabel(coloji:)` where the `label` is added to the `contentView` and constrained to its parent. It looks like this:

```swift
label.coloji = coloji
if label.superview == .none {
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

There aren’t any constraints here that set the height or width of the `label` that explain what you’re seeing at runtime.

But, something else may have caught your eye. Auto Layout is being used, yet this is missing the vital setting to prevent autoresizing masks from being converted into constraints. The zeroed label size is exactly the type of behavior you might hit in such a case, so it seems you’ve found your culprit.

Add the following line, right after the `if label.superview == .none` line:

```swift
label.translatesAutoresizingMaskIntoConstraints = false
```

This prevents autoresizing masks from converting into constraints that you don’t expect.

Build and run, check out the table view, and you’ll see you’re back in business.

![iPhone bordered](./images/working-tableview-cells.png)

Unfortunately, this still hasn’t solved your issue with emoji detail views. Take another look, and you’ll see they appear to be centered horizontally, but not vertically:

![iPhone bordered](./images/emoji-vertically-off-center.png)

### Runtime constraint debugging

Missing constraints at runtime are View Debugger’s time to really shine. With an emoji detail view presented, select Debug View Hierarchy again. Once the debugger renders, select the Issue navigator and **Runtime** toggle and you’ll see something like this:

![width=40% bordered](./images/layout-issue-warning.png)

Select the warning and then go to the Size Inspector to see a little more information about the vertical layout. You’ll see the same things as you do at design time in Interface Builder, but now you can see them at runtime!

![width=40% bordered](./images/size-inspector-constraint-warning.png)

It’s pretty easy to see why the vertical layout is ambiguous. The height of the label is defined, but it has no y-position.

Open **ColojiViewController.swift** and find `layoutFor(emoji:)`, where the label constraints are defined. Modify the array passed to `NSLayoutConstraint.activate` so that it looks like this:

```swift
NSLayoutConstraint.activate([
  emojiLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
  emojiLabel.widthAnchor.constraint(equalTo: view.widthAnchor),
  emojiLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
  ])
```

You’ve added a constraint that equates the `centerYAnchor` of the `emojiLabel` with that of the `view`. With this and the height derived via the label’s intrinsic content size, you now have a full set of vertical constraints.

Build and run, select an emoji from the table, and the emoji will now be centered on the detail view.

![width=30% bordered](./images/vertically-centered-emoji.png)

In the past, it was difficult to debug runtime issues if you created or modified your constraints programmatically. You had to dig through frequently-confusing console logs and go over your constraint code with a fine-toothed comb. Layout issue warnings in the View Debugger have changed all this, bringing the ease of design time constraint warnings to runtime.

Having fixed these last couple of issues, it’s just a simple matter of sending the feedback to Ray and getting Coloji out the door. The good news is, Ray (hopefully) has learned a lot throughout this ordeal. Who knows — maybe someday _Ray_ will be the one helping others learn how to build apps! :]

## Static analyzer enhancements

Xcode 8 drastically enhances your ability to debug runtime issues. But it doesn’t stop there — the trusty **static analyzer** has gained a few tricks of its own. But before you get too excited, remember the static analyzer only works with C, C++ and Objective-C.

If you’re working with legacy code, the static analyzer does have some goodies to offer. Besides identifying logic and memory management flaws, it can now assist with solving localization issues and instance cleanup. It can also flag nullability violations.

To use the static analyzer, select **Product\Analyze** with a project open in Xcode. If there are any issues, a static analyzer icon will be displayed in the activity viewer. Clicking the icon will bring you to the Issue navigator, where you can see more information about the problem.

![width=60% bordered](./images/static-analyser-warning.png)

Localizability will notify you whenever a non-localized string is set on a user-facing control in a localized app. Consider the situation where you have a method that accepts an `NSString` and uses it to populate a `UILabel`. If the method caller provided a non-localized string, the static analyzer will flag it and visually indicate the flow of the problem data so you can resolve it.

![width=90% bordered](./images/localizability-tool.png)

Instance Cleanup adds some new warnings around manual retain-release. The mere mention of this probably sends shudders down your spine! But if you occasionally have to suffer through some legacy code without ARC, know that there are some new checks centered around `dealloc`.

Finally, nullability checking finds logical issues in code that contains nullability annotations. This is especially useful for applications that mix Objective-C and Swift. For example, it flags cases where a method with a `_Nonnull` return type has a path that would return `nil`.

While not quite as exciting as new runtime tools, it’s great to see continued improvement in the static analyzer. You can get more detail and some demos of these tools in the WWDC videos referenced below.

## Where to go from here?

In this chapter, you learned about several great new additions and enhancements to Xcode’s debugging tools. The Memory Graph Debugger and Thread Sanitizer have the potential to save countless developer hours and make difficult problems much easier to debug. That old dog, View Debugger, also learned some new tricks including runtime constraint warnings.

This chapter provided a basic introduction to what these tools can do and how to use them. You now know enough to take them for a spin and fit them into your debugging workflow. For more detail on each, check out these WWDC videos:

- Thread Sanitizer and Static Analysis—[apple.co/2aCtz6t](http://apple.co/2aCtz6t)
- Visual Debugging with Xcode—[apple.co/2as1vVu](http://apple.co/2as1vVu)
  