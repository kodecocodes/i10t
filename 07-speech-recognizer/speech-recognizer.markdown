```metadata
author: "By Jeff Rames"
number: "7"
title: "Chapter 7: Speech Recognition"
```
# Chapter 7: Speech Recognition

iOS 10's new Speech Recognition API lets your app transcribe live or pre-recorded audio. It leverages the same speech recognition engine used by Siri and Keyboard Dictation, but provides much more control and improved access.

The engine is fast and accurate and can currently interpret over 50 languages and dialects. It even adapts results to the user using information about their contacts, installed apps, media and various other pieces of data.

Audio fed to a recognizer is transcribed in near real time, and results are provided incrementally. This lets you react to voice input very quickly, regardless of context, unlike Keyboard Dictation, which is tied to a specific input object.

Speech Recognizer creates some truly amazing possibilities in your apps. For example, you could create an app that takes a photo when you say "cheese". You could also create an app that could automatically transcribe audio from Simpsons episodes so you could search for your favorite lines. 

In this chapter, you'll build an app called Gangstribe that will transcribe some pretty hardcore (hilarious) gangster rap recordings using speech recognition. It will also get users in the mood to record their own rap hits with a live audio transcriber that draws emojis on their faces based on what they say. :]

![iPhone bordered](./images/intro-teaser-image.png)

The section on live recordings will use AVAudioEngine. If you haven't used AVAudioEngine before, you may want to familiarize yourself with that framework first. The 2014 WWDC session *AVAudioEngine in Practice* is a great intro to this, and can be found at [apple.co/28tATc1](http://apple.co/28tATc1). This session video explains many of the systems and terminology we'll use in this chapter.

The Speech Recognition framework doesn't work in the simulator, so be sure to use a real device with iOS 10 for this chapter.

## Getting started

Open **Gangstribe.xcodeproj** in the starter project folder for this chapter. Select the project file, the **Gangstribe** target and then the **General** tab. Choose your development team from the drop-down.

![bordered width=75%](./images/select-team.png)

Connect an iOS 10 device and select it as your run destination in Xcode. Build and run and you'll see the bones of the app.

From the master controller, you can select a song. The detail controller will then let you play the audio file, recited by none other than our very own DJ Sammy D!

![width=40%](./images/gangsta-sam-icon.png) 

The transcribe button is not currently operational, but you'll use this later to kick off a transcription of the selected recording.

![iPhone bordered](./images/recorded-transcription-starter.png)

Tap **Face Replace** on the right of the navigation bar to preview the live transcription feature. You'll be prompted for permission to access the camera; accept this, as you'll need it for this feature.

Currently if you select an emoji with your face in frame, it will place the emoji on your face. Later, you'll trigger this action with speech.

![iPhone bordered](./images/live-transcription-starter.png)

Take a moment to familiarize yourself with the starter project. Here are some highlights of classes and groups you'll work with during this chapter:

- **MasterViewController.swift**: Displays the list of recordings in a table view. The recording model object is defined in **Recording.swift** along with the seeded song data.
- **RecordingViewController.swift**: Plays the pre-recorded audio selected in the master controller. You'll code the currently stubbed out `handleTranscribeButtonTapped(_:)` to have it kick off file transcription.
- **LiveTranscribeViewController.swift**: Handles the Face Replace view, which leverages the code included in the **FaceReplace** folder. It currently displays live video and a collection view of emojis, attaching the selected emoji to any face in the live view. This is where you'll add code to record and transcribe audio.
- **FaceReplace**: Contains a library provided by Rich Turton that places emojis over faces in live video. It uses Core Image's CIDetector — but you don't need to understand how this works for this tutorial. However, if you'd like to learn more, you can read about CIDetector here: [apple.co/1Tx2uCN](http://apple.co/1Tx2uCN).

You'll start this chapter by making the transcribe button work for pre-recorded audio. It will then feed the audio file to Speech Recognizer and present the results in a label under the player.

The latter half of the chapter will focus on the Face Replace feature. You'll set up an audio engine for recording, tap into that input, and transcribe the audio as it arrives. You'll display the live transcription and ultimately use it to trigger placing emojis over the user's face.

You can't just dive right in and start voice commanding unicorns onto your face though; you'll need to understand a few basics first.

## Transcription basics

There are four primary actors involved in a speech transcription:

1. **SFSpeechRecognizer** is the primary controller in the framework. Its most important job is to generate recognition tasks and return results. It also handles authorization and configures locales. 
2. **SFSpeechRecognitionRequest** is the base class for recognition requests. Its job is to point the `SFSpeechRecognizer` to an audio source from which transcription should occur. There are two concrete types: **SFSpeechURLRecognitionRequest**, for reading from a file, and **SFSpeechAudioBufferRecognitionRequest** for reading from a buffer.
3. **SFSpeechRecognitionTask** objects are created when a request is kicked off by the recognizer. They are used to track progress of a transcription or cancel it.
4. **SFSpeechRecognitionResult** objects contain the transcription of a chunk of the audio. Each result typically corresponds to a single word.

Here's how these objects interact during a basic Speech Recognizer transcription:

![width=100%](./images/speech-recognizer-chart.png)

The code required to complete a transcription is quite simple. Given an audio file at `url`, the following code transcribes the file and prints the results:

```swift
let request = SFSpeechURLRecognitionRequest(url: url)
SFSpeechRecognizer()?.recognitionTask(with: request) { (result, _) in
  if let transcription = result?.bestTranscription {
    print("\(transcription.formattedString)")
  }
}
```

`SFSpeechRecognizer` kicks off a `SFSpeechRecognitionTask` for the `SFSpeechURLRecognitionRequest` using `recognitionTask(with:resultHandler:)`. It returns partial results as they arrive via the `resultHandler`. This code prints the formatted string value of the `bestTranscription`, which is a cumulative transcription result adjusted at each iteration.

You'll start by implementing a file transcription very similar to this.

## Audio file speech transcription 

Before you start reading and sending chunks of the user's audio off to a remote server, it would be polite to ask permission. In fact, considering their commitment to user privacy, it should come as no surprise that Apple requires this! :]

You'll kick off the the authorization process when the user taps the **Transcribe** button in the detail controller.

Open **RecordingViewController.swift** and add the following to the `import` statements at the top:

```swift
import Speech
```

This imports the Speech Recognition API.

Add the following to `handleTranscribeButtonTapped(_:)`:

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

You call the `SFSpeechRecognizer` type method `requestAuthorization(_:)` to prompt the user for authorization and handle their response in a completion closure. 

In the closure, you look at the `authStatus` and print error messages for all of the exception cases. For `authorized`, you unwrap the selected recording for later transcription.

Next, you have to provide a usage description displayed when permission is requested. Open **Info.plist** and add the key `Privacy - Speech Recognition Usage Description` providing the String value `I want to write down everything you say`:

![width=90% bordered](./images/speech-recognition-permission.png)

Build and run, select a song from the master controller, and tap **Transcribe**. You'll see a permission request appear with the text you provided. Select **OK** to provide Gangstribe the proper permission:

![iPhone bordered](./images/speech-recognition-prompt.png)

Of course nothing happens after you provide authorization — you haven't yet set up speech recognition! It's now time to test the limits of the framework with DJ Sammy D's renditions of popular rap music.

### Transcribing the file

Back in **RecordingViewController.swift**, find the `RecordingViewController` extension at the bottom of the file. Add the following method to transcribe a file found at the passed `url`:

```swift
fileprivate func transcribeFile(url: URL) {

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
      self.updateUIWithCompletedTranscription(
        result.bestTranscription.formattedString)
    }
  }
}
```

Here are the details on how this transcribes the passed file:

1. The default `SFSpeechRecognizer` initializer provides a recognizer for the device's locale, returning `nil` if there is no such recognizer. `isAvailable` checks if the `recognizer` is ready to be used, failing in cases such as missing network connectivity.
2. `updateUIForTranscriptionInProgress()` is provided with the starter to disable the Transcribe button and start an activity indicator animation while the transcription is in process. A `SFSpeechURLRecognitionRequest` is created for the file found at `url`, creating an interface to the transcription engine for that recording.
3. `recognitionTask(with:resultHandler:)` processes the transcription `request`, repeatedly triggering a completion closure. The passed `result` is unwrapped in a guard, which prints an error on failure.
4. The `isFinal` property will be true when the entire transcription is complete. `updateUIWithCompletedTranscription(_:)` stops the activity indicator, re-enables the button and displays the passed string in a text view. `bestTranscription` contains the transcription Speech Recognizer is most confident is accurate, and `formattedString` provides it in String format for display in the text view.

>**Note**: Where there is a `bestTranscription`, there can of course be lesser ones. `SFSpeechRecognitionResult` has a `transcriptions` property that contains an array of transcriptions sorted in order of confidence. As you see with Siri and Keyboard Dictation, a transcription can change as more context arrives, and this array illustrates that type of progression.

Now you need to call this new code when the user taps the Transcribe button. In `handleTranscribeButtonTapped(_:)` replace `//TODO: Kick off the transcription` with the following:

```swift
self.transcribeFile(url: recording.audio)
```

After successful authorization, the button handler now calls `transcribeFile(url:)` with the URL of the currently selected recording. 

Build and run, select **Gangsta's Paradise**, and then tap the **Transcribe** button. You'll see the activity indicator for a while, and then the text view will eventually populate with the transcription:

![iPhone bordered](./images/transcription-result.png)

## Transcription and locales

The results aren't bad, considering Coolio doesn't seem to own a copy of Webster's Dictionary. Depending on the locale of your device, there could be another reason things are a bit off. The above screenshot was a transcription completed on a device configured for US English, while DJ Sammy D has a slightly different dialect.

But you don't need to book a flight overseas to fix this. When creating a recognizer, you have the option of specifying a locale — that's what you'll do next.

>**Note**: Even if your device is set to en_GB (English - United Kingdom) as Sam's is, the locale settings are important to Gangstribe. In just a bit, you'll transcribe text in an entirely different language!

Still in **RecordingViewController.swift**, find `transcribeFile(url:)` and replace the following two lines:

```swift
fileprivate func transcribeFile(url: URL) {
  guard let recognizer = SFSpeechRecognizer() else {
```

with the code below:

```swift
fileprivate func transcribeFile(url: URL, locale: Locale?) {
  let locale = locale ?? Locale.current
  
  guard let recognizer = SFSpeechRecognizer(locale: locale) else {
```

You've added an optional `Locale` parameter which will specify the locale of the file being transcribed. If `locale` is `nil` when unwrapped, you fall back to the device's locale. You then initialize the `SFSpeechRecognizer` with this locale.

Now you need to modify where this method is called. Find `handleTranscribeButtonTapped(_:)` and replace the `transcribeFile(url:)` call with the following:

```swift
self.transcribeFile(url: recording.audio, locale: recording.locale)
```

You use the new method signature, passing the locale stored with the `recording` object. 

>**Note**: If you want to see the locale associated with a Gangstribe recording, open **Recording.swift** and look at the `recordingNames` array up top. Each element contains the song name, artist, audio file name and locale. You can find information on how locale identifiers are derived in Apple's Internationalization and Localization Guide here — [apple.co/1HVWDQa](http://apple.co/1HVWDQa)

Build and run, and complete another transcription on **Gangsta's Paradise**. Assuming your first run was with a locale other than `en_GB`, you should see some differences.

![iPhone bordered](./images/transcription-result-with-locale.png)

In both transcription screenshots, look for the words following *treated like a punk you know that's*. With the correct locale set, the next words read *unheard-of* whereas the American English transcription heard *on head of*. This is a great example of the power of this framework with its understanding of a wide range of languages and dialects.

>**Note**: Keep in mind that your transcriptions may differ from the screenshots. The engine evolves over time and it does customize itself based on its knowledge of you.

You can probably understand different dialects of languages you speak pretty well. But you're probably significantly weaker when it comes to understanding languages you don't speak. The Speech Recognition engine understands over 50 different languages and dialects, so it likely has you beat here.

Now that you are passing the locale of files you're transcribing, you'll be able to successfully transcribe a recording in any supported language. Build and run, and select the song **Raise Your Hands**, which is in Thai. Play it, and then tap **Transcribe** and you'll see something like this:  

![iPhone bordered](./images/thai-transcription.png)

Flawless transcription! Presumably.

## Live speech recognition  

Live transcription is very similar to file transcription. The primary difference in the process is a different request type — **SFSpeechAudioBufferRecognitionRequest** — which is used for live transcriptions.

As the name implies, this type of request reads from an audio buffer. Your task will be to append live audio buffers to this request as they arrive from the source. Once connected, the actual transcription process will be identical to the one for recorded audio.

Another consideration for live audio is that you'll need a way to stop a transcription when the user is done speaking. This requires maintaining a reference to the **SFSpeechRecognitionTask** so that it can later be canceled.

Gangstribe has some pretty cool tricks up its sleeve. For this feature, you'll not only transcribe live audio, but you'll use the transcriptions to trigger some visual effects. With the use of the FaceReplace library, speaking the name of a supported emoji will plaster it right over your face!

### Connect to the audio buffer

To do this, you'll have to configure the audio engine and hook it up to a recognition request. But before you start recording and transcribing, you need to request authorization to use speech recognition in this controller.

Open **LiveTranscribeViewController.swift** and add the following to the top of the file by the other imports:

```swift
import Speech
```

Now the live transcription controller has access to Speech Recognition.

Next find `viewDidLoad()` and replace the line `startRecording()` with the following:

```swift
SFSpeechRecognizer.requestAuthorization {
  [unowned self] (authStatus) in
  switch authStatus {
  case .authorized:
    self.startRecording()
  case .denied:
    print("Speech recognition authorization denied")
  case .restricted:
    print("Not available on this device")
  case .notDetermined:
    print("Not determined")
  }
}
```

Just as you did with pre-recorded audio, you're calling `requestAuthorization(_:)` to obtain or confirm access to Speech Recognition. 

For the `authorized` status, you call `startRecording()` which currently just does some preparation — you'll implement the rest shortly. For failures, you print relevant error messages.

Next, add the following properties at the top of `LiveTranscribeViewController`: 

```swift
let audioEngine = AVAudioEngine()
let speechRecognizer = SFSpeechRecognizer()
let request = SFSpeechAudioBufferRecognitionRequest()
var recognitionTask: SFSpeechRecognitionTask?
```

- **audioEngine** is an `AVAudioEngine` object you'll use to process input audio signals from the microphone.
- **speechRecognizer** is the `SFSpeechRecognizer` you'll use for live transcriptions.
- **request** is the `SFSpeechAudioBufferRecognitionRequest` the speech recognizer will use to tap into the audio engine.
- **recognitionTask** will hold a reference to the `SFSpeechRecognitionTask` kicked off when transcription begins.

Now find `startRecording()` in a `LiveTranscribeViewController` extension in this same file. This is called when the Face Replace view loads, but it doesn't yet do any recording. Add the following code to the bottom of the method:

```swift
// 1
guard let node = audioEngine.inputNode else {
  print("Couldn't get an input node!")
  return
}
let recordingFormat = node.outputFormat(forBus: 0)

// 2
node.installTap(onBus: 0, bufferSize: 1024,
                format: recordingFormat) { [unowned self]
  (buffer, _) in
  self.request.append(buffer)
}

// 3
audioEngine.prepare()
try audioEngine.start()
```

This code does the following:

1. Obtains the input audio `node` associated with the device's microphone, as well as its corresponding `outputFormat`. 
2. Installs a tap on the output bus of `node`, using the same recording format. When the buffer is filled, the closure returns the data in `buffer` which is appended to the `SFSpeechAudioBufferRecognitionRequest`. The `request` is now tapped into the live input node.
3. Prepares and starts the `audioEngine` to start recording, and thus gets data going to the tap.

Because starting the audio engine throws, you need to signify this on the method. Change the method definition to match the following:

```swift
fileprivate func startRecording() throws {
```

With this change, you likewise need to modify where the method gets called. Find `viewDidLoad()` and replace `self.startRecording()` with the following:

```swift
do {
  try self.startRecording()
} catch let error {
  print("There was a problem starting recording: \(error.localizedDescription)")
}
```

`startRecording()` is now wrapped in a `do-catch`, printing the error if it fails.

There is one last thing to do before you can kick off a recording — ask for user permission. The framework does this for you, but you need to provide another key in the plist with an explanation. Open **Info.plist** and add the key `Privacy - Microphone Usage Description` providing the String value `I want to record you live`:

![width=90% bordered](./images/microphone-privacy-setting.png) 

Build and run, choose a recording, then select **Face Replace** from the navigation bar. You'll immediately be greeted with a prompt requesting permission to use the microphone. Hit **OK** so that Gangstribe can eventually transcribe what you say:

![iPhone bordered](./images/microphone-permission.png)

With the tap in place, and recording started, you can finally kick off the speech recognition task. 

In **LiveTranscribeViewController.swift**, go back to `startRecording()` and add the following at the bottom of the method:

```swift
recognitionTask = speechRecognizer?.recognitionTask(with: request) {
  [unowned self]
  (result, _) in
  if let transcription = result?.bestTranscription {
    self.transcriptionOutputLabel.text = transcription.formattedString 
  }
}
```

`recognitionTask(with:resultHandler:)` is called with the `request` connected to the tap, kicking off transcription of live audio. The task is saved in `recognitionTask` for later use.

In the closure, you get `bestTranscription` from the result. You then update the label that displays the transcription with the formatted string of the `transcription`.

Build and run, and tap the **Face Replace** button in the navigation bar. Start talking, and you'll now see a real time transcription from speech recognition!

![iPhone bordered](./images/first-live-transcription.png)

>**Note**: Apple has hinted at some throttling limits, including an utterance duration limit of “about one minute”. If you stay in live transcription long enough, you'll probably see it stop responding. Now you know why!

But there's a problem. If you try opening Face Replace enough times, it will crash spectacularly. You're currently leaking the `SFSpeechAudioBufferRecognitionRequest` because you've never stopping transcription or recording!

Add the following method to the `LiveTranscribeViewController` extension that also contains `startRecording()`: 

```swift
fileprivate func stopRecording() {
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

### Transcription segments 

The live transcription below your video is pretty cool, but it's not what you set out to do. It's time to dig into these transcriptions and use them to trigger the emoji face replacement!

First, you need to understand a bit more about the data contained in the `SFTranscription` objects returned in `SFSpeechRecognitionResult` objects. You've been accessing these with the `bestTranscription` property of results returned to the `recognitionTask(with:resultHandler:)` closure.

`SFTranscription` has a `segments` property containing an array of all `SFTranscriptionSegment` objects returned from the request. Among other things, a `SFTranscriptionSegment` has a `substring` containing the transcribed String for that segment, as well as its `duration` from the start of the transcription. Generally, each segment will consist of a single word.

Each time the live transcription returns a new result, you want to look at the most recent segment to see if it matches an emoji keyword.

First add the following property to at the top of the class:

```swift
var mostRecentlyProcessedSegmentDuration: TimeInterval = 0
```

`mostRecentlyProcessedSegmentDuration` tracks the timestamp of the last processed segment. Because the segment duration is from the start of transcription, the highest duration indicates the latest segment.

Now add the following to the top of `startRecording()`:

```swift
mostRecentlyProcessedSegmentDuration = 0
```

This will reset the tracked duration each time recording starts. 

Now add the following new method to the bottom of the last `LiveTranscribeViewController` extension:

```swift
// 1
fileprivate func updateUIWithTranscription(_ transcription: SFTranscription) {
  self.transcriptionOutputLabel.text = transcription.formattedString
  
  // 2
  if let lastSegment = transcription.segments.last,
    lastSegment.duration > mostRecentlyProcessedSegmentDuration {
    mostRecentlyProcessedSegmentDuration = lastSegment.duration
    // 3
    faceSource.selectFace(lastSegment.substring)
  }
}
```
Here's what this code does:

1. This defines a new method that accepts an `SFTranscription` and uses it to update the UI with results. First, it updates the transcription label at the bottom of the screen with the results; this will soon replace similar code found in `startRecording()`.
2. This unwraps the `last` segment from the passed `transcription`. It then checks that the segment's duration is higher than the `mostRecentlyProcessedSegmentDuration` to avoid an older segment being processed if it returns out of order. The new duration is then saved in `mostRecentlyProcessedSegmentDuration`.
3. `selectFace()`, part of the Face Replace code, accepts the `substring` of this new transcription, and completes a face replace if it matches one of the emoji names.

In `startRecording()`, replace the following line:

```swift
self.transcriptionOutputLabel.text = transcription.formattedString
```

with:

```swift
self.updateUIWithTranscription(transcription)
```

`updateUIWithTranscription()` is now called each time the `resultHandler` is executed. It will update the transcription label as well as triggering a face replace if appropriate. Because this new method updates the transcription label, you removed the code that previously did it here.

Build and run and select **Face Replace**. This time, say the name of one of the emojis. Try “cry” as your first attempt. 

The speech recognizer will transcribe the word “cry” and feed it to the `FaceSource` object, which will attach the cry emoji to your face. What a time to be alive!

![iPhone bordered](./images/cry-face-replace.png)

>**Note**: For a full list of available keywords, open **FaceSource.swift** and look for the `names` array. Each of these map to one of the emojis in the `faces` array above it.

## Usage guidelines

While they aren't yet clearly defined, Apple has provided some usage guidelines for Speech Recognition.

Apple will be enforcing the following types of limitations:

- Per device per day
- Per app per day (global limitations for all users of your app)
- One minute limitation for a single utterance (from start to end of a recognition task) 

Apple hasn't provided any numbers for device and app daily limits. These rules are likely to mature and become more concrete as Apple sees how third party developers use the framework.

Apple also emphasizes that you must make it very clear to users when they are being recorded. While it isn't currently in the review guidelines, it's in your best interest to follow this closely to avoid rejections. You also wouldn't want to invade your user's privacy!

Finally, Apple suggests presenting transcription results before acting on them. Sending a text message via Siri is a great example of this: she'll present editable transcription results and delay before sending the message. Transcription is certainly not perfect, and you want to protect users from the frustration and possible embarrassment of mistakes.

## Where to go from here?

In this chapter, you learned everything you need to know to get basic speech recognition working in your apps. It's an extremely powerful feature where the framework does the heavy lifting. With just a few lines of code, you can bring a lot of magic to your apps.

There isn't currently much documentation on Speech Recognition, so your best bet is to explore the headers in the source for more detail.

Here are a couple of other places to go for more info:

- WWDC Speech Recognition API Session - [apple.co/2aSMrlw](http://apple.co/2aSMrlw)
- Apple Speech Recognition sample project (SpeakToMe) - [apple.co/2aSO6HS](http://apple.co/2aSO6HS)