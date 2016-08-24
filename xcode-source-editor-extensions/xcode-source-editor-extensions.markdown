## xcode-source-editor-extensions

```metadata
author: "By Jeff Rames"
number: "3"
title: "Chapter 3: Xcode 8 Source Editor Extensions"
```
# Chapter 3: Xcode 8 Source Editor Extensions

Source editor extensions, new to Xcode 8, are the first official way to add custom functionality to Xcode. As the name implies, they rely on the extension architecture that has gained increasing prevalence on Apple's platforms recently.

As you might guess from the *source* in source editor extensions, scope is limited to performing operations on text from the IDE. This means you cannot customize Xcode's UI or modify settings—your interface is via menu items and only text passes between Xcode and the extension.

Xcode plugins have been available with fewer restrictions for some time thanks to the developer community and the package manager Alcatraz. These rely on private frameworks, introduce security and stability risks, and depend on frequent updates to keep them working. 

Xcode 8 uses runtime library validation to improve security. With this change, the time for updating plug-ins has come to an end, as the mechanism they used to run under Xcode is now closed off.

Source editor extensions are fully asynchronous and run under their own process, minimizing any performance impacts to the IDE. Using an officially supported interface, they're also less likely to break with each Xcode release. Finally, the extension model provides a clean interface to Xcode that makes it quite easy to generate tools.

While this is a book on iOS 10, keep in mind that source editor extensions are actually macOS applications. That being said, you'll be working primarily with Foundation, so even if this is your first foray into macOS, there aren't any pre-requisites.

In this chapter, you'll build an extension called ASCIIify. It's based on an existing macOS application that takes text input and outputs an ASCII art version of that text. The extension will leverage that code to convert text selected in Xcode into a comment in ASCII art format.

```swift
//      _      ____     ____   ___   ___   _    __         
//     / \    / ___|   / ___| |_ _| |_ _| (_)  / _|  _   _ 
//    / _ \   \___ \  | |      | |   | |  | | | |_  | | | |
//   / ___ \   ___) | | |___   | |   | |  | | |  _| | |_| |
//  /_/   \_\ |____/   \____| |___| |___| |_| |_|    \__, |
//                                                   |___/ 
```

## Getting started

In the starter project folder, open **Asciiify.xcodeproj**.

Take a look around the source. Here are some notable items you'll see:

- The **Figlet** group consists of a Swift wrapper around a JavaScript FIGlet implementation by Scott González. A FIGlet is a program that makes ASCII art representations of text. You'll use this, but it's not necessary to become familiar with the implementation details.
- **Main.storyboard** contains a simple view with a text field and label. This view is for the macOS app—not your extension. However, it will help demonstrate what the library does.
- **AsciiTransformer.swift** TODO add some details and figure out if this is worth explaining here

Before you can build and run, you need to set up signing with your team information. Select the **Asciiify** project from the navigator and then the **Asciiify** target. From the General tab, select your team name from the **Team** dropdown:

![width=100% bordered](./images/select-team-asciiify.png)

Build and run the Asciiify target and type some text into the top text field. Your asciiified output will show up in the label below.

![width=70% bordered](./images/asciiify-demo.png)

Your goal is to have this same behavior occur within Xcode's source editor. To do so, you'll create a source editor extension that leverages the Figlet framework in the same way this macOS application does.

Navigate to File\New\Target and under the macOS tab select **Xcode Source Editor Extension**.

![width=90% bordered](./images/create-extension.png)

Click **Next**, provide the **Project Name** of AsciiifyComment and click **Finish**.

![width=90% bordered](./images/name-extension.png)

If prompted to activate the AsciiifyComment scheme, click **Activate**. This will be used when building the extension.

You'll now notice a new target and a new group in the navigator, both named **AsciiifyComment**. Expand the new group and take a look at what the template has provided. Here's a brief overview of the files you'll be working with:

- **SourceEditorExtension.swift** contains an NSObject that conforms to the `XCSourceEditorExtension` protocol. The protocol defines an optional method, `extensionDidFinishLaunching()`, which is called upon initial launch allowing you to do any required setup. `commandDefinitions` is an optional property that can be used to provide an array of objects that define commands the extension can accept.
- **SourceEditorCommand.swift** defines an object that conforms to the `XCSourceEditorCommand` protocol which consists of one required method—`perform(with:completionHandler:)`. The method is called when a user invokes the extension by selecting a menu item. This is where you'll ultimately asciiify the passed text.
- The **Info.plist** of an extension has several important keys under `NSExtension` that point to the classes covered above, as well as providing a name for the command. It's an array, but currently only contains a single command (*Source Editor Command*) pointing to the classes mentioned above.

Select the AsciiifyComment build scheme, then build and run. When prompted to choose an app to run, select Xcode and then click **Run**. A version of Xcode will launch with a dark icon, activity viewer, and splash screen icon as seen below:

![width=70% bordered](./images/test-xcode-splash.png)

This instance of Xcode is meant for testing your extensions. Once launched, select one of your recent projects or create a new playground. The specifics don't matter as you'll just be adding comments.

Next, navigate to **Editor\Asciiify Comment\Source Editor Command** in the test Xcode instance. Currently this does nothing, because you've not yet implemented any functionality.

![width=80% bordered](./images/extension-menu-item.png)

Now that you have an extension and know how to test it, it's time to implement it!

## Building the asciiify extension

You probably already noticed some low hanging fruit—the name **Source Editor Extension** in the menu item doesn't explain what it's going to do.

Open **Info.plist** in the AsciiifyComment group and expand the `NSExtension` dictionary. Now expand `NSExtensionAttributes` which contains an array of command definitions with the key `XCSourceEditorCommandDefinitions`. For the first array item change the value for key `XCSourceEditorCommandName` to be **Asciiify Comment**:

![width=100% bordered](./images/extension-plist.png)

Build and run the extension, open any project in the test Xcode and you'll now be able to navigate to **Editor\Asciiify Comment\Asciiify Comment**:

![width=80% bordered](./images/extension-menu-item-new-name.png)

Now it looks the way you'd expect, but it still doesn't do anything. Your next step will be to implement the functionality, but first you need to learn a bit more about the data model used by source editor extensions.

### Exploring the command invocation [Theory]

Recall that when a menu command associated with your extension is selected, `perform(with:completionHandler:)` in the `SourceEditorCommand` class will get called. In addition to the completion handler, it is passed a `XCSourceEditorCommandInvocation`.

Inside the `XCSourceEditorCommandInvocation` you'll find everything you need to identify the text to be modified, including the text itself. Here's a quick overview of its properties:

- **commandIdentifier** is a unique identifier for the invoked command, used to determine what processing should be done. The identifier comes from the `XCSourceEditorCommandIdentifier` key in the command definition found in **Info.plist**.
- **buffer** is of type `XCSourceTextBuffer` and is a mutable representation of the text to act upon. You'll get into more detail about its makeup below. 
- **cancellationHandler** gets invoked by Xcode when the user cancels the extension command. Cancellation can be done via a banner that appears within Xcode during processing by a source code extension. Extensions block other operations, including typing in the IDE itself, to avoid merge issues.

The `XCSourceTextBuffer` is the most interesting here, as it contains the data you act upon. Here's a closer look at its notable properties:

[todo need to fill these out once I better understand them]
- **lines** is an array of 
- **selections** is an array of `XCSourceTextRange` objects that identify a start and end position in the text buffer. Generally a single item will be present, representing the user's selection or cursor position in absence of selection. Multiple selections are also possible with macOS using Shift+Command, and are supported here. 
- **completeBuffer** is a String containing the entire buffer. [todo not sure I will put this here] 

TODO: probably want a model that shows how these all fit together; probably showing the flow of data in and out of the extension and back to Xcode

### Build the editor command [Instruction] 

Now that you have a better understanding of the model involved, it's time to dive in and handle a request.

Open **SourceEditorCommand.swift** and add the following to the top with the other imports:

```swift
import Figlet 
```

This is the framework used to create FIGlet representations of text, otherwise known as ASCII art.

Now just inside the `SourceEditorCommand` class, add the following:

```swift
let figlet = FigletRenderer()
```

`FigletRenderer` is the primary controller involved in rendering the FIGlet.

Now replace the comments in `perform(with:completionHandler:)` with the following:

```swift
let buffer = invocation.buffer

// 1
for selection in buffer.selections
  where selection is XCSourceTextRange
    && (selection as! XCSourceTextRange).start.line ==
    (selection as! XCSourceTextRange).end.line {
      // 2
      let selection = selection as! XCSourceTextRange
      let line = buffer.lines[selection.start.line] as! String
      let startIndex = line.characters.index(
        line.startIndex, offsetBy: selection.start.column)
      let endIndex = line.characters.index(
        line.startIndex, offsetBy: selection.end.column)
      
      // 3
      let selectedText = line.substring(with: startIndex ..<
        line.index(after: endIndex))
      // TODO: asciiify the text
}
// 4
completionHandler(.none)
```

This code does some validation and then examines `XCSourceEditorCommandInvocation` to get the selected String and its location in the buffer. Here's how this is accomplished:

1. Each `selection` in the buffer is tested to determine if it exists on a single line. `XCSourceTextRange` contains a `start` and `end` position, and this code confirms those positions are on the same line. This is necessary as FIGlets aren't designed to wrap.
2. Because the selection is only a single line, it can be pulled from the `buffer` using the selection's `start` line position. The `startIndex` and `endIndex` of the selected text within the buffer are derived using the start and end `column` properties of the `selection` offset from the start of the line.
3. `selectedText` is set to the selected String by using `substring(with:aRange:)` and the selection start and end index. A TODO is left here to pass the resulting string to the FIGlet framework to generate the new content.
4. The `completionHandler()` must be called to signify completion of processing for this invocation.

Now that you've the selected text, it's time to feed it to the FIGlet renderer and update the text buffer with the ASCII art.

Still in `perform(with:completionHandler:)`, replace `// TODO: asciiify the text` with the following:

```swift
// 1
if let asciiified = figlet.render(input: selectedText) {
  // 2
  let newLines = asciiified.components(separatedBy: "\n")
  let startLine = selection.start.line
  // 3
  buffer.lines.removeObject(at: startLine)
  buffer.lines.insert(newLines, at: IndexSet(startLine ..< startLine + newLines.count))
}
```

Here's a detailed look at what you did:

1. The FIGlet renderer has a method `render(input:)` that takes a String and returns the ASCII art version of it. You call that here with the `selectedText` obtained in the prior chunk of code.
2. Using the newline character as a separator, you break the resulting String into the array `newLines`. You set `startLine` to the first line of the `selection` which, because you've guarded against multi-line selections, is the only line.
3. You remove the original selected line from the `buffer`, and then insert the `newLines` in its place. The insertion range for `newLines` is from the originally selected `startLine` through the number of lines being inserted.

Build and run, attaching to Xcode and opening any file you like. Select a piece of text and then **Editor\Asciiify Comment\Asciiify Comment** to kick off the extension. And then you'll see...

![width=40%](./images/xcode-quit-ragecomic.png)

This probably looks a bit familiar if you've used Xcode more than once or twice. On the resulting alert, select **Report**:

![width=70%](./images/xcode-quit.png)

In the report window that appears, scroll until you see **Application Specific Information** followed by a backtrace.

![width=100%](./images/xcode-problem-report.png)

For once it's not Xcode being flaky. It's you!

Xcode is crashing due to a an NSSelectionArray—an internal class associated with selection ranges—that appears to be empty. This is because at the time you call the completion handler in `perform(with:completionHandler:)`, you're expected to also identify either an insertion point or selection in the buffer. Otherwise, Xcode doesn't know where to put the cursor after the extension is done.

Add the following property to the top of `perform(with:completionHandler:)`:

```swift
var newSelections = [XCSourceTextRange]()
```

This will be used to save the position of the FIGlet you create. The idea is to select the added text for the user after insertion, so you'll need to track it.

Now add the following code to the bottom of body of `if let asciiified`:

```swift
let startRange = XCSourceTextPosition(line: startLine, column: 0)
let endRange = XCSourceTextPosition(line: startLine +
  newLines.count, column: 0)
let selection = XCSourceTextRange(start: startRange,
                                  end: endRange)
newSelections.append(selection)
```

The selection `startRange` is the first column of the originally selected line. The `endRange` is the first column of the line after the last inserted line, based on the count of `newLines`. 

These are used to create a `XCSourceTextRange` covering the area you want selected after the extension returns. You append this new `selection` to the `newSelections` array you just defined.

TODO: I need to determine precisely where the buffer.selections gets cleared out.  I noticed it doesn't seem to in the 'complete' code, even before I add stuff to it.  In the earlier code it seemed to get cleared right before the completion block.  I need to determien exactly why it gets cleared so I can explain.

- Coding the perform method to kick off asciiify on the selected text
- Placing the Cursor (Selection crash to do some debugging)

### Adding some polish

- Add comments around insertion
- Select the created text on completion
- Key binding for the command

## Dynamic commands

- add the commandDefinitions property with the font list

## Where to go from here?

- WWDC video https://developer.apple.com/videos/play/wwdc2016/414/

