```metadata
author: "By Jeff Rames"
number: "7"
title: "Chapter 7: Speech Recognition"
```
# Chapter 7: Speech Recognition

The new Speech Recognition API allows your app to transcribe live or pre-recorded audio. It leverages the same speech recognition engine used by Siri and Keyboard Dictation, but provides direct access to the results.

This engine comes with some big bonuses in addition to its speed and accuracy. It can interpret over 50 languages and dialects, based on your configuration. It even adapts results to the user based on its knowledge of their contacts, apps, media and various other data.

Audio fed to a recognizer is transcribed, generally by a remote server, in near real time. Incremental results are provided in text format along with some metadata as they return. This allows you to react to voice input very quickly and regardless of context, unlike Keyboard Dictation.

Direct access to transcriptions opens the door to powerful new features in your apps. A cool live speech implementation described at WWDC—a camera app could take a photo when it hears the word *cheese*. For pre-recorded audio, transcriptions could be stored and used to enable text searches in a library of recordings.

In this chapter, you'll build an app called Gangstribe that will transcribe completely serious gangster rap recordings using speech recognition. It will also get users in the mood to record their own rap hits with a live audio transcriber that draws emojis on their faces based on what they say. :]

The section on live recordings will use AVAudioEngine. The text will guide you through it, but you may want to familiarize yourself if you haven't used it before. The 2014 WWDC session *AVAudioEngine in Practice* is a great intro to this, and can be found here - [apple.co/28tATc1](http://apple.co/28tATc1)

The Speech Recognition framework does not work in the simulator, so be sure you have a real device with iOS 10 for this chapter.

## Getting Started [Instruction]

Open **Gangstribe.xcodeproj** in the starter project folder for this chapter. Select the project file, the **Gangstribe** target and then the **General** tab. Choose your development team from the dropdown.

![width=50%](./images/select-team.png)

Connect an iOS 10 device and select it as the active scheme. Build and run and you'll see the bones of the app.

From the master controller, you can select a song. The detail controller will then allow you to play the audio file, recited by none other than our very own DJ Sammy D!

![width=40%](./images/gangsta-sam-icon.png) 

The transcribe button is not currently operational, but you'll later use this to kick off a transcription of the selected recording.

![iPhone bordered](./images/recorded-transcription-starter.png)

Tap **Face Replace** on the right of the navigation bar to preview the live transcription feature. You'll be prompted for permission to access the camera—accept this as it's needed for this feature.

Currently if you select an emoji with your face in frame, it will place the emoji on your face. Later, you'll trigger this action with speech.

![iPhone bordered](./images/live-transcription-starter.png)

Take a moment to familiarize yourself with the starter project. Here are some highlights of classes and groups you'll work with during this chapter:

- **MasterViewController.swift** displays the list of recordings in a table view. The recording model object is defined in **Recording.swift**, which includes the packaged data.
- **RecordingViewController.swift** plays the pre-recorded audio selected in the master controller. You'll populate the currently stubbed out `handleTranscribeButtonTapped(_:)` and have it kick off file transcription.
- **LiveTranscribeViewController.swift** handles the *Face Replace* view, which leverages the code included in the **FaceReplace** folder. It currently displays live video and a collection view of emojis, attaching the selected emoji to any face in the live view. This is where you'll add code to record and transcribe audio.
- **FaceReplace** contains a library provided by Rich Turton used to place emojis over faces in live video. It uses Core Image's CIDetector, and understanding it is completely optional for this tutorial. However, if you'd like to learn more you can read about CIDetector here - [apple.co/1Tx2uCN](http://apple.co/1Tx2uCN).

You'll start this chapter by making the transcribe button work for pre-recorded audio. It will feed the audio file to Speech Recognizer and present the results in a label under the player.

The latter half of the chapter will focus on the Face Replace feature. You'll set up an audio engine for recording, tap into that input, and transcribe the audio as it arrives. You'll display the live transcription and ultimately use it to trigger placing emojis over the user's face.

You can't just dive right in and start voice commanding unicorns onto your face. First, there are some basics you need to understand.

## Transcription Basics

There are four primary actors involved in a speech transcription:

1. **SFSpeechRecognizer** is the primary controller in the framework. Its most important job is to generate recognition tasks and return results. It also handles authorization and configures locales. 
2. **SFSpeechRecognitionRequest** is the base class for recognition requests. Its job is to point the `SFSpeechRecognizer` to an audio source from which transcription should occur. There are two concrete types—**SFSpeechURLRecognitionRequest**, for reading from a file and **SFSpeechAudioBufferRecognitionRequest** for reading from a buffer.
3. **SFSpeechRecognitionTask** objects are created when a request is kicked off by the recognizer. They are used to track progress of a transcription or cancel it.
4. **SFSpeechRecognitionResult** objects contain the transcription of a chunk of the audio. Each result typically corresponds to a single word.

Below is a look at how these objects interact during a basic speech recognizer transcription.

![width=100%](./images/speech-recognizer-chart.png)

The code for a basic request is quite simple. Given an audio file at `url`, the following code transcribes the file and prints the results:  

```swift
let request = SFSpeechURLRecognitionRequest(url: url)
SFSpeechRecognizer()?.recognitionTask(with: request) { (result, _) in
  if let transcription = result?.bestTranscription {
    print("\(transcription.formattedString)")
  }
}
```

The `SFSpeechRecognizer` kicks off a `SFSpeechRecognitionTask` for the `SFSpeechURLRecognitionRequest` using `recognitionTask(with:resultHandler:)`. It returns partial results as they arrive via the `resultHandler`. This code prints the formatted string value of the `bestTranscription`, which is a cumulative transcription result adjusted at each iteration.

You'll start on Gangstribe by implementing a file transcription very similar to this.

## Audio File Speech Transcription 

Before you start reading and sending chunks of the user's audio off to a remote server, it would be polite to ask permission. In fact, considering their commitment user privacy, it should come as no surprise that Apple requires this! :]

You're going to kick off the authorization process when the **Transcribe** button in the detail controller is tapped.

Open **RecordingViewController.swift** and add the following to the `import` statements up top:
```swift
import Speech
```

This imports the Speech Recognition API.

Now find `handleTranscribeButtonTapped(_:)`. Add the following to the method:

```swift
SFSpeechRecognizer.requestAuthorization {
  [unowned self] (authStatus) in
  switch authStatus {
  case .authorized:
    if let recording = self.recording {
      //TODO: Kick off the transcription
    }
  case .denied:
    print("Speech recognition authorization denied")
  case .restricted:
    print("Not available on this device")
  case .notDetermined:
    print("Not determined")
  }
}
```

You call the `SFSpeechRecognizer` class method `requestAuthorization`, which will prompt the user for authorization and handle their response in a completion closure. 

In the closure, you look at the `authStatus` and print error messages for all of the exception cases. For `authorized`, you unwrap the selected recording for later transcription.

Next, you have to provide a usage description to be displayed when permission is requested. Open **Info.plist** and add the key **Privacy - Speech Recognition Usage Description** providing the value **I want to write down everything you say**:

![width=90% bordered](./images/speech-recognition-permission.png)

Build and run, select a song from the master controller, and tap **Transcribe**. You'll see a permission request appear with the text you provided:

![iPhone bordered](./images/speech-recognition-prompt.png)

With that accomplished, it's time to test the limits of speech recognition with recordings of our very own DJ Sam Davies spitting some mad rhymes.

### Transcribing the File [Instruction]

Still in **RecordingViewController.swift**, find the `RecordingViewController` extension at the bottom of the file. Add the following method to it:

```swift
private func transcribeFile(url: URL) {
  
  // 1
  guard let recognizer = SFSpeechRecognizer() else {
    print("Speech recognition not available for specified locale")
    return
  }
  
  if !recognizer.isAvailable {
    print("Speech recognition not currently available")
    return
  }
  
  // 2
  updateUIForTranscriptionInProgress()
  let request = SFSpeechURLRecognitionRequest(url: url)
  // 3
  recognizer.recognitionTask(with: request) {
    [unowned self] (result, error) in
    guard let result = result else {
      print("There was an error transcribing that file")
      return
    }
    // 4
    if result.isFinal {
      self.updateUIWithCompletedTranscription(result.bestTranscription.formattedString)
    }
  }
}
```

`transcribeFile(url:)` kicks off a transcription of the file found at `url`. It does the following:

1. The default `SFSpeechRecognizer()` initializer provides a recognizer for the device's locale, returning nil if there is no such recognizer. `isAvailable` checks if the `recognizer` is ready to be used, failing in cases such as missing network connectivity.
2. `updateUIForTranscriptionInProgress()` is provided with the starter to disable the Transcribe button and start an activity indicator animation while processing. A `SFSpeechURLRecognitionRequest` is also created for the file found at `url`.
3. `recognitionTask(with:)` processes the transcription `request`, repeatedly triggering a completion closure. The passed `result` is unwrapped in a guard, which prints an error on failure. 
4. The `isFinal` property will be true when transcription is complete. `updateUIWithCompletedTranscription()`, included with the starter, stops the activity indicator, re-enables the button, and displays the passed string in a text view. `bestTranscription` contains the transcription Speech Recognizer is most confident is accurate, and `formattedString` provides it in String format.

>**Note**: Where there is a `bestTranscription`, there can of course be lesser ones. `SFSpeechRecognitionResult` has a `transcriptions` property that contains an array of transcriptions sorted in order of confidence. As you see with Siri and Keyboard Dictation, a transcription can change as more context arrives, and this array illustrates that type of progression.

Now you need to call this new code when the Transcribe button is tapped. In `handleTranscribeButtonTapped(_:)` replace `//TODO: Kick off the transcription` with the following:

```swift
self.transcribeFile(url: recording.audio)
```

After successful authorization, the button handler now calls `transcribeFile(url:)` with the URL of the currently selected recording, found in `audio`. 

Build and run, select **Gangsta's Paradise**, and then tap the **Transcribe** button. You'll see the activity indicator for a while, and then the text view will eventually populate with the transcription:

![iPhone bordered](./images/transcription-result.png)

The results actually aren't too bad, considering Coolio doesn't entirely follow Webster's Dictionary. Depending on the locale of your device, there could be another reason things are a bit off. The above screenshot was a transcription completed on a device configured for US English, while DJ Sammy D has a slightly different dialect.

But you don't need to book a flight overseas to fix this. When creating a recognizer, you have the option of specifying a locale, and that's what you'll do here. 

>**Note**: Even if your device is set to en_GB (English - United Kingdom) as Sam's is, the locale settings are important to Gangstribe. In just a bit, you'll transcribe text in an entirely different language!

In **RecordingViewController.swift**, find `transcribeFile(url:)` and replace the following two lines:

```swift
private func transcribeFile(url: URL) {
  guard let recognizer = SFSpeechRecognizer() else {
```

with the following:

```swift
private func transcribeFile(url: URL, locale: Locale?) {
  let locale = locale ?? Locale.current
  
  guard let recognizer = SFSpeechRecognizer(locale: locale) else {
```

You've added an optional `Locale` parameter, which will specify the locale of the file being transcribed. `locale` is unwrapped, falling back to the current locale if it's nil. When initializing the `SFSpeechRecognizer`, you now pass this locale.

Now you need to modify where this method is called. Find `handleTranscribeButtonTapped(_:)` and replace the `transcribeFile(url:)` call with the following:

```swift
self.transcribeFile(url: recording.audio, locale: recording.locale)
```

You use the new method signature, and pass the locale stored with the `recording` object. 

>**Note**: If you want to see the locale associated with a recording, open **Recording.swift** and look at the `recordingNames` array up top. Each element contains the song name, artist, audio file name, and locale. You can find information on how locale identifiers are derived in Apple's Internationalization and Localization Guide here—[apple.co/1HVWDQa](http://apple.co/1HVWDQa)

Build and run, and complete another transcription on **Gangsta's Paradise**. Assuming your first run was with a locale other than *en_GB*, you should see some differences.

![iPhone bordered](./images/transcription-result-with-locale.png)

In both transcription screenshots, look for the words following *treated like a punk you know that's*. With the correct locale set, the next words read *unheard-of* where the American English transcription heard *on head of*. This is a great example of the power of this framework with its understanding of a wide range of languages and dialects.

You can probably understand different dialects of languages you speak pretty well. But you're probably significantly weaker when it comes to understanding languages you don't speak. The Speech Recognition engine understands over 50 different languages and dialects, so likely has you beat here.

Now that you are passing the locale of files you're transcribing, you'll be able to successfully transcribe a recording in any supported language. Build and run, and select the song **Raise Your Hands**, which is in Thai. Play it, and then tap **Transcribe** and you'll see something like this:  

![iPhone bordered](./images/thai-transcription.png)

Flawless transcription! Presumably.

## Live Speech Recognition [Theory]  

Live transcription is very similar to file transcription. The primary difference in the process is a different request type—**SFSpeechAudioBufferRecognitionRequest** is used for live transcriptions.

As the name implies, this type of request reads from an audio buffer. Your task will be to append live audio buffers to this request as they arrive from the source. Once connected, the actual transcription process will be identical to that for recorded audio.

Another consideration for live audio is that you'll need a way to stop a transcription when the user is done speaking. This requires maintaining a reference to the **SFSpeechRecognitionTask** so that it can later be canceled.

Gangstribe has some pretty cool tricks up its sleeve. For this feature, you'll not only transcribe live audio, but you'll use the transcriptions to trigger some visual effects. With the use of the FaceReplace library, speaking the name of a supported emoji will plaster it right over your face!

### Connect to the Audio Buffer [Instruction]

To do this, you'll have to configure the audio engine and hook it up to a recognition request. But before you start recording and transcribing, you need to request authorization to use speech recognition in this controller.

Open **LiveTranscribeViewController.swift** and find `viewDidLoad()`. Replace `startRecording()` with the following:

```swift
SFSpeechRecognizer.requestAuthorization {
  [unowned self] (authStatus) in
  switch authStatus {
  case .authorized:
    startRecording()
  case .denied:
    print("Speech recognition authorization denied")
  case .restricted:
    print("Not available on this device")
  case .notDetermined:
    print("Not determined")
  }
}
```

Just as you did with pre-recorded audio, you're calling `requestAuthorization(_:)` to obtain or confirm access to Speech Recognition. For the `authorized` status, you call `startRecording()` which currently just does some preparation—you'll be implementing the rest shortly. Otherwise, you print various error messages depending on the failure.

Next, add the following properties at the top of `LiveTranscribeViewController`: 

```swift
let audioEngine = AVAudioEngine()
let speechRecognizer = SFSpeechRecognizer()
let request = SFSpeechAudioBufferRecognitionRequest()
var recognitionTask: SFSpeechRecognitionTask?
```

- **audioEngine** is an `AVAudioEngine` object that you'll use for processing input audio signals.
- **speechRecognizer** is the `SFSpeechRecognizer` you'll use for live transcriptions. 
- **request** is the `SFSpeechAudioBufferRecognitionRequest` the speech recognizer will use to tap into the audio engine.
- **recognitionTask** will hold a reference to the `SFSpeechRecognitionTask` kicked off when transcription begins.

Now find `startRecording()` in a `LiveTranscribeViewController` extension in this same file. This is called when the Face Replace view loads, but it doesn't yet do any recording. Add the following code to the bottom of the method:

```swift
guard let node = audioEngine.inputNode else {
  print("Couldn't get an input node!")
  return
}
let recordingFormat = node.outputFormat(forBus: 0)
node.installTap(onBus: 0, bufferSize: 1024,
                format: recordingFormat) { [unowned self]
  (buffer, _) in
  self.request.append(buffer)
}
```

You obtain the input audio `node` (associated with the device's mic), as well as its corresponding `outputFormat`. You then install a tap on the output bus of this node, using that same recording format. When the buffer is filled, the closure returns the data in `buffer`.

Within the closure, you append the returned buffer data to your `SFSpeechAudioBufferRecognitionRequest()`. Providing data to the request in this way has the same result as a `SFSpeechURLRecognitionRequest` reading from a URL—the request is fed audio that can be transcribed. Your `request` is now tapped into the live input node.

With the tap in place, you need to start the audio engine and kick off the recognition task. Because starting the audio engine throws, you need to signify this on the method before adding that code. Change the method definition to match the following:

```swift
private func startRecording() throws {
```

TODO: add mic plist permission here.  Might want to move the audioEngine.prepare() and start() up to the prior block so that I can have a breakpoint here to test that recording works with no crash.

Now add the following at the bottom of the method:

```swift
audioEngine.prepare()
try audioEngine.start()
recognitionTask = speechRecognizer?.recognitionTask(with: request) {
  [unowned self]
  (result, _) in
  if let transcription = result?.bestTranscription {
    self.transcriptionOutputLabel.text = transcription.formattedString 
  }
}
```

This starts the audio engine, causing the tap to begin pushing audio to the speech recognizer request. `recognitionTask(with:)` is then called with that `request`, kicking off transcription of live audio. The task is saved in `recognitionTask` for later use.

In the closure, the `bestTranscription` is obtained from the result. The label that displays the transcription is then updated with the formatted string of the `transcription`.

Because `startRecording()` now throws, you need to modify where it gets called. Find `viewDidLoad()` and replace `startRecording()` with the following:

```swift
do {
  try startRecording()
} catch let error {
  print("There was a problem starting recording: \(error.localizedDescription)")
}
```

`startRecording()` is now wrapped in a do-catch, printing the error if it fails.

Build and run, and tap the Face Replace button in the navigation bar. Start talking, and you'll now see a real time transcription from speech recognitiion!

![iPhone bordered](./images/first-live-transcription.png)

>**Note**: Apple has hinted at some throttling limits, including an utterance duration limit of 'about one minute'. You're likely to see if you stay in live transcription long enough, it will stop responding. Now you know why!

But there's a problem. If you try opening Face Replace enough times, you're going to get a crash. You're currently leaking the `SFSpeechAudioBufferRecognitionRequest` as you're not stopping transcription (or the audio engine for that matter).

Add the following method to `LiveTranscribeViewController`: 

```swift
private func stopRecording() {
  audioEngine.stop()
  request.endAudio()
  recognitionTask?.cancel()
}
```

Calling `stop()` on the audio engine releases all resources associated with it. `endAudio()` tells the request that it shouldn't expect any more incoming audio, and causes it to stop listening. `cancel()` is called on the recognition task to let it know its work is done so that it can free up resources.

You'll want to call this when the user taps the **Done!** button before you dismiss the controller. Add the following to `handleDoneTapped(_:)`, just before the `dismiss`:

```swift
stopRecording()
```

The audio engine and speech recognizer will now get cleaned up each time the user finishes with a live recording. Good job cleaning up your toys! :]

### Transcription Segments 

The live transcription below your video is pretty cool, but it's not what you set out to do. It's time to dig into these transcriptions and use them to trigger the emoji face replacement!

First, you need to understand a bit more about the data contained in a `SFTranscription` object.

`SFTranscription` has a `segments` property containing an array of all `SFTranscriptionSegment` objects a request has returned. Among other things, a `SFTranscriptionSegment` has a `substring` containing the transcribed String for that segment and its `duration` from the start of transcription. Generally, each segment will consist of a single word.

//TODO: change self.transcriptionOutputLabel.text = transcription.formattedString to be
the method self.updateUIWithTranscription(transcription) and call it in the TODO in the code in recognitionTask's closure.  This is the code it shoudl start with:
  private func updateUIWithTranscription(_ transcription: SFTranscription) {
    self.transcriptionOutputLabel.text = transcription.formattedString
  }

Recall that `updateUIWithTranscription(_:)` is called each time the live transcription updates—the perfect place to check the transcription text and trigger a face replacement. Add the following at the bottom of the method:

```swift
if let lastSegment = transcription.segments.last,
  lastSegment.duration > self.mostRecentlyProcessedSegmentDuration {
  self.mostRecentlyProcessedSegmentDuration = lastSegment.duration
  faceSource.selectFace(string: lastSegment.substring)
}
```

This unwraps the `last` segment from the passed `transcription` and checks that its duration is higher than the `mostRecentlyProcessedSegmentDuration`, which is initialized to 0 at the start of a new recording. It then saves the new `duration` in `mostRecentlyProcessedSegmentDuration`, ensuring that an older segment doesn't override a new one if they arrive out of order. `selectFace(string:)`, part of the Face Replace code, accepts the `substring` of this new transcription, and completes a face replace if it matches one of the emoji names.

Build and run and select **Face Replace**. This time, say the name of one of the emojis—for example, same *cry*. The speech recognizer transcribed what you said and fed it to the `FaceSource` object, which plastered the corresponding emoji on your face. What a time to be alive! 

![iPhone bordered](./images/cry-face-replace.png)

>**Note**: For a full list of available keywords, open **FaceSource.swift** and look for the `names` array. Each of these map to one of the emojis in the `faces` array above it.

## Usage Guidelines

While they aren't yet clearly defined, Apple has provided some usage guidelines for Speech Recognition.

Apple will be enforcing the following types of limitations:

- Per device per day
- Per app per day (global limitations for all users of your app)
- One minute limitation for a single utterance (from start to end of a recognition task) 

No numbers were provided for device and app daily limits. These rules are likely to mature and become more concrete as Apple sees how third party developers are using the framework.

Apple also emphasizes that you must make it very clear to users when they are being recorded. While it isn't currently in the review guidelines, it's in your best interest to follow this closely to avoid rejections. You also wouldn't want to invade your user's privacy!

Finally, Apple suggests presenting results of transcription before acting on them. Sending a text message via Siri is a great example of this—she'll present editable transcription results and delay before sending the message. Transcription is certainly not perfect, and you want to protect users from the frustration and possible embarrassment of mistakes.

## Where to Go From Here?

In this chapter, you learned everything you need to know to get basic speech recognition integrated into your apps. It's an extremely powerful feature where the framework does most of the heavy lifting. With just a few lines of code, you can bring a lot of magic to your apps.

There isn't currently much documentation on Speech Recognition, so your best bet is to explore the headers in the source for more detail.

Here are a couple of other places to go for more info:

- WWDC Speech Recognition API Session - [apple.co/2aSMrlw](http://apple.co/2aSMrlw)
- Apple Speech Recognition sample project (SpeakToMe) - [apple.co/2aSO6HS](http://apple.co/2aSO6HS)