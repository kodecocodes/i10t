## speech-recognizer

Introduction
- Overview of the framework (backend, multiple languages, limitations, comparison to other options)

##Getting Started [Instruction]
- Review starter project (reference to Face Replace)
- Describe completed project

##Audio File Speech Transcription [Theory]
- Brief overview of file transcription

###Requesting Authorization [Instruction]
- add the plist key for recognition
- Call requestAuthorization

###Transcribing the File [Instruction]
- Transcribe the file
- add localization

##Live Speech Recognition [Theory]  
(this is going to be pretty light I think, so may end up jumping straight to instruction)

- Describe the difference between file & live transcription
    - SFSpeechAudioBufferRecognitionRequest
    - SFSpeechRecognitionTask cleanup

###Connect to the Audio Buffer [Instruction]
- New plist entries
- Use  SFSpeechAudioBufferRecognitionRequest to pull audio from AVAudioEngine
- Start audio engine and update UI with transcription progress
- Stop / Cancel recording & task

###Triggering Face Replace [Instruction] 
(this is pretty short and may be absorbed into the above section)

- Extract segments and pass it to face replace

##Limitations [Reference]
Some notes on the fairly vague throttling policy outlined in the WWDC video

##Where to Go From Here?
- WWDC Video
- Apple sample app


