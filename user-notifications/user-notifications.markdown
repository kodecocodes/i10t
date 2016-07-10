```metadata
author: "By Jeff Rames"
number: "10"
title: "Chapter 10: User Notifications"
```
# Chapter 10: User Notifications

## Introduction

Remote push notifications were released way back in iOS 3, followed by local notifications in iOS 4. Looking through your most used apps, many of them likely leverage one or both of these types of User Notifications. They are integral to keeping users engaged in an app, up to date, and in near real time communication with others.

For such an important feature, they haven't changed all that much over the years. iOS 8 introduced the ability to implement custom actions in your application triggered by buttons in the notification. iOS 9 added text input as another custom action.

With iOS 10, Apple has made sweeping changes, really opening up notifications to developers:

- **Media attachments** can be added to notifications, including audio, video and images.
- **Notification Content extensions** allow you to create custom interfaces for notifications.
- **Managing notifications** is now possible with interfaces in the new user notification center.
- **Notification Service app extensions** allow you to process remote notification payloads before they're delivered.

In this chapter, you'll explore all of these features. For Notification Service app extensions, you'll need a device running iOS 10 and a basic understanding of configuring remote notifications. For later, you may want to review *Push Notifications Tutorial: Getting Started* here - [raywenderlich.com/123862](http://raywenderlich.com/123862).

## Getting Started

The sample app for this chapter is **cuddlePix**, which aims to spread cheer with visually rich notifications containing pictures of cuddly cactuses*. When complete, it will act as a management dashboard for notification status and configuration data as well as a scheduler for local notifications. It will also define custom notifications complete with custom actions.

> **Note**: While cuddlePix employs only the most cuddly digital cacti, remember to use caution when cuddling a real cactus. Real world prototyping of cuddlePix indicated that some cacti can be quite painful.

Open the starter project for this chapter, then build and run. You'll be greeted by an empty table view that will eventually house the notification status and configuration info.

Tap the **+** bar button, and you'll see an interface for scheduling multiple local notifications over the hour, or a single one in 5 seconds. Right now these don't do anything, but you'll set them up shortly.

![bordered width=90%](./images/cuddlePix-starter.png)

Take a few minutes to explore key items in the project.

- **NotificationTableViewController.swift** contains the table view controller and displays a sectioned table using a datasource built from a struct and protocol found in **TableSection.swift**.
- **ConfigurationViewController.swift** manages the view that schedules notifications, centered around a mostly stubbed out method `scheduleRandomNotification(inSeconds:completion:)` that will ultimately create and schedule notifications.
- **Main.storyboard** defines the simple UI you've already seen in full while testing the app.
- **Utilities** contains some helpers you'll use during this tutorial.
- **Supporting Files** contains artwork attributions, the plist, and images including some of beautiful cactuses you'll display in your notifications.

## User Notifications Framework

Gone are the days of handling notifications via your application delegate. Enter **UserNotifications.framework**, which does everything its predecessor did, while also enabling all of the new user notification functionality like attachments, Notification Service extensions, foreground notifications, and more.

The core of the new framework is `UNUserNotificationCenter`, which is accessed via a singleton. It manages user authorization, defines notifications and associated actions, schedules local notifications, and provides a management interface for existing notifications.

Start by setting up authorization. Open **NotificationTableViewController.swift** and add the following to `viewDidLoad()`, just below the call to super:

```swift
UNUserNotificationCenter.current()
  .requestAuthorization(options: [.alert, .sound]) {
    (granted, error) in
    if granted {
      self.loadNotificationData()
    } else {
      print(error?.localizedDescription)
    }
}
```

`UNUserNotificationCenter.current()` returns the singleton user notification center on which you call `requestAuthorization(options:completionHandler:)` to request authorization to present notifications. You pass in an array of `UNAuthorizationOptions` indicating what options you're requesting—in this case `alert` and `sound` notifications. If access is granted, you call the currently stubbed out `loadNotificationData()` and otherwise you print the passed error.

Build and run, and you'll see an authorization prompt as soon as the NotificationTableViewController loads.

![bordered width=40%](./images/notification-prompt.png)

### Notification Scheduling

Now that you have permission, it's time to take this new framework for a spin by scheduling notifications!

Open **ConfigurationViewController.swift** and take a look at how `scheduleRandomNotification(inSeconds:completion:)` is used. `handleCuddleMeNow(_:)` is triggered when the **Cuddle me now!** button is pressed and passes `scheduleRandomNotification(inSeconds:completion:)` a delay of 5 seconds. `scheduleRandomNotifications(number:completion:)` is triggered by the **Schedule** button, and calls `scheduleRandomNotification(inSeconds:completion:)` with various delays to space out repeat notifications over an hour.

Right now `scheduleRandomNotification(inSeconds:completion:)` obtains the URL of a random image in the bundle and prints it, but it doesn't yet schedule a notification.

To create a local notification, you need to provide some content and a trigger condition. In the `scheduleRandomNotification` function, delete `print("Schedule notification with \(imageURL)")` and add the following in its place:

```swift
// 1
let content = UNMutableNotificationContent()
content.title = "New cuddlePix!"
content.subtitle = "What a treat"
content.body = "Cheer yourself up with a hug 🤗"
//TODO: Add attachment

// 2
let trigger = UNTimeIntervalNotificationTrigger(
  timeInterval: inSeconds, repeats: false)
```

Here's what you're doing:

1. You create a `UNMutableNotificationContent`, which defines what is displayed on the notification—in this case, you're setting a `title`, `subtitle` and `body`. This is also where you'd set things like badges, sounds and attachments. As the comment teases, you'll add an attachment here soon.
2. A `UNTimeIntervalNotificationTrigger` needs to know when to fire, and if it should repeat. You're passing through the `inSeconds` parameter for the delay, and creating a one time notification. User notifications can also be triggered from location or calendar triggers.

Next up, you need to create the notification request and schedule it. Replace the `completion()` call with the following:

```swift
// 1
let request = UNNotificationRequest(
  identifier: randomImageName, content: content, trigger: trigger)

// 2
UNUserNotificationCenter.current().add(request, withCompletionHandler: { (error) in
  if let error = error {
    print(error)
    completion(success: false)
  } else {
    completion(success: true)
  }
})
```

Here's the breakdown of what you've done:

1. You create a `UNNotificationRequest` from the `content` and `trigger` you created above. You provide the required unique identifier to be used later when managing the request. In this case, you set it to the name of the randomly selected image.
2. You call `add(_:withCompletionHandler)` on the shared user notification center to add your `request` to the notification queue. In the completion handler, if an error exists you print it and indicate failure with `completion(success:)` to inform the caller. On success, you call the `completion(success:)` closure indicating success, which ultimately notifies its delegate (the `NotificationTableViewController`) that a refresh of pending notifications is necessary. You'll learn more about what `NotificationTableViewController` is doing later in the chapter.

Build and run, tap the **+** bar item, tap **Cuddle me now!** then quickly background the application with **Command + Shift + H**. Five seconds after the notification was added, you'll see the notification banner complete with your custom content!

![width=40%](./images/first-notification.png)

### Adding an Attachment

Its seems a bit wasteful to have a bunch of beautiful cactus images only to use their URLs as notification identifiers. How about actually displaying the images on the notification? Hopefully you saw this coming.

Back in `scheduleRandomNotification(inSeconds:completion:)`, add the following just below the `imageURL` declaration:

```swift
let attachment = try! UNNotificationAttachment(identifier:
  randomImageName, url: imageURL, options: .none)
```

A `UNNotificationAttachment` is an image, video, or audio attachment that is presented with a notification. It requires an identifier, for which you've used the `randomImageName` string, as well as a URL pointing to a local resource of a supported type. This method throws an error if the media is not readable or not supported—because you've included these images in your bundle it's fairly safe to disable error propagation with a `try!`.

Next, replace `//TODO: Add attachment` with:

```swift
content.attachments = [attachment]
```

You're setting `attachments` to the single image attachment wrapped in an array. This will make it available to display when the notification fires, using default notification handling for image attachments.

> **Note**: When the notification is scheduled, a security-scoped bookmark is created for the attachment to provide Notification Content extensions access to the file.

Build and run, initiate a notification with **Cuddle me now!** then return to the home screen as you did before. You'll now be greeted with a notification containing a random cactus picture on the right side of the banner. Force tap or select and drag down on the banner, and you'll be treated to an expanded view of the huggable cactus.

![width=90%](./images/notification-attachment.png)

### Foreground Notifications

The **UNUserNotificationCenterDelegate** protocol defines methods for handling incoming notifications and their actions. It enables another great enhancement to iOS 10 notifications—the ability to display system notification banners in the foreground.

To do this, open **AppDelegate.swift** and add the following at the end of the file:

```swift
extension AppDelegate: UNUserNotificationCenterDelegate {
  func userNotificationCenter(_ center: UNUserNotificationCenter,
      willPresent notification: UNNotification,
      withCompletionHandler completionHandler:
      (UNNotificationPresentationOptions) -> Void) {
        completionHandler(.alert)
  }
}
```

This extends `AppDelegate` to adopt the `UNUserNotificationCenterDelegate` protocol. The optional `userNotificationCenter(_:willPresent:withCompletionHandler:)` is called when a notification is received in the foreground, and provides the opportunity to act upon it.

In it, you call the `completionHandler()`, which determines if and how the alert should be presented. The `.alert` notification option indicates you want to present the alert, but no badge updates or sounds. You could also choose to suppress the alert here by passing an empty array.

In `application(_:didFinishLaunchingWithOptions:)`, add the following just before the `return`:

```swift
UNUserNotificationCenter.current().delegate = self
```

This sets your AppDelegate as the `UNUserNotificationCenterDelegate` so that user notification center will pass along this message when a foreground notification is received.

Build and run, and schedule a notification as you've done before. This time, leave CuddlePix in the foreground and you'll see a system banner appear in app!

![bordered width=40%](./images/in-app-banner.png)

Think briefly now about all the times you had to build your own banner for these situations. Take a deep breath—that's all in your past now.

![width=30%](./images/hero-ragecomic.png)

## Notification Management

As an iOS user, you've probably experienced the frustration of clearing out countless missed and outdated notifications. You might have an app posting updates on the score of a game, and if you've been away you likely only care about the latest one. With iOS 10, developers finally have the information and access necessary to improve this experience.

The **UNUserNotificationCenter** provides accessor methods to read an app's user notification settings (the user permissions), so you can keep up to date on changes made. More excitingly, it provides you read and *delete* accessors for pending and delivered notifications. This means you can remove those outdated notifications, freeing your users from a wall of unwanted notifications.

Finally, you have the ability to read and and set notification categories, which you'll learn about a little later in this chapter.

### Notification Center Queries

You'll kick this off by obtaining the notification settings and displaying them in cuddlePix's initial table view.

Open **NotificationTableViewController.swift** and find `loadNotificationData(callback:)`. Your code calls this when the table is refreshed, authorization is returned, a notification is scheduled or a notification is received. Right now, it just reloads the table. Add the following just below the `group` declaration near the top:

```swift
// 1
let notificationCenter = UNUserNotificationCenter.current()
let dataSaveQueue = DispatchQueue(label:
  "com.raywenderlich.CuddlePix.dataSave")

// 2
group.enter()
// 3
notificationCenter.getNotificationSettings { (settings) in
  let settingsProvider = SettingTableSectionProvider(settings:
    settings, name: "Notification Settings")
  // 4
  dataSaveQueue.async(execute: {
    self.tableSectionProviders[.settings] = settingsProvider
    group.leave()
  })
}
```

This code queries for notification settings and updates the table datasource object involved in their display. Here are the details:

1. You create `notificationCenter` to reference the shared notification center more concisely. Then you create a `DispatchQueue` that will be used to prevent concurrency issues when updating the table view data source.
2. First you enter a dispatch group that will be used to ensure all data fetches complete before you refresh the table. Note the project already refreshes in a group.notify(callback:) closure for this reason.
3. You call `getNotificationSettings(callback:)` to fetch current notification settings from the notification center. The results are passed to the callback closure via `settings`, which you use to initialize a `SettingTableSectionProvider`. SettingTableSectionProvider was included in the starter and extracts interesting information from the provided UNNotificationSettings for presentation in a table view cell.
4. Using the `dataSaveQueue`, you asynchronously update `tableSectionProviders`' settings section with the just created `settingsProvider`. The table management is all provided by the starter project, and setting the provider is all you need to do for the data to be provided to the table view. Finally, you leave `group` to release your hold on the dispatch group.

Build and run, and you'll now see a **Notification Settings** section in the table view that represents the current status of notification settings for cuddlePix. To test it out, go to iOS Settings, then find **CuddlePix** and toggle some of the switches. Once done, return to cuddlePix, pull to refresh, and you'll see the updated status.

![bordered width=90%](./images/notification-settings.png)

Knowing your users settings can help you know how to best present notifications.

It's just as easy to fetch information about pending and delivered notifications. Just below the closing bracket of the `getNotificationSettings(completionHandler:)` closure, add the following:

```swift
group.enter()
notificationCenter.getPendingNotificationRequests { (requests) in
  let pendingRequestsProvider =
    PendingNotificationsTableSectionProvider(requests:
      requests, name: "Pending Notifications")
  dataSaveQueue.async(execute: {
    self.tableSectionProviders[.pending] = pendingRequestsProvider
    group.leave()
  })
}
group.enter()
notificationCenter.getDeliveredNotifications { (notifications) in
  let deliveredNotificationsProvider =
    DeliveredNotificationsTableSectionProvider(notifications:
      notifications, name: "Delivered Notifications")
  dataSaveQueue.async(execute: {
    self.tableSectionProviders[.delivered]
      = deliveredNotificationsProvider
    group.leave()
  })
}
```

You've implemented two additional fetches in a manner identical to the settings fetch, updating their respective `tableSectionProviders`. `getPendingNotificationRequests(completionHandler:)` fetches notifications that are pending—scheduled but not yet delivered. `getDeliveredNotifications(completionHandler:)` fetches those that have been delivered, but not yet deleted.

Now, build and run. Schedule a notification, and you'll see it appear under **Pending Notifications**. Once delivered, pull to refresh and you'll see it under **Delivered Notifications**.

Delivered notifications remain until they are deleted. Test this by expanding a notification when the banner appears then selecting **Dismiss**—then see if it exists in the table after a refresh. You can also delete a notification by pulling down notification center and clearing it from the **Missed** list.

![bordered iphone](./images/notification-status.png)

It would be even nicer if you didn't have to pull to refresh when a new notification comes in. In **AppDelegate.swift** add the following to the top of `userNotificationCenter(_:willPresent:withCompletionHandler)`:

```swift
NotificationCenter.default.post(name:
  userNotificationReceivedNotificationName, object: .none)
```

`userNotificationReceivedNotificationName` is a system notification that cuddlePix uses to reload the status table. You post it here, because this method is triggered whenever a notification comes in, and thus notification status updates.

A very compelling application of this status awareness is to avoid sending repeat notifications if an identical one is still in delivered status.

### Modify Notifications

Being able to query notifications is even more exciting combined with the fact that you can update or delete them. Consider an app that reports sports scores. Rather than littering notification center with outdated score alerts, you could continually update the same notification, bumping it to the top of the notification list each time for visibility into the update.

Updating a notification is straightforward. You create a new `UNNotificationRequest` with the same identifier as the existing notification, pass it your updated content, and add it to `UNUserNotificationCenter`. Once the trigger conditions are met, it will overwrite the existing notification with the matching identifier.

For cuddlePix, notifications are serious business. Consider a case where you scheduled 10 notifications, when you meant to do just 5. Too much of a good thing can get pretty prickly, so you're going to work on the ability to delete pending notifications.

Open **NotificationTableViewController.swift** and you'll see tableView editing methods near the end of the data source methods extension. Deletion is already enabled for rows in the **pending** section, but committing the delete currently doesn't do anything.

Add the following to `tableView(_:commit:forRowAt:)`:

```swift
// 1
guard let section =
  NotificationTableSection(rawValue: indexPath.section)
  where editingStyle == .delete && section == .pending else { return }

// 2
guard let provider = tableSectionProviders[.pending]
  as? PendingNotificationsTableSectionProvider else { return }

let request = provider.requests[indexPath.row]

// 3
UNUserNotificationCenter.current()
  .removePendingNotificationRequests(withIdentifiers:
    [request.identifier])
loadNotificationData(callback: {
  self.tableView.deleteRows(at: [indexPath], with: .automatic)
})
```

This method is called when an insertion or deletion is attempted on the `tableView`. Here is what your code does:

1. You check that the selected cell came from the `pending` section of the table and that the attempted operation was a `delete`. If not, you return.
2. You unwrap and typecast the `tableSectionProviders` datasource object associated with pending notifications, returning if it fails. `request` is then set to the `UNNotificationRequest` represented by the selected cell.
3. You call `removePendingNotificationRequests(withIdentifiers:)` on the user notification center to delete the notification matching your request's identifier. Then you call `loadNotificationData(callback:)` to refresh the datasource, deleting the row in the callback closure.

Build and run, create a new notification, and swipe the cell in the **Pending Notifications** section to reveal the delete button. Before the notification is delivered, tap **Delete**. Because you've deleted it from the user notification center before delivery, the notification will never be shown, and the cell will be deleted.

![bordered iphone](./images/delete-pending-notification.png)

## Notification Content Extensions

Another major change to notifications in iOS 10 is the introduction of Notification Content extensions. They allow you to provide a custom interface for the expanded version of your notifications. Interaction is limited—the notification view won't pass along gestures, but the extension can update the view in response to *actions*, which you'll learn about a little later.

These extensions are built with the **UNNotificationContentExtension** protocol, which your extension view controller must adopt. The protocol defines optional methods that notify the extension when it's being presented, helps it respond to actions, and assists in media playback.

The interface can contain anything you might place in a view, including playable media like video and audio. However, they run as a separate binary from your app, and don't have direct access to its resources. For this reason, any resources they require that aren't included in the extension bundle are passed via attachments of type **UNNotificationAttachment**.

### Creating an Extension with an Attachment

Time to dive in and build your first Notification Content extension!

Select **File -> New -> Target** in Xcode and then in the iOS section choose **Application Extension**. In the detail pane, select **Notification Content** and then select **Next**. Enter **ContentExtension** in the Product Name, select the **Team** associated with your developer account, choose Swift as the **Language**, and hit **Finish**. If prompted, choose to **Activate** the scheme.

![width=100% bordered](./images/content-extension-setup.png)

You've created a new target and project group, both named **ContentExtension**. In the group you have a view controller, storyboard, and plist necessary for configuring the extension. You'll visit each of these in turn while implementing the extension.

![width=40% bordered](./images/content-extension-group.png)

Open **MainInterface.storyboard** and take a look at what the template provided. You'll see a single view controller of type `NotificationViewController`—the controller created when you generated the extension. Inside is a single view with a *Hello World* label connected to an outlet in the controller.

For cuddlePix, your goal is to create something similar to the default expanded view, but just a tad more cuddly. A cactus picture with a hug emoji in the corner should do quite nicely.

To start, delete the existing label and change the view's background color to white. Set the view height to 320 to allow yourself more room to work. Add an Image View and pin it to the edges of the superview with a fixed size as pictured below.

![width=35% bordered](./images/imageview-constraints.png)

Select the Image View and go to the Attributes Inspector. In the View section, set the Content Mode to **Aspect Fill** to ensure as many pixels as possible are filled with beautiful cactus.

![width=35% bordered](./images/aspect-fill.png)

Clean things up by selecting the **Resolve Auto Layout Issues** button in the lower right and selecting **Update Frames** in the *All Views in Notification View Controller* section. This will cause your Image View to resize to match the constraints and the Auto Layout warnings should resolve.

Next, drag a label just under the image view in the Document Outline pane on the left-hand side of the Interface Builder window:
![width=30% bordered](./images/label-placement.png)

 Pin it to the bottom left of the view with the following constraints:

![width=35% bordered](./images/label-constraints.png)

If you've been paying any attention, you'll surely guess what goes in this label. The hug emoji! Use **Control + Command + Spacebar** to bring up the picker, and select the 🤗.

![width=40% bordered](./images/emoji-picker.png)

Set the font size of the label to 100 so your hug gets a bit more visibility. **Update Frames** again to resize the label to match the new content.

Now, open **NotificationViewController.swift** in the Assistant Editor so that you can wire up some outlets.

First, delete this line:

```swift
@IBOutlet var label: UILabel?
```

That outlet was associated with the label you deleted from the storyboard template. You'll see an error now as you still reference it. Delete the following in `didReceive(_:)` to resolve that:

```swift
self.label?.text = notification.request.content.body
```
Next, control drag from the Image View in the storyboard to the spot where you just deleted the old outlet. Name it **imageView** and select **Connect**.

![width=80% bordered](./images/imageview-outlet.png)

With the interface done, close the storyboard and open **NotificationViewController.swift** in the Standard editor.

Remember that `didReceive(_:)` is called when a notification arrives, and is where you should do any view configuration. For this extension, that means populating the imageView with the cactus picture from the notification. Add the following to `didReceive(_:)`:

```swift
// 1
guard let attachment = notification.request.content.attachments.first
  else { return }
// 2
if attachment.url.startAccessingSecurityScopedResource() {
  imageView.image = UIImage(contentsOfFile: attachment.url.path!)
  attachment.url.stopAccessingSecurityScopedResource()
}
```

Here's what this does:

1. The passed `UNNotification` (`notification`) contains a reference to the original `UNNotificationRequest` (`request`) that generated it. A request contains `UNNotificationContent` (`content`) that, among other things, contains an array of `UNNotificationAttachments` (`attachments`). In a guard, you grab the first of those attachments—you know you've only included one—and you place it in `attachment`.
2. Attachments in the user notification center live inside your app's sandbox, not the extension's, and thus they must be accessed via security-scoped URLs. `startAccessingSecurityScopedResource()` makes the file available to the extension when it successfully returns, and `stopAccessingSecurityScopedResource()` is required to indicate you're finished with the resource. In between, you load `imageView` using the file pointed to by this URL.

The extension is all set. But when a notification triggers for cuddlePix, how is the the system supposed to know what, if any, extension to send it to?

![width=30%](./images/notification-gnomes.png)

Gnomes are a good guess, but they're notoriously unreliable. Instead, user notification center relies on a key defined in the extension's plist to identify the types of notifications it should handle.

Open **Info.plist** in the ContentExtension group and expand `NSExtension`, then `NSExtensionAttributes` to reveal **UNNotificationExtensionCategory**. This key takes a string (or array of strings) identifying the notifications it should handle. Enter **newCuddlePix** here, which you'll later provide in the content of your notification requests.

![width=80% bordered](./images/content-extension-plist.png)

> **Note**: In the same plist dictionary, you'll see another required key—**UNNotificationExtensionInitialContentSizeRatio**. Because the system starts to present a notification before loading your extension, it needs something to base the initial size on. You provide a ratio of the notification's height to its width, and the system will animate any expansion or contraction once the extension view loads.
>
> cuddlePix's extension view frame is set to fill the full width of a notification, so in this case you leave it at the default ratio of 1.

The operating system knows notifications using the *newCuddlePix* category should go to your extension, but you haven't yet set this category on your outgoing notifications. Open **ConfigurationViewController.swift** and find `scheduleRandomNotification(inSeconds:completion:)` where you generate `UNNotificationRequest`s. Add the following line after `content` is declared:

```swift
content.categoryIdentifier = newCuddlePixCategoryName
```

The `UNNotificationRequest` that gets created in this method will now use `newCuddlePixCategoryName` as a `categoryIdentifier` for its content. `newCuddlePixCategoryName` is a string constant defined in the starter that matches the one you placed in the extension plist—*newCuddlePix*.

When the system prepares to deliver a notification, it will check that notification's category identifier and try to find an extension registered to handle it. In this case, that will be the extension you just created.

> **Note**: For a remote notification to invoke your Notification Content extension, you'd need to add this same category identifier as the value for the `category` key in the payload dictionary.

Make sure you have the **CuddlePix** scheme selected and then build and run. Next, switch to the **ContentExtension** scheme then build and run again. Select **CuddlePix** and **Run** when prompted what to run the extension with.

![width=65% bordered](./images/run-extension-prompt.png)

In cuddlePix, generate a new notification with **Cuddle me now!**. When the banner appears, expand it either by force touching on a compatible device, or selecting the notification and dragging down in the simulator. You'll now see the new custom view from your extension!

![iphone bordered](./images/content-extension-presented.png)

> **Note**: You'll notice that the custom UI you designed is presented above the default banner content. In this case, it's appropriate, as your custom view didn't implement any of this text.
>
> However, if you shifted the titles and messages to the extension, you could easily remove the system generated banner at the bottom. This is done by adding the `UNNotificationExtensionDefaultContentHidden` key to your extension plist with a value of `true`.


### Notification Action Handling

So far, the custom notification for cuddlePix isn't all that different from the default. However, a custom view does provide quite a lot of opportunity depending on your needs. For example, a ride sharing app could provide a map of your ride's location and a sports app could provide a full box score.

Where extensions get a chance to shine in cuddlePix, however, is interactivity. While Notification Content extensions do not allow touch handling—the touches are not passed to the controller—they do provide interaction through custom action handlers.

Prior to iOS 10, custom actions were forwarded on to the application and handled in an application delegate method. This worked great for things like responding to a message where there wasn't a need to see the results of the action.

Because Notification Content extensions can handle actions directly, that means the notification view can be updated with results. For instance, when an invite is accepted, you could display an updated calendar view right there in the notification.

The driver of this is the new **UNNotificationCategory**, which uniquely defines a notification type and references actions the type can act upon. The actions are defined with **UNNotificationAction** objects that in turn uniquely define actions. When configured and added to the `UNUserNotificationCenter`, these objects help direct actionable notifications to the right handlers in your app or extensions.

#### Defining the Action

For cuddlePix, your goal is to spread cheer, and what better way to do that than an explosion of stars over a cactus? You're now going to wire up an action for starring a cactus, which will kick off an animation in your custom notification view.

To start, you need to register a notification category and action in the app. Open **AppDelegate.swift** and add the following method in `AppDelegate`:

```swift
private func configureUserNotifications() {
  // 1
  let starAction = UNNotificationAction(identifier:
    "star", title: "🌟 star my cuddle 🌟 ", options: [])
  let dismissAction = UNNotificationAction(identifier:
    "dismiss", title: "Dismiss", options: [])
  // 2
  let category =
    UNNotificationCategory(identifier: newCuddlePixCategoryName,
      actions: [starAction, dismissAction],
      minimalActions: [starAction, dismissAction],
      intentIdentifiers: [],
      options: [])
  // 3
  UNUserNotificationCenter.current()
    .setNotificationCategories([category])
}
```

Here's what this code does:

1. A `UNNotificationAction` has two jobs—it provides data used in displaying an action to the user, and it uniquely identifies actions so that controllers can act upon them. It requires a title for the first job and a unique identifier string for the second. Here you've created a `starAction` and a `dismissAction` with recognizable identifiers and titles.
2. You defined a `UNNotificationCategory` with the string constant set up for this notification (and used in your extension plist)—`newCuddlePixCategoryName`. You've passed an array containing your newly created `UNNotificationActions` to `actions` and `minimalActions`. The `actions` parameter requires all custom actions you want displayed in order of display while `minimalActions` needs to contain the two most important actions to be displayed when space is limited.
3. You pass the new `category` to the `UNUserNotificationCenter` with `setNotificationCategories()`, which accepts an array of categories and registers cuddlePix as supporting them.

> **Note**: You're probably shouting as you read this that the notification *already* shows a dismiss option when expanded. That *is* the default behavior for a Notification Content extension when no actions are provided. But, as soon as you use a custom action, only those you create will be shown—so you need to create your own dismiss action here.

In `application(_:didFinishLaunchingWithOptions:)` add the following just before the `return`:

```swift
configureUserNotifications()
```

This ensures category registration happens as soon as the app is started.

Now, build and run the **CuddlePix** scheme, followed by the **ContentExtension** scheme which you should choose to run with cuddlePix. Create a notification and expand it with force touch or a drag down when it arrives.

You'll now see buttons for your new actions at the bottom of the notification.

![iphone bordered](./images/notification-actions.png)

Try selecting **star my cuddle**, and the notification will simply dismiss, because you haven't yet implemented the action.

#### Extension Response Handling and Forwarding

Notification extensions get first crack at handling an action response. In fact, they determine whether or not to forward the request along to the app when they finish.

Inside ContentExtension, open **NotificationViewController.swift** and you'll see your controller already adheres to `UNNotificationContentExtension`, which provides an optional method for handling responses. Add the following to `NotificationViewController`:

```swift
func didReceive(_ response: UNNotificationResponse,
                completionHandler completion:
  (UNNotificationContentExtensionResponseOption) -> Void) {
  // 1
  if response.actionIdentifier == "star" {
    // TODO Show Stars
    let time = DispatchTime.now() +
      DispatchTimeInterval.milliseconds(2000)
    DispatchQueue.main.after(when: time) {
      // 2
      completion(.dismissAndForwardAction)
    }
  // 3
  } else if response.actionIdentifier == "dismiss" {
    completion(.dismissAndForwardAction)
  }
}
```

`didReceive(_:completionHandler:)` is called with the action response and a completion closure. The closure must be called when you're done with the action, and it requires a parameter indicating what should happen next. Here is some detail on what you did:

1. When setting up your `UNNotificationActions`, you gave the star action an identifier of *star*, which you check here to catch responses of this type. Inside, you have a `TODO` for implementing the star animation that you'll soon revisit. You let the animation continue for 2 seconds via `DispatchQueue.main.after` before calling the completion closure.
2. `completion` takes an enum value defined by `UNNotificationContentExtensionResponseOption`. In this case, you've used `dismissAndForwardAction`, which dismisses the notification and allows the app an opportunity to act on the response. (Alternative values include `doNotDismiss`, which keeps the notification on screen and `dismiss`, which doesn't pass the action along to the app after dismissal)
3. For the dismiss action, the extension dismisses immediately and forwards the action along to the app to handle.

Your current implementation of the star action leaves something to be desired—specifically, the stars! The starter project already contains everything you need for this animation, but it's not yet available to the Notification Content extension's target.

In the project navigator, expand the **Utiltiies** and then **Star Animatior** group and select both files inside.
![width=40% bordered](./images/star-animator.png)

Open the File inspector in the utilities pane of Xcode, and select **ContentExtension** under **Target Membership**.
![width=40% bordered](./images/target-membership.png)

Back in **NotificationViewController.swift**, replace `// TODO Show Stars` with:

```swift
imageView.showStars()
```

This uses a `UIImageView` extension defined in the **StarAnimator.swift** file you just added to the target. `showStars()` uses core animation to create a shower of stars over the ImageView.

Build and run the extension and the app as you've done before. Create and expand a notificaiton, then select **star my cuddle** and you'll see an awesome star shower over your cactus before it dismisses.

![iphone bordered](./images/star-shower.png)

Your extension has done its job, and the cuddle has been starred. But recall that `dismissAndForwardAction` was called in the completion closure—where is it getting forwarded?

The answer is it forwards to the app, but right now the `UNUserNotificationCenterDelegate` in cuddlePix isn't listening. Open **AppDelegate.swift** and add the following method to the `UNUserNotificationCenterDelegate` extension:

```swift
func userNotificationCenter(_ center: UNUserNotificationCenter,
                            didReceive response: UNNotificationResponse,
                            withCompletionHandler
  completionHandler: () -> Void) {
  print("Response received for \(response.actionIdentifier)")
  completionHandler()
}
```

`userNotificationCenter(_:didReceive:withCompletionHandler)` is called to let you know a notification action was selected. In it, you print out the `actionIdentifier` of the response, simply to confirm things are working as they should. You then call `completionHandler()` which accepts no arguments and is required to notify user notification center that you're done handling the action.

Build and run the app and Notification Content extension, and trigger a notification. Expand the notification and select either response. Search the Debug Console and you should see responses like the ones below appear as soon as the notification dismisses (depending on the action chosen):

```html
Response received for dismiss
Response received for star
```

To recap, here is the flow of messages being passed around when you receive a notification in the foreground and respond to an action in a Notification Content extension:

1. **userNotificationCenter(_:willPresent:withCompletionHandler:)** is called in the `UNUserNotificationCenterDelegate` (only in the foreground), and determines if the notification should present.
2. **didReceive(_:)** is called in the the `UNNotificationContentExtension` and allows the opportunity to configure the custom notification's interface.
3. **didReceive(_:completionHandler:)** is called in the `UNNotificationContentExtension` after the user selects a response action.
4. **userNotificationCenter(_:didReceive:withCompletionHandler:)** is called in the `UNUserNotificationCenterDelegate` if the `UNNotificationContentExtension` passes it along via the `dismissAndForwardAction` response option.

## Notification Service App Extensions

Believe it or not, another major feature awaits in the form of Notification Service extensions. These allow you to intercept remote notifications and modify the payload. A common use case would be to add a media attachment to the notification, or decrypt content.

cuddlePix doesn't really demand end to end encryption, so instead you're going to add an image attachment to incoming remote notifications. But first, you need to set up a development environment.

Because the simulator cannot register for remote notifications, you'll need a device with iOS 10 to test.

Start by configuring cuddlePix for push with your Apple Developer account. First select the **CuddlePix** target and **General** tab. In the **Signing** section, select your **Team** and then in **Bundle Identifier** enter a unique **Identifier**.

![width=80% bordered](./images/general-configuration.png)

Now switch to the **Capabilities** tab and switch **Push Notifications** on for the CuddlePix target. cuddlePix is now set up to successfully receive tokens from the Apple Push Notification Service (APNS).

![width=80% bordered](./images/push-configuration.png)

Select the **ContentExtension** target and change the *com.razeware.CuddlePix* prefix in its bundle identifier to match the unique identifier you used for the **CuddlePix** target (leaving `.ContentExtension` at the end of the identifier). Also set your **Team** as you did in the other target. Apple requires your extensions to have a prefix that matches the main app.

You'll also need a way to send test pushes, for which you'll use a popular open source tool called **NWPusher**. It sends push notifications directly to APNS. To start, follow the instructions in the **Installation** section of their GitHub readme to get the app running - [github.com/noodlewerk/NWPusher](https://github.com/noodlewerk/NWPusher).

NWPusher's readme also has a **Getting Started** section that guides you through creating the required SSL certificate, which you should follow for creating a Development certificate. You may also find the section titled *Creating an SSL Certificate and PEM file* in *Push Notifications Tutorial: Getting Started* useful. You can find it here - [raywenderlich.com/123862](http://raywenderlich.com/123862).

With your p12 file in hand, go back to Pusher and select it in the **Select Push Certificate** dropdown. You may need to choose **Import PCKS #12 file (.p12)** and manually select it if it doesn't appear here.

Pusher of course requires a push token so it can tell APNS where to send the notification. Head back to Xcode and open **AppDelegate.swift**. Add the following just before the return in `application(_:didFinishLaunchingWithOptions)`:

```swift
application.registerForRemoteNotifications()
```

When cuddlePix starts up, it will now register for notifications. Remember it will only be successful when run on a device.

Add the following at the bottom of the AppDelegate, just below the final bracket:

```swift
extension AppDelegate {
  // 1
  func application(_ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: NSError) {
      print("Registration for remote notifications failed")
      print(error.localizedDescription)
  }

  // 2
  func application(_ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
      print("Registered with device token: \(deviceToken.hexString)")
  }
}
```

This extension contains the `UIApplicationDelegate` methods for handling the response from APNS. They do the following:

1. `application(_:didFailToRegisterForRemoteNotificationsWithError:)` is called when registration fails. Here, you print the error message.
2. `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)` is called when registration is successful, and returns the `deviceToken`. You use `hexString`, a helper method included with the starter, to convert it to hex format and print it to the console.

Build and run on a device, and check the Debug Console for your device token, prefixed with the string *Registered with device token*. Copy the hex string and paste it into the **Device Push Token** field in Pusher. Then paste the following in the payload field (use Paste and Match Style to avoid formatting issues):

```html
{  
   "aps":{  
      "alert":{  
         "title":"New cuddlePix!",
         "subtitle":"From your friend",
         "body":"Cheer yourself up with this remote hug 🤗"
      },
      "category":"newCuddlePix"
   }
}
```

Your setup should now look like this:

![width=60% bordered](./images/pusher-hug.png)

Select **Push** in the lower right of Pusher and, if everything is configured properly, you should see a push that looks like this:

![width=40% bordered](./images/remote-hug.png)

The default notification banner is here, but if you expand it, the image view will be blank. You passed the category of `newCuddlePix`, identifying your Notification Content extension, but you didn't provide an attachment to load. That's just not possible from a remote payload, which is where Notification Service extensions come in.

### Creating and Configuring a Notification Service Extension

The plan is to modify your payload to include the URL of an attachment that you'll download in the Notification Service extension and create an attachment. Update the JSON in the payload section in **Pusher** to match the following:

```html
{  
   "aps":{  
      "alert":{  
         "title":"New cuddlePix!",
         "subtitle":"From your friend",
         "body":"Cheer yourself up with this remote hug 🤗"
      },
      "category":"newCuddlePix",
	 "mutable-content": 1
   },
   "attachment-url": "https://wolverine.raywenderlich.com/books/i10t/notifications/i10t-feature.png"
}
```
(Depending on how it pastes, you may need to remove a line break in the URL)

This contains two new keys:

1. **mutable-content** takes a bool and indicates whether or not the notification should be modifiable by a Notification Service extension. You set it to a 1 to override the default 0, which prevents a Notification Service app extension from running.
2. **attachment-url** resides outside of the main payload, and is of your own design—the key name and content are not dictated by the user notification services. You'll write code in the extension to grab this and use it to load an image in the notification.

With the content in mind, it's time to start creating the Notification Service extension to load the content-url and build an attachment with it.

Select **File -> New -> Target** in Xcode. Chose **Application Extension** under iOS in the left pane, and then chose **Notification Service** in the detail view. Name it **ServiceExtension**, make sure your correct **Team** is selected, select Swift, and hit **Finish**. If prompted, choose to **Activate** the scheme.

This will create a target called **ServiceExtension**. It will also add the following files in your project:

![width=40% bordered](./images/service-extension.png)

Take a look at **NotificationService.swift**, which contains a class `NotificationService` that inherits from `UNNotificationServiceExtension`. `UNNotificationServiceExtension` is the central class for Notification Service extensions, and it contains two important methods the template code is overriding:

1. **didReceive(_:withContentHandler)** is called when a notification is received and routed to the extension, and is given a limited amount of time to modify the notification contents. It accepts a `UNNotificationRequest`, from which it creates `bestAttemptContent`, a mutable copy of the notification content. The template unwraps this and appends `[modified]` to the end of the title then calls the contentHandler, passing the updated content.
2. **serviceExtensionTimeWillExpire()** is called to provide a best attempt at updating notification content in cases where `didReceive(_:UNNotificationServiceExtension)` doesn't return quickly enough. The template contains a property `bestAttemptContent` that `didReceive(_:UNNotificationServiceExtension)` uses while updating content. Here, `serviceExtensionTimeWillExpire()` unwraps `bestAttemptContent` and sends it along to the `contentHandler`.

You'll modify this code to handle downloading the attachment-url. First, add the following import to the top of the file:

```swift
import MobileCoreServices
```

You'll need this for referencing a file type constant in just a moment.

In **didReceive(_:withContentHandler)**, delete the template code inside the `if let bestAttemptContent = bestAttemptContent` block. Add the following in its place:

```swift
// 1
guard let attachmentString = bestAttemptContent
  .userInfo["attachment-url"] as? String,
  attachmentUrl = URL(string: attachmentString) else { return }

// 2
let session = URLSession(configuration:
  URLSessionConfiguration.default)
let attachmentDownloadTask = session.downloadTask(with:
  attachmentUrl, completionHandler: { (url, response, error) in
    if let error = error {
      print("Error downloading: \(error.localizedDescription)")
    } else if let url = url {
      // 3
      let attachment = try! UNNotificationAttachment(identifier:
        attachmentString, url: url, options:
        [UNNotificationAttachmentOptionsTypeHintKey: kUTTypePNG])
      bestAttemptContent.attachments = [attachment]
    }
    // 5
    contentHandler(bestAttemptContent)
})
// 4
attachmentDownloadTask.resume()
```

Here's what this does:

1. This obtains the string value for `attachment-url` found in `userInfo` of the request content copy. A URL is created from this string and saved in `attachmentUrl`. If this guard isn't successful, it bails out early with a return.
2. `session` is a `URLSession` that is used when creating a `downloadTask` to obtain the image at `attachmentUrl`. In the completion handler, an error is printed on failure.
3. On success, a `UNNotificationAttachment` is created using the `attachmentString` as a unique identifier and the local `url` as the content. `UNNotificationAttachmentOptionsTypeHintKey` provides a hint as to the file type—in this case `kUTTypePNG` is used as the file is known to be a PNG. The resulting attachment is set on `bestAttemptContent`.
4. The `completionHandler` is called, passing over the modified notification content. This signifies the extension's work is done, and sends back the updated notification. This must be done whether or not the attempt was successful (when unsuccessful, the original request is sent back)
5. Once the `downloadTask` is defined, it is kicked off with `resume()`. This leads to the `attachmentDownloadTask`'s `completionHandler` executing on completion, which in turn calls the `contentHandler` to complete processing.

`serviceExtensionTimeWillExpire()` is already in good shape with the template code—it will return whatever you currently have in `bestAttemptContent`.

Build and run the **ServiceExtension** scheme on your device, making sure to run with **cuddlePix**. Now return to **Pusher** where you should have already copied the new payload containing the `attachment-url`. Hit **Push** and in no time, you should see a remote sourced cuddle, complete with an image of iOS 10 by Tutorials.

![width=40% bordered](./images/remote-push-content.png)

A remote push was intercepted by a Notification Service extension, which downloaded the image in the URL provided in the payload and attached it to the notification. Pretty cool!

## Where To Go From Here?

In this chapter, you cuddled some cactuses while checking out everything new with notifications—and there was quite a lot!

You learned how to create custom notification interfaces, respond to actions in Notification Content extensions and the app, query and modify existing notifications, and enhance remote notifications with Notification Service extensions. Hopefully you've already come up with some ideas on how to enhance your apps with these basic ideas, which should make notifications quite a bit more user friendly and useful.

For more detail on any of these topics, be sure to check out Apple's UserNotifications API Reference here—[apple.co/29F1nzE](http://apple.co/29F1nzE)

There are also some great WWDC videos covering all of these new features:

- Advanced Notifications (Session 708)—[apple.co/29t7c6v](http://apple.co/29t7c6v)
- Introduction to Notifications (Session 707)—[apple.co/29Wv6D6](http://apple.co/29Wv6D6)
