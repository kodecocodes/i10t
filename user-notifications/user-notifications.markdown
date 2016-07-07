## user-notifications

## Introduction

Remote push notifications were released way back in iOS 3, followed by local notifications in iOS 4. Looking through your most used apps, many of them likely leverage one or both of these types of User Notifications. They are undoubtedly useful for keeping users engaged in an app, up to date, and in near real time communication with others.

For such an integral feature, they haven't change all that much over the years. iOS 8 introduced the ability to implement custom actions in your application triggered by buttons in the notification. iOS 9 added text as another custom action input.

With iOS 10, Apple has made sweeping changes, opening up notificaitons to developers. 

TODO: flesh out these descriptions

- Media attachments
- Custom notification UIs  
- Query and modify status
- service extensions

In this chapter, you'll explore all of these features.

TODO: any prerequesites?

## Getting Started

The sample app for this chapter is **cuddlePix**, with the aim of cheering people up with visually rich notifications containing pictures of cuddly cacti *. When complete, it will act as a management dashboard for notification status and configuration data, as well as a scheduler for local notifications. It will also define custom notifications complete with custom actions.

> **Note**: While CuddlePix employs only the most cuddly digital cacti, remember to use caution when cuddling a real cactus. Real world prototyping of CuddlePix indicated that some cacti can be quite painful.

Open the starter project for this chapter, then build and run. You'll be greeted by an empty table view that will eventually house the notification status and configuration info. 

Tap the **+** bar button, and you'll see an interface for scheduling multiple local notifications over the hour, or a single one in 5 seconds. Right now, these don't do anything, but you'll set them up shortly.

Take a few minutes to explore the project. **NotificationTableViewController.swift** is the table view controller and displays a sectioned table using a datasource built from a struct and protocol found in **TableSection.swift**. **ConfigurationViewController.swift** manages the view that schedules notifications, centered around a stubbed out method `scheduleRandomNotification(inSeconds:completion:)` that will ultimately create and schedule notifications.

In the **Images** folder, you'll see some beautiful cactus images that you'll display in notifications. **Main.storyboard** defines the simple UI you've already seen in full while testing the app.

TODO: some segue

## User Notifications Framework

Gone are the days of handling notifications via your application delegate. Enter **UserNotifications.framework**, which does everything its predicesor did, while also enabling all of the new user notification functionality like attachments, service extensions, foreground notifications, and more.

The core of the new framework is `UNUserNotificationCenter`, which is accessed via a singleton. It manages user authorization, defines notification and associated actions, schedules local notifications and provides a management interface for existing notifications.

You'll start by setting up authorization. Open **NotificationTableViewController.swift** and add the following to `viewDidLoad()`, just below the call to super:

```swift
UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (granted, error) in
  if granted {
    self.loadNotificationData()
  } else {
    print(error?.localizedDescription)
  }
}
```

`UNUserNotificationCenter.current()` returns the singleton user notification center on which you call `requestAuthorization(options:completionHandler:)` to request authorization. You pass in an array of `UNAuthorizationOptions` indicating what options you're requesting—in this case `alert` and `sound` notifications. If access is granted, you call the currently stubbed out `loadNotificationData()` and otherwise you print the passed error.

Build and run, and you'll see an authorization prompt as soon as the NotificationTableViewController loads.

![bordered iphone](./images/notification-prompt.png)

### Notification Scheduling

Now that you have permission, it's time to take this new framework for a spin by scheduling notifications!

Open **ConfigurationViewController.swift** and take a look at how `scheduleRandomNotification(inSeconds:completion:)` is used. `handleCuddleMeNow(_:)` is triggered when the **Cuddle me now!** button is pressed and passes `scheduleRandomNotification(inSeconds:completion:)` a delay of 5 seconds. `scheduleRandomNotifications(number:completion:)` is triggered by the **Schedule** button, and calls `scheduleRandomNotification(inSeconds:completion:)` with various delays to space out repeat notifications over an hour.

Right now `scheduleRandomNotification(inSeconds:completion:)` obtains the URL of a random image in the bundle, but it doesn't yet schedule a notification.

To create a local notification, you need to provide some content and a trigger condition. Add the following just above the call to `completion()`:

```swift
// 1
let content = UNMutableNotificationContent()
content.title = "New cuddlePix!"
content.subtitle = "What a treat"
content.body = "Cheer yourself up with a hug 🤗"
//TODO: Add attachment

// 2
let trigger = UNTimeIntervalNotificationTrigger(timeInterval: inSeconds, repeats: false)
```

This code does the following:

1. You create a `UNMutableNotificationContent`, which defines what is displayed on the notification—in this case, you're setting a `title`, `subtitle` and `body`. This is also where you'd set things like badges, sounds and attachments. As the comment teases, you'll add an attachment here soon.
2. A `UNTimeIntervalNotificationTrigger` simply needs to know when to fire, and if it should repeat. You're passing through the `inSeconds` parameter for the delay, and creating a one time notification. User notifications can also be triggered from location or calendar triggers.

Next up, you need to create the notification request and schedule it. Replace the `completion()` call with the following:

```swift
// 1
let request = UNNotificationRequest(identifier: randomImageName, content: content, trigger: trigger)

// 2
UNUserNotificationCenter.current().add(request, withCompletionHandler: { (error) in
  if let error =  error {
    print(error)
  }
  completion()
})
```

Here's the breakdown of what this does:

1. You create a `UNNotificationRequest` from the `content` and `trigger` you created above. It also requires a unique identifier that you can use later to manage the request. In this case, you set it to the name of the randomly selected image.
2. `add(_:withCompletionHandler)` is called on your shared user notification center to add your `request` to the notification queue. In the completion handler, you print an error if one exists. You then call the passed `completion()` closure, which ultimately notifies its delegate (the `NotificationTableViewController`) that a refresh of pending notifications is necessary. You'll learn more about what `NotificationTableViewController` is doing later in the chapter.

Build and run, tap the **+** bar item, tap **Cuddle me now!** then quickly background the application with **Command + Shift + H**. Five seconds after the notification was added, you'll see the notification banner complete with your custom content!

![iphone](./images/first-notification.png)

### Adding an Attachment

It's seems a bit wasteful to have a bunch of beatiful cactus images and only use their URLs as notification identifiers. How about actually displaying the images on the notification? Hopefully you saw this coming.

Back in `scheduleRandomNotification(inSeconds:completion:)` add the following just below the `imageURL` declaration:

```swift
let attachment = try! UNNotificationAttachment(identifier: randomImageName, url: imageURL, options: .none)
```

A `UNNotificationAttachment` is an image, video, or audio attachment that gets presented with a notification. It requires an identifier, for which you've used the `randomImageName` string, as well as a URL pointing to a local resource of a supported type. This method throws if the media is not readable or not supported—because you've included these images in your bundle it's safe to disable error propagation with a `try!`.

Next, after the `content` declaration, add:

```swift
content.attachments = [attachment]
```

You're setting `attachments` to the single image attachment wrapped in an array.

Build and run, initiate a notification with **Cuddle me now!** then return to home screen as you did before. You'll now be greeted with a notification containing a random cactus picture on the right side of the banner. Force tap, and you'll be treated to an expanded view of the huggable cactus. 

TODO: figure out images and instructions on how to test this for the user
TODO: possibly do the try! properly if there is room
TODO: note about copying image to the system

### Foreground Notifications

The **UNUserNotificationCenterDelegate** protocol defines methods for handling incoming notifications and their actions. It enables another great enhancement to iOS 10 notifications—the ability to display system notification banners in the foreground. 

To do this, open **AppDelegate.swift** and add the following at the end of the file:

```swift
extension AppDelegate: UNUserNotificationCenterDelegate {
  func userNotificationCenter(_ center: UNUserNotificationCenter,
      willPresent notification: UNNotification,
      withCompletionHandler completionHandler:
      (UNNotificationPresentationOptions) -> Void) {
        NotificationCenter.default().post(name: 
          userNotificationReceivedNotificationName, object: .none)
        completionHandler(.alert)
  }
}
```

This extends `AppDelegate` to adopt the UNUserNotificationCenterDelegate protocol. The protocol's optional method **userNotificationCenter(_:willPresent:withCompletionHandler:)** is called when a notification is received in the foreground, and provides the opportunity to act upon it. 

TODO: If there is room, make the notification change later, after you've set up the table
`userNotificationReceivedNotificationName` is a system notification that cuddlePix uses to reload a table that you'll later populate with user notification status. You post it here because you know a notification was just received, and you'll want to reflect the new status. 

Finally, you call the `completionHandler()`, which determines if and how the alert should be displayed to the user. The `.alert` notification option indicates you want to present the alert, but no badge updates or sounds. You could also choose to suppress the alert here by passing an empty array.

In `application(_:didFinishLaunchingWithOptions:)`, add the following just before the `return true`:

```swift
UNUserNotificationCenter.current().delegate = self
```

This sets your AppDelegate as the `UNUserNotificationCenterDelegate` so that user notification center will pass along this message when a foreground notification is received.

Build and run, and schedule a notification as you've done before. This time, leave CuddlePix in the foreground and you'll see a system banner appear in app! 

![bordered iphone](./images/in-app-banner.png)

Think briefly now about all the times you had to build your own banner for these situations. Take a deep breath—that's all in your past now.

![width=40%](./images/hero-ragecomic.png)

## Notifications Management

As an iOS user, you've probably experienced the frustration of clearing out countless missed and outdated notifications. You might have an app posting updates on the score of a game, and if you've been away you likely only care about the latest one. With iOS 10, developers finally have the information and access necessary to improve this experience.

The `UNUserNotificationCenter` provides accessor methods to read an app's notification settings (the user permissions), so you can keep up to date on changes made. More excitingly, it provides you read and *delete* accessors for pending and delivered notifications. This means you can remove those outdated notifications, freeing your users from a wall of unwanted notifications.

Finally, you have the ability to read and and set notification categories, which you'll learn about a little later in this chapter.

### Notification Center Queries 
TODO: settings, pending, delivered

You'll kick this off by obtaining the notification settings and displaying them in cuddlePix's initial table view.

Open **NotificationTableViewController.swift** and find `loadNotificationData(callback:)`, which gets called when the table is refreshed, authorization is returned, a notification is scheduled or a notification is received. Right now, it just reloads the table. Add the following just below the `group` declaration near the top:

```swift
// 1
let notificationCenter = UNUserNotificationCenter.current()
let dataSaveQueue = DispatchQueue(label:
  "com.raywenderlich.CuddlePix.dataSave")

// 2
group.enter()
// 3
notificationCenter.getNotificationSettings { (settings) in
  let settingsProvider = SettingTableSectionProvider(settings: settings, name: "Notification Settings")
  // 4
  dataSaveQueue.async(execute: {
    self.tableSectionProviders[.settings] = settingsProvider
    group.leave()
  })
}
```

This code queries for notification settings and updates the table datasource involved in their display. Here are the details:

1. You create `notificationCenter` to reference your notification center more concisely. Then you create a `DispatchQueue` that will be used to prevent concurrency issues when updating the table view data source.
2. First you enter a dispatch group that will be used to ensure all data fetches complete before you refresh the table. Note the project already refreshes in a group.notify(callback:) closure for this reason. 
3. You call `getNotificationSettings(callback:)` to fetch current notification settings from the notification center. The results are passed to the callback closure in `settings`, which you use to initialize a `SettingTableSectionProvider`. SettingTableSectionProvider was included in the starter and extracts interesting information from the provided UNNotificationSettings for presentation in a table view cell.
4. Using the `dataSaveQueue`, you asynchronously update `tableSectionProviders` with the just created `settingsProvider` for it's settings section. The table management is all provided by the starter project, and setting the provider is all you need to do for the data to be provided to the table view. Finally, you leave `group` to release your hold on the dispatch group.

Build and run, and you'll now see a **Notification Settings** section in the table view that represents the current status of notification settings for cuddlePix. To test it out, go to iOS Settings, then find cuddlePix and toggle some of the switches. Once done, return to cuddlePix, pull to refresh, and you'll see the updated status.

![bordered iphone](./images/notification-settings.png)

Knowing your users settings can help you know how to best present notifications. 

It's just as easy to fetch information about pending and delivered notifications. Just below the closing bracket of the `getNotificationSettings(completionHandler:)` closure, add the following:

```swift
group.enter()
notificationCenter.getPendingNotificationRequests { (requests) in
  let pendingRequestsProvider = PendingNotificationsTableSectionProvider(requests: requests, name: "Pending Notifications")
  dataSaveQueue.async(execute: {
    self.tableSectionProviders[.pending] = pendingRequestsProvider
    group.leave()
  })
}

group.enter()
notificationCenter.getDeliveredNotifications { (notifications) in
  let deliveredNotificationsProvider = DeliveredNotificationsTableSectionProvider(notifications: notifications, name: "Delivered Notifications")
  dataSaveQueue.async(execute: {
    self.tableSectionProviders[.delivered] = deliveredNotificationsProvider
    group.leave()
  })
}
```

You've implemented two additinal fetches in a manner identical to the settings fetch, updating their respective `tableSectionProviders`. `getPendingNotificationRequests(completionHandler:)` fetches notifications that are pending—scheduled but not yet delivered. `getDeliveredNotifications(completionHandler:)` fetches those that have been delivered, but not yet deleted. 

Now, build and run. Schedule a notification, and you'll see it appear under **Pending Notifications**. Once delivered, pull to refresh and you'll see it under **Delivered Notifications**. 

Note that delivered notifications remain until they are deleted. Test this by expanding a notification when the banner appears then dismissing it. You can also delete a notification by pulling down notification center and clearing it from the **Missed** list.

![bordered iphone](./images/notification-status.png)

There are some great applications for this. A very compelling one is to avoid sending repeat notifications if an identical one is still in delivered status. 

### Modify Notifications 
deletion of a pending notification

Being able to query notifications is even more exciting combined with the fact that you can update or delete them. Consider an app that reports sports scores. Rather than literring notification center with outdated score alerts, you could continually update the same notification, bumping it to the top of the notification list each time for visibility into the update.

Updating a notification is straightforward. You create a new UNNotificationRequest with the same identifier as the existing notification, pass it your updated content, and add it to UNUserNotificationCenter. Once the trigger conditions are met, it will overwrite the existing notification with the matching identifier.

For cuddlePix, notifications are serious business. Consider a case where you scheduled 10 notifications, when you meant to do just 5. Too much of a good thing can get pretty prickly, so you're going to work on the ability to delete pending notifications.

Go to **NotificationTableViewController.swift** and you'll see an extension at the end where the table view editing methods are already implemented. Deletion is enabled for rows in the **pending** section, but commiting the delete currently doesn't do anything.

Add the following to `tableView(_:commit:forRowAt:)`:

```swift
// 1
if let section = NotificationTableSection(rawValue: indexPath.section)
  where editingStyle == .delete && section == .pending {
  
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
}
```

This method is called when an insertion or deletion is attempted on the `tableView`. Here is what your code does:

1. You check that the selected cell came from the `pending` section of the table and that the attempted operation was a `delete`. If so, we want to proceed with deleting the notification.
2. In the guard, you grab a reference to the `tableSectionProviders` datasource object associated with pending notifications. From this, `request` is set to the `UNNotificationRequest` represented by the selected cell.
3. You call `removePendingNotificationRequests(withIdentifiers:)` on the user notification center to delete the notification matching your request's identifier. Then you call `loadNotificationData(callback:)` to refresh the datasource, and you delete the row in the callback closure.

Build and run, create a new notification, and swipe the cell in the **Pending Notifications** section to reveal the delete button. Before the notification is delivered, tap **Delete**. Because you've deleted it from the user notification center before delivery, the notification will never be shown, and the cell will be deleted.

![bordered iphone](./images/delete-pending-notification.png)

## Custom Notifications
Create notification content extension

TODO: add some kind of intro / theory on extensions.  This should really be an entire theory section.  Also explain what UNNotificationContentExtension protocol is (and briefly  mention its methods) and mention audio & video playback.  https://developer.apple.com/reference/usernotificationsui/unnotificationcontentextension

Another major change to notifications in iOS 10 is the introduction of Notification Content extensions. They allow you to provide a custom interface for the expanded version of your notifications.

Like all extensions, they come with some limitations. 

### Notification Content Extensions

Select **New -> Target** in Xcode and then in the iOS section choose **Application Extension**. In the detail pane, select **Notification Content** and then select **Next**. Enter **ContentExtension** in the Product Name, choose Swift as the language, and select **Finish**. 

![width=90% bordered](./images/content-extension-setup.png)

You've created a new target and project group, both named **ContentExtension**. In the group you have a view controller, storyboard, and plist necessary for configuring the extension. You'll visit each of these in turn while implementing the extension.

![width=40% bordered](./images/content-extension-group.png)

Open **MainInterface.storyboard** and take a look at what the template provided. You'll see a single view controller of type `NotificationViewController`—the controller created when you generated the extension. Inside is a single view with a *Hello World* label connected to an outlet in the controller. 

For cuddlePix, your goal is to create something similar to the default expanded view, but just a tad more cuddly. A cactus picture with a hug emoji in the corner should do quite nicely.

To start, delete the existing label and change the view's background color to white. Set the view height to 320 to allow yourself more room to work. Add an Image View and set the constraints pictured below.

![width=50% bordered](./images/imageview-constraints.png)

Select the Image View and go to the Attributes Inspector. In the View section, set Mode to **Aspect Fill** to ensure as many pixels as possible are filled with beautiful cactus pictures.
![width=50% bordered](./images/aspect-fill.png)

Clean things up by selecting the **Resolve Auto Layout Issues** button in the lower right and selecting **Update Frames** in the *All View in Notification View Controller* section. This will cause your Image View to resize to match the constraints and the autolayout warnings should resolve.

Next drag a label just under the image view in the Document Outline pane on the left-hand side of the Interface Builder window. Pin it to the bottom left of the view with the following constraints:

![width=50% bordered](./images/label-constraints.png)

If you've been paying any attention, you'll surely guess what goes in this label. The hug emoji! Use **Control + Command + Spacebar** to bring up the picker, and select the 🤗.

![width=50% bordered](./images/emoji-picker.png)

Set the fontsize of the label to 100 so your hug gets a bit more visibility. **Update Frames** again to resize the label to match the new content.

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

![width=90% bordered](./images/imageview-outlet.png)

With the interface done, close the storyboard and open **NotificationViewController.swift** in the Standard editor.

Remember that `didReceive(_:)` is called when a notificaiton arrives, and is where you should do any necessary configuration of the view. For this extension, that means populating the imageView with the cactus picture from the notification. Add the following to `didReceive(_:)`: 

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

1. The passed UNNotification (`notification`) contains a reference to the original UNNotificationRequest (`request`) that generated it. A request contains UNNotificationContent (`content`) that, among other things, contains an array of UNNotificationAttachments (`attachments`). In a guard, you grab the first of those attachments—you know you've only included one—and you place it in `attachment`.
2. Attachments in the user notification center live outside of your app's sandbox, and thus they must be accessed via security-scoped URLs. `startAccessingSecurityScopedResource()` makes the file available to the extension when it successfully returns, and `stopAccessingSecurityScopedResource()` is required to indicate you're finished with the resource. In between, you load `imageView` using the file pointed to by this URL.

The extension is all set. But when a notification triggers for cuddlePix, how is the the system supposed to know what, if any, extension to send it to?

![width=40%](./images/notification-gnomes.png)

Gnomes are a good guess, but they're notoriously unreliable. Instead, user notification center relies on a key defined in the extension's plist to identify the types of notifications it should handle. 

Open **Info.plist** in the ContentExtension group and expand `NSExtension`, then `NSExtensionAttributes` to reveal **UNNotificationExtensionCategory**. This key takes a string (or array of strings) identifying the notifications it should handle. Enter **newCuddlePix** here, which you'll later provide in the content of your notification requets.

![width=90% bordered](./images/content-extension-plist.png)

> **Note**: In the same plist dictionary, you'll see another required key—**UNNotificationExtensionInitialContentSizeRatio**. Because the system starts to present a notification before loading your extension, it needs something to base the initial size on. You provide a ratio of the notification's height to its width, and the system will animate any expansion or contraction once the extension view loads.
> 
> cuddlePix's extension view frame is based on fixed constraints of 320 x 320, so in this case you leave it at the default ratio of 1.

The operating system knows notifications using the *newCuddlePix* category should go to your extension, but you haven't yet set this category on your outgoing notifications. Open **ConfigurationViewController.swift** and find `scheduleRandomNotification(inSeconds:completion:)` where you generate UNNotificationRequests. Add the following line after `content` is declared:

```swift
content.categoryIdentifier = newCuddlePixCategoryName
```

The UNNotificationRequest that gets created in this method will now use `newCuddlePixCategoryName` as a `categoryIdentifier` for its content. `newCuddlePixCategoryName` is a string constant defined in the starter that matches the one you placed in the extension plist—*newCuddlePix*. 

When the system prepares to deliver a notification, it will check that notification's category identifier and try to find an extension registered to handle it. In this case, that will be the extension you just created.

> **Note**: For a remote notification to invoke your content extension, you'd need to add this same category identifier as the value for the `category` key in the payload dictionary.

Make sure you have the **CuddlePix** scheme selected and then build and run. Next, switch to the **ContentExtension** scheme then build and run again. Select **CuddlePix** and **Run** when prompted what to run the extension with, as that's where you'll generate the notification.

![width=80% bordered](./images/run-extension-prompt.png)

In cuddlePix, generate a new notification with **Cuddle me now!**. When the banner appears, expand it either by force touching on a compatible device, or selecting the notification and dragging down in the simulator. You'll now see the new custom view from your extension!

![iphone bordered](./images/content-extension-presented.png)

> **Note**: You'll notice that the custom UI you designed is presented above the default banner content. In this case, it's apporpriate, as your custom view didn't implement any of this text.
> 
> However, if you shifted the titles and messages to the extension, you could easily remove the system generated banner at the bottom. This is done by adding the `UNNotificationExtensionDefaultContentHidden` key to your extension plist with a value of true.


### Notification Action Handling

So far, the custom notification for cuddlePix isn't all that different from the default. However, a custom view does provide quite a lot of opportunity depending on your needs. For example, a ride sharing app could provide a map of your ride's location and a sports app could provide a full box score.

Where extensions get a chance to shine in cuddlePix, however, is interactivity. While content extensions do not allow touch handling—the touches are not passed to the controller—they do provide interaction through custom action handlers.

Prior to iOS 10, custom actions were forwarded on to the application and handled in an application delegate method. This worked great for things like responding to a message where there wasn't a need to see the results of the action.

Because content extensions can handle actions directly, that means the notification view can be updated with results. For instance, when an invite is accepted, you could display an updated calendar view right there in the notification.

The driver of this is the new **UNNotificationCategory**, which uniquely defines a notification type and references actions the type can act upon. The actions are defined with **UNNotificationAction** objects that in turn uniquely define actions. When configured and added to the UNUserNotificationCenter, these objects help direct actionable notifications to the right handlers in your app or extensions.

#### Defining the Action

TODO: note that actions can be used without extensions as well

For cuddlePix, your goal is to spread cheer, and what better way to do that than an explosion of stars over a cactus? You're now going to wire up an action for starring a cactus, which will kick off an animation in your custom notification view.

To start, you need to register a notification category and action in the app. Open **AppDelegate.swift** and add the following method in `AppDelegate`:

```swift
private func configureUserNotifications() {
  // 1
  let starAction =
    UNNotificationAction(identifier: "star",
                         title: "🌟 star my cuddle 🌟", options: [])
  let dismissAction =
    UNNotificationAction(identifier: "dismiss",
                         title: "Dismiss", options: [])
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

1. A `UNNotificationAction` has two jobs—it provides data used in displaying an action to the user, and it uniquely identifies actions so that controllers can act upon them. It requires a title for the first job and a unique identifier string for the second. Here you've created a `starAction` and a `dismissAction` with recognizable identfiers and titles.
2. You defined a `UNNotificationCategory` with the unique identifier string constant set up for this notification (and used in your extension plist). You've passed an array containing your newly created UNNotificationActions to `actions` and `minimalActions`. The `actions` parameter requires all custom actions you want displayed in order of display while `minimalActions` needs to contain the two most important actions to be displayed when space is limited.
3. You pass the new `category` to the UNUserNotificationCenter with `setNotificationCategories()`, which accepts an array of categories and registers cuddlePix as supporting them.

> **Note**: You're probably shouting as you read this that the notification *already* shows a dismiss option when expanded. That *is* the default behavior for a content extension when no actions are provided. But, as soon as you use a custom action, only those you create will be shown—so you need to create your own dismiss action here.

In `application(_:didFinishLaunchingWithOptions:)` add the following just before the `return`:

```swift
configureUserNotifications()
```

This ensures category registration happens as soon as the app is started.

Now, build and run the **CuddlePix** scheme, followed by the **ContentExtension** scheme which you should choose to run with cuddlePix. Create a notification and expand it with force touch or a drag down when it arrives. You'll see buttons for your new actions at the bottom of the notification.

![iphone bordered](./images/notification-actions.png)

Try selecting **star my cuddle**, and the notification will simply dismiss, because you haven't yet implemented the action. 

#### Extension Response Handling and Forwarding

Notification extensions get first crack at handling an action response. In fact, they determine whether or not to forward the request along to the app when they finish.   

Open **NotificationViewController.swift** and you'll see your controller already adheres to `UNNotificationContentExtension`, which provides an optional method for handling responses. Add the following to `NotificationViewController`:

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

1. When setting up your UNNotificationActions, you gave the star action an identifier of *star*, which you check here to catch responses of this type. Inside, you have a `TODO` for implementing the star animation that you'll soon revisit. You let the animation continue for 2 seconds via `DispatchQueue.main.after` before calling the completion closure.
2. `completion` takes an enum value defined by `UNNotificationContentExtensionResponseOption`. In this case, you've used `dismissAndForwardAction`, which dismisses the notification and allows the app an opportunity to act on the response. (Alternative values include `doNotDismiss`, which keeps the notification on screen and `dismiss`, which doesn't pass the action along to the app after dismissal)
3. For the dismiss action, the extension dismisses immediately and forwards the action along to the app to handle.

Your current implementation of the star action leaves something to be desired—specifically, the stars! The starter project already contains everything you need for this animation, but it's not yet available to the content extension target. 

In the project navigator, open the **Star Animation** group and select both files inside. 
![width=40% bordered](./images/star-animator.png)

Open the file inspector in the utilities pane of Xcode, and select **ContentExtension** under **Target Membership**.
![width=40% bordered](./images/target-membership.png)

Back in **NotificationViewController.swift**, replace `// TODO Show Stars` with:

```swift
imageView.showStars()
```

This uses a UIImageView extension defined in the **StarAnimator.swift** file you just added to the target. `showStars()` uses core animation to create a shower of stars over the ImageView.

Build and run the extension and the app as you've done before. Now select **star my cuddle** and you'll see an awesome star shower over your cactus. 

![iphone bordered](./images/star-shower.png)

Your extension has done it's job, and the cuddle has been starred. But recall that `dismissAndForwardAction` was called in teh completion closure—where is it getting forwarded?

The answer is it forwards to the app, but right now the `UNUserNotificationCenterDelegate` in cuddlePix isn't listening. Open **AppDelegate.swift** and add the following method to the `UNUserNotificationCenterDelegate` extension:

```swift
func userNotificationCenter(_ center: UNUserNotificationCenter,
                            didReceive response: UNNotificationResponse,
                            withCompletionHandler completionHandler: () -> Void) {
  print("Response received for \(response.actionIdentifier)")
  completionHandler()
}
```

`userNotificationCenter(_:didReceive:withCompletionHandler` is called to let you know a notification action was selected. In it, you print out the `actionIdentifier` of the response, simply to confirm things are working as they should. You then call `completionHandler()` which accepts no arguments and is required to notify user notification center that you're done handling the action.

Build and run the app and content extension, and trigger a notification. Expand the notification and select either response. Search the Debug Console and you should see responses like the below appear as soon as the notification dismisses (depending on the action chosen):

```swift
Response received for dismiss
Response received for star
```

To recap, here is the flow of messages being passed around when you receive a notification in the foreground and respond to an action in a content extension:

1. **userNotificationCenter(_:willPresent:withCompletionHandler:)** is called in the UNUserNotificationCenterDelegate (only in the foreground), and determines if the notification should present.
2. **didReceive(_:)** is called in the the UNNotificationContentExtension and allows the opportunity to configure the custom notification's interface.
3. **didReceive(_:completionHandler:)** is called in the UNNotificationContentExtension after the user selects a response action.
4. **userNotificationCenter(_:didReceive:withCompletionHandler:)** is called in the UNUserNotificationCenterDelegate if the UNNotificationContentExtension passes it along via the `dismissAndForwardAction` response option.

## Service Extensions
TODO: Very high level setup (Pusher, enable push notifications)

Beleive it or not, another major feature awaits in the form of service extensions. These allow you to intercept remote notifications and modify the payload. A common use case would be to add a media attachment to the notification, or decrypt content.

cuddlePix doesn't really demand end to end encryption, so instead you're going to add an image attachment to incoming remote notifications. But first, you need to set up a development environment.

Because the simulator cannot register for remote notifications, you'll need a device with iOS 10 to test. 

You'll also need a way to send test pushes, for which you'll use a popular open source tool called **NWPusher**. It sends push notifications directly to the Apple Push Notification Service (APNS). To start, follow the instructions in the **Installation** section of their GitHub readme to get the app running - https://github.com/noodlewerk/NWPusher.

NWPusher's readme also has a **Getting Started** section that guides you through creating the required SSL 

### Creating and Configuring a Service Extension 
download attachment

## Where to Go From Here
