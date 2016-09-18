```metadata
author: "By Jeff Rames"
number: "8"
title: "Chapter 8: User Notifications"
```
# Chapter 8: User Notifications

Consider your favorite apps. It's likely that a good portion of them leverage some type of User Notification. 

Remote push notifications date all the way back to iOS 3, while local notifications were introduced iOS 4. Notifications engage users with your app, keep you up to date, and provide near real-time communication with others.

For all their importance, User Notifications haven't changed much over the years. However, iOS 10 has introduced sweeping changes to the way User Notifications work for developers:

- **Media attachments** can now be added to notifications, including audio, video and images.
- New **Notification Content extensions** let you create custom interfaces for notifications.
- **Managing notifications** is now possible with interfaces in the new user notification center.
- New **Notification Service app extensions** let you process remote notification payloads before they're delivered.

In this chapter, you'll explore all of these new features. Let's get started!

> **Note**: For most of this chapter, you'll be fine with the iOS simulator, and don't need any prior experience with user notifications. However, to work with Notification Service app extensions in the final section of this chapter, you'll need a device running iOS 10 and a basic understanding of configuring remote notifications. For more background information on notifications, check out _Push Notifications Tutorial: Getting Started_ at [raywenderlich.com/123862](http://raywenderlich.com/123862).

## Getting started

The sample app for this chapter is **cuddlePix**, which aims to spread cheer with visually rich notifications containing pictures of cuddly cacti. 

> **Note**: While cuddlePix employs only the most cuddly digital cacti, remember to use caution when cuddling a real cactus. Real world prototyping of cuddlePix indicated that some cacti can be quite painful. :]

When complete, the app will act as a management dashboard for notification statuses and configuration data, as well as a scheduler for local notifications. It will also define custom notifications complete with custom actions.

Open the starter project for this chapter, and set your team in the CuddlePix Target General Signing settings. Then build and run to see what you have to work with. You'll be greeted by an empty table view that will eventually house the notification status and configuration information.

Tap the **+** bar button, and you'll see an interface for scheduling multiple local notifications over the next hour, or scheduling a single one in five seconds' time. These don't do anything at present - that's where you come in.

![width=90%](./images/cuddlePix-starter.png)

Take a few minutes and explore the below items in the starter project:

- **NotificationTableViewController.swift** contains the table view controller and displays a sectioned table using a datasource built from a struct and protocol found in **TableSection.swift**.
- **ConfigurationViewController.swift** manages the view that schedules notifications, centered around a mostly stubbed-out method `scheduleRandomNotification(in:completion:)` that will ultimately create and schedule notifications.
- **Main.storyboard** defines the simple UI you've already seen in full while testing the app.
- **Utilities** contains some helpers you'll use during this tutorial.
- **Supporting Files** contains artwork attributions, the plist, and images you'll display in your notifications.

$[=s=]

## The User Notifications framework

Gone are the days of handling notifications via your application delegate. Enter **UserNotifications.framework**, which does everything its predecessor did, along with enabling all of the new user notification functionality such as attachments, Notification Service extensions, foreground notifications, and more.

The core of the new framework is `UNUserNotificationCenter`, which is accessed via a singleton. It manages user authorization, defines notifications and associated actions, schedules local notifications, and provides a management interface for existing notifications.

The first step in using `UNUserNotificationCenter` is to ask the user to authorize your app to use notifications. Open **NotificationTableViewController.swift** and add the following to `viewDidLoad()`, just below the call to `super`:

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

`UNUserNotificationCenter.current()` returns the singleton user notification center.

You then call `requestAuthorization(options:completionHandler:)` to request authorization to present notifications. You pass in an array of `UNAuthorizationOptions` to indicate what options you're requesting — in this case, `alert` and `sound` notifications. If access is granted, you call the currently stubbed out `loadNotificationData()`; otherwise you print the passed error.

Build and run, and you'll see an authorization prompt as soon as `NotificationTableViewController` loads. Be sure to tap **Allow**.

![bordered width=40%](./images/notification-prompt.png)

### Scheduling notifications

Now that you have permission from the user, it's time to take this new framework for a spin and schedule some notifications!

Open **ConfigurationViewController.swift** and review the following code:

  * Pressing the **Cuddle me now!** button triggers `handleCuddleMeNow(_:)`, which passes a delay of 5 seconds to `scheduleRandomNotification(inSeconds:completion:)`.

  * The **Schedule** button triggers `scheduleRandomNotifications(number:completion:)`, which calls `scheduleRandomNotification(inSeconds:completion:)` with various delays to space out repeat notifications over an hour.

  * Right now `scheduleRandomNotification(inSeconds:completion:)` obtains the URL of a random image in the bundle and prints it to the console, but it doesn't yet schedule a notification. That's your first task.

To create a local notification, you need to provide some content and a trigger condition. 

In the `scheduleRandomNotification` function, delete `print("Schedule notification with \(imageURL)")` and add the following in its place:

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

> **Note**: You can select an emoji from the Xcode editor with **Command** + **Control** + **Spacebar**. Don't stress if you can't find this exact emoji, as it doesn't matter for this tutorial.

Here's what you're doing in the code above:

1. You create a `UNMutableNotificationContent`, which defines what is displayed on the notification — in this case, you're setting a `title`, `subtitle` and `body`. This is also where you'd set things like badges, sounds and attachments. As the comment teases, you'll add an attachment here a bit later in the tutorial.
2. A `UNTimeIntervalNotificationTrigger` needs to know when to fire and if it should repeat. You're passing through the `inSeconds` parameter for the delay, and creating a one-time notification. You can also trigger user notifications via location or calendar triggers.

Next up, you need to create the notification request and schedule it. Replace the `completion()` call with the following:

```swift
// 1
let request = UNNotificationRequest(
  identifier: randomImageName, content: content, trigger: trigger)

// 2
UNUserNotificationCenter.current().add(request, withCompletionHandler: { (error) in
  if let error = error {
    print(error)
    completion(false)
  } else {
    completion(true)
  }
})
```

Here's the breakdown:

1. You create a `UNNotificationRequest` from the `content` and `trigger` you created above. You also provide the required unique identifier (the name of the randomly selected image) to use later when managing the request.
2. You then call `add(_:withCompletionHandler)` on the shared user notification center to add your `request` to the notification queue. Take a look at the completion handler: if an error exists, you print it to the console and inform the caller. If the call was successful, you call the `completion(success:)` closure indicating success, which ultimately notifies its delegate `NotificationTableViewController` that a refresh of pending notifications is necessary. You'll learn more about `NotificationTableViewController` later in the chapter.

Build and run, tap the **+** bar item, tap **Cuddle me now!** then quickly background the application (you can use **Command + Shift + H** to background the application if you are using the Simulator). Five seconds after you created the notification, you'll see the notification banner complete with your custom content:

![width=40%](./images/first-notification.png)

### Adding attachments

When you have such a beautiful cactus image, it seems a bit wasteful to only use it for the unique notification identifier. It would be nice to display this image in the notification itself as well.

To do this, back in `scheduleRandomNotification(inSeconds:completion:)`, add the following just below the `imageURL` declaration at the beginning of the method:

```swift
let attachment = try! UNNotificationAttachment(identifier:
  randomImageName, url: imageURL, options: .none)
```

A `UNNotificationAttachment` is an image, video, or audio attachment that is included with a notification. It requires an identifier, for which you've used the `randomImageName` string, as well as a URL that points to a local resource of a supported type. 

Note this method throws an error if the media isn't readable or otherwise isn't supported. But since you've included these images in your bundle, it's fairly safe to disable error propagation with a `try!`.

Next, replace `//TODO: Add attachment` with the following:

```swift
content.attachments = [attachment]
```

Here you're setting `attachments` to the single image attachment wrapped in an array. This makes it available for display when the notification fires using default notification handling for image attachments.

> **Note**: When the notification is scheduled, a security-scoped bookmark is created for the attachment so Notification Content extensions have access to the file.

Build and run, initiate a notification with **Cuddle me now!** then return to the home screen as you did before. You'll be greeted with a notification containing a random cactus picture on the right side of the banner. Force tap, or select and drag down on the banner, and you'll be treated to an expanded view of the huggable cactus.

![width=90%](./images/notification-attachment.png)

### Foreground notifications

The **UNUserNotificationCenterDelegate** protocol defines methods for handling incoming notifications and their actions, including an enhancement to iOS 10 notifications: the ability to display system notification banners in the foreground.

Open **AppDelegate.swift** and add the following at the end of the file:

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

This extends `AppDelegate` to adopt the `UNUserNotificationCenterDelegate` protocol. The optional `userNotificationCenter(_:willPresent:withCompletionHandler:)` is called when a notification is received in the foreground, and gives you an opportunity to act upon that notification. Inside, you call the `completionHandler()`, which determines if and how the alert should be presented. 

The `.alert` notification option indicates you want to present the alert, but with no badge updates or sounds. You could also choose to suppress the alert here by passing an empty array.

In `application(_:didFinishLaunchingWithOptions:)`, add the following just before the `return`:

```swift
UNUserNotificationCenter.current().delegate = self
```

This sets your app's delegate as the `UNUserNotificationCenterDelegate` so the user notification center will pass along this message when a foreground notification is received.

Build and run, and schedule a notification as you've done before. This time, leave cuddlePix in the foreground and you'll see a system banner appear in the foreground:

![bordered width=40%](./images/in-app-banner.png)

Think back to all the times you had to build your own banner for these situations. Take a deep breath — that's all in the past now! :]

![width=30%](./images/hero-ragecomic.png)

## Managing notifications

You've probably experienced the frustration of clearing out countless missed and outdated notifications in Notification Center. Think of an app that posts sports scores in real-time; you likely care only about the most recent score. iOS 10 gives developers the ability to realize this improved user experience.

The accessor methods of **UNUserNotificationCenter** let you read an app's user notification settings (the user permissions) so you can stay up-to-date on changes. But more excitingly, the _delete_ accessors let you programmatically remove pending and delivered notifications to free your users from a wall of unnecessary notifications.

Finally, the accessor methods let you read and and set notification categories – you'll learn about those a little later in this chapter.

### Querying Notification Center

You'll start by reading the notification settings and displaying them in cuddlePix's initial table view.

Open **NotificationTableViewController.swift** and find `loadNotificationData(callback:)`. Your code calls this when the table is refreshed, an authorization is returned, a notification is scheduled or a notification is received. Right now, it simply reloads the table.

Add the following just below the `group` declaration near the top:

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

This code queries for notification settings and updates the table datasource object that displays them:

1. You create `notificationCenter` to reference the shared notification center more concisely. Then you create a `DispatchQueue` to prevent concurrency issues when updating the table view data source.
2. You then enter a dispatch group to ensure all data fetch calls have completed before you refresh the table. Note the project already refreshes in a `group.notify(callback:)` closure for this reason.
3. You call `getNotificationSettings(callback:)` to fetch current notification settings from Notification Center. You pass the results of the query to the callback closure via `settings`, which in turn you use to initialize a `SettingTableSectionProvider`. `SettingTableSectionProvider` is from the starter project; it extracts interesting information from the provided `UNNotificationSettings` for presentation in a table view cell.
4. Using the `dataSaveQueue`, you asynchronously update the settings section of `tableSectionProviders` with the newly created `settingsProvider`. The table management is all provided by the starter project; all you need to do is set the provider so as to provide the data to the table view. Finally, you leave `group` to release your hold on the dispatch group.

Build and run, and you'll see a **Notification Settings** section in the table view that represents the current status of notification settings for cuddlePix.

To test it out, go to iOS Settings, find **CuddlePix** and toggle some of the switches. Return to cuddlePix, pull to refresh, and you'll see the updated status:

![width=90%](./images/notification-settings.png)

Knowing your user's settings can help you tailor your notifications to suit.

It's just as easy to fetch information about pending and delivered notifications.

Add the following code just below the closing bracket of the `getNotificationSettings(completionHandler:)` closure:

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

This implements two additional fetches that are similar to the settings fetch you coded earlier and update each `tableSectionProviders` respectively. `getPendingNotificationRequests(completionHandler:)` fetches notifications that are pending; that is, scheduled, but not yet delivered. `getDeliveredNotifications(completionHandler:)` fetches those notifications that have been delivered, but not yet deleted.

Build and run, schedule a notification, and you'll see it appear under **Pending Notifications**. Once it's been delivered, pull to refresh and you'll see it under **Delivered Notifications**.

Delivered notifications persist until they're deleted. To test this, expand a notification when the banner appears then select **Dismiss**. Refresh the table, then check to see if the notification still exists. You can also delete a notification by pulling down Notification Center and clearing it from the **Missed** list:

![bordered iphone](./images/notification-status.png)

It would be even nicer if you didn't have to pull to refresh when a new notification arrives.

Add the following to **AppDelegate.swift** at the top of `userNotificationCenter(_:willPresent:withCompletionHandler)`:

```swift
NotificationCenter.default.post(name:
  userNotificationReceivedNotificationName, object: .none)
```

`userNotificationReceivedNotificationName` is a system notification cuddlePix uses to reload the status table. You've placed it here, because `userNotificationCenter(_:willPresent:withCompletionHandler)` triggers whenever a notification arrives.

A very compelling application of this "status awareness" is to prevent repeat notifications if an identical status is still in "delivered" status.

### Modifying notifications

Consider again the app that reports sport scores. Rather than littering Notification Center with outdated score alerts, you could update the same notification and bump it to the top of the notification list each time an update comes through.

Updating notifications is straightforward. You simply create a new `UNNotificationRequest` with the same identifier as the existing notification, pass it your updated content, and add it to `UNUserNotificationCenter`. Once the trigger conditions are met, it will overwrite the existing notification that has a matching identifier.

For cuddlePix, notifications are serious business. Consider the scenario where you scheduled 10 notifications, when you meant to only schedule five. Too much of a good thing can get pretty prickly, so you're going to make your notification strategy a little more _succulent_ and delete pending notifications.

Open **NotificationTableViewController.swift**; you'll see `tableView` editing methods near the end of the data source methods extension. Deletion is enabled for rows in the **pending** section, but committing the delete doesn't do anything. Time to fix that.

Add the following to `tableView(_:commit:forRowAt:)`:

```swift
// 1
guard let section =
  NotificationTableSection(rawValue: indexPath.section),
  editingStyle == .delete && section == .pending else { return }

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

This method executes when you attempt an insertion or deletion on the `tableView`. Taking it step-by-step:

1. You check that the selected cell came from the `pending` section of the table and that the attempted operation was a `delete`. If not, return.
2. You unwrap and typecast the `tableSectionProviders` datasource object associated with pending notifications, and return if the operation fails. You then set `request` to the `UNNotificationRequest` represented by the selected cell.
3. You call `removePendingNotificationRequests(withIdentifiers:)` on the user notification center to delete the notification matching your request's identifier. Then you call `loadNotificationData(callback:)` to refresh the datasource, deleting the row in the callback closure.

Build and run, create a new notification, and swipe the cell in the **Pending Notifications** section to reveal the delete button. Tap **Delete** quickly before the notification is delivered. Because you've deleted it from the user notification center before it was delivered, the notification will never be shown, and the cell will be deleted.

![bordered iphone](./images/delete-pending-notification.png)

## Notification content extensions

Another major change to notifications in iOS 10 is the introduction of Notification Content extensions, which let you provide custom interfaces for the expanded version of your notifications. Interaction is limited, though — the notification view won't pass along gestures, but the extension can update the view in response to **actions**, which you'll learn about a little later.

To make a Notification Content extension, you must adopt the **UNNotificationContentExtension** protocol in your extension view controller. This protocol defines optional methods that notify the extension when it's being presented, help it respond to actions, and assist in media playback.

The interface can contain anything you might normally place in a view, including playable media such as video and audio. However, the extension runs as a separate binary from your app, and you don't have direct access to the app's resources. For this reason, any required resources that aren't included in the extension bundle are passed via attachments of type **UNNotificationAttachment**.

### Creating an extension with an attachment

Let's try this out. Select **File\New\Target** in Xcode; choose the **iOS\Application Extension\Notification Content Extension** template then select **Next**. 

![width=60% bordered](./images/content-extension-setup2.png)

Enter **ContentExtension** for the Product Name, select the **Team** associated with your developer account, choose **Swift** as the Language, then hit **Finish**. If prompted, choose to **Activate** the scheme.

You've created a new target and project group, both named **ContentExtension**. In the group, you have a view controller, storyboard, and plist necessary for configuring the extension. You'll visit each of these in turn while implementing the extension.

![width=40% bordered](./images/content-extension-group.png)

Open **MainInterface.storyboard** and take a look; you'll see a single view controller of type `NotificationViewController` — this is the controller created when you generated the extension. Inside is a single view with a "Hello World" label connected to an outlet in the controller.

For cuddlePix, your goal is to create something similar to the default expanded view, but just a tad more cuddly. A cactus picture with a hug emoji in the corner should do quite nicely! :]

To start, delete the existing label and change the view's background color to white. Set the view height to **320** to give yourself more room to work. Add an Image View and pin it to the edges of the superview with a fixed size as pictured below (these are indeed conflicting, bear with me):

![width=35% bordered](./images/imageview-constraints.png)

To fix the conflicting constraints, in the document outline, select the **height** constraint under the Image View. Use the Size Inspector to change the constraint relation to **Greater Than or Equal**:

![width=60% bordered](./images/greater-than-autolayout.png)

Do the same thing with the width constraint of the Image View. This will let the Image View grow based on the size of the presented notification. 

Select the Image View and go to the Attributes Inspector. In the View section, set the Content Mode to **Aspect Fill** to ensure as many pixels as possible are filled with beautiful, poky, cactusy goodness:

![width=35% bordered](./images/aspect-fill.png)

To clean things up, select the **Resolve Auto Layout Issues** button in the lower right and then select **Update Frames** in the **All Views in Notification View Controller** section. This will cause your Image View to resize to match the constraints, and the Auto Layout warnings should resolve as well.

Next, drag a label just under the image view in the document outline pane on the left-hand side of Interface Builder:
![width=30% bordered](./images/label-placement.png)

Pin it to the bottom left of the view with the following constraints:

![width=35% bordered](./images/label-constraints.png)

Now to add a big spiny cactus hug! With the label selected, change the Text in the attribute inspector to a hug emoji. To do this, use **Control + Command + Spacebar** to bring up the picker, and select the 🤗.

![width=40% bordered](./images/emoji-picker.png)

Set the font size of the label to **100** so your hug emoji is more visible. Click **Update Frames** again to resize the label to match the new content.

Now, open **NotificationViewController.swift** in the Assistant Editor so that you can wire up some outlets.

First, delete the following line:

```swift
@IBOutlet var label: UILabel?
```

That outlet was associated with the label you deleted from the storyboard template. You'll see an error now as you're still referencing it. 

Delete the following in `didReceive(_:)` to resolve that:

```swift
self.label?.text = notification.request.content.body
```
Next, Control-drag from the image view in the storyboard to the spot where you just deleted the old outlet. Name it **imageView** and select **Connect**:

![width=80% bordered](./images/imageview-outlet.png)

With the interface done, close the storyboard and open **NotificationViewController.swift** in the Standard editor.

Remember that `didReceive(_:)` is called when a notification arrives; this is where you should perform any required view configuration. For this extension, that means populating the image view with the cactus picture from the notification.

Add the following to `didReceive(_:)`:

```swift
// 1
guard let attachment = notification.request.content.attachments.first
  else { return }
// 2
if attachment.url.startAccessingSecurityScopedResource() {
  let imageData = try? Data.init(contentsOf: attachment.url)
  if let imageData = imageData {
    imageView.image = UIImage(data: imageData)
  }
  attachment.url.stopAccessingSecurityScopedResource()
}
```

Here's what the above does:

1. The passed-in `UNNotification` (`notification`) contains a reference to the original `UNNotificationRequest` (`request`) that generated it. A request has `UNNotificationContent` (`content`) which, among other things, contains an array of `UNNotificationAttachments` (`attachments`). In a guard, you grab the first of those attachments — you know you've only included one — and you place it in `attachment`.
2. Attachments in the user notification center live inside your app's sandbox – not the extension's – therefore you must access them via security-scoped URLs. `startAccessingSecurityScopedResource()` makes the file available to the extension when it successfully returns, and `stopAccessingSecurityScopedResource()` indicates you're finished with the resource. In between, you load `imageView` using `Data` obtained from the file pointed to by this URL.

The extension is all set. But when a notification triggers for cuddlePix, how is the the system supposed to know what, if any, extension to send it to?

![width=30%](./images/notification-gnomes.png)

Gnomes are a good guess, but they're notoriously unreliable. :] Instead, the user notification center relies on a key defined in the extension's plist to identify the types of notifications it should handle.

Open **Info.plist** in the **ContentExtension** group and expand `NSExtension`, then `NSExtensionAttributes`, to reveal **UNNotificationExtensionCategory**. This key takes a string (or array of strings) identifying the notifications it should handle. Enter **newCuddlePix** here, which you'll later use in the content of your notification requests.

![width=80% bordered](./images/content-extension-plist.png)

> **Note**: In the same plist dictionary, you'll see another required key: `UNNotificationExtensionInitialContentSizeRatio`. Because the system starts to present a notification before it loads your extension, it needs something on which to base the initial content size. You provide a ratio of the notification's height to its width, and the system will animate any expansion or contraction once the extension view loads.
>
> cuddlePix's extension view frame is set to fill the full width of a notification, so in this case you leave it at the default ratio of 1.

The operating system knows that notifications using the *newCuddlePix* category should go to your extension, but you haven't yet set this category on your outgoing notifications. Open **ConfigurationViewController.swift** and find `scheduleRandomNotification(inSeconds:completion:)` where you generate instances of `UNNotificationRequest`.

Add the following after the spot where you declare `content`:

```swift
content.categoryIdentifier = newCuddlePixCategoryName
```

The `UNNotificationRequest` created in this method will now use `newCuddlePixCategoryName` as a `categoryIdentifier` for its content. `newCuddlePixCategoryName` is a string constant defined in the starter that matches the one you placed in the extension plist: "newCuddlePix".

When the system prepares to deliver a notification, it will check the notification's category identifier and try to find an extension registered to handle it. In this case, that is the extension you just created.

> **Note**: For a remote notification to invoke your Notification Content extension, you'd need to add this same category identifier as the value for the `category` key in the payload dictionary.

Make sure you have the **CuddlePix** scheme selected, then build and run. Next, switch to the **ContentExtension** scheme then build and run again. When you're prompted what to run the extension with, select **CuddlePix** and **Run**: 

![width=65% bordered](./images/run-extension-prompt.png)

In cuddlePix, generate a new notification with **Cuddle me now!**. When the banner appears, expand it either by force touching on a compatible device, or selecting the notification and dragging down in the simulator. You'll now see the new custom view from your extension:

![iphone bordered](./images/content-extension-presented.png)

> **Note**: You'll notice that the custom UI you designed is presented _above_ the default banner content. In this case, that's what you want, as your custom view didn't implement any of this text.
>
> However, if you shifted the titles and messages to the extension, you might want to remove the system-generated banner at the bottom. You could do this by adding the `UNNotificationExtensionDefaultContentHidden` key to your extension plist with a value of `true`.

### Handling notification actions 

So far, the custom notification for cuddlePix isn't all that different from the default one. However, a custom view _does_ provide quite a lot of opportunity depending on your needs. For example, a ride-sharing app could provide a map of your ride's location, while a sports app could provide a large scoreboard.

The feature that makes extensions shine in cuddlePix is _interactivity_. While Notification Content extensions don't allow touch handling, where the touches aren't passed to the controller, they _do_ provide interaction through custom action handlers.

Before iOS 10, custom actions were forwarded on to the application and handled in an application delegate method. This worked great for things like responding to a message where there wasn't any need to see the results of the action.

Because Notification Content extensions can handle actions directly, that means the notification view can be updated with results. For instance, when you accept an invitation, you could display an updated calendar view right there in the notification showing the new event.

The driver behind this is the new **UNNotificationCategory**, which uniquely defines a notification type and references actions the type can act upon. The actions are defined with **UNNotificationAction** objects that, in turn, uniquely define actions. When configured and added to the `UNUserNotificationCenter`, these objects help direct actionable notifications to the right handlers in your app or extensions.

#### Defining the action

The goal of cuddlePix is to spread cheer, and what better way to do that than shower your cuddly cactus with stars? You're going to wire up an action for "starring" a cactus, which will kick off an animation in your custom notification view.

To start, you need to register a notification category and action in the app.

Open **AppDelegate.swift** and add the following method to `AppDelegate`:

```swift
func configureUserNotifications() {
  // 1
  let starAction = UNNotificationAction(identifier:
    "star", title: "🌟 star my cuddle 🌟 ", options: [])
  let dismissAction = UNNotificationAction(identifier:
    "dismiss", title: "Dismiss", options: [])
  // 2
  let category =
    UNNotificationCategory(identifier: newCuddlePixCategoryName,
      actions: [starAction, dismissAction],
      intentIdentifiers: [],
      options: [])
  // 3
  UNUserNotificationCenter.current()
    .setNotificationCategories([category])
}
```

Taking each numbered comment in turn:

1. A `UNNotificationAction` has two jobs: it provides the data used to display an action to the user, and it uniquely identifies actions so controllers can act upon them. It requires a title for the first job and a unique identifier string for the second. Here you've created a `starAction` and a `dismissAction` with recognizable identifiers and titles.
2. You defined a `UNNotificationCategory` with the string constant set up for this notification: `newCuddlePixCategoryName`. You've passed an array containing your newly created `UNNotificationActions` to `actions` and `minimalActions`. The `actions` parameter requires all custom actions in the order you want them displayed, while `minimalActions` needs to contain the two most important actions to display when space is limited.
3. You pass the new `category` to the `UNUserNotificationCenter` with `setNotificationCategories()`, which accepts an array of categories and registers cuddlePix as supporting them.

> **Note**: You're probably shouting as you read this that the notification *already* shows a dismiss option when it's expanded. That _is_ the default behavior for a Notification Content extension – when you don't use a custom action. As soon as you provide a custom action, only those actions you create will display, so you need to create your own dismiss action here.

Add the following code just before the `return` statement in `application(_:didFinishLaunchingWithOptions:)`:

```swift
configureUserNotifications()
```

This ensures category registration occurs as soon as the app starts.

Build and run the **CuddlePix** scheme, followed by the **ContentExtension** scheme, which you should choose to run with CuddlePix. Create a notification and expand it via force touch or a drag down when it arrives.

You'll now see buttons for your new actions at the bottom of the notification:

![iphone bordered](./images/notification-actions.png)

Select **star my cuddle**; the notification will simply dismiss, because you haven't yet implemented the action to be performed.

#### Handling and forwarding extension responses

Notification extensions get first crack at handling an action response. In fact, they determine whether or not to forward the request along to the app when they finish.

Inside ContentExtension, open **NotificationViewController.swift** and you'll see your controller already adheres to `UNNotificationContentExtension`. This provides an optional method for handling responses. 

Add the following to `NotificationViewController`:

```swift
internal func didReceive(_ response: UNNotificationResponse,
                  completionHandler completion:
    @escaping (UNNotificationContentExtensionResponseOption) -> Void) {
  // 1
  if response.actionIdentifier == "star" {
    // TODO Show Stars
    let time = DispatchTime.now() +
      DispatchTimeInterval.milliseconds(2000)
    DispatchQueue.main.asyncAfter(deadline: time) {
      // 2
      completion(.dismissAndForwardAction)
    }
  // 3
  } else if response.actionIdentifier == "dismiss" {
    completion(.dismissAndForwardAction)
  }
}
```

`didReceive(_:completionHandler:)` is called with the action response and a completion closure. The closure must be called when you're done with the action, and it requires a parameter indicating what should happen next. Here's what's going on in more detail:

1. When you set up `UNNotificationAction`, you gave the star action an identifier of `star`, which you check here to catch responses of this type. Inside, you have a `TODO` for implementing the star animation that you'll soon revisit. You let the animation continue for two seconds via `DispatchQueue.main.after` before calling the completion closure.
2. `completion` takes an enum value defined by `UNNotificationContentExtensionResponseOption`. In this case, you've used `dismissAndForwardAction`, which dismisses the notification and gives the app an opportunity to act on the response. Alternative values include `doNotDismiss`, which keeps the notification on screen, and `dismiss`, which doesn't pass the action along to the app after dismissal.
3. For the dismiss action, the extension dismisses immediately and forwards the action along to the app.

Your current implementation of the star action leaves something to be desired — specifically, the stars! The starter project already contains everything you need for this animation, but it's not yet available to the Notification Content extension's target.

In the project navigator, expand the **Utiltiies** and the **Star Animator** group and select both files inside:
![width=40% bordered](./images/star-animator.png)

Open the File Inspector in the utilities pane of Xcode and select **ContentExtension** under **Target Membership**:
![width=40% bordered](./images/target-membership.png)

Back in **NotificationViewController.swift**, replace `// TODO Show Stars` with the following:

```swift
imageView.showStars()
```

This uses a `UIImageView` extension defined in the **StarAnimator.swift** file you just added to the target. `showStars()` uses Core Animation to create a shower of stars over the image view.

Build and run the extension and the app as you've done before. Create and expand a notification, then select **star my cuddle** and you'll see an awesome star shower over your cactus before the notification dismisses:

![iphone bordered](./images/star-shower.png)

Your extension has done its job, and the cuddle has been starred. But recall that you called `dismissAndForwardAction` in the completion closure. Where is it being forwarded _to_?

The answer is that it's forwarded to the app, but right now the `UNUserNotificationCenterDelegate` in cuddlePix isn't expecting anything.

Open **AppDelegate.swift** and add the following method to the `UNUserNotificationCenterDelegate` extension:

```swift
func userNotificationCenter(_ center: UNUserNotificationCenter,
                            didReceive response: UNNotificationResponse,
                            withCompletionHandler
  completionHandler: () -> Void) {
  print("Response received for \(response.actionIdentifier)")
  completionHandler()
}
```

`userNotificationCenter(_:didReceive:withCompletionHandler)` will let you know a notification action was selected. Inside, you print out the `actionIdentifier` of the response, simply to confirm things are working as they should. You then call `completionHandler()` which accepts no arguments and is required to notify the user notification center that you're done handling the action.

Build and run the app and Notification Content extension, and trigger a notification. Expand the notification and select either response. Watch the console and you should see responses like the ones below:

```html
Response received for dismiss
Response received for star
```

To recap, here's the flow of messages that takes place when you receive a notification in the foreground and respond to an action in a Notification Content extension:

1. **userNotificationCenter(_:willPresent:withCompletionHandler:)** is called in the `UNUserNotificationCenterDelegate` (only in the foreground), and determines if the notification should present itself.
2. **didReceive(_:)** is called in the `UNNotificationContentExtension` and provides an opportunity to configure the custom notification's interface.
3. **didReceive(_:completionHandler:)** is called in the `UNNotificationContentExtension` after the user selects a response action.
4. **userNotificationCenter(_:didReceive:withCompletionHandler:)** is called in the `UNUserNotificationCenterDelegate` if the `UNNotificationContentExtension` passes it along via the `dismissAndForwardAction` response option.

## Notification Service app extensions

Believe it or not, another major feature awaits in the form of Notification Service extensions. These let you intercept remote notifications and modify the payload. Common use cases would include adding a media attachment to the notification, or decrypting content.

cuddlePix doesn't really demand end-to-end encryption, so instead you'll add an image attachment to incoming remote notifications. But first, you need to set up a development environment. Because the simulator cannot register for remote notifications, you'll need a device with iOS 10 to test.

Start by configuring cuddlePix for push with your Apple Developer account. First select the **CuddlePix** target and **General** tab. In the **Signing** section, select your **Team** and then in **Bundle Identifier** enter a unique **Identifier**.

![width=80% bordered](./images/general-configuration.png)

Now switch to the **Capabilities** tab and switch **Push Notifications** on for the CuddlePix target. cuddlePix is now set up to receive tokens from the Apple Push Notification Service (APNS).

![width=80% bordered](./images/push-configuration.png)

Select the **ContentExtension** target and change the *com.razeware.CuddlePix* prefix in its bundle identifier to match the unique identifier you used for the **CuddlePix** target (leaving `.ContentExtension` at the end of the identifier). Also set your **Team** as you did in the other target. Apple requires that your extensions have a prefix that matches the main app.

You'll also need a way to send test pushes. For this, you'll use a popular open source tool called **Pusher**, which sends push notifications directly to APNS. To start, follow the instructions in the **Installation** section of their GitHub readme to get the app running: [github.com/noodlewerk/NWPusher](https://github.com/noodlewerk/NWPusher).

Pusher's readme also has a **Getting Started** section that guides you through creating the required SSL certificate; follow this to create a Development certificate. You may also find the section titled *Creating an SSL Certificate and PEM file* in *Push Notifications Tutorial: Getting Started* useful. You can find it here - [raywenderlich.com/123862](http://raywenderlich.com/123862).

With your `p12` file in hand, go back to Pusher and select it in the **Select Push Certificate** dropdown. You may need to choose **Import PCKS #12 file (.p12)** and manually select it if it doesn't appear here.

Pusher requires a push token so it can tell APNS where to send the notification.

Head back to Xcode and open **AppDelegate.swift**. Add the following just before the `return` statement in `application(_:didFinishLaunchingWithOptions)`:

```swift
application.registerForRemoteNotifications()
```

When cuddlePix starts up, it will now register for notifications. Remember – this will only work when run on a device.

Add the following at the bottom of the app delegate, just below the final bracket:

```swift
extension AppDelegate {
  // 1
  func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
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

This extension contains `UIApplicationDelegate` methods for handling responses from APNS:

1. `application(_:didFailToRegisterForRemoteNotificationsWithError:)` is called when registration fails. Here, you print the error message.
2. `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)` is called when registration is successful, and returns the `deviceToken`. You use `hexString`, a helper method included with the starter project, to convert it to hex format and print it to the console.

Build and run on a device, and check the debug console for your device token, prefixed with the string `Registered with device token`. Copy the hex string and paste it into the **Device Push Token** field in Pusher. Then paste the following in the payload field, using **Paste and Match Style** to avoid formatting issues:

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

The default notification banner is here, but if you expand it, the image view will be blank. You passed in the category of `newCuddlePix`, identifying your Notification Content extension – but you didn't provide an attachment to load. That's just not possible from a remote payload...but that's where Notification Service extensions come in.

### Creating and configuring a Notification Service extension

The plan is to modify your payload to include the URL of an attachment you'll download in the Notification Service extension and use to create an attachment. Update the JSON in the payload section in Pusher to match the following:

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

This contains two new keys:

1. `mutable-content` takes a boolean and indicates whether or not the notification should be modifiable by a Notification Service extension. You set it to **1** to override the default of 0, which prevents a Notification Service app extension from running.
2. `attachment-url` resides outside of the main payload, and is of your own design; the key name and content are not dictated by the user notification services. You'll write code in the extension to grab this and use it to load an image in the notification.

With the content in mind, it's time to start creating the Notification Service extension to load the `content-url` and build an attachment with it.

Select **File\New\Target** in Xcode, and choose the **iOS\Application Extension\Notification Service Extension** template. Name it **ServiceExtension**, make sure your correct **Team** is selected, select **Swift** as the Language, and hit **Finish**. If prompted, choose to **Activate** the scheme.

This will create a target called **ServiceExtension**. It will also add the following files to your project:

![width=40% bordered](./images/service-extension.png)

Take a look at **NotificationService.swift**, which contains a class `NotificationService` that inherits from `UNNotificationServiceExtension`. `UNNotificationServiceExtension` is the central class for Notification Service extensions, and it contains two important methods overridden in the template code:

1. **didReceive(_:withContentHandler)** is called when a notification is received and routed to the extension, and is given a limited amount of time to modify the notification contents. It accepts a `UNNotificationRequest`, from which it creates `bestAttemptContent`, a mutable copy of the notification content. The template unwraps this, appends `[modified]` to the end of the title, then calls the content handler, passing the updated content.
2. **serviceExtensionTimeWillExpire()** is called to provide a best attempt at updating notification content in cases where `didReceive(_:UNNotificationServiceExtension)` doesn't return quickly enough. The template contains a property `bestAttemptContent` that `didReceive(_:UNNotificationServiceExtension)` uses while updating content. Here, `serviceExtensionTimeWillExpire()` unwraps `bestAttemptContent` and sends it along to the content handler.

You'll modify this code to handle downloading the `attachment-url`. First, add the following import to the top of the file:

```swift
import MobileCoreServices
```

You'll need this for referencing a file type constant in just a moment.

In **didReceive(_:withContentHandler)**, delete the template code inside the `if let bestAttemptContent = bestAttemptContent` block. Add the following in its place:

```swift
// 1
guard let attachmentString = bestAttemptContent
  .userInfo["attachment-url"] as? String,
  let attachmentUrl = URL(string: attachmentString) else { return }

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

1. This gets the string value for `attachment-url` found in `userInfo` of the request content copy. It then creates a URL from this string and saves it in `attachmentUrl`. If this guard isn't successful, it bails out early with a return.
2. `session` is an instance of `URLSession` used when creating a `downloadTask` to get the image at `attachmentUrl`. In the completion handler, an error is printed on failure.
3. On success, a `UNNotificationAttachment` is created using the `attachmentString` as a unique identifier and the local `url` as the content. `UNNotificationAttachmentOptionsTypeHintKey` provides a hint as to the file type; in this case, `kUTTypePNG` is used as the file is known to be a PNG. The resulting attachment is set on `bestAttemptContent`.
4. The `completionHandler` is called, passing over the modified notification content. This signifies the extension's work is done, and sends back the updated notification. This must be done whether or not the attempt was successful. If unsuccessful, the original request is sent back.
5. Once the `downloadTask` is defined, it kicks off with `resume()`. This leads to the `attachmentDownloadTask` `completionHandler` executing on completion, which in turn calls the `contentHandler` to complete processing.

`serviceExtensionTimeWillExpire()` is already in good shape with the template code. It will return whatever you currently have in `bestAttemptContent`.

Build and run the **ServiceExtension** scheme on your device, making sure to run with **cuddlePix**. Now return to **Pusher** where you should have already copied the new payload containing `attachment-url`. Hit **Push** and you should see a remotely-sourced cuddle, complete with an image of something truly beautiful:

![width=40% bordered](./images/remote-push-content.png)

The Notification Service extension intercepted the remote push, downloaded the image in the URL provided in the payload and attached it to the notification. Pretty cool!

## Where to go from here?

In this chapter, you got up close and personal with some cuddly cacti while checking out all the new features in notifications.

You learned how to create custom notification interfaces, respond to actions in Notification Content extensions and the app, query and modify existing notifications, and enhance remote notifications with Notification Service extensions. I imagine you've already come up with some ideas on your own to enhance your apps with these basic concepts.

For more detail on any of these topics, be sure to check out **Apple's UserNotifications API Reference** at [apple.co/29F1nzE](http://apple.co/29F1nzE)

Also check out the great WWDC 2016 videos that cover all of these new features:

- Advanced Notifications (Session 708)—[apple.co/29t7c6v](http://apple.co/29t7c6v)
- Introduction to Notifications (Session 707)—[apple.co/29Wv6D6](http://apple.co/29Wv6D6)
