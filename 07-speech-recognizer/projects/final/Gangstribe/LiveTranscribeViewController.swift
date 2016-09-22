/*
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import GLKit
import AVFoundation
import Speech

class LiveTranscribeViewController: UIViewController {

  let audioEngine = AVAudioEngine()
  let speechRecognizer = SFSpeechRecognizer()
  let request = SFSpeechAudioBufferRecognitionRequest()
  var recognitionTask: SFSpeechRecognitionTask?
  var mostRecentlyProcessedSegmentDuration: TimeInterval = 0
  
  @IBOutlet weak var imageView: GLKView!
  var faceReplacer: FaceReplacer!
  
  @IBOutlet weak var faceCollectionView: UICollectionView!
  let faceSource = FaceSource()
  
  @IBOutlet weak var transcriptionOutputLabel: UILabel!
  
  @IBAction func handleDoneTapped(_ sender: BorderedButton) {
    faceReplacer.stopCapture()
    stopRecording()
    dismiss(animated: true, completion: .none)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    initialiseFaceReplacer()
    SFSpeechRecognizer.requestAuthorization {
      [unowned self] (authStatus) in
      switch authStatus {
      case .authorized:
        do {
          try self.startRecording()
        } catch let error {
          print("There was a problem starting recording: \(error.localizedDescription)")
        }
      case .denied:
        print("Speech recognition authorization denied")
      case .restricted:
        print("Not available on this device")
      case .notDetermined:
        print("Not determined")
      }
    }
  }
}

// MARK: - Recording Management
extension LiveTranscribeViewController {
  fileprivate func startRecording() throws {
    self.transcriptionOutputLabel.text = ""
    mostRecentlyProcessedSegmentDuration = 0
    
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
    audioEngine.prepare()
    try audioEngine.start()
    
    recognitionTask = speechRecognizer?.recognitionTask(with: request) {
      [unowned self]
      (result, _) in
      if let transcription = result?.bestTranscription {
        self.updateUIWithTranscription(transcription)
      }
    }
  }
  
  fileprivate func stopRecording() {
    audioEngine.stop()
    request.endAudio()
    recognitionTask?.cancel()
  }
}

// MARK: - Face Replacer
extension LiveTranscribeViewController {
  fileprivate func initialiseFaceReplacer() {
    faceReplacer = FaceReplacer(imageView: imageView)
    do {
      try faceReplacer.startCapture()
    } catch let error as NSError {
      let alert = UIAlertController(title: "Sorry", message: error.localizedDescription, preferredStyle: .alert)
      present(alert, animated: true, completion: .none)
    }
    faceCollectionView.dataSource = faceSource
    faceCollectionView.delegate = faceSource
    faceSource.collectionView = faceCollectionView
    faceSource.faceChosen = {
      [unowned self]
      face in
      self.faceReplacer.newFace = face
    }
  }
  
  fileprivate func updateUIWithTranscription(_ transcription: SFTranscription) {
    self.transcriptionOutputLabel.text = transcription.formattedString
    
    if let lastSegment = transcription.segments.last,
      lastSegment.duration > mostRecentlyProcessedSegmentDuration {
      mostRecentlyProcessedSegmentDuration = lastSegment.duration
      faceSource.selectFace(lastSegment.substring)
    }
  }
}

