```metadata
author: "By Jeff Rames"
number: "13"
title: "Chapter 13: What’s New with Search"
```
# Chapter 13: What’s New with Search

Search frameworks gain some hefty new features with iOS 10. Most notable is the introduction of the Core Spotlight Search API, which brings the power of Spotlight search to your apps. For apps that already use Core Spotlight or user activity indexing, leveraging that same engine and index inside your app is easy — and powerful.

Another great new feature is the ability to continue Spotlight searches in your app. If a search yields results for your app, you can enable an annotation that launches your app and passes in the search string for further searching.

![width=50%](./images/search-in-app-annotation.png)

In addition, proactive suggestions have learned some exciting new tricks. By adding location data to your user activities, addresses displayed in your app can be made available throughout iOS. Features and apps such as QuickType, Siri and Maps will now have direct access to your data, while giving your app credit as the source.

![width=50%](./images/proactive-location-suggestion-example.png)

All of these changes continue the trend of increasing your app’s reach outside of its own little world. iOS 10 gives you more ways to entice users into launching your app — and more opportunities to remind users how useful your app can be.

If you’re already indexing Core Spotlight or NSUserActivity items, these features are amazingly easy to implement in your apps. If your app deals in data, and you’re not currently using these features, this is probably the time to bring your app into the 21st century and integrate these frameworks in your app. 

For some background on search APIs in iOS, check out Introducing iOS 9 Search APIs here: [https://videos.raywenderlich.com/courses/introducing-ios-9-search-apis/lessons/1](https://videos.raywenderlich.com/courses/introducing-ios-9-search-apis/lessons/1)

You can complete most of this chapter with the simulator, but you’ll need a device running iOS 10 to test proactive location suggestions.

## Getting started

In this chapter, you’ll update an existing app called Green Grocer. It displays produce available at Ray’s Fruit Emporium and employs a simple product filter. It also has a tab with contact info for the store along with a map.

![width=75%](./images/green-grocer-starter.png)

In the starter folder, open **GreenGrocer.xcodeproj** and take a look around. There’s quite a lot in the project, but here’s a quick overview of the important files:

- **AppDelegate.swift** does two things of note already. In `application(_:didFinishLaunchingWithOptions:)` it calls `dataStore?.indexContent()` which indexes all products in Core Spotlight. `application(_:continue:restorationHandler:)` is currently set up to restore state when the user launches the app by tapping a product that Core Spotlight matched.
- **Product.swift** is the model object for the `Product` class. This represents one of the produce items central to Green Grocer. 
- **SearchableExtensions.swift** contains an extension to `Product` that generates `CSSearchableItem` and `CSSearchableItemAttributeSet` objects used when indexing to Core Spotlight.
- **ProductTableViewController.swift** is the root controller in the **Products** tab. It displays a table view of produce and includes a `UISearchController` for filtering the content. Filtering happens in `filterContentForSearchText(searchText:)` which triggers each time content in the search bar changes.
- **ProductViewController.swift** is the detail controller for produce, which displays when the user selects a cell in the `ProductTableViewController`. It configures the view with data from the passed Product and creates a `NSUserActivity` to index the activity.
- **StoreViewController.swift** controls the view displayed in the **Store** tab that contains contact info for Ray’s Fruit Emporium. It also contains a map view for displaying the location of the store — something you’ll leverage when implementing proactive suggestions.

Green Grocer already enables Spotlight search via Core Spotlight and NSUserActivity indexing. In this chapter, you will make three modifications:

1. You’ll start by implementing search continuation to feed Spotlight search queries to the search filter found in `ProductTableViewController`. 
2. Next, you’ll refactor the existing in-app search to use the Core Spotlight Search API. 
3. Finally, you’ll modify the `StoreViewController` so that it provides activity information necessary to enable location based proactive suggestions.

Enough talk — the future of Ray’s Fruit Emporium depends on you! Head on in to the next section to get started.

## Enabling search continuation

Spotlight search helps users quickly find what they’re looking for. A user could enter the word *apple* into Spotlight and be one tap away from seeing the price on the Ray’s Fruit Emporium product page. Spotlight fits that model quite well.

But what if the user’s goal is a little different? If the user wanted to view all of Ray’s fruit, they could search for *fruit* in Spotlight, but it would be unreasonable to expect every item to display right there. Results are limited to just a few matches per source; otherwise, responses would be unmanageably long.

This is where **search continuation** steps into the, er, spotlight. It lets Spotlight launch your app and pass the user’s search query. This lets you not only display all results, but display them in your custom interface.

Open **Info.plist** and add a Boolean key named **CoreSpotlightContinuation** and set it to **YES**.

![width=70%](./images/search-continuation-plist.png)

This key tells Spotlight to display an annotation in the upper right of Green Grocer search results to indicate the search can be continued in-app.

This is where things gets scary. As of the initial public release of iOS 10, updating this plist does not cause the annotation to start working until you reboot the device or simulator. Feel free to bravely forge ahead without a reboot, but if **Search in App** doesn’t appear in the next step, you’re going to have to reboot your device after building.

Build and run, then background the app with the home button or **Shift+Command+H** in the simulator. Drag down to reveal Spotlight search and enter **apple**. Note the **Search in App** annotation that appears to the right of **GREENGROCER** in the section header:

![iphone](./images/search-annotation.png)

Tap **Search in App**, and Green Grocer will launch to the Products table — but it won’t kick off a search. This shouldn’t come as a surprise, considering you haven’t written any code to accept the query from Spotlight and act on it!

You’ll take care of that next.

## Implementing search continuation

Open **AppDelegate.swift** and add the following near the top of the file with the other `import`:

```swift
import CoreSpotlight
```

Search continuation requires some properties that are available in the framework.

Now look for `application(:_continue:restorationHandler:)` and replace the following line:

```swift
if let rootVC = window?.rootViewController,
```

With this:

```swift
if userActivity.activityType == CSQueryContinuationActionType {
  // TODO handle search continuation
} else if let rootVC = window?.rootViewController,
```

Previously, `application(:_continue:restorationHandler:)` was used solely as an entry point for restoring state after a user had selected an activity indexed in Spotlight. You’ve added a check for `CSQueryContinuationActionType` activities — which is what **Search in App** triggers. The prior check moves down to an `else if`, letting the processing of Spotlight result launches operate as they did before.

Now replace `// TODO handle search continuation` with the following:

```swift
// 1
guard let searchQuery =
  userActivity.userInfo?[CSSearchQueryString]
    as? String else {
    return false
}
// 2
guard let rootVC = window?.rootViewController,
  let tabBarViewController = rootVC as? TabBarViewController
  else {
    return false
}
tabBarViewController.selectedIndex = 0
// 3
guard let navController =
  tabBarViewController.selectedViewController as?
  UINavigationController else {
    return false
}
navController.popViewController(animated: false)
if let productTableVC = navController.topViewController as?
  ProductTableViewController {
  //4
  productTableVC.search(with: searchQuery)
  return true
}
```

Here’s some detail on what happens when you hit a search continuation activity:

1. The `CSSearchQueryString` key in `userActivity.userInfo` points to the string typed into Spotlight. This guard unwraps and casts the `searchQuery` or, on failure, returns `false` to indicate the activity could not be processed.
2. The root view of Green Grocer is a tab bar controller. This guard places a reference to that controller in `tabBarViewController`. You then set `selectedIndex` to the first tab to display the product list.
3. The selected tab in `tabBarViewController` contains a navigation controller. You get a reference to it here, then call `popViewController(animated:)` with no animation to get to the root controller. The root is the `ProductTableViewController`, which `productTableVC` now points to.
4. `search(with:)` is a method in `ProductTableViewController` that kicks off the in-app product search using the passed parameter. It’s called here with the `searchQuery`, followed by `return true` to indicate Green Grocer was able to handle the incoming search request.

Build and run, background the app, then search for **apple** in Spotlight. Tap the **Search in App** annotation by the Green Grocer results. This time, your new restoration handler code will trigger and you’ll be brought straight to search results!

![width=75%](./images/search-continuation-working.png)

Of course, doing a search continuation for *apple* doesn’t make much sense. Before you tapped **Search in App**, you already knew there would be only a single match, because Spotlight would have shown at least a few if there were more. Beyond that, the custom search result cells in Green Grocer actually provides less information than Spotlight does!

A search with a result set too large to display completely in Spotlight would be a better use case for this feature. Green Grocer includes the term “fruit” with every product it indexes in Spotlight, so that’s a good one to try. 

Background Green Grocer again and complete a Spotlight search for **fruit**. Only three results will display; a mere sample of what Green Grocer contains. Tap **Search in App** to see the in-app results for *fruit*.

![width=75%](./images/mismatched-fruit-search.png)

Green Grocer successfully launches and presents a search result for *fruit* — but where are all the matches?

![width=25%](./images/why-hide-produce.png)

It’s clear `fruit` was included in the meta-data when indexing the produce, but the search must not be looking at this in the same way. Open **ProductTableViewController.swift** and find `filterContentForSearchText(searchText:)`. Take a look at the filter contained in this method:

```swift
filteredProducts = dataStore.products.filter { product in
  return product.name.lowercased().contains(searchText.lowercased())
}
```

`filteredProducts` acts as the data source when filtered results display. Here it’s set using a `filter` on the complete `dataStore.products` array. The filter does a case-insensitive compare to identify any product names that contain the search string.

This isn’t a bad way to filter the product list, but it’s clear you could do better. To replicate Spotlight’s results, you could index all of the associated meta-data for each product and create a more complex filter that includes that data. 

But wouldn’t it be nice to use Spotlight’s existing index, search algorithm, and performance benefits instead of rolling your own? With iOS 10, you can! The new Core Spotlight Search API provides access to all of these features in Spotlight.

Before refactoring your code, you’ll do well to walk through the following overview of Core Spotlight’s features and query syntax first. 

## Core Spotlight Search API

Spotlight handles the indexing of your data and provides a powerful query language for use with its speedy search engine. This lets you use your own search interface — backed by the power of Spotlight.

If you’ve already indexed content with Core Spotlight, using the Search API means you'll have more consistency between in-app searches and those completed in Spotlight. It also protects user privacy as an app can only search its own indexed data.

To complete a search, you first create a **CSSearchQuery** that defines what and how you want to search. The initializer for `CSSearchQuery` requires two things:

- **queryString**: A formatted string that defines how you want to search. You’ll learn more about how to format query strings shortly.
- **attributes**: An array of strings that correspond to names of properties in the **CSSearchableItemAttributeSet** class. The properties you include here will be returned in the result set, if available. You’d then use them to display the result or look it up in the application model.

Knowing how to format the search query string is the primary challenge in implementing Core Spotlight Search. The format of the most basic query is as follows:

```
attributeName operator value[modifiers]
```

Note these names are for illustration and not associated with the format syntax. Here’s a breakdown of each component:

1. **attributeName** is one of the properties included in the `attributes` array. For example, this could be the product `title` in Green Grocer.
2. **operator** is a relational operator from the following list: ==, !=, <, <=, >, >=. 
3. **value** is the literal value you’re comparing against. For the title example, the value might be *fruit*.
4. **modifiers** consist of four different character values that represent modifications to how the comparison is applied. See the table below for detail on the available modifiers.

![bordered width=100%](./images/modifier-table.png)

The existing Green Grocer in-app search does a case-insensitive compare for product names that contain the search query. Assuming the user searched for *apple*, and *title* was passed as an attribute, a comparable Spotlight search query would look like this:

```
title == "*apple*"c
```

The base compare checks that the `title` attribute contains the string *apple*. The * is a simple wildcard, meaning titles that contain *apple* meet the criteria, even if they have text before or after the word. The `c` modifier makes the comparison case-insensitive.

A word-based search may make more sense if the user simply wants strings that contain the unique word *apple*. They may want to see Fuji Apple and Red Delicious Apple, but not Pineapple or Snapple. In such a case, you likely want to ditch the wildcard to focus only on complete matches, making it more like a true search rather than a filter.

Here’s what such a search would look like:

```
title == "apple"wc
```

Here the string is *apple*, with no wildcards. The `w` modifier says *apple* can appear anywhere in the title string, as long as it’s a standalone word. Core Spotlight indexing is optimized to handle this faster than a wildcard, and as a bonus it provides a more accurately refined result set.

Numerics, especially dates, are quite common in search queries. It’s especially common to check that a value falls within a given range. For this reason, the query language provides a second query syntax for this purpose:

```
InRange(attributeName, minValue, maxValue)
```

This checks that values associated with `attributeName` fall within the range bounded by `minValue` and `maxValue`.

Dates are an obvious use case for InRange queries. For dates, the query language uses floating-point values representing seconds relative to January 1, 2001. More commonly, you’ll use `$time` values to derive dates. 

`$time` has properties such as `now` and `today` that represent specific times relative to when a query kicks off. It allows for calculated dates relative to the current time, such as `now(NUMBER)` where `NUMBER` represents seconds added to the current time.

These simple queries formats can be combined to create more complex searches with the familiar `&&` and `||` operators. Here’s an example using both query formats:

```
title == "apple"wc && InRange(metadataModificationDate,$time.today(-5),$time.today)
```

`metadataModificationDate` is an attribute property that indicates the last date an item’s metadata was updated. This query looks for products with _apple_ in the title, as before. In addition, it checks that the item has been updated within the past 5 days — a great way to search for new or updated product listings.

>**Note**: The above query example won’t work in Green Grocer, because it doesn’t set the `metadataModificationDate`. If you wanted to do this, you’d have to add the property when indexing data. Additionally, you’d likely only do this if the user indicated a desire to view only new or updated products, perhaps via a search flag in your UI.

A complete list of `$time` properties, along with more detail on query language in general, can be found in Apple’s documentation on CSSearchQuery: [apple.co/1UPjAry](http://apple.co/1UPjAry) 

With this knowledge in hand, you’ve got all you need to start converting Green Grocer’s search to use Core Spotlight!

### Migrating to Core Spotlight Search API

Open **ProductTableViewController.swift** and add the following to the other properties at the top of `ProductTableViewController`:

```swift
var searchQuery: CSSearchQuery?
```

You’ll use this to manage the state of the `CSSearchQuery` requests you kick off.

Now look for `filterContentForSearchText(searchText:)` in the `UISearchResultsUpdating` extension. This is called when the user updates their search string. It currently uses a `filter` to identify products in the `dataStore` with names matching the search string.

It’s time to throw that away in favor of Core Spotlight Search!

Start by deleting this code:

```swift
filteredProducts = dataStore.products.filter { product in
  return product.name.lowercased().contains(searchText.lowercased())
}

tableView.reloadData()
```

In its place, add the following:

```swift
// 1
searchQuery?.cancel()

// 2
let queryString = "title=='*\(searchText)*'c"
// 3
let newQuery = CSSearchQuery(queryString: queryString, attributes: [])
searchQuery = newQuery

// 4
//TODO: add found items handler
//TODO: add completion handler

// 5
filteredProducts.removeAll(keepingCapacity: true)
newQuery.start()
```

This sets up the bones of the search. Here’s what’s going on:

1. As this method gets called each time a new search should be kicked off, canceling any currently running searches is good practice. `searchQuery` will later point to the new search query.
2. This `queryString` seeks to replicate Spotlight’s behavior; it looks for the user-provided `searchText` in the `title` property. The query uses a case-insensitive compare and flanks the term with wildcards, meaning the product name can have other text before or after it and still match.
3. You then create a `CSSearchQuery`, passing `newQuery` as the query string and an empty attributes array. No attributes are required in the result set; instead, you’ll pull object from the database using the returned search item’s unique identifier. `searchQuery` now points to the `newQuery` so that you can cancel it when you kick off another search.
4. These TODOs relate to required handlers associated with the `CSSearchQuery` operation. You’ll address these shortly.
5. You use `filteredProducts` as the table view data source when a filter is in effect. Because you’re kicking off a new search, you should clear out the previous results. `newQuery.start()` then starts the Spotlight query.

Right now, nothing is listening for returned search results. Fix that by replacing `//TODO: add found items handler` with:

```swift
newQuery.foundItemsHandler = {
  (items: [CSSearchableItem]) -> Void in
  for item in items {
    if let filteredProduct = dataStore.product(withId: 
      item.uniqueIdentifier) {
      self.filteredProducts.append(filteredProduct)
    }
  }
}
```

The `foundItemsHandler` is called as batches of `CSSearchableItem` objects matching the query criteria return from Core Spotlight. This code iterates over each returned `item` and locates a Product with a matching `uniqueIdentifier` in the `dataStore`. You then add the products to `filteredProducts`, which is the table view data source when a filter is active.

Finally, there is a `completionHandler` that runs when all results are in. This is where you’d do any processing on the final results and display them.

Replace `//TODO: add completion handler` with the following:

```swift
newQuery.completionHandler = { [weak self] (err) -> Void in
  guard let strongSelf = self else {
    return
  }
  strongSelf.filteredProducts = strongSelf.filteredProducts.sorted
    { return $0.name < $1.name }
  
  DispatchQueue.main.async {
    strongSelf.tableView.reloadData()
  }
}
```

You added the results to `filteredProducts` in the arbitrary order as returned by Core Spotlight. This code sorts them to match the order used by the unfiltered data. Code to reload the tableview is dispatched to the main queue, as this handler runs on a background thread.

Build and run; test your the filter on the **Products** tab. The behavior will be identical to the previous implementation. The example below shows a partial match for *Ap* that includes _Apple_ and _Grapes_:

![bordered iphone](./images/spotlight-search-implemented.png)

This query filters products in a similar manner to Spotlight, but it has a major shortcoming: It only searches the product title, whereas Spotlight checks all of the metadata. 

To prove this, do an in-app search for *fruit* as you did before implementing Core Spotlight Search.

![bordered iphone](./images/empty-fruit-search.png)

The title field doesn’t include _fruit_, but the `keywords` property does. Clearly, Spotlight searches more than just title. You’ll have to expand your query to match.

Still in `filterContentForSearchText(searchText:)`, find the following line:

```swift
let queryString = "title=='*\(searchText)*'c"
```

Replace it with the following:

```swift
let queryString = "**=='*\(searchText)*'cd"
```

The main change here is that instead of matching on `title`, you’re using `**`. This applies the comparison to all properties in the search items’ attribute sets. You’ve also added the `d` modifier to ignore diacritical marks. While this has no impact with Green Grocer’s current inventory, it’s a good general practice to follow.

Build and run, and enter a search for **fruit**. This time, you’ll see all of the produce in the result set, just as you do in Spotlight.

![bordered iphone](./images/fruit-search.png)

>**Note**: A more practical example might be a user who recalled seeing a product with “potassium” in the description. Searching on that keyword in Spotlight will show “banana” — and now you can support that with in-app search!

The search you implemented was a simple one, with the primary goal of making Green Grocer’s in-app results match those out of Spotlight. However, understanding these mechanics gives you all you need to know to deploy more sophisticated searches tailored to your specific data and user’s needs.

## Proactive suggestions for location

Adopting search makes it easy to implement other features that use NSUserActivity, such as Handoff and contextual reminders. Adding location data to your indexed NSUserActivity objects means they can be consumed by Maps, QuickType, Siri, and more.

View the Store tab in Green Grocer; the content is related to a physical location: the address of Ray’s Fruit Emporium. 

![bordered iphone](./images/store-tab.png)

Wouldn’t it be great if the Emporium address appeared above recent locations when you switch to the Map view? Or what if if the address appeared as a QuickType option in Messages, so you could tell your friends where to pick up the freshest pears in town?

Proactive suggestions with location based activities make all of this possible, and more. Below are a few examples.

![width=100%](./images/location-feature-preview.png)

From a user’s perspective, this is one of the more exciting multitasking features iOS has introduced in a long time. From a developer’s perspective, it’s a great way to increase awareness of your app and your brand throughout iOS. As an added bonus, it’s extremely easy to implement for apps that already index NSUserActivity objects.

To enable the feature, you need to minimally set the new **thoroughfare** and **postalCode** `CSSearchableItemAttributeSet` properties for location-related activities. These are used both for display purposes and to help location services find the address. You can further improve the quality of the results by including the following optional properties:

- `namedLocation`
- `city`
- `stateOrProvince`
- `country`

For more accuracy, you should include the `latitude` and `longitude` properties as well.

Adding a few properties isn’t too hard, but wouldn’t it be easier if it was just one propery? If you’re using MapKit, you can point your `MKMapItem` to an NSUserActivity and it will populate all the location information for you. Fortunately, Green Grocer already leverages this, so it will be a snap to set up.

Time for a quick experiment. You need to do this on a physical device, as many location features are unavailable on the simulator. If you haven’t already, be sure to set your development team in the GreenGrocer target’s Signing section in the General tab.

Launch Green Grocer on a physical device, navigate to the **Store** tab and take note of the store address on Mulberry Street. Switch back and forth between tabs a couple of times to make sure the NSUserActivity indexing occurs.

Now jump to the home screen and do a Spotlight search for **Mulberry Street**. Make sure to scroll through all the results, and you’ll see there are no Green Grocer matches. 

![iphone](./images/mulberry-street-no-match.png)

Take a quick look in **StoreViewController.swift** and you’ll see a `MKMapItem` with the store’s address, as well as a `CSSearchableItemAttributeSet` containing the `longitude` and `latitude` of the shop. 

The `supportsNavigation` attribute is also set to `true`, allowing navigation from Spotlight using the coordinates. However, Spotlight currently has no knowledge of the address, so it makes sense that Mulberry Street turned up no matches.

In one single line of code, you’re going to provide the `NSUserActivity` with attributes needed to enable address search and enable proactive location suggestions.

In **StoreViewController.swift** find `prepareUserActivity()`. This is called when the store view loads and creates a search eligible `NSUserActivity` for the view.

Add the following line just above the `return` at the end:

```swift
activity.mapItem = mapItem()
```

`mapItem()` returns an `MKMapItem` that represents the location of the store. Setting `mapItem` to that value is all that’s required to unlock location suggestions. Additionally, setting the `mapItem` populates the `CSSearchableItemAttributeSet` of the activity with all of its location information, including the street name.

Although `CSSearchableItemAttributeSet` properties are now set from the `MKMapItem`, they are overridden by existing code. 

Find the following line in `updateUserActivityState(_:)`:

```swift
let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeContact as String)
```

This creates a new `CSSearchableItemAttributeSet` that is ultimately assigned to the new NSUserActivity, thus replacing anything `MKMapItem` provided.

Replace it with the following:

```swift
let attributeSet = activity.contentAttributeSet ??
  CSSearchableItemAttributeSet(itemContentType: kUTTypeContact as String)
```

Now, if `contentAttributeSet` is already populated — thanks to the map item — it’s added to, rather than replaced.

Build and run on a device, and flip between the two tabs a few times to ensure the NSUserActivity changes are indexed. Now double-tap the home button to bring up the app switcher. You’ll see a proactive suggestion appear at the bottom of the screen including Green Grocer’s name and the location of Ray’s Fruit Emporium. 

The suggested app differs based on what you have installed, but in the example below it’s offering to launch Maps with directions to the store. Tapping the banner takes you to the suggested app with your location data prepopulated. Ray’s Produce is really great, but it might not be worth the 18 hour drive from Texas! :]

![width=75%](./images/map-direction-fast-switcher.png)

Now open Messages and start typing a message that includes the words **Meet me at** and you’ll see a QuickType suggestion including Ray’s store. As with other proactive suggestions, your app is getting some good press here with the *From GreenGrocer* tagline.

![bordered iphone](./images/message-quicktype.png)

Think back to the test in Spotlight search, where *Mulberry* pulled up zero results from Green Grocer. Repeat the search for **Mulberry**, and you’ll now see a result for Ray’s Fruit Emporium! This means the `MKMapItem` is successfully providing location information to the `CSSearchableItemAttributeSet`.

![iphone](./images/mulberry-spotlight-search-working.png)

These are just a handful of examples of proactive suggestions. It should be pretty clear at this point that adding location data to your NSUserActivity objects is quite powerful. Not only does it streamline common user workflows, it reinforces awareness of your app throughout iOS.

## Where to go from here?

In this chapter, you took an existing app with Core Spotlight and activity indexing and added some seriously cool functionality with minor effort. You enabled search continuation from Spotlight, and then refactored in-app search to use Spotlight’s engine. Then with a single line of code, you enabled location based proactive suggestions to better integrate your app with iOS.

If you have an app already using Core Spotlight, the effort-to-benefit ratio should make adopting these features very compelling. Not only do they improve user experience, but they better integrate your app with iOS, giving you more opportunity to engage with the iOS ecosystem.

For more detail, check out the following resources:

- WWDC 2016 Making the Most of Search APIs [apple.co/2cPwCbA](http://apple.co/2cPwCbA)
- WWDC 2016 Increase Usage of Your App With Proactive Suggestions [apple.co/2cvOsAM](http://apple.co/2cvOsAM)
- [search.developer.apple.com](https://search.developer.apple.com)