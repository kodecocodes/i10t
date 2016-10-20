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
import AVFoundation
import Photos

class ViewController: UIViewController {
  
  //MARK: Interface builder
  @IBOutlet weak var cameraPreviewView: CameraPreviewView!
  @IBOutlet weak var shutterButton: UIButton!
  @IBOutlet weak var previewImageView: UIImageView!
  @IBOutlet weak var thumbnailSwitch: UISwitch!
  @IBOutlet weak var livePhotoSwitch: UISwitch!
  @IBOutlet weak var capturingLabel: UILabel!
  @IBAction func handleShutterButtonTap(_ sender: UIButton) {
    capturePhoto()
  }
    
    @IBAction func handlePreviewTap(_ sender: UITapGestureRecognizer) {
    }
  
  //MARK: Properties
  fileprivate let session = AVCaptureSession()
  fileprivate let sessionQueue = DispatchQueue(label: "com.razeware.PhotoMe.session-queue")
  var videoDeviceInput: AVCaptureDeviceInput!
  fileprivate let photoOutput = AVCapturePhotoOutput()
  fileprivate var photoCaptureDelegates = [Int64 : PhotoCaptureDelegate]()
  fileprivate var currentLivePhotoCaptures: Int = 0
  fileprivate var lastAsset: PHAsset?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    cameraPreviewView.session = session
    sessionQueue.suspend()
    AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo) {
      success in
      if !success {
        print("Come on, it's a camera app!")
        return
      }
      self.sessionQueue.resume()
    }
    
    sessionQueue.async {
      [unowned self] in
      self.prepareCaptureSession()
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    sessionQueue.async {
      self.session.startRunning()
    }
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let editor = segue.destination as? PhotoEditingViewController {
      editor.asset = lastAsset
    }
  }
  
  private func prepareCaptureSession() {
    session.beginConfiguration()
    
    session.sessionPreset = AVCaptureSessionPresetPhoto
    
    // Create a video input device - using the front-facing camera
    do {
      let videoDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .front)
      let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
      
      if session.canAddInput(videoDeviceInput) {
        session.addInput(videoDeviceInput)
        self.videoDeviceInput = videoDeviceInput
        
        DispatchQueue.main.async {
          self.cameraPreviewView.cameraPreviewLayer.connection.videoOrientation = .portrait
        }
      } else {
        print("Couldn't add device to the session")
        return
      }
    } catch {
      print("Couldn't create video device input: \(error)")
      return
    }
    
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
    
    // Create photo output
    if session.canAddOutput(photoOutput) {
      session.addOutput(photoOutput)
      photoOutput.isHighResolutionCaptureEnabled = true
      photoOutput.isLivePhotoCaptureEnabled = photoOutput.isLivePhotoCaptureSupported
      DispatchQueue.main.async {
        self.livePhotoSwitch.isEnabled = self.photoOutput.isLivePhotoCaptureSupported
      }
    } else {
      print("Unable to add photo output")
      return
    }
    
    session.commitConfiguration()
  }
  
}

// MARK: - Photo Capture
extension ViewController {
  fileprivate func capturePhoto() {
    let cameraPreviewLayerOrientation = cameraPreviewView.cameraPreviewLayer.connection.videoOrientation
    
    sessionQueue.async {
      if let connection = self.photoOutput.connection(withMediaType: AVMediaTypeVideo) {
        connection.videoOrientation = cameraPreviewLayerOrientation
      }
      
      // Capture a JPEG
      let photoSettings = AVCapturePhotoSettings()
      photoSettings.flashMode = .off
      photoSettings.isHighResolutionPhotoEnabled = true
      
      // Capture a preview image
      if self.thumbnailSwitch.isOn && photoSettings.availablePreviewPhotoPixelFormatTypes.count > 0 {
        photoSettings.previewPhotoFormat = [
          kCVPixelBufferPixelFormatTypeKey as String : photoSettings.availablePreviewPhotoPixelFormatTypes.first!,
          kCVPixelBufferWidthKey as String : 160,
          kCVPixelBufferHeightKey as String : 160
        ]
      }
      
      // Capture a Live Photo
      if self.livePhotoSwitch.isOn {
        let movieFileName = UUID().uuidString
        let moviePath = (NSTemporaryDirectory() as NSString).appendingPathComponent("\(movieFileName).mov")
        photoSettings.livePhotoMovieFileURL = URL(fileURLWithPath: moviePath)
      }
      
      // Create a delegate
      let uniqueID = photoSettings.uniqueID
      let photoCaptureDelegate = PhotoCaptureDelegate() { [unowned self] (photoCaptureDelegate, asset) in
        self.sessionQueue.async { [unowned self] in
          self.photoCaptureDelegates[uniqueID] = .none
          self.lastAsset = asset
        }
      }
      
      // UI Update for begins
      photoCaptureDelegate.photoCaptureBegins = { [unowned self] in
        DispatchQueue.main.async {
          self.shutterButton.isEnabled = false
          self.cameraPreviewView.cameraPreviewLayer.opacity = 0
          UIView.animate(withDuration: 0.2) {
            self.cameraPreviewView.cameraPreviewLayer.opacity = 1
          }
        }
      }
      
      // Display the thumbnail when it arrives
      photoCaptureDelegate.thumbnailCaptured = { [unowned self] image in
        DispatchQueue.main.async {
          self.previewImageView.image = image
        }
      }
      
      // Handle completion
      photoCaptureDelegate.photoCaptured = { [unowned self] in
        DispatchQueue.main.async {
          self.shutterButton.isEnabled = true
        }
      }
      
      // Live photo UI updates
      photoCaptureDelegate.capturingLivePhoto = { (currentlyCapturing) in
        DispatchQueue.main.async { [unowned self] in
          self.currentLivePhotoCaptures += currentlyCapturing ? 1 : -1
          UIView.animate(withDuration: 0.2) {
            self.capturingLabel.isHidden = self.currentLivePhotoCaptures == 0
          }
        }
      }
      
      self.photoCaptureDelegates[uniqueID] = photoCaptureDelegate
      
      self.photoOutput.capturePhoto(with: photoSettings, delegate: photoCaptureDelegate)
      
    }
  }
}

