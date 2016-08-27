## xcode-source-editor-extensions

```metadata
author: "By Jeff Rames"
number: "3"
title: "Chapter 3: Xcode 8 Source Editor Extensions"
```
# Chapter 3: Xcode 8 Source Editor Extensions

Source editor extensions, new to Xcode 8, are the first official way to add custom functionality to Xcode. As the name implies, they rely on the extension architecture that has gained increasing prevalence on Apple's platforms recently.

As you might guess from the *source* in source editor extensions, scope is limited to performing operations on text from the IDE. This means you cannot customize Xcode's UI or modify settings—your interface is via menu items and only text passes between Xcode and the extension.

>**Note**: There has been no official word, but plenty of chatter about Apple's plans to expand to additional editor extension types based on community demand. Make sure to file a Radar if there is an Xcode extension you're trying to build that isn't possible with the source extension.

Xcode plugins have been available with fewer restrictions for some time thanks to the developer community and the package manager Alcatraz. They are able to modify Xcode's UI and behavior anywhere—not just within a single source file. However, these rely on private frameworks, introduce security and stability risks, and depend on frequent updates to keep them working. 

Xcode 8 uses runtime library validation to improve security. With this change, the time for updating plug-ins has come to an end, as the mechanism they used to run under Xcode is now closed off. It's a brave new world and developers will be working within Apple's ecosystem to create new tools.

Source editor extensions are fully asynchronous and run under their own process, minimizing any performance impacts to the IDE. Using an officially supported interface, they're also less likely to break with each Xcode release. Finally, the extension model provides a clean interface to Xcode that makes it quite easy to generate tools.

The new source extensions are fairly limited compared to Xcode plugins of old—but what *can* you do with them? Here are some ideas:

- Generate a documentation block for a method containing all parameters and return type based on its signature
- Convert non localized String definitions within a file to the localized version
- Convert color and image definitions to the new color and image literals in Xcode 8 (this was demoed in the WWDC session on source editor extensions)
- Create comment MARKs above an extension block using the name of a protocol it extends
- Generate a print statement with debugging info on a highlighted property
- Clean up whitespace formatting of a file—for instance you might enforce a single line between each method by deleting or adding lines to the file

You'll likely come up with a half dozen more off the top of your head—even with their limitations source editor extensions have a lot of utility. Some will be more general in scope, and some may be very specific to your codebase or standards.

Many developers will prefer to be consumers of editor extensions created by others. If you don't have the itch, and don't have any needs requiring a custom extension, feel free to skip ahead to the next chapter.

While this is a book about iOS 10, keep in mind that source editor extensions are actually macOS applications. That being said, you'll be working primarily with Foundation, so even if this is your first foray into macOS, there aren't any pre-requisites.

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

Take a look around the source. You'll be working exclusively with a source editor extension, which isn't included in the starter, but you will leverage the base functionality in the starter. Here are some notable items you'll see:

- The **Figlet** group consists of a Swift wrapper around a JavaScript FIGlet implementation by Scott González. A FIGlet is a program that makes ASCII art representations of text. You'll use this, but it's not necessary to become familiar with the implementation details.
- **Main.storyboard** contains a simple view with a text field and label. This view is for the macOS app—not your extension. However, it will help demonstrate what the library does.
- **AsciiTransformer.swift** contains the controller class for the Asciiify macOS app.

Before you can build and run, you need to set up signing with your team information. Select the **Asciiify** project from the navigator and then the **Asciiify** target. From the General tab, select your team name from the **Team** dropdown:

![width=100% bordered](./images/select-team-asciiify.png)

Build and run the Asciiify scheme and type some text into the top text field. Your asciiified output will show up in the label below.

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

### Exploring the command invocation

Recall that when a menu command associated with your extension is selected, `perform(with:completionHandler:)` in the `SourceEditorCommand` class will get called. In addition to the completion handler, it is passed a `XCSourceEditorCommandInvocation`.

Inside the `XCSourceEditorCommandInvocation` you'll find everything you need to identify the text to be modified, including the text itself. Here's a quick overview of its properties:

- **commandIdentifier** is a unique identifier for the invoked command, used to determine what processing should be done. The identifier comes from the `XCSourceEditorCommandIdentifier` key in the command definition found in **Info.plist**.
- **buffer** is of type `XCSourceTextBuffer` and is a mutable representation of the text to act upon. You'll get into more detail about its makeup below. 
- **cancellationHandler** gets invoked by Xcode when the user cancels the extension command. Cancellation can be done via a banner that appears within Xcode during processing by a source editor extension. Extensions block other operations, including typing in the IDE itself, to avoid merge issues.

The `XCSourceTextBuffer` is the most interesting here, as it contains the data you act upon. Here's an overview of its notable properties:

- **lines** is an array of String objects in the buffer, where lines are separated by line breaks.
- **selections** is an array of `XCSourceTextRange` objects that identify a start and end position in the text buffer. Generally a single item will be present, representing the user's selection or cursor position in absence of selection. Multiple selections are also possible with macOS using *Shift+Command*, and are supported here.

It's also important to understand the **XCSourceTextRange** object used for `selections`. It defines the `start` and `end` text positions for a text range. The positions are represented by `XCSourceTextPosition`, a zero based coordinate system that uses `column` and `line` to track position in the buffer.

The diagram below illustrates the relation between a buffer, its lines and selections.

![height=35%](./images/buffer-diagram.png)

### Build the editor command 

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
3. `selectedText` is set to the selected String by using `substring(with:aRange:)` and the selection start and end index. A `TODO` is left here to pass the resulting string to the FIGlet framework to generate the new content.
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

![width=70% bordered](./images/xcode-quit.png)

In the report window that appears, scroll until you see **Application Specific Information** followed by a backtrace.

![width=100% bordered](./images/xcode-problem-report.png)

For once it's not Xcode being flaky. It's you!

Xcode is crashing due to a an NSSelectionArray—an internal class associated with selection ranges—that contains no ranges. This is because by the time you call the completion handler in `perform(with:completionHandler:)`, `buffer.selections` is empty. Without a selection or insertion point in the buffer, Xcode doesn't know where to put the cursor when it regains control.

Take a look at the code you just added, and it makes sense. When the extension kicked off, the buffer selection was whatever you had selected before kicking it off. But towards the end of `perform(with:completionHandler:)`, you called `removeObject(at:)` on the selected line, thus removing the selection from the buffer.

For the sake of simplicity, you're going to get around this by simply inserting the cursor at a known position—the start of the buffer.

Still in **SourceEditorCommand.swift**, add the following to `perform(with:completionHandler:)`, just above the completion handler at the end of the method:

```swift
let insertionPosition = XCSourceTextPosition(line: 0, column: 0)
let selection = XCSourceTextRange(start: insertionPosition,
                                  end: insertionPosition)
buffer.selections.setArray([selection])
```

You create a `XCSourceTextPosition` at the first line and column of the buffer. The position is used to create a `XCSourceTextRange` where the start and end are equal—which means you're inserting without doing any selection. You then wrap this in an array and set it to the buffer `selections`.

Build and run and launch the extension as you've done before. This time, you'll see your ASCIIified text! As expected, the cursor appears at the start of the file.

![width=80% bordered](./images/figlet-starting-insertion.png)

### Adding some polish

Congrats! You officially have a working source editor extension. But while the asciiified text isn't going to revolutionize the way you code, there are some things you could do to make it a bit more useful. Time to add some polish!

While the FIGlet you created looks glorious, it doesn't compile. Since you are working on a *source* editor, it makes sense to output these decorative items as comments.

In **SourceEditorCommand.swift**, find the following line in `perform(with:completionHandler:)`:

```swift
let newLines = asciiified.components(separatedBy: "\n")
```

Replace that line with:

```swift
let newLines = asciiified.components(separatedBy: "\n")
  .map { "// \($0)" }
```

Here you've added a `map` to the existing String operation. The map simply appends `//` and a space to the start of each line, thus changing your FIGlet into a comment.

Build and run and test the extension again. This time, you'll see the new text is commented:

![width=100% bordered](./images/commented-figlet.png)

That's definitely better, but not perfect. It's a little jarring to have some text selected, and have the cursor hop to the start of the file as you did to resolve the earlier crash. It would be a lot nicer to come back with the replaced text selected.

Add the following property to the top of `perform(with:completionHandler:)`:

```swift
var newSelections = [XCSourceTextRange]()
```

This will be used to save the position of the FIGlet you create so you can select it in the buffer before returning.

Add the following code to the bottom of body of `if let asciiified`:

```swift
// 1
let startPosition = XCSourceTextPosition(line: startLine, column: 0)

// 2
var endLine = startLine
if newLines.count > 0 {
  endLine = startLine + newLines.count - 1
}
// 3
var endColumn = 0
if let lastLine = newLines.last {
  endColumn = lastLine.characters.count
}
// 4
let endPosition = XCSourceTextPosition(line: endLine, column: endColumn)

// 5
let selection = XCSourceTextRange(start: startPosition,
                                  end: endPosition)
newSelections.append(selection)
```

This code is setting a selection range based on the newly inserted FIGlet. Here's how:

1. The selection `startPosition` is the first column of the originally selected line—the same place you inserted the new text.
2. The line number for the last inserted line is calculated by adding the newly inserted lines to the start line and subtracting one to avoid the initial line being double counted. If no lines were added, the `startLine` is used as the `endLine`.
3. The last column to select is determined by looking at the `last` of the `newLines` and counting its characters.
4. `endPosition` is an `XCSourceTextPosition` created with the newly calculated `endLine` and `endColumn`.
5. These positions are used to create an `XCSourceTextRange` covering the area you want selected after the extension returns. To handle the possibility of multiple selections, you save each range to the array `newSelections`.

Once all the FIGlets are created, you can set the selections in the buffer. Look just above the call to to `completionHandler()` and replace the following:

```swift
let bufferStartPosition = XCSourceTextPosition(line: 0, column: 0)
let selection = XCSourceTextRange(start: bufferStartPosition,
                                  end: bufferStartPosition)
buffer.selections.setArray([selection])
```

with:

```swift
if newSelections.count > 0 {
  buffer.selections.setArray(newSelections)
} else {
  let insertionPosition = XCSourceTextPosition(line: 0, column: 0)
  let selection = XCSourceTextRange(start: insertionPosition,
                                    end: insertionPosition)
  buffer.selections.setArray([selection])
}
```

If `newSelections` contains any ranges, it is used to set the buffer's `selections` resulting in the newly inserted text getting selected when Xcode loads the returned buffer. If nothing was inserted, there is no selection. In that case, this falls back to the old method of setting the insertion to the top of the file.

Build and run, select some text in the editor, and launch the extension. This time, you'll see the new text is selected.

![width=80% bordered](./images/successful-figlet-test.png)

You're probably going to be asciiifying with reckless abandon from now on, and having to navigate to the menu item is going to cut into productivity. Fortunately, you can map a key binding for your extension once installed.

In Xcode, navigate to **Xcode\Preferences**. Select the **Key Bindings** tab and filter for **Asciiify Comment** to find your new command. Double click the **Key** field and hold down **Control+Option+Command+A** (or anything available you prefer) to assign a hotkey.

Now build and run the extension, select some text in the test editor and type **Control+Option+Command+A** to trigger asciiify. Now that it's this easy, you only have one thing left to do.

![width=40%](./images/asciiify-all-the-things.png)

## Dynamic commands

What you've built works well to asciiify text, but it doesn't fully leverage the FIGlet library. The library is capable of creating FIGlets with a number of different fonts, whereas your extension doesn't offer the user a choice.

You could go through and add each supported font to the extension `Info.plist`, but that isn't very flexible and it's manually intensive. If you wanted the extension to download new fonts, for instance, you'd have no way to add them to the menu—the extension would have to be updated.

Fortunately, source editor extensions allow an alternate and more dynamic means of defining menu items. The `XCSourceEditorExtension` protocol defines an optional property `commandDefinitions` that provides the same information about each command as the **Info.plist**. 

`commandDefinitions` provides of an array of dictionaries, with each dictionary representing a single command. The dictionary keys are defined in a struct `XCSourceEditorCommandDefinitionKey` and represent the command name, associated source editor class, and a unique identifier. They map directly to keys provided in the **Info.plist** here:

![width=100% bordered](./images/source-editor-command-keys.png)

You'll implement this property and use it to pull available fonts from the FIGlet library.

Open **SourceEditorExtension.swift** and delete the commented template code inside `SourceEditorExtension`. Add the following import at the top:

```swift
import Figlet
```

You'll use the `Figlet` library to pull over a list of available fonts.

Now add the following method to `SourceEditorExtension`:

```swift
var commandDefinitions: [[XCSourceEditorCommandDefinitionKey: Any]] {
  // 1
  let className = SourceEditorCommand.className()
  let bundleIdentifier = Bundle(for: type(of: self)).bundleIdentifier!
  // 2
  return FigletRenderer.topFonts.map {
    fontName in
    let identifier = [bundleIdentifier, fontName].joined(separator: ".")
    return [
      // 3
      .nameKey: "Font: \(fontName)",
      .classNameKey: className,
      .identifierKey: identifier
    ]
  }
}
```

You've implemented the `commandDefinitions` property covered above. Here's what the code does:

1. `className` contains the String representation of the `SourceEditorCommand` class responsible for processing the commands that will be defined here. `bundleIdentifier` is a String containing the name of the bundle this extension resides in, which will be part of the unique identifier for the commands.
2. `FigletRenderer` has a `topFonts` property containing the names of fonts the extension can use. This maps each `fontName` to the required dictionary. Before returning the dictionary, the `identifier` is created by joining the `bundleIdentifier` and `fontName`.
3. Each of the three required keys are set here. The `nameKey` value will appear in the menu item, and consists of the word `Font` followed by the `fontName`. The class name and identifier use values derived in earlier steps.

>**Note**: You may have noticed another optional method defined in the template of `SourceEditorExtension`. `extensionDidFinishLaunching()` is called as soon as the extension is launched by Xcode and provides an opportunity to prepare prior to a request. Asciiify, for instance, might take this opportunity to download new fonts.

Build and run and navigate to the **AsciiifyComment** menu once again. This time, you'll see several new menu options, courtesy of `commandDefinitions`! 

![width=50% bordered](./images/new-menu-options.png)

The extension was previously using the **Standard** font. Select something different this time to confirm your new commands do indeed pass a different parameter to the FIGlet library.

![width=70% bordered](./images/new-font-result.png)

## Where to go from here?

Congrats! In just a small amount of time you created a functional source editor extension. In the process, you learned everything you need to know to implement your own ideas.

While it is disappointing to lose the progress made in the thriving plugin community, exciting times are ahead. The simplicity of source editor extensions make Xcode 'plugin' development much more attainable to the masses. Creating extensions for your own refactoring efforts or to address standards on your product is feasible in a short amount of time.

The landscape will continue to change as Apple will likely open up more Xcode functionality via extensions. It is up to the community to adopt and leverage source editor extensions while also pleading the case for more Xcode extension points.

For more insight into source editor extensions, see the 2016 WWDC session on the topic here: [apple.co/2byNQd6](http://apple.co/2byNQd6)
