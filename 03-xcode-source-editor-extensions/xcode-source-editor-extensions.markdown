## xcode-source-editor-extensions

```metadata
author: "By Jeff Rames"
number: "3"
title: "Chapter 3: Xcode 8 Source Editor Extensions"
```
# Chapter 3: Xcode 8 Source Editor Extensions

New in Xcode 8, Apple has provided the first official way to extend the capabilities of Xcode: source editor extensions. As the name implies, they rely on the extension architecture that has gained increasing prevalence on Apple’s platforms recently.

The scope is limited to performing operations on text. This means you cannot customize Xcode’s UI or modify settings — your interface is via menu items, and only text passes between Xcode and the extension.

>**Note**: There’s no official word, but there _is_ plenty of chatter about Apple’s plans to expand editor extension capabilities based on community demand. Make sure to file a Radar if there is an Xcode extension you’re trying to build that isn’t possible with a source extension.

Many developers will prefer to use editor extensions created by others. If you don’t have the itch, and don’t have any needs requiring a custom extension, feel free to skip ahead to the next chapter.

In this chapter, you’ll build an extension called **Asciiify**, based on an existing macOS application that takes text input and outputs an ASCII art version of that text:

```swift
//      _      ____     ____   ___   ___   _    __         
//     / \    / ___|   / ___| |_ _| |_ _| (_)  / _|  _   _
//    / _ \   \___ \  | |      | |   | |  | | | |_  | | | |
//   / ___ \   ___) | | |___   | |   | |  | | |  _| | |_| |
//  /_/   \_\ |____/   \____| |___| |___| |_| |_|    \__, |
//                                                   |___/
```

$[=s=]

## Getting started

Open **Asciiify.xcodeproj** in the starter project folder.

Before you can build and run, you need to set up signing with your team information.

Select the **Asciiify** project from the navigator and then the **Asciiify** target. From the **General** tab, select your team name from the **Team** dropdown:

![width=100% bordered](./images/select-team-asciiify.png)

Build and run the **Asciiify** scheme and type some text into the top text field. Your asciiified output will show up in the label below.

![width=70% bordered](./images/asciiify-demo2.png)

Take a look around the source, which includes some helper files you'll use to build the source editor extension:

- The **Figlet** group consists of **FigletRenderer.swift**, a Swift wrapper around a JavaScript FIGlet implementation by Scott González. A FIGlet is a program that makes ASCII art representations of text. You’ll use this, but you don’t need to know how it works in detail. 
- **Main.storyboard** contains a simple view with a text field and label. This view is for the macOS app, not your extension. However, it will help demonstrate what the library does.
- **AsciiTransformer.swift** transforms `String` input to a FIGlet and is used by the Asciiify macOS app.

## Why source editor extensions?

Your goal is to take this functionality and build it into Xcode itself. But before you begin, you might be wondering why source code extensions are useful at all, considering the community has been able to develop Xcode plugins without an official method provided by Apple for some time.

Xcode 8 source editor extensions bring several benefits:

  * They are fully asynchronous and run under their own process, minimizing any performance impacts to the IDE. 
  * Using an officially supported interface, they’re also less likely to break with each Xcode release. 
  * Finally, the extension model provides a clean interface to Xcode that makes it quite easy to generate tools.

It's true that Xcode plugins have been available with fewer restrictions for some time, thanks to the developer community and the package manager [Alcatraz](http://alcatraz.io). These community extensions are able to modify Xcode’s UI and behavior anywhere — not just within a single source file. However, these rely on private frameworks, introduce security and stability risks, and depend on frequent updates to keep them working.

Xcode 8 uses runtime library validation to improve security. With this change, the time for updating plugins has come to an end, as the mechanism they used to run under in Xcode is now closed off. It’s a brave new world: for better or worse, developers will be working within Apple’s ecosystem to create new tools.

The new source extensions are fairly limited compared to Xcode plugins of old — but here are a few ideas of what you *can* do:

- Generate a documentation block for a method containing all parameters and the return type based on its signature
- Convert non localized `String` definitions within a file to the localized version
- Convert color and image definitions to the new color and image literals in Xcode 8 (demoed in the WWDC session on source editor extensions)
- Create comment MARKs above an extension block using the name of a protocol it extends
- Generate a print statement with debugging info on a highlighted property
- Clean up whitespace formatting of a file; for instance, you might enforce a single line between each method by deleting or adding lines to the file

You’ll likely come up with a half dozen more off the top of your head. Even with their limitations, source editor extensions have a lot of utility. Some will be more general in scope, and some may be very specific to your codebase or standards.

While this is a book about iOS 10, keep in mind that source editor extensions are actually macOS applications. That being said, you’ll be working primarily with Foundation, so even if this is your first foray into macOS, there aren’t any pre-requisites.

## Creating a new extension

Back to your goal: to implement this same asciiification within Xcode’s source editor. To do this, you’ll create a source editor extension that leverages the Figlet framework in the same way this macOS application does.

Navigate to **File\New\Target** and under the **macOS** tab select **Xcode Source Editor Extension**.

![width=70% bordered](./images/create-extension.png)

Click **Next**, use **AsciiifyComment** for the Project Name, ensure Swift is selected and click **Finish**.

![width=90% bordered](./images/name-extension.png)

If prompted to activate the AsciiifyComment scheme, click **Activate**. This will be used when building the extension.

You’ll now notice a new target and a new group in the navigator, both named **AsciiifyComment**. Expand the new group and take a look at what the template has provided:

- **SourceEditorExtension.swift** contains an NSObject that conforms to the `XCSourceEditorExtension` protocol. The protocol defines an optional method, `extensionDidFinishLaunching()`, which is called upon initial launch allowing you to do any required setup. `commandDefinitions` is an optional property that can be used to provide an array of objects that define commands the extension can accept.
- **SourceEditorCommand.swift** defines an object that conforms to the `XCSourceEditorCommand` protocol which consists of one required method—`perform(with:completionHandler:)`. The method is called when a user invokes the extension by selecting a menu item. This is where you’ll asciiify the passed text.
- The **Info.plist** of an extension has several important keys under `NSExtension` that point to the classes covered above, as well as providing a name for the command. You’ll dig into this shortly.

Select the AsciiifyComment build scheme, then build and run. When prompted to choose an app to run, select Xcode (version 8 or above) and then click **Run**. A version of Xcode will launch with a dark icon, activity viewer, and splash screen icon:

![width=80% bordered](./images/test-xcode-splash.png)

This instance of Xcode is meant for testing your extensions. Once launched, create a new playground, as all you’ll be doing is adding comments. Make sure that the new playground is open in the test instance of Xcode, not the original version of Xcode.

With the cursor in your test playground, navigate to **Editor\Asciiify Comment\Source Editor Command**. Clicking the command does nothing at present:

![width=70% bordered](./images/extension-menu-item.png)

Time to implement some functionality!

## Building the Asciiify extension

You probably already noticed some low hanging fruit — the name **Source Editor Extension** in the menu item doesn’t explain what it’s going to do.

Open **Info.plist** in the AsciiifyComment group and expand the `NSExtension` dictionary. Now expand `NSExtensionAttributes` which contains an array of command definitions with the key `XCSourceEditorCommandDefinitions`.

For the first array item, change the value for key `XCSourceEditorCommandName` to be **Asciiify Comment**:

![width=100% bordered](./images/extension-plist.png)

Take a moment to check out the other keys found in the **Item 0** dictionary that help Xcode determine what code to execute for a given command. `XCSourceEditorCommandIdentifier` is a unique ID Xcode will use to look up this command in the dictionary. `XCSourceEditorCommandClassName` then points to the source editor command class responsible for performing this command.

Build and run the extension, open your test playground from earlier, and  you’ll now be able to navigate to **Editor\Asciiify Comment\Asciiify Comment**:

![width=40% bordered](./images/extension-menu-item-new-name.png)

Now the name looks the way you’d expect, but it still doesn’t do anything. Your next step will be to implement the functionality, but first you need to learn a bit more about the data model used by source editor extensions.

### Exploring the command invocation

Selecting a menu command associated with your extension will call `perform(with:completionHandler:)` in the `SourceEditorCommand` implementation. In addition to the completion handler, it’s passed an `XCSourceEditorCommandInvocation`.

This class contains the text buffer and everything you need to identify the selections. Here’s a quick overview of its properties:

- **commandIdentifier** is a unique identifier for the invoked command, used to determine what processing should be done. The identifier comes from the `XCSourceEditorCommandIdentifier` key in the command definition found in **Info.plist**.
- **buffer** is of type `XCSourceTextBuffer` and is a mutable representation of the buffer and its properties to act upon. You’ll get into more detail about its makeup below.
- **cancellationHandler** is invoked by Xcode when the user cancels the extension command. Cancellation can be done via a banner that appears within Xcode during processing by a source editor extension. Extensions block other operations, including typing in the IDE itself, to avoid merge issues.

>**Note**: The cancellation handler brings up an important point: Your extensions need to be fast, because they block the main UI thread. Any type of network activity or processor-intensive operations should be done at launch whenever possible.

The `buffer` is the most interesting item in the `XCSourceEditorCommandInvocation`, as it contains the data to act upon. Here’s an overview of the `XCSourceTextBuffer` class’ notable properties:

- **lines** is an array of `String` objects in the buffer, with each item representing a single line from the buffer. A line consists of the characters between two line breaks.
- **selections** is an array of `XCSourceTextRange` objects that identify start and end positions in the text buffer. Generally a single item will be present, representing the user’s selection or cursor position in absence of selection. Multiple selections are also possible with macOS using *Shift+Command*, and are supported here.

It’s also important to understand `XCSourceTextPosition`, the class used to represent the start and end of selections. `XCSourceTextPosition` uses a zero-based coordinate system and defines `column` and `line` indexes to represent buffer position.

The diagram below illustrates the relation between a buffer, its lines and selections.

![height=40%](./images/buffer-diagram.png)

Now that you have a better understanding of the model involved, it’s time to dive in and handle a request.

$[=s=]

### Build the editor command

Open **SourceEditorCommand.swift** and add the following to the top with the other imports:

```swift
import Figlet
```

This is the framework used to create FIGlet representations of text.

Just inside the `SourceEditorCommand` class, add the following:

```swift
let figlet = FigletRenderer()
```

`FigletRenderer` is the primary controller involved in rendering FIGlets. You’ll call this in the extension.

Now replace the body of `perform(with:completionHandler:)` with the following:

```swift
let buffer = invocation.buffer

// 1
buffer.selections.forEach({ selection in
  guard let selection = selection as? XCSourceTextRange,
    selection.start.line == selection.end.line else { return }

  // 2
  let line = buffer.lines[selection.start.line] as! String
  let startIndex = line.characters.index(
    line.startIndex, offsetBy: selection.start.column)
  let endIndex = line.characters.index(
    line.startIndex, offsetBy: selection.end.column)

  // 3
  let selectedText = line.substring(
    with: startIndex..<line.index(after: endIndex))
  // TODO: asciiify the text
})
// 4
completionHandler(.none)
```

This code does some validation and then examines `XCSourceEditorCommandInvocation` to get the selected `String` and its location in the buffer. Here’s how this happens:

1. You test each `selection` in the buffer to determine if it exists on a single line. `XCSourceTextRange` contains a `start` and `end` position, and this code confirms those positions are on the same line. This is necessary as FIGlets aren’t designed to wrap.
2. Because the selection is only a single line, you find it in the `buffer.lines` array using the selection’s `start` line position. You derive the `startIndex` and `endIndex` of the selected text within the buffer using the index of the start of the line offset by the start and end `column` properties, respectively.
3. You then set `selectedText` to the selected `String` by using `substring(with:aRange:)` and the selection start and end index. A `TODO` is here to pass the resulting `String` to the FIGlet framework to generate the new content.
4. The `completionHandler()` must be called to signify completion of processing for this invocation.

Now that you’ve the selected text, it’s time to feed it to the FIGlet renderer and update the text buffer with the results. Still in `perform(with:completionHandler:)`, replace `// TODO: asciiify the text` with the following:

```swift
// 1
if let asciiified = figlet.render(input: selectedText) {
  // 2
  let newLines = asciiified.components(separatedBy: "\n")
  let startLine = selection.start.line
  // 3
  buffer.lines.removeObject(at: startLine)
  buffer.lines.insert(
    newLines,
    at: IndexSet(startLine ..< startLine + newLines.count))
}
```

Here’s a detailed look at what this does:

1. The FIGlet renderer method `render(input:)` takes the `selectedText` you obtained earlier and returns its ASCII art version.
2. Using the newline character as a separator, this code breaks the resulting `String` into the array `newLines`. It then sets `startLine` to the first line of the `selection`. Because you’ve guarded against multi-line selections, the first line is the only line.
3. This removes the originally selected line from the `buffer`, replacing it with those in `newLines`. The insertion range for `newLines` is from the original selection’s `startLine` through the number of lines being inserted.

Build and run, attach to Xcode and open the Playground from earlier. Select a piece of text and then select **Editor\Asciiify Comment\Asciiify Comment** to kick off the extension. And then you’ll see...

![width=40s%](./images/xcode-quit-ragecomic.png)

Sigh. This probably looks quite familiar if you’ve used Xcode more than once or twice. 

In the report window that appears, scroll until you see **Application Specific Information** followed by a backtrace.

![width=95% bordered](./images/xcode-problem-report.png)

For once it’s not Xcode being flaky. It’s you!

Xcode is crashing due to a an `NSSelectionArray` — an internal class associated with selection ranges — that contains no ranges. By the time you call the completion handler in `perform(with:completionHandler:)`, `buffer.selections` is empty. Without a selection or insertion point in the buffer, Xcode doesn’t know where to put the cursor when it regains control. Whoops!

Take a look at the code you just added. When the extension kicks off, the buffer selection is whatever you had selected. But near the end of `perform(with:completionHandler:)`, you call `removeObject(at:)` on the selected line — thus removing the selection from the buffer.

For the sake of simplicity, you’re going to get around this by inserting the cursor at a known position: the start of the buffer.

Still in **SourceEditorCommand.swift**, add the following to `perform(with:completionHandler:)`, just above the completion handler at the end of the method:

```swift
let insertionPosition = XCSourceTextPosition(line: 0, column: 0)
let selection = XCSourceTextRange(
  start: insertionPosition,
  end: insertionPosition)
buffer.selections.setArray([selection])
```

Here you create an `XCSourceTextPosition` at the first line and column of the buffer. The position is used to create an `XCSourceTextRange` where the start and end are equal — which means you’re inserting the cursor without doing any selection. You wrap `selection` in an array and set it to the buffer `selections`.

Build and run, and launch the extension as you’ve done before. This time, you’ll see your asciiified text! As expected, the cursor appears at the start of the file.

![width=80% bordered](./images/figlet-starting-insertion.png)

### Adding some polish

Congrats! You officially have a working source editor extension. But while the asciiified text isn’t going to revolutionize the way you code, there are some things you could do to make it a bit more useful.

While the FIGlet you created looks glorious, it won’t compile as code. Since you are working on a *source* editor, it makes sense to output these decorative items as comments.

In **SourceEditorCommand.swift**, find the following line in `perform(with:completionHandler:)`:

```swift
let newLines = asciiified.components(separatedBy: "\n")
```

Replace that line with the following:

```swift
let newLines = asciiified.components(separatedBy: "\n")
  .map { "// \($0)" }
```

You’ve added a `map` to the existing `String` operation. The map simply appends `//` and a space to the start of each line, thus changing your FIGlet into a comment.

Build and run and test the extension again. This time, you’ll see the FIGlet is commented:

![width=100% bordered](./images/commented-figlet.png)

That’s definitely better, but not perfect. It’s a little jarring to have some text selected, then have the cursor hop to the start of the file after the extension returns. It would be a lot nicer to have the replaced text selected when the call returns.

Add the following property to the top of `perform(with:completionHandler:)`:

```swift
var newSelections = [XCSourceTextRange]()
```

This will be used to save the position of the FIGlet you create so you can select it in the buffer before returning.

Add the following code to the bottom of the body of `if let asciiified`:

```swift
// 1
let startPosition = XCSourceTextPosition(
  line: startLine,
  column: 0)

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
let endPosition = XCSourceTextPosition(
  line: endLine,
  column: endColumn)

// 5
let selection = XCSourceTextRange(
  start: startPosition,
  end: endPosition)
newSelections.append(selection)
```

This code sets a selection range around the newly inserted FIGlet. Here’s how:

1. The selection `startPosition` is the first column of the originally selected line — the same place you inserted the new text.
2. You calculate the line number for the last inserted line by adding the newly inserted lines to the start line and subtracting one so the start line isn’t double counted. If no lines were added, the `startLine` is used as the `endLine`.
3. You then determine the last column to select by looking at the `last` of the `newLines` and counting its characters. This results in a selection point at the end of the new insertion.
4. `endPosition` is an `XCSourceTextPosition` created with the newly calculated `endLine` and `endColumn`.
5. Finally, you use the calculated positions to create an `XCSourceTextRange` covering the area you want selected after the extension returns. To handle the possibility of multiple selections, you save each range to the array `newSelections`.

Once you’ve created all the FIGlets, you can set the selections in the buffer. Look just above the call to to `completionHandler()` and replace the code below:

```swift
let insertionPosition = XCSourceTextPosition(line: 0, column: 0)
let selection = XCSourceTextRange(
  start: bufferStartPosition,
  end: bufferStartPosition)
buffer.selections.setArray([selection])
```

...with the following:

```swift
if newSelections.count > 0 {
  buffer.selections.setArray(newSelections)
} else {
  let insertionPosition = XCSourceTextPosition(line: 0, column: 0)
  let selection = XCSourceTextRange(
    start: insertionPosition,
    end: insertionPosition)
  buffer.selections.setArray([selection])
}
```

If `newSelections` contains any ranges, it’s used to set the buffer’s `selections`. Now Xcode will select the newly inserted text when the buffer is returned.

If nothing was inserted, there is no selection. In that case, this code falls back to the old method of setting an insertion at the top of the file.

Build and run, select some text in the editor, and launch the extension. This time, you’ll see the new text ends up selected:

![width=80% bordered](./images/successful-figlet-test.png)

You’re probably going to be asciiifying with reckless abandon from now on, and navigating to the menu item is going to cut into productivity. Fortunately, you can map a key binding for your extension once it’s installed.

In Xcode, navigate to **Xcode\Preferences**. Select the **Key Bindings** tab and filter for **Asciiify Comment** to find your new command. Double click the **Key** field and hold down **Control+Option+Command+A** (or anything available you prefer) to assign a hotkey.

![width=100% bordered](./images/key-binding.png)

Now build and run the extension, select some text in the test editor and type **Control+Option+Command+A** to trigger Asciiify.

Now that triggering your extension is this easy, you only have one thing left to do:

![width=40%](./images/asciiify-all-the-things.png)

## Dynamic commands

What you’ve built works well to asciiify text, but it doesn’t fully leverage the FIGlet library. The library is capable of creating FIGlets with a number of different fonts, whereas your extension doesn’t offer the user a choice.

You could go through and add each supported font to the extension `Info.plist`, but that isn’t very flexible and it’s manually intensive. If you wanted the extension to download new fonts, for instance, you’d have no way to dynamically add them to the menu, and you’d have to update the extension.

Fortunately, source editor extensions allow an alternate, dynamic means to define menu items. The `XCSourceEditorExtension` protocol defines an optional property `commandDefinitions` that provides the same information about each command as the **Info.plist**.

`commandDefinitions` is an array of dictionaries, with each dictionary representing a single command. The dictionary keys are defined in a struct `XCSourceEditorCommandDefinitionKey` and represent the command name, associated source editor class, and a unique identifier. They map directly to keys provided in the **Info.plist** here:

![width=100% bordered](./images/source-editor-command-keys.png)

You’ll implement this property and use it to pull available fonts from the FIGlet library.

Open **SourceEditorExtension.swift** and delete the commented template code inside `SourceEditorExtension`.

Add the following import above the class:

```swift
import Figlet
```

You’ll use the `Figlet` library to pull over a list of available fonts.

Now add the following property definition to `SourceEditorExtension`:

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

You’ve implemented the `commandDefinitions` property covered above. Here’s what the code does:

1. `className` contains the `String` representation of the `SourceEditorCommand` class responsible for processing the commands to be defined here. `bundleIdentifier` is a `String` containing the name of the bundle this extension resides in, which will be part of the unique identifier for the commands.
2. `FigletRenderer` has a `topFonts` property containing the names of fonts the extension can use. This maps each `fontName` to the required dictionary. Before returning the dictionary, the `identifier` for a given font command is created by joining the `bundleIdentifier` and `fontName`.
3. You set each of the three required keys here. The `nameKey` value will appear in the menu item, and consists of the word `Font` followed by the `fontName`. The class name and identifier use values derived in earlier steps.

>**Note**: You may have noticed another optional method defined in the template of `SourceEditorExtension`. `extensionDidFinishLaunching()` is called as soon as the extension is launched by Xcode and provides an opportunity to prepare prior to a request. Asciiify, for instance, might take this opportunity to download new fonts.

Now that the command definition contains a font name, you need to use it on the receiving end.

Open **SourceEditorCommand.swift** and add the following method to `SourceEditorCommand`:

$[=s=]

```swift
private func font(from commandIdentifier: String) -> String {
  let bundleIdentifier = Bundle(for: type(of: self)).bundleIdentifier!
    .components(separatedBy: ".")
  let command = commandIdentifier.components(separatedBy: ".")

  if command.count == bundleIdentifier.count + 1 {
    return command.last!
  } else {
    return "standard"
  }
}
```

This accepts a `String` representing the command identifier which you formatted in the dynamic command creation as ``{Bundle Identifier}.{Font Name}``. The method first obtains arrays representing the period delimited components of the `bundleIdentifier` and the incoming `commandIdentifier`.

It then checks that the count of items in the `command` array is one more than the count for those in `bundleIdentifier`. This enables a check to see that the `commandIdentifier` consists only of the bundle identifier followed by a command name. In this case, the command name would be the font name.

If the count comparison determines a command name is present, the final array element is the font name and it gets returned. If it isn’t, the code falls back to returning `"standard"`, which is the default font name.

Now add the following property to the top of `perform(with:completionHandler:)`:

```swift
let selectedFont = font(from: invocation.commandIdentifier)
```

This uses the new `font(from:)` method to set `selectedFont` with the font name to be processed.

Now find where you set `asciiified` using `figlet.render(input:)`. Replace the `render(input:)` call with the following:

```swift
figlet.render(input: selectedText, withFont: selectedFont)
```

This now uses `render(input:withFont:)`, which accepts a font name `String` as its second argument. This uses `selectedFont` to render the text with the chosen font.

Build and run, and navigate to the **AsciiifyComment** menu once again. This time, you’ll see several new menu options, courtesy of `commandDefinitions`!

![width=50% bordered](./images/new-menu-options.png)

$[=s=]

The extension previously used the **Standard** font. Select something different this time to confirm your new commands do indeed pass a different parameter to the FIGlet library.

![width=70% bordered](./images/new-font-result.png)

>**Note**: Of course, because you’ve replaced the **Asciiify Comment** command with the new dynamic commands, your key binding no longer works. If you like, you can add new key bindings for each of the new Asciiify commands.

## Where to go from here?

In a short amount of time, you’ve created a functional source editor extension. In the process, you learned everything you need to know to implement your own idea for a source editor extension.

While it is disappointing to lose the progress made in the thriving plugin community, exciting times are ahead. The simplicity of source editor extensions make Xcode extension development much more accessible to the masses. Creating extensions for your own refactoring efforts, or to address standards on your product, can be done quickly.

The landscape extensions will continue to change as Apple opens up more Xcode functionality to developers. It’s up to the community to adopt and leverage source editor extensions while also pleading the case for more Xcode extension points to fill any voids.

For more insight into source editor extensions, see the 2016 WWDC session on the topic here: [apple.co/2byNQd6](http://apple.co/2byNQd6)
