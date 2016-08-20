## xcode-source-editor-extensions

```metadata
author: "By Jeff Rames"
number: "3"
title: "Chapter 3: Xcode 8 Source Editor Extensions"
```
# Chapter 3: Xcode 8 Source Editor Extensions
Introduction
- Compare to existing options & explain why they chose extension model
- Describe distribution method
- Describe ASCIIify high level & plan to create extension
- Prerequisites 

## Getting started [Instruction]

- Open ASCIIify and review what it does
- Create extension
- Explore template

## Building the asciiify extension [Instruction]

- Info.plist config / Rename extension
- Build & Run to see menu items appear

### Exploring the command invocation [Theory]

- invocation / buffer / selection model overview

### Build the editor command [Instruction] 

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

