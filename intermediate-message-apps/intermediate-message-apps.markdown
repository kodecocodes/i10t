## intermediate-message-apps

Starter project should contain:

- The game model without the initializers
- All three game view controllers (these are not relevant to messages, really)
- The storyboard with everything in it
- Utilities.swift
- Everything in Views
- MessagesViewController as it comes from the Xcode template.

# Introduction

Capabilities of custom messaging apps
Overview of WenderPic, screenshots of final project, starter project tour

## MSMessagesAppViewController

What this is and how it works
Lifecycle methods
presentation styles

## Summary view controller

Explain purpose, add code to make it come on screen, build and run
Add connections to make it do something, build and run - shows new presentation style

## Drawing view controller

Explain purpose, add code to make it appear when expanded style requested, explain participant UUID, build and run.
Add code to build message on delegate method, explain all the model structure for a conversation
Diagram explaining and linking the message, conversation and session objects
Add code to insert message and dismiss - explain MSMessageTemplateLayout
Build and run

## Custom message content / Guess view controller

Explain other conversation view, but that there's nothing yet to handle responding to the drawing

Clever business with MSMessage:
URL and what you can use that for
Serialized game in URL components things
code to ensure guess controller shows up
code to handle guesses

Challenge: guessee can do additional drawing? 
