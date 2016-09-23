## other-ios10-topics

## Introduction

Some general talk about the breadth of iOS 10 updates.

## Getting Started [Theory / Instruction]

Check out the starter project and go over plans

## Data Source Prefetching [Instruction]

- review existing architecture and experience sluggish load time
- Add pre-fetch
- Add pre-fetch cancel
- mention UITableViewDataSourcePrefetching 

### UICollectionView Cell Pre-Fetching [Theory]
- brief overview of what it is and some best practices (not sure if this fits well since it is a lot of theory that they won't apply.  Looking for feedback but I thought it might be necessary to fill out the chapter and is interesting)

### UIRefreshControl [Instruction]
- Add pull to refresh to the collection view.  Since I don't want to interfere with the data source methods used to demonstrate the pre-fetch, I'm not quite sure how I'd demonstrate this in an interesting way.  It's a nice little tweak impacting collection view so I thought it might fit well here.

## UIPreviewInteraction [Theory]

- Overview of feature & preview interaction lifecycle

### Implement UIPreviewInteractionDelegate [Instruction]

- Implement delegate methods with prints for status testing
- add preview mode overlay with rating emoji over cells
- commit implementation - obtain emoji rating and update datastore, update cell to show new rating

## Haptic Feedback [Instruction]
This will be pretty lean since the code is just 3 variations of a single line of code

- I'll start with a para or two of theory and then the instruction.  
- ImpactFeedback, NotificationFeedback, FeedbackGenerator

## Where to Go From Here

- What's New in UICollectionView in iOS 10: https://developer.apple.com/videos/play/wwdc2016/219
- A Peek at 3D Touch: https://developer.apple.com/videos/play/wwdc2016/228/
