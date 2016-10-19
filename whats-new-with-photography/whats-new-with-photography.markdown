```metadata
author: "By Rich Turton"
number: "12"
title: "Chapter 12: What’s New with Photography"
```
# Chapter 12: What’s New with Photography

iOS 10 introduced several improvements to taking and editing photos and videos. For the first time, your apps can take and edit live photos, and there is a new photo capture pipeline which allows you to give rich UI responses for various stages of image capture and processing. 

In this chapter you’ll learn about the new photo capturing methods by creating a selfie-taking app. You’ll then level up by adding live photo capabilities, and finish off by editing live photos. You’ll be building the app from scratch, so you’ll also find out about lots of pre-existing `AVFoundation` goodies involved in photography. 

## Smile, you’re on camera! 

For this project, you’ll need to run on a device with a front-facing camera — there's no camera on the simulator. raywenderlich.com readers are a good-looking bunch of people, so this app will only allow you to use the front camera — when you look this good, why would you want to take pictures in the other direction? For the later sections, you’ll also need a device that supports Live Photos. 

Create a new Xcode project using the **Single View Application** template, named **PhotoMe**. Make it for **iPhone** only. Leave the Core Data, Unit Tests and UI Tests boxes unchecked. Choose your team in the **Signing** section in the target’s **General** settings tab to allow you to run on a device, and untick all of the **Device Orientation** options except **Portrait**. Using a single orientation keeps things simple for the demo.

Right-click on **Info.plist** and choose **Open As > Source Code**. Paste the following values just above the final `</dict>` tag:

```none
<key>NSCameraUsageDescription</key>
<string>PhotoMe needs the camera to take photos. Duh!</string>
<key>NSMicrophoneUsageDescription</key>
<string>PhotoMe needs the microphone to record audio with Live Photos.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>PhotoMe will save photos in the Photo Library.</string>
```

This is required to access to the camera, microphone and photo library. 

`AVFoundation` contains a specialist `CALayer` subclass, `AVCaptureVideoPreviewLayer`, which you can can use to show the user what the camera is currently seeing. There's no support for this in Interface Builder, so you need to make a `UIView` subclass to deal with it. 

Create a new file, using the **Cocoa Touch Class** template. Name the new class **CameraPreviewView**, and make it a subclass of **UIView**. Replace the contents of the file with the following: 

```swift
import UIKit
import AVFoundation
import Photos

class CameraPreviewView: UIView {
//1
override static var layerClass: AnyClass {
return AVCaptureVideoPreviewLayer.self
}
//2
var cameraPreviewLayer: AVCaptureVideoPreviewLayer {
return layer as! AVCaptureVideoPreviewLayer
}
//3
var session: AVCaptureSession? {
get {
return cameraPreviewLayer.session
}
set {
cameraPreviewLayer.session = newValue
}
}
}
```

Here’s the breakdown:

1. Views have a `layerClass` class property which can specify a specific `CALayer` subclass to use for the main layer. Here, you specify `AVCaptureVideoPreviewLayer`. 
2. This is a convenience method to give you a typed property for the view’s layer. 
3. The capture preview layer needs have an `AVCaptureSession` to show input from the camera, so this property passes through a session to the underlying layer.

Open **Main.storyboard** and drag in a view. Drag the resizing handles to make the view touch the top, left and right sides of the scene. Use the pinning menu to pin it to those edges, then Control-drag from the view to itself to create an aspect ratio constraint. Edit this new constraint to give a 3:4 aspect ratio. 

With the new view selected, open the **Identity** Inspector and set the **Class** to **CameraPreviewView**. At this point your storyboard should look like this:

![width=80% bordered](images/BuildingCamera1.png)

Open the assistant editor and Control-drag into **ViewController.swift** to make a new outlet from the camera preview view. Name it **cameraPreviewView**.

Still in **ViewController.swift**, add the following `import` statement:

```swift
import AVFoundation
``` 

Then add these properties: 

```swift
fileprivate let session = AVCaptureSession()
fileprivate let sessionQueue = DispatchQueue(
label: "com.razeware.PhotoMe.session-queue")
var videoDeviceInput: AVCaptureDeviceInput!
```

An `AVCaptureSession` is the object that handles the input from the cameras and microphones. Most of the methods relating to capture and processing are asynchronous and can be handled on background queues, so you create a new queue to deal with everything session-related. The capture device input represents the actual camera / microphone that is capturing the audio and video.

Now add the following code to `viewDidLoad()`: 

```swift
//1
cameraPreviewView.session = session
//2
sessionQueue.suspend()
//3
AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo) {
success in
if !success {
print("Come on, it's a camera app!")
return
}
//4
self.sessionQueue.resume()
}
```

Here’s the breakdown: 

1. Pass through the capture session to the view so it can display the output.
2. Suspend the session queue, so nothing can happen with the session.
3. Ask for permission to access the camera and microphone. Both of these are required for live photos, which you’ll add later.
4. Once permission is granted, resume the queue. 

You’re almost ready to get your face on the screen. First, you need to configure the capture session. Add the following method to do this:

```swift
private func prepareCaptureSession() {
// 1
session.beginConfiguration()
session.sessionPreset = AVCaptureSessionPresetPhoto

do {
// 2
let videoDevice = AVCaptureDevice.defaultDevice(
withDeviceType: .builtInWideAngleCamera,
mediaType: AVMediaTypeVideo,
position: .front)
// 3
let videoDeviceInput = try 
AVCaptureDeviceInput(device: videoDevice)

// 4
if session.canAddInput(videoDeviceInput) {
session.addInput(videoDeviceInput)
self.videoDeviceInput = videoDeviceInput

// 5
DispatchQueue.main.async {
self.cameraPreviewView.cameraPreviewLayer
.connection.videoOrientation = .portrait
}
} else {
print("Couldn't add device to the session")
return
}
} catch {
print("Couldn't create video device input: \(error)")
return
}

// 6
session.commitConfiguration()
}
``` 

Here’s what’s happening above:

1. `beginConfiguration()` tells the session that you’re about to add a series of configuration changes, which are committed at the end. There are a series of presets that can be applied. [TODO: FPE: Do we need to expand on these presets here?]
2. Create a device representing the front facing camera.
3. Create a device input representing the data the device can capture.
4. Add the input to the session, and store it in the property you declared earlier.
5. Back on the main queue, tell the preview layer that you’ll be dealing with portrait only.
6. If everything went OK, commit all of the changes to the session. 

At the end of `viewDidLoad()`, call this new method on the session queue. This means it won’t get called until permission has been granted, and the main queue won’t be blocked while the configuration happens:

```swift
sessionQueue.async {
[unowned self] in
self.prepareCaptureSession()
}
```

Finally, you need to start the session running. Add this `viewWillAppear(_:)` implementation:

```swift
override func viewWillAppear(_ animated: Bool) {
super.viewWillAppear(animated)
sessionQueue.async {
self.session.startRunning()
}
}
```

`startRunning()` is a blocking call that can take some time to complete, so you call it on the dedicated queue created earlier. 

Build and run, grant permission for the camera, and you should see your lovely face on the device! 

![iPhone bordered](images/BuildAndRun1.png)

In this section you’ve created an **input**, which represents the front camera of your device, and a **session**, which handles the data coming from the input. Next up, you’re going to add a way of getting output from the session. 

## Taking a photo

New to iOS 10 is the `AVCapturePhotoOutput` class. This replaces `AVCaptureStillImageOutput`, which is deprecated in iOS 10. Learning about the cool new features of this class takes up the next few sections of this chapter. Add a new property to **ViewController.swift** to hold an output object:

```swift
fileprivate let photoOutput = AVCapturePhotoOutput()
```

The output has to be configured and added to the capture session. In `prepareCaptureSession()`, just before the `commitConfiguration()` call, add this code:

```swift
if session.canAddOutput(photoOutput) {
session.addOutput(photoOutput)
photoOutput.isHighResolutionCaptureEnabled = true
} else {
print("Unable to add photo output")
return
}
```

The `isHighResolutionCaptureEnabled` property sets up the output to generate full-size photos, as opposed to the smaller images that are used to feed the on-screen preview. You must set this to `true` _before_ the session has started running, otherwise the session has to reconfigure itself mid-flight, which will make the preview stutter and discard any photos that are in progress. 

Now that an output object is created and configured, there are three more steps necessary to actually take a photo: 

1. Add a “take photo” button to the UI so that the user can get their duck-face ready.
2. Create an `AVCapturePhotoSettings` object which contains the information about how the photo should be taken, such as the flash mode to use or other details.
3. Tell the output object to capture a photo, passing in the settings and a delegate object. 

First, you’ll take care of the UI. Open **Main.storyboard** and make things look a little more camera-like by setting the main view’s background color to black, and the **Global Tint** color to a tasteful orange using the File Inspector. Set the camera preview view's background color to black as well.

Drag in a **Visual Effect View With Blur** and pin it to the left, bottom and right edges of the main view. Set the **Blur Style** to **Dark**.

Drag a **button** into the visual effect view, and change the label to **Take Photo!**, with a font size of **20.0**. With the button selected, click the **Stack** button or choose **Editor > Embed In > Stack View** to create a vertical stack view. You’ll be adding more controls here as your camera gets more sophisticated, so a stack view is a good idea. 

Add constraints to center the stack view horizontally in the superview, then pin it to the **top** of the superview with a spacing of **5** and to the **bottom** with a spacing of **20**. Update any frames that Xcode complains about, and you should end up with something like this:

![width=60% bordered](images/BuildingCamera2.png)

Open the assistant editor and Control-drag to create an outlet and action for the button in **ViewController.swift**:

```swift
@IBOutlet weak var shutterButton: UIButton!
@IBAction func handleShutterButtonTap(_ sender: UIButton) {
}
```

The action is going to call a separate method, `capturePhoto()`. Add this in a new extension: 

```swift
extension ViewController {
fileprivate func capturePhoto() {
// 1
let cameraPreviewLayerOrientation = cameraPreviewView
.cameraPreviewLayer.connection.videoOrientation

// 2
sessionQueue.async {
if let connection = self.photoOutput
.connection(withMediaType: AVMediaTypeVideo) {
connection.videoOrientation =
cameraPreviewLayerOrientation
}

// 3
let photoSettings = AVCapturePhotoSettings()
photoSettings.flashMode = .off
photoSettings.isHighResolutionPhotoEnabled = true

}
}
}
```

This method creates the settings object mentioned earlier. Here’s the breakdown:

1. The output connection needs to know what orientation the camera is in. You could cheat here since the camera is fixed to portrait, but this is useful stuff to know.
2. Again, all work relating to the actual capture is pushed off onto the session queue. First, an `AVCaptureConnection` is obtained from the `AVCapturePhotoOutput` object. A connection represents a stream of media coming from one of the inputs, through the session, to the output. You pass the orientation to the connection. 
3. The photo settings is created and configured. For basic JPEG capture, there aren’t many things to configure.

Add a call to `capturePhoto()` from `handleShutterButtonTap(_:)`. 

[TODO: FPE: Do we need a code block for the above action?]

The app isn’t ready to take a photo yet. First, a little bit of theory.

Processing a captured photo takes a certain amount of time. You may have noticed when taking photos in the standard Camera app that you can hit the shutter button lots of times and it can take a while before the photos show up in the thumbnail preview. There’s a lot of work to be done on the raw data captured by the camera’s sensor before you get a JPEG (or RAW) file saved to disk with embedded EXIF data, thumbnails and so on. 

Because it’s possible (and indeed, desirable — your user doesn’t want to miss her perfect shot!) to take another photo without waiting for the first one to finish processing, it would get hopelessly confusing if the view controller was the photo output’s delegate. In each delegate method you’d have to work out which particular photo capture you were dealing with. 

To make things easier to understand, you will create a separate object whose only job is to act as the delegate for the photo output. The view controller will hold a dictionary of these delegate objects. It just so happens that each `AVCapturePhotoSettings` object is single-use only and comes with a unique identifier to enforce that, which you’ll use as a key for the dictionary. 

Create a new Swift file called **PhotoCaptureDelegate.swift**. Add the following implementation: 

```swift
import AVFoundation
import Photos

class PhotoCaptureDelegate: NSObject {
// 1
var photoCaptureBegins: (() -> ())? = .none
var photoCaptured: (() -> ())? = .none
fileprivate let completionHandler: (PhotoCaptureDelegate, PHAsset?) -> ()

// 2
fileprivate var photoData: Data? = .none

// 3
init(completionHandler: @escaping (PhotoCaptureDelegate, PHAsset?) -> ()) {
self.completionHandler = completionHandler
}

// 4
fileprivate func cleanup(asset: PHAsset? = .none) {
completionHandler(self, asset)
}
}
```

Here’s the explanation: 

1. You’ll supply closures to execute at key points in the photo capture process. These are when the capture begins and ends, then when the captured image has been processed and everything is complete. 
2. A property to hold the data captured from the output
3. `init` ensures that a completion closure is passed in; the other event closures are optional.
4. This method calls the completion closure once everything is completed. 

This diagram shows the various stages of the photo capture process: 

![width=100%](images/PhotoProcess.png)

Each stage is associated with delegate method calls. Some of these delegate calls are relevant to the view controller (hence the various closures), and some can be handled within the delegate object itself. The delegate methods aren’t mentioned specifically in the diagram because _they are the longest method signatures in the universe_, so there are comments indicating when each one is called. 

Add the following extension: 

```swift
extension PhotoCaptureDelegate: AVCapturePhotoCaptureDelegate {
// Process data completed
func capture(_ captureOutput: AVCapturePhotoOutput,
didFinishProcessingPhotoSampleBuffer 
photoSampleBuffer: CMSampleBuffer?, 
previewPhotoSampleBuffer: CMSampleBuffer?, 
resolvedSettings: AVCaptureResolvedPhotoSettings,
bracketSettings: AVCaptureBracketedStillImageSettings?,
error: Error?) {

guard let photoSampleBuffer = photoSampleBuffer else {
print("Error capturing photo \(error)")
return
}
photoData = AVCapturePhotoOutput
.jpegPhotoDataRepresentation(
forJPEGSampleBuffer: photoSampleBuffer,
previewPhotoSampleBuffer: previewPhotoSampleBuffer)
}
}
```

See? That’s quite the method name. This one is called when the sensor data from the capture has been processed. All you do here is use a class method on `AVCapturePhotoOutput` to create the JPEG data and save it to the property. Now add this method to the same extension:

```swift  
// Entire process completed
func capture(_ captureOutput: AVCapturePhotoOutput, 
didFinishCaptureForResolvedSettings 
resolvedSettings: AVCaptureResolvedPhotoSettings, 
error: Error?) {

// 1
guard error == nil, let photoData = photoData else {
print("Error \(error) or no data")
cleanup()
return
}

// 2
PHPhotoLibrary.requestAuthorization {
[unowned self]
(status) in
// 3
guard status == .authorized  else {
print("Need authorisation to write to the photo library")
self.cleanup()
return
}
// 4
var assetIdentifier: String?
PHPhotoLibrary.shared().performChanges({
let creationRequest = PHAssetCreationRequest.forAsset()
let placeholder = creationRequest
.placeholderForCreatedAsset

creationRequest.addResource(with: .photo, 
data: photoData, options: .none)

assetIdentifier = placeholder?.localIdentifier

}, completionHandler: { (success, error) in
if let error = error {
print("Error saving to the photo library: \(error)")
}
var asset: PHAsset? = .none
if let assetIdentifier = assetIdentifier {
asset = PHAsset.fetchAssets(
withLocalIdentifiers: [assetIdentifier], 
options: .none).firstObject
}
self.cleanup(asset: asset)
})
}
}
```

This method is called when the entire capture and processing is finished with. It’s the last delegate method to be called. Here’s the breakdown: 

1. Check to make sure everything is as expected.
2. Request access to the photo library. The first time this runs, the user will be prompted to allow permission. 
3. If access is not granted, your camera app is of limited utility.
4. Save the captured data to the photo library and obtain a `PHAsset`, which is an object representing a photo or movie from the photos library. The Photos framework isn’t the topic for this chapter, so you only get a summary explanation: You ask to create an asset, then attempt to create one, and if all is well, you end up with a full `PHAsset`. 

Note that the `cleanup(asset:)` method is called in all cases. Switch back to **ViewController.swift** and add a property to hold the list of delegates discussed earlier:

```swift
fileprivate var photoCaptureDelegates = 
[Int64 : PhotoCaptureDelegate]()
```

Now add the following code to the end of the closure that is performed on the session queue in `capturePhoto()`: 

```swift
// 1
let uniqueID = photoSettings.uniqueID
let photoCaptureDelegate = PhotoCaptureDelegate() { 
[unowned self] (photoCaptureDelegate, asset) in
self.sessionQueue.async { [unowned self] in
self.photoCaptureDelegates[uniqueID] = .none
}
}

// 2
self.photoCaptureDelegates[uniqueID] = photoCaptureDelegate

// 3
self.photoOutput.capturePhoto(
with: photoSettings, delegate: photoCaptureDelegate)
```

This code kicks off the capture process:

1. Create the delegate and, in a cruel twist of fate, tell it to remove itself from memory when it’s finished.
2. Store the delegate in the dictionary
3. Start the capture process, passing in the delegate and the settings object. 

Build and run, and you’ll see your new photo UI: 

![iPhone](images/BuildAndRun2.png)

Tap the Take Photo button and you’ll be prompted for access to the photo library. Allow this and then switch to the Photos app – there’s your selfie! That’s nice, but it could use a little UI polish. You’ll add that next. 

## Making it fabulous

You get a shutter noise for free, but it would be nice to see something on the screen as well. You can use the capture begins and capture ends delegate methods for this. In `capturePhoto()`, after you create the delegate object, add the following code:

```swift
photoCaptureDelegate.photoCaptureBegins = { [unowned self] in
DispatchQueue.main.async {
self.shutterButton.isEnabled = false
self.cameraPreviewView.cameraPreviewLayer.opacity = 0
UIView.animate(withDuration: 0.2) {
self.cameraPreviewView.cameraPreviewLayer.opacity = 1
}
}
}

photoCaptureDelegate.photoCaptured = { [unowned self] in
DispatchQueue.main.async {
self.shutterButton.isEnabled = true
}
}
```

You pass in two closures, one to be executed when the capture starts, and one when it ends. When the capture begins, you blank out and fade back in to give a shutter effect and disable the shutter button. When the capture is complete, the shutter button is enabled again.

Open **PhotoCaptureDelegate.swift** and add the following to the `AVCapturePhotoCaptureDelegate` extension:

```swift
func capture(_ captureOutput: AVCapturePhotoOutput,
willCapturePhotoForResolvedSettings 
resolvedSettings: AVCaptureResolvedPhotoSettings) {
photoCaptureBegins?()
}

func capture(_ captureOutput: AVCapturePhotoOutput,
didCapturePhotoForResolvedSettings 
resolvedSettings: AVCaptureResolvedPhotoSettings) {
photoCaptured?()
}
```

Some more very wordy methods, that just execute the closures that have been passed in for these event points. 

Build and run and take some more photos, and you’ll see a camera-like animation each time you hit the button. 

The built-in camera app has a nice feature where it shows a thumbnail of the last photo you took in the corner. You’re going to add that to PhotoMe. You may have noticed the `previewPhotoSampleBuffer` parameter in the extraordinarily long delegate method called when the photo sample buffer is processed. This gets used to make an embedded preview in the JPEG file that is created, but you can also use it to make in-app thumbnails. 

Add a new property to `PhotoCaptureDelegate` to hold a closure to be executed when a thumbnail is captured:

```swift
var thumbnailCaptured: ((UIImage?) -> ())? = .none
```

Then add this code to the end of the `...didFinishProcessingPhotoSampleBuffer...` method:

```swift
if let thumbnailCaptured = thumbnailCaptured,
let previewPhotoSampleBuffer = previewPhotoSampleBuffer,
let cvImageBuffer = CMSampleBufferGetImageBuffer(previewPhotoSampleBuffer) {

let ciThumbnail = CIImage(cvImageBuffer: cvImageBuffer)
let context = CIContext(options: [kCIContextUseSoftwareRenderer: false])
let thumbnail = UIImage(cgImage: context.createCGImage(ciThumbnail, from: ciThumbnail.extent)!, scale: 2.0, orientation: .right)

thumbnailCaptured(thumbnail)
}
```

This is a faintly ludicrous game of pass-the-parcel where you make the `CMSampleBuffer` into a `CVImageBuffer`, then a `CIImage`, then a `CGImage`, then a `UIImage`. It’s a good job this is all happening on a background thread! :]

The next part sounds more complicated than it is. You’re going to add a whole stack of stack views. There’s a diagram afterwards to help you. Open **Main.storyboard** and drag a **Horizontal Stack View** in to the existing stack view, at the same level as the shutter button. Add two **Vertical Stack Views** to the new stack view. Add a **Horizontal Stack View** to the first vertical stack view, and to _that_ stack view add a switch and a label. 

Set the **Value** of the switch to **Off**, and the text of the label to **Capture Thumbnail**, with the text color set to white.

Add an image view to the second vertical stack view. Add a width constraint to the image view to make it 80 points wide, then add an aspect ratio constraint to make it 1:1 (square). Check **Clip to Bounds** and set the **Content Mode** to **Aspect Fill**.

Take a deep breath, then check what you have against this diagram. Rename each stack view to match, because you’ll be adding more views later on and this will stop you getting confused: 

![bordered width=50%](images/StackOfStacks.png) 

Select the **Capture Stack** and set the **Alignment** to **Center** and the **Spacing** to **20**. 

Select the **Option Stack** and set the **Alignment** to **Leading** and the **Spacing** to **5**.

Select the **Thumbnail Stack** and set the **Spacing** to **5**.

Use the **Resolve Autolayout Issues** menu to update all of the frames if necessary.

Open the assistant editor and make two new outlets from  **ViewController.swift** to the switch and image view:

```swift
@IBOutlet weak var previewImageView: UIImageView!
@IBOutlet weak var thumbnailSwitch: UISwitch!
```

If the user has turned the thumbnail switch on, you need to add a preview format to the photo settings object. In **ViewController.swift**, add the following to `capturePhoto()` before the delegate object is created:

```swift
if self.thumbnailSwitch.isOn 
&& photoSettings.availablePreviewPhotoPixelFormatTypes
.count > 0 {
photoSettings.previewPhotoFormat = [
kCVPixelBufferPixelFormatTypeKey as String :
photoSettings
.availablePreviewPhotoPixelFormatTypes.first!,
kCVPixelBufferWidthKey as String : 160,
kCVPixelBufferHeightKey as String : 160
]
}
```

This tells the photo settings that you want to create a 160x160 preview image, in the same format as the main photo. Still in `capturePhoto()`, add the following code after you’ve created the delegate object:

```swift
photoCaptureDelegate.thumbnailCaptured = { [unowned self] image in
DispatchQueue.main.async {
self.previewImageView.image = image
}
}
```

This will set the preview image once the thumbnail is captured and processed. Build and run, turn the thumbnail switch on and take a photo. Check out that preview!

![iPhone](images/BuildAndRun3.png)

## Live photos

What you’ve done so far is really a slightly nicer version of what you could already do with `AVCaptureStillImageOutput`. In the next two sections you’ll get on to totally new stuff: taking live photos, and editing them! 

Open **Main.storyboard** and drag a new **Horizontal Stack View** into the **Option Stack**, above the **Thumbnail Stack**. Name the new stack view **Live Photo Stack** and set the **Spacing** to **5**. Drag in a switch and a label, set the label text to **Live Photo Mode** and the text color to white, and set the switch to **Off**. This will control your capture of live photos.

Drag a label to the top of the **Control Stack**, set the text color to the same orange you’re using for the overall tint, and the font size to **35**. Set the new label to **Hidden**. This will tell the user if a live photo capture is still rolling. 

Open the assistant editor and create outlets to the new switch and the “capturing...” label:

```swift
@IBOutlet weak var livePhotoSwitch: UISwitch!
@IBOutlet weak var capturingLabel: UILabel!
```

Open **ViewController.swift** and add the following code to `prepareCaptureSession()`, just after the video device input is created:

```swift
do {
let audioDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
if session.canAddInput(audioDeviceInput) {
session.addInput(audioDeviceInput)
} else {
print("Couldn't add audio device to the session")
return
}
} catch {
print("Unable to create audio device input: \(error)")
return
}
```

A live photo is a full-size photo with an accompanying video, which contains sound. This means you need to add another input to the  session. As with high-resolution capture, you need to configure the output object up front to support live photos, even if you’re not taking live photos by default. Add the following code after the line where you enable high-resolution capture: 

```swift
photoOutput.isLivePhotoCaptureEnabled =
photoOutput.isLivePhotoCaptureSupported
DispatchQueue.main.async {
self.livePhotoSwitch.isEnabled =
self.photoOutput.isLivePhotoCaptureSupported
}
```

This checks to see if live photo capture is possible on the device, and if so, it adds that capability to the output. If not, the live photo switch is disabled, but left on screen to show you what you’re missing. 

Move to `capturePhoto()` and perform the additional configuration needed to support live photo capture. Before the delegate object is created, add the following:

```swift
if self.livePhotoSwitch.isOn {
let movieFileName = UUID().uuidString
let moviePath = (NSTemporaryDirectory() as NSString)
.appendingPathComponent("\(movieFileName).mov")
photoSettings.livePhotoMovieFileURL = URL(
fileURLWithPath: moviePath)
}
```

During capture the video file will be recorded into this unique name in the temporary directory.

Switch to **PhotoCaptureDelegate.swift** and add these two new properties:

```swift
var capturingLivePhoto: ((Bool) -> ())? = .none
fileprivate var livePhotoMovieURL: URL? = .none
```

The first is a closure which the view controller will use to update the UI to indicate if live photo capture is happening. The second will store the URL of the movie file that accompanies the live photo.

In the `AVCapturePhotoCaptureDelegate` extension, add the following to `...willCapturePhotoForResolvedSettings...`:

```swift
if resolvedSettings.livePhotoMovieDimensions.width > 0
&& resolvedSettings.livePhotoMovieDimensions.height > 0 {
capturingLivePhoto?(true)
}
```

This will call the closure, saying that another live photo capture session will begin. Close the loop by adding this new delegate method, which you’ll be happy to know keeps with the tradition of lengthy method signatures:

```swift
func capture(_ captureOutput: AVCapturePhotoOutput,
didFinishRecordingLivePhotoMovieForEventualFileAt
outputFileURL: URL, 
resolvedSettings: AVCaptureResolvedPhotoSettings) {
capturingLivePhoto?(false)
}
```

This delegate method is called when the video capture is complete. As with photos, there is a further method that is called when the _processing_ of the video capture is complete. Add this now: 

```swift
func capture(_ captureOutput: AVCapturePhotoOutput,
didFinishProcessingLivePhotoToMovieFileAt outputFileURL: URL,
duration: CMTime, 
photoDisplay photoDisplayTime: CMTime,
resolvedSettings: AVCaptureResolvedPhotoSettings,
error: Error?) {
if let error = error {
print("Error creating live photo video: \(error)")
return
}
livePhotoMovieURL = outputFileURL
}
```

Add the following code to `capture(_: didFinishCaptureForResolvedSettings:error:)`, just after you call `addResource` on the creation request:

```swift
if let livePhotoMovieURL = self.livePhotoMovieURL {
let movieResourceOptions = PHAssetResourceCreationOptions()
movieResourceOptions.shouldMoveFile = true
creationRequest.addResource(with: .pairedVideo,
fileURL: livePhotoMovieURL, options: movieResourceOptions)
}
```

This bundles in the video data with the photo data you’re already sending, making your photo live. Setting the `shouldMoveFile` option means that the video file will be removed from the temporary directory for you. 

You’re ready to take a live photo now, but first you’ll add that handy capturing indicator to the view. Switch back to **ViewController.swift** and add a new property to track the number of ongoing live photo captures:

```swift
fileprivate var currentLivePhotoCaptures: Int = 0
```

Then in `capturePhoto()`, where you assign all the other closures, add this new closure:

```swift
// Live photo UI updates
photoCaptureDelegate.capturingLivePhoto = { (currentlyCapturing) in
DispatchQueue.main.async { [unowned self] in
self.currentLivePhotoCaptures += currentlyCapturing ? 1 : -1
UIView.animate(withDuration: 0.2) {
self.capturingLabel.isHidden =
self.currentLivePhotoCaptures == 0
}
}
}
```

This increments or decrements the property and hides the label as necessary. Build and run, turn on the live photos switch and start creating memories!

![iPhone](images/LivePhotoCapture.png)

## Editing Live Photos

Previously, when you edited Live Photos they lost the accompanying video and became, well, Dead Photos. In iOS 10 you can apply the same range of edits to a Live Photo as you can to any photo; those edits are applied to every frame of the video as well. What’s even better is that you can do this in your own apps. You’re going to apply a cool core image filter to live photos taken in PhotoMe. 

Open **Main.storyboard** and drag a button into the bottom of the **Preview Stack**. Set the title of the button to **Edit**.  

Drag a new view controller into the storyboard, Control-drag from the edit button to the new controller and choose to create a **Present Modally** segue.

Set the main view's background color to black. Drag in a vertical stack view and drag the left, top and bottom edges out to reach the edges of the screen. Add constraints to pin those edges, and set the spacing to **20**. 

Add a UIView and two buttons to the stack. Create a 3:4 aspect ratio constraint on the view, and set its class to **PHLivePhotoView** using the Identity Inspector. This class allows you to play live photos as in the Photo Library. 

Set the text of the first button to **Comicify** (because that’s definitely a real word) and the font size to **30**. Set the text of the second button to **Done**. 

Create a new view controller subclass called **PhotoEditingViewController**. Add the following imports to the new file:

```swift
import Photos
import PhotosUI
```

These modules are required to handle photo assets and the live photo view.

Switch back to **Main.storyboard** and change the class of the new view controller to `PhotoEditingViewController`. Open the assistant editor and create and connect an outlet for the live photo view and actions from each button: 

```swift
@IBOutlet weak var livePhotoView: PHLivePhotoView!

@IBAction func handleComicifyTapped(_ sender: UIButton) {
}

@IBAction func handleDoneTapped(_ sender: UIButton) {
dismiss(animated: true)
}
```

Add a property to `PhotoEditingViewController` to hold the asset being edited:

```swift
var asset: PHAsset?
```

And code to load and display the live photo:

```swift
override func viewDidAppear(_ animated: Bool) {
super.viewDidAppear(animated)
if let asset = asset {
PHImageManager.default().requestLivePhoto(for: asset,
targetSize: livePhotoView.bounds.size, 
contentMode: .aspectFill, 
options: .none, resultHandler: { (livePhoto, info) in
DispatchQueue.main.async {
self.livePhotoView.livePhoto = livePhoto
}
})
}
}
``` 

Switch to **ViewController.swift** and add a new property to hold the last photo that was taken. Add `import Photos` to the top of the file first, then:

```swift
fileprivate var lastAsset: PHAsset?
```

Store the value by adding this to the completion closure you create when making the capture delegate in `capturePhoto()`:

```swift
self.lastAsset = asset
```

Finally, pass the asset along by adding this implementation of `prepare(for: sender:)`:

```swift
override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
if let editor = segue.destination as? PhotoEditingViewController {
editor.asset = lastAsset
}
}
```

Build and run, take a live photo, and tap the edit button. You’ll see your live photo, and can 3D touch it to play:

![iPhone](images/LivePhotoView.png)

In **PhotoEditingViewController.swift** add the following method:

```swift
fileprivate func comicifyImage() {
guard let asset = asset else { return }

// 1
asset.requestContentEditingInput(with: .none) { 
[unowned self] (input, info) in
guard let input = input else { 
print("error: \(info)")
return 
}

// 2
guard input.mediaType == .image,
input.mediaSubtypes.contains(.photoLive) else {
print("This isn't a live photo")
return
}

// 3
let editingContext =
PHLivePhotoEditingContext(livePhotoEditingInput: input)
editingContext?.frameProcessor = { 
(frame, error) in
// 4
var image = frame.image
image = image.applyingFilter("CIComicEffect",
withInputParameters: .none)
return image
}

// 5
editingContext?.prepareLivePhotoForPlayback(
withTargetSize: self.livePhotoView.bounds.size, 
options: .none) { 
(livePhoto, error) in
guard let livePhoto = livePhoto else { 
print("Preparation error: \(error)")
return
}
self.livePhotoView.livePhoto = livePhoto
}
}
}
```

Here’s the breakdown:

1. `requestContentEditingInput` loads the asset data from the library and gets it ready for editing.
2. Check that the photo is actually a live photo.
3. Create a live photo editing context and assign it a frame processor. This is a closure that is applied to each `PHLivePhotoFrame` in the live photo, including the full-resolution image. You can identify how far through the video you are, or if you’re editing the full image, by inspecting the frame object. The closure must return a `CIImage` — returning `nil` at any point aborts the edit. 
4. In your case, you apply the same `CIFilter` to each frame, which is the Comic Effect filter. You could put any combination of core image filters in here, or perform any other manipulations you can think of.
5. This call creates preview-level renderings of the live photo. When it's done, it will update the live photo view.

Build and run, take a live photo and hit that Comicify button. See, I told you it was a real word:

![iPhone](images/EditedLivePhoto.png)

`prepareLivePhotoForPlayback` only renders a low-resolution version of the edited photo, for previewing. To edit the actual live photo and save the edits to the library, you need to do a little more work. Add the following code to `comicifyImage()`, at the end of the completion block for `prepareLivePhotoForPlayback`. 

```swift
// 1
let output = PHContentEditingOutput(contentEditingInput: input)
// 2
output.adjustmentData = PHAdjustmentData(
formatIdentifier: "PhotoMe", 
formatVersion: "1.0", 
data: "Comicify".data(using: .utf8)!)
// 3
editingContext?.saveLivePhoto(to: output, options: nil) {
success, error in
if !success {
print("Rendering error \(error)")
return
}
// 4
PHPhotoLibrary.shared().performChanges({
let request = PHAssetChangeRequest(for: asset)
request.contentEditingOutput = output
}, completionHandler: { (success, error) in
print("Saved \(success), error \(error)")
})
}
```

The code is placed into that completion block because it needs to wait until the preview is rendered, otherwise saving the photo cancels the preview rendering. In a full app you’d have a separate save button for the user once they were happy with the preview. Here’s the breakdown:

1. The content editing output acts as a destination for the editing operation. For live photos, it’s configured using the content editing input object you requested earlier. 
2. Despite the adjustment data property being optional, you _must_ set it, otherwise the photo can’t be saved. This information allows your edits to be reverted. 
3. `saveLivePhoto(to: options:)` re-runs the editing context’s frame processor, but for the full-size video and still.
4. Once rendering is complete, you save the changes to the photo library in the standard manner by creating requests inside a photo library’s changes block. 

Build and run, go through the motions and now, when you hit Comicify, you'll get a system prompt asking for permission to modify the photo:

![iPhone](images/PermissionToEdit.png)

If you don’t hit that Modify button after all this work, you and I can’t be friends any more. 

## Where to go from here?

Congratulations! That was a marathon session, but you built an entire live-selfie filtering app! It’s easy to imagine building on that foundation with a wider range of filters and options to come up with a really nice product. 

There’s more information on the new photography capabilities in WWDC16 sessions 501, 505 and 511, including RAW capture and processing. The Photos framework itself was introduced in iOS 8 and is covered in our iOS8 By Tutorials book. 
