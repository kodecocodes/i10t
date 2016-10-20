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

import AVFoundation
import Photos

class PhotoCaptureDelegate: NSObject {
  // 1
  var photoCaptureBegins: (() -> ())? = .none
  var photoCaptured: (() -> ())? = .none
  var thumbnailCaptured: ((UIImage?) -> ())? = .none
  var capturingLivePhoto: ((Bool) -> ())? = .none
  fileprivate var livePhotoMovieURL: URL? = .none
  
  fileprivate let completionHandler: (PhotoCaptureDelegate, PHAsset?) -> ()
  
  // 2
  fileprivate var photoData: Data? = .none
  
  // 3
  init(completionHandler: @escaping (PhotoCaptureDelegate, PHAsset?) -> ()) {
    self.completionHandler = completionHandler
  }
  
  // 5
  fileprivate func cleanup(asset: PHAsset? = .none) {
    completionHandler(self, asset)
  }
}

extension PhotoCaptureDelegate: AVCapturePhotoCaptureDelegate {
  
  func capture(_ captureOutput: AVCapturePhotoOutput, willCapturePhotoForResolvedSettings resolvedSettings: AVCaptureResolvedPhotoSettings) {
    if resolvedSettings.livePhotoMovieDimensions.width > 0
      && resolvedSettings.livePhotoMovieDimensions.height > 0 {
      capturingLivePhoto?(true)
    }
    photoCaptureBegins?()
  }

  func capture(_ captureOutput: AVCapturePhotoOutput, didCapturePhotoForResolvedSettings resolvedSettings: AVCaptureResolvedPhotoSettings) {
    photoCaptured?()
  }
  
  func capture(_ captureOutput: AVCapturePhotoOutput, didFinishRecordingLivePhotoMovieForEventualFileAt outputFileURL: URL, resolvedSettings: AVCaptureResolvedPhotoSettings) {
    capturingLivePhoto?(false)
  }
  
  // Process data completed
  func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
    guard let photoSampleBuffer = photoSampleBuffer else {
      print("Error capturing photo \(error)")
      return
    }
    photoData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer)
    
    if let thumbnailCaptured = thumbnailCaptured,
      let previewPhotoSampleBuffer = previewPhotoSampleBuffer,
      let cvImageBuffer = CMSampleBufferGetImageBuffer(previewPhotoSampleBuffer) {
      
      let ciThumbnail = CIImage(cvImageBuffer: cvImageBuffer)
      let context = CIContext(options: [kCIContextUseSoftwareRenderer: false])
      let thumbnail = UIImage(cgImage: context.createCGImage(ciThumbnail, from: ciThumbnail.extent)!, scale: 2.0, orientation: .right)
      
      thumbnailCaptured(thumbnail)
    }
  }
  
  func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingLivePhotoToMovieFileAt outputFileURL: URL, duration: CMTime, photoDisplay photoDisplayTime: CMTime, resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
    if let error = error {
      print("Error creating live photo video: \(error)")
      return
    }
    livePhotoMovieURL = outputFileURL
  }
  
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
        
        if let livePhotoMovieURL = self.livePhotoMovieURL {
          let movieResourceOptions = PHAssetResourceCreationOptions()
          movieResourceOptions.shouldMoveFile = true
          creationRequest.addResource(with: .pairedVideo, fileURL: livePhotoMovieURL, options: movieResourceOptions)
        }
        
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
}
