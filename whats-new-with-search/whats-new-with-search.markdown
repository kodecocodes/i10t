## whats-new-with-search

Sample project: I plan to use GreenGrocer with several modifications as the starter. I'll add some more canned content, and build in a basic item search using string matching.  I'll also have it indexing all lists and products with core spotlight as well as adding activity tracking everywhere. Activity tracking will be especially important in the store tab as we'll add location stuff to the activity during the tutorial.

Intro - cover the high level changes to search including

- Continue search in app
- CoreSpotlight Search API
- NSUserActivity changes for location
- Others: ranking changes with differential privacy (may not mention), weakRelatedUniqueIdentifier

prerequisites: understanding of Core Spotlight and Activity Searching (point to iOS 9 book & Sam's video series)

## Getting started [Instruction]

Brief review of the starter and talking about the changes to be made

## CoreSpotlight Search API [Theory]

- Overview
- Query syntax

### Migrating to CoreSpotlight Search API [Instruction]

Take the existing search in the starter, and convert it to use CoreSpotlight Search API.

## Search continuation [Instruction]

Add search continuation (plist change, add CSQueryContinuationActionType restoration handler)

## Location proactive suggestions [Theory & Instruction]

Add location to the CSSearchableItemAttributeSet for the store tab NSUserActivity. Demonstrate how this can be used for QuickType, multi-tasking and Siri suggestions.  This will be a relatively short section as it's only a line of code, but it's powerful so important to review.

## Other enhancements [Reference]

Not positive if this section will stay here, but as I think we'll need to fill out some space it could make sense to briefly cover some of these other changes. 

- changes to ranking with differential privacy (touching on best practices related to this)
- weakRelatedUniqueIdentifier and bulk deletion of NSUserActivity associated with this (haven't decided if this is going in because frankly the use case isn't 100% clear. Discussed with Sam and I do agree it's likely to address large index jobs running while activities are generated but there isn't quite enough info to be sure and it's too difficult to demo)

## Where to go from here?

- WWDC 2016 Making the Most of Search APIs
- WWDC 2016 Increase Usage of Your App With Proactive Suggestions
- https://search.developer.apple.com