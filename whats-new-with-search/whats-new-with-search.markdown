```metadata
author: "By Jeff Rames"
number: "13"
title: "Chapter 13: What's New with Search"
```
# Chapter 13: What's New with Search

The search frameworks gain some hefty new features with iOS 10. Most notable is the introduction of the Core Spotlight Search API which brings the power of Spotlight search to your apps. For apps that already use Core Spotlight or user activity indexing, leveraging that same engine and index inside your app is easy and powerful.

You can also now provide your users the ability to continue Spotlight searches in your app. If a search yields results for your app, an annotation can be enabled that launches your app with access to the search string.

![width=35%](./images/search-in-app-annotation.png)

Proactive suggestions, which share user activities with search functions, have also learned exciting new tricks. By adding location data to your user activities, you'll now be able to make addresses displayed in your app available throughout iOS. Features and apps such as QuickType, Siri and Maps will have direct access to your data while giving your app credit as the source.

![width=35%](./images/proactive-location-suggestion-example.png)

All of these changes continue the great trend of increasing the reach of your app outside of its sandbox. You now have more ways to entice users into launching your app, and more opportunities to remind them how useful your app is.

On top of the benefits, these features are amazingly easy to implement if you're already indexing Core Spotlight or NSUserActivity items. If your app deals in data, and you're not currently using these features, you most likely should be. 

If you need to get up to speed, check out Introducing iOS 9 Search APIs here: https://videos.raywenderlich.com/courses/introducing-ios-9-search-apis/lessons/1

For most of this chapter, you'll be fine using the simulator. However, you'll need a device running iOS 10 handy for testing proactive location suggestions. They are not fully supported in the simulator.

## Getting started

In this chapter, you'll work with an existing app called Green Grocer. It currently displays produce available at Ray's Fruit Emporium, and employs a simple product filter. It also has a tab containing contact info for the store along with a map.

![width=75%](./images/green-grocer-starter.png)

Green Grocer already enables Spotlight search via Core Spotlight and NSUserActivity indexing. Using the index, you'll replace the existing string matching product search with one using the Core Spotlight Search API. You'll also implement search continuation and location based proactive suggestions.

In the starter folder, open **GreenGrocer.xcodeproj** and take a look around. There's quite a lot in the project, but here's a quick overview of files you'll interact with:

- **AppDelegate.swift** does two things of note already. In `application(_:didFinishLaunchingWithOptions:)` it calls `dataStore?.indexContent()` which indexes all products in Core Spotlight. `application(_:continue:restorationHandler:)` is currently set up to restore state when the app is launched by a user tapping a product matched in Core Spotlight.
- **Product.swift** is the model object for the `Product` class. This represents one of the produce items that are central to Green Grocer. **SearchableExtensions.swift** contains an extension to `Product` that is used to generate `CSSearchableItem` and `CSSearchableItemAttributeSet` objects used when indexing to Core Spotlight.
- **ProductTableViewController.swift** is the root controller in the **Products** tab. It displays a table view of produce and includes a `UISearchController` for filtering the content. Filtering happens in `filterContentForSearchText(searchText:)` which is triggered each time content in the search bar changes.
- **ProductViewController.swift** is the detail controller for produce, displayed when selecting a cell in the `ProductTableViewController`. It configures the view with data from the passed Product, and creates a `NSUserActivity` to index the activity.
- **StoreViewController.swift** controls the view displayed in the **Store** tab containing contact info for Ray's Fruit Emporium. It also contains a map view for displaying the location of the store—something you'll leverage when implementing proactive suggestions.

You'll start by implementing search continuation to feed Spotlight search queries to the search filter found in `ProductTableViewController`. Then you'll refactor the existing in-app search to use the Core Spotlight Search API. Finally, you'll modify the `StoreViewController` so that it provides activity information necessary to enable location based proactive suggestions.

Enough planning—it's time to get to the fun stuff, starting with search continuation! :]

## Search continuation

The primary purpose of Spotlight search is to help users find what they're looking for quickly. If someone was trying to find the price of an apple at Ray's Fruit Emporium, they could enter the word *apple* into Spotlight and be one tap away from seeing the price on the product page. For that case, Spotlight serves its purpose perfectly.

But what if the goal is a little different? If the user wanted to view all fruits currently available, they could search for *fruit* in Spotlight, but it would be unreasonable to expect every item to be displayed right there. Results are limited to just a few matches per source—otherwise responses would be unmanageably long.

This is where **search continuation** steps in—it allows Spotlight to launch your app while passing the user's search query. This allows you to not only display all results, but to display them in your custom interface.

Open **Info.plist** and add a key called **CoreSpotlightContinuation** of type Boolean and set it to **YES**.

![width=50%](./images/search-continuation-plist.png)

This key tells Spotlight to display an annotation in the upper right of Green Grocer search results indicating the search can be continued in-app.

Build and run—and this is where it gets scary. As of the initial public release of iOS 10, updating this plist does not cause the annotation to start working until the device or simulator is rebooted. Feel free to bravely forge ahead without doing so, but if **Search in App** does not appear in the next step, you're going to have to reboot your device after building.

Build and run, then background the app with the home button or **Shift+Command+H** if you're in the simulator. Drag down to reveal Spotlight search and enter **apple**. Note the **Search in App** annotation that now appears to the right of **GREENGROCER** in the section header:

![iphone](./images/search-annotation.png)

Tap **Search in App**, and Green Grocer will launch to the Products table—but it won't kick off a search. This shouldn't come as a surprise, considering you haven't written any code to accept the query from Spotlight and act on it! Time to do that :]

Open **AppDelegate.swift** and add the following near the top of the file with the other `import`:

```swift
import CoreSpotlight
```

Search continuation requires some properties available in the framework.

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

Previously, `application(:_continue:restorationHandler:)` was solely used as an entry point for restoring state after a user selected an activity indexed in Spotlight. You've added a check for `CSQueryContinuationActionType` activities—which is what *Search in App* triggers. The prior check is moved down to an `else if`, allowing processing of Spotlight result launches to operate as they did before.

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

Here's some detail on what happens when a search continuation activity is hit:

1. The `CSSearchQueryString` key in `userActivity.userInfo` points to the string typed into Spotlight. This guard unwraps and casts the `searchQuery` or, on failure, returns `false` to indicate the activity could not be processed.
2. The root view of Green Grocer is a tab bar controller, which this guard places a reference to in `tabBarViewController`. The `selectedIndex` is then set to the first tab, where the product list is displayed.
3. The selected tab in `tabBarViewController` contains a navigation controller. A reference is obtained here, and then `popViewController(animated:)` is called with no animation to get to the root controller. The root is the `ProductTableViewController`, which `productTableVC` now points to.
4. `search(with:)` is a method in `ProductTableViewController` that kicks off the in-app product search using the passed parameter. It gets called here with the `searchQuery`, followed by `return true` to indicate Green Grocer was able to handle the incoming search request.

Build and run, and again background the app, search for **apple** in Spotlight and then tap the **Search in App** annotation by the Green Grocer results. This time, your new restoration handler code will trigger and you'll be brought straight to search results!

![width=75%](./images/search-continuation-working.png)

Of course, doing a search continuation for *apple* doesn't make much sense. Before you tapped **Search in App**, you already knew there was only a single match because Spotlight would have shown at least a few if there were more. Beyond that, the custom search result cells in Green Grocer actually provides less information than Spotlight does!

A search with a result set too large to display in Spotlight would be a better use case for this feature. Green Grocer includes the term fruit with every product it indexes in Spotlight, so that's a good one to try. 

Background Green Grocer again, and complete a Spotlight search for **fruit**. Only three results will be shown—just a sample of what Green Grocer contains. Tap **Search in App** to see the in-app results for *fruit*.

![width=75%](./images/mismatched-fruit-search.png)

Green Grocer successfully launches and presents a search result for *fruit*—but there are no matches!

![width=25%](./images/why-hide-produce.png)

It's clear fruit was included in the meta-data when indexing the produce, but the search must not be looking at this same thing. Open **ProductTableViewController.swift** and find `filterContentForSearchText(searchText:)`. Take a look at the filter contained in this method:

```swift
filteredProducts = dataStore.products.filter { product in
  return product.name.lowercased().contains(searchText.lowercased())
}
```

`filteredProducts` acts as the data source when filtered results are displayed. Here it's set using a `filter` on the complete `dataStore.products` array. The filter does a case insensitive compare to identify any product names containing the search string.

This isn't a bad way to filter the product list, but face to face with Spotlight results it's clear you could do better. To replicate Spotlight's results, you could index all of the associated meta-data for each product and create a more complex filter including that data. 

But wouldn't it be nice to use Spotlight's existing index, search algorithm, and performance benefits? With iOS 10, you can! The new Core Spotlight Search API provides access to Spotlight, enabling all of these benefits.

Before diving into this refactor, an overview of the feature and the query syntax it employs is in order. 

## Core Spotlight Search API

The new Core Spotlight Search API provides access to Spotlight from within your own app. Spotlight handles the indexing of your data and provides a powerful query language for use with its speedy search engine. This allows you to use your own search interface backed by the power of Spotlight.

If you've already indexed content with Core Spotlight, leveraging the Search API results in consistency between in-app searches and those completed in Spotlight. User privacy is maintained as an app only has the ability to search its own indexed data.

To complete a search, you first create a **CSSearchQuery** that defines what and how you want to search. The initializer for `CSSearchQuery` requires two things:

- **queryString** is a formatted string that defines how you want to search. You'll learn more about how to format query strings shortly.
- **attributes** is an array of strings that correspond to names of properties in the **CSSearchableItemAttributeSet** class. The properties you include here will be returned in the result set, if available. They would then be used to display the result or look it up in the application model.

Knowing how to format that search query string is the primary challenge in implementing Core Spotlight Search. An overview of the basics is in order before you jump in.

The format of the most basic query is as follows:

```
attributeName operator value[modifiers]
```

Note these names are for illustration and not associated with the format syntax. Here's a breakdown of each component:

1. **attributeName** is one of the properties included in the `attributes` array. For example, this could be the product `title` in Green Grocer.
2. **operator** is a relational operator from the following list: ==, !=, <, <=, >, >=. 
3. **value** is the literal value you're comparing against. For the title example, the value might be *fruit*.
4. **modifiers** consist of four different character values that represent modifications to how the comparison is applied. See the table below for detail on the available modifiers.

![bordered width=90%](./images/modifier-table.png)

Recall the existing Green Grocer in-app search does a case insensitive compare for product names containing the search query. Assuming the user searched for *apple* and *title* was passed as an attribute, a comparable Spotlight search query would look like this:

```
title == "*apple*"c
```

The base compare checks that the `title` attribute contains the string *apple*. The * is a simple wildcard, meaning titles that contain *apple* meet the criteria even if they have text before or after the word. The `c` modifier makes the comparison case insensitive.

A word-based search may make more sense if the user just wants strings that contain the unique word apple. They may want to see Fuji Apple and Red Delicious Apple but not Pineapple or Snapple. In such a case, you likely want to ditch the wildcard to focus only on complete matches—making it more similar to a true search rather than a filter.

Here's what such a search would look like:

```
title == "apple"wc
```

Here the string is *apple*, with no wildcards. The `w` modifier says *apple* can appear anywhere in the title string, as long as it's a standalone word. Core Spotlight indexing is optimized to handle this faster than a wildcard, and as a bonus it provides a more accurately refined result-set.

Numerics, especially dates, are quite common in search queries. It's especially common to check that a value falls within a given range. For this reason, the query language provides a second query syntax for this purpose:

```
InRange(attributeName, minValue, maxValue)
```

This checks that values associated with `attributeName` fall within the range bounded by `minValue` and `maxValue`.

Dates are an obvious use case for InRange queries. For dates, the query language uses floating-point values representing seconds relative to January 1, 2001. More commonly, you'll use **\$time** values to derive dates. 

\$time has properties such as `now` and `today` that represent specific times relative to when a query kicks off. It allows for calculated dates relative to the current time such as `now(NUMBER)` where `NUMBER` represents seconds added to the current time.

These simple queries formats can of course be combined to create more complex searches. This is done with the familiar `&&` and `||` operators allowing you to AND or OR multiple queries. Here's an example using both query formats:

```
title == "apple"wc && InRange(metadataModificationDate,$time.today(-5),$time.today)
```

`metadataModificationDate` is an attribute property used to indicate the date metadata was last updated on an item. This query looks for products with apple in the title, as before. In addition, it checks that the item had some metadata updates within the past 5 days—a great way to look for only new or updated product listings.

>**Note** The above query example won't work in Green Grocer, because it doesn't set the `metadataModificationDate`. If you wanted to be able to do this, you'd have to add the property when indexing data. Additionally, you'd likely only do this if the user indicated a desire to view only new or updated products, perhaps via a search flag in your UI.

A complete list of ```$time``` properties, along with more detail on query language in general, can be found in Apple's documentation on CSSearchQuery: [apple.co/1UPjAry](http://apple.co/1UPjAry) 

With this knowledge in hand, you've got all you need to start converting Green Grocer's search to use Core Spotlight!

### Migrating to Core Spotlight Search API

Open **ProductTableViewController.swift** and add the following with the other properties at the top of `ProductTableViewController`:

```swift
var searchQuery: CSSearchQuery?
```

You'll use this to manage state of the `CSSearchQuery` requests you kick off when searching.

Now look for `filterContentForSearchText(searchText:)` in the `UISearchResultsUpdating` extension. As you may recall, this is called when the user updates their search string. It currently uses a `filter` to identify products in the `dataStore` with names matching the search string.

It's time to throw that away in favor of Core Spotlight Search! Start by deleting this code:

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

This sets up the bones of the search. Here are some details:

1. As this method gets called each time a new search should be kicked off, canceling any currently running searches is good practice. `searchQuery` will later be pointed to the newly running search query.
2. This `queryString` seeks to replicate Spotlight's behavior—it looks for the user typed `searchText` in the `title` property. The query uses a case insensitive compare and flanks the term with wildcards, meaning the product name can have other text before or after it and still match.
3. A `CSSearchQuery` is created, passing `newQuery` as the query string and an empty attributes array. No attributes will be required in the result set—objects will instead be pulled from the database using the returned search item's unique identifier. `searchQuery` is now pointed to the `newQuery`, so that it can be canceled when another search is kicked off.
4. These TODOs relate to required handlers associated with the CSSearchQuery operation—they'll be addressed shortly.
5. `filteredProducts` is used as the table view data source when a filter is in effect. Because a new search is being kicked off, the previous results should be cleared out. `newQuery.start()` then starts the Spotlight query.

Right now nothing is listening for returned search results. Fix that by replacing `//TODO: add found items handler` with:

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

The `foundItemsHandler` is called as batches of `CSSearchableItem` objects matching the query criteria are returned by Core Spotlight. This code iterates over each returned `item` and locates a Product with a matching `uniqueIdentifier` in the `dataStore`. The products are added to `filteredProducts`, which is the table view data source when a filter is in place.

Finally, there is a `completionHandler` that runs when all results are in. This is where you'd do any processing on the final results and display them. Replace `//TODO: add completion handler` with the following:

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

The results were added to `filteredProducts` in an arbitrary order as they were returned by Core Spotlight, so this code sorts them to match the order used by the unfiltered data. Code to reload the tableview needs to be dispatched to the main queue, as this handler runs on a background thread.

Now build and run, and test out the filter on the **Products** tab. You will see behavior identical to the previous implementation. The below example shows a partial match for *Ap* that includes Apple and Grapes.

![bordered iphone](./images/spotlight-search-implemented.png)

The way this query filters products closely resembles the Spotlight search, but it has a major shortcoming. It only searches the product title, whereas Spotlight is checking all of the metadata. 

To prove this, do an in-app search for *fruit* as you did before implementing Core Spotlight Search.

![bordered iphone](./images/empty-fruit-search.png)

This is because fruit doesn't appear in the title field, but rather in the `keywords` property. Clearly, Spotlight searches more than just title, and you're going to expand your query to match.

Still in `filterContentForSearchText(searchText:)`, find the following line:

```swift
let queryString = "title=='*\(searchText)*'c"
```

Replace it with the following:

```swift
let queryString = "**=='*\(searchText)*'cd"
```

The main change here is that instead of matching on `title`, you're using `**`. This indicates the comparison should be applied to all properties in the search items' attribute sets. You've also added the `d` modifier to ignore diacritical marks—while it has no impact with Green Grocer's current inventory, it is a good practice to follow.

Build and run, and enter a search for **fruit**. This time, you'll see all of the produce in the result set, just as you do in Spotlight.

![bordered iphone](./images/fruit-search.png)

>**Note**: A more practical example might be that a user recalled seeing a product that mentioned potassium in the description. Searching on that keyword in Spotlight will show banana - and now it does with in-app search, too!

The search you implemented was a simple one, with the primary goal of making Green Grocer's in-app results match those out of Spotlight. However, understanding these mechanics gives you all you need to know to deploy more sophisticated searches tailored to your specific data and user's needs.

## Proactive suggestions for location

Adopting search makes it easy to implement other features that use NSUserActivity such as Handoff and contextual reminders. With iOS 10, another opportunity arrises in the form of proactive location suggestions. Adding location data to your indexed NSUserActivity objects now allows them to be consumed by Maps, QuickType, Siri, and more.

If you view the Store tab in Green Grocer, the content you're looking at is related to a physical location—the address of Ray's Fruit Emporium. 

![bordered iphone](./images/store-tab.png)

How amazing would it be if, upon switching to the Maps app, the Emporium address appeared above recent locations? How about if the address appeared as a QuickType option in Messages so you could tell your friends where to pick up the freshest pears in town?

Proactive suggestions with location based activities make all of this possible, and more. Below are a few examples.

![width=100%](./images/location-feature-preview.png)

From a user's perspective, this is one of the more exciting multitasking features iOS has introduced in a long time. From a developer's perspective, it's a great way to increase awareness of your app and brand throughout iOS. As an added bonus, it's extremely easy to implement for apps that already index NSUserActivity objects.

To enable the feature, you need to minimally set the new **thoroughfare** and **postalCode** `CSSearchableItemAttributeSet` properties for location related activities. These are used both for display purposes and to help location services find the address. You can further improve the quality of the results by including the following optional properties:

- namedLocation
- city
- stateOrProvince
- country

For more accuracy, you should include the `latitude` and `longitude` properties as well.

Adding a few properties isn't too bad—but wouldn't it be easier if it was just one? Well, if you're using MapKit, you can point your `MKMapItem` to an NSUserActivity and it will populate all the location info for you. Fortunately, Green Grocer already leverages this, so it will be a snap to set up.

First, it's time for a quick experiment. You need to do this on a physical device, as many location features are unavailable on the simulator. If you haven't already, be sure to set your development team in the GreenGrocer target's Signing section in the General tab.

Launch Green Grocer on a physical device, navigate to the **Store** tab, and take note of the store address on Mulberry Street. Switch back and forth between tabs a couple of times to make sure the NSUserActivity indexing occurs.

Now jump to the home screen and do a Spotlight search for **Mulberry Street**. Make sure to scroll through all the results, and you'll see there are currently no Green Grocer matches. 

![iphone](./images/mulberry-street-no-match.png)

Take a quick look in **StoreViewController.swift** and you'll see a `MKMapItem` with the store's address as well as a `CSSearchableItemAttributeSet` containing the `longitude` and `latitude` of the shop. 

The `supportsNavigation` attribute is also set to `true`, allowing navigation from Spotlight using the coordinates. However, Spotlight currently has no knowledge of the address, and so it makes sense that Mulberry Street turned up no matches.

In one line of code you're going to provide the `NSUserActivity` with attributes needed to enable address search and enable proactive location suggestions.

In **StoreViewController.swift** find `prepareUserActivity()`. This gets called when the store view loads and creates a search eligible `NSUserActivity` for the view. Just above the `return` at the end, add the following line:

```swift
activity.mapItem = mapItem()
```

`mapItem()` returns an `MKMapItem` that represents the location of the store. Setting `mapItem` to that value is all that is required to unlock location suggestions. Additionally, setting the `mapItem` populates the `CSSearchableItemAttributeSet` of the activity with all of its location information, which includes the street name.

Although `CSSearchableItemAttributeSet` properties are now getting set from the `MKMapItem`, they are currently getting overridden by existing code. In `updateUserActivityState(_:)`, find the following line:

```swift
let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeContact as String)
```

This creates a new `CSSearchableItemAttributeSet` that ultimately is assigned to the new NSUserActivity, thus replacing anything `MKMapItem` provided. Replace it with the following:

```swift
let attributeSet = activity.contentAttributeSet ??
  CSSearchableItemAttributeSet(itemContentType: kUTTypeContact as String)
```

Now, if `contentAttributeSet` is already populated thanks to the map item—it gets added to rather than replaced.

Build and run on a device, and again flip between the two tabs a couple of times to ensure the NSUserActivity changes get indexed. Now double tap the home button to bring up the app switcher. You'll see a proactive suggestion appear at the bottom of the screen including Green Grocer's name and the location of Ray's Fruit Emporium. 

The suggested app differs based on what you have installed, but in the below case it's offering to launch Maps with directions to the store. Tapping the banner takes you to the suggested app with your location data pre-populated. Ray's Produce is really great, but might not be worth the 18 hour drive from Texas!

![width=75%](./images/map-direction-fast-switcher.png)

Now open Messages and start typing a message that includes the words **Meet me at** and you'll see a QuickType suggestion including Ray's store. As with other proactive suggestions, your app is getting some good press here with the *From GreenGrocer* tagline.

![bordered iphone](./images/message-quicktype.png)

Hopefully you also remember back to the test in Spotlight search, where *Mulberry* pulled up zero results from Green Grocer. Repeat the search for **Mulberry** and you'll now see a result for Ray's Fruit Emporium! This means the `MKMapItem` is successfully providing location information to the `CSSearchableItemAttributeSet`.

![iphone](./images/mulberry-spotlight-search-working.png)

These are just a handful of examples of proactive suggestions. It should be pretty clear at this point that adding location data to your NSUserActivity objects is quite powerful. Not only does it streamline common user workflows, it reinforces awareness of your app throughout iOS.

## Where to go from here?

In this chapter, you took an existing app with Core Spotlight and activity indexing and added some seriously cool functionality with minor effort. You enabled search continuation from Spotlight, and then refactored in-app search to use Spotlight's engine. Then with a single line of code, you enabled location based proactive suggestions to better integrate your app with iOS.

If you have an app already using Core Spotlight, the effort to benefit ratio should make adoption of these features very compelling. Not only do they improve user experience, but they better integrate your app with iOS, allowing you more opportunity to engage.

For more detail, check out the following resources:

- WWDC 2016 Making the Most of Search APIs [apple.co/2cPwCbA](http://apple.co/2cPwCbA)
- WWDC 2016 Increase Usage of Your App With Proactive Suggestions [apple.co/2cvOsAM](http://apple.co/2cvOsAM)
- [search.developer.apple.com](https://search.developer.apple.com)