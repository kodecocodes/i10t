```metadata
author: "By Rich Turton"
number: "99"
title: "Chapter 99: Beginning Message Apps"
```
# Chapter 99: Beginning Message Apps

## Introduction

Overview of changes to iMessage, summary of chapter content

## Sticker Packs

Sticker packs are the simplest possible iMessage application you can make. In fact, they are so simple, you don't even need to write any code! 

Create a new Xcode project and choose the **iOS > Application > Sticker Pack Application** template:

![bordered width=60%](images/StickerPackTemplate.png)

Call the project **RWPeeps**. 

The project that is created is probably one of the simplest Xcode projects you've ever seen! It only contains one thing - a specialised asset catalog, called **Stickers.xcstickers**. Within the asset catalog is a place for the app icon, and a folder called **Sticker Pack**:

![width=60%](images/StickerPackProject.png)

In the resources for this chapter is a zip file, **RWPeepsImages.zip**. Unzip this file and drag the images into the **Sticker Pack** folder:

![bordered width=60%](images/StickersInPlace.png)

And you're done!

Build and run your "app", and you'll see a new option - Xcode offers you a choice of host applications to run. Select **Messages**, since that's what your stickers are for:

![bordered width=60%](images/ChooseHostApp.png)

The iOS simulator now contains a working messages app, where you can view both sides of a conversation. This is so you can test and develop messages apps easily. 

When the simulator launches and Messages opens up, you'll see an app button at the bottom of the screen: 

![iphone](images/MessagesAppButton.png)

Tap the button and wait a second or so (it seems to take some time for the simulator to launch your app) and you'll see your stickers ready to go! Tap one to send it, or tap and hold to "peel" it off and attach to another message: 

![iphone](images/StickersStuck.png)

You can use the back button in the navigation bar to switch to the other side of the conversation. 

Sticker pack applications created like this need to follow a few rules:

- The sticker images must be PNG, APNG, GIF or JPEG format, and less than 500KB
- The stickers in a pack will all be of the same size
- You can choose small (100 x 100), medium (136 x 136) or large (206 x 206) for your sticker pack
- The images should be supplied at 3x resolution _only_. 

Once you have recovered from the dizzying excitement of static sticker packs, 

## Sticker application: Stickerlicious

Why make one of these instead of supplying a sticker pack?
MSMessagesAppViewController (quick note since it doesn't do much in this project)

### Sticker browser view controllers - subclassing MSStickerBrowserViewController

MSSticker
Data source

### Making your own sticker browser

(Subject to dropping if it looks like it will be too big) - implement a collection view with sections so you can have some decoration views or something like that - chocolate section etc. 

MSStickerView to give the drag and drop and peeling functionality


