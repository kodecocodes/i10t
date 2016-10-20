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
import Photos
import PhotosUI

class PhotoEditingViewController: UIViewController {
  
  @IBOutlet weak var livePhotoView: PHLivePhotoView!
  @IBAction func handleComicifyTapped(_ sender: UIButton) {
    comicifyImage()
  }
  @IBAction func handleDoneTapped(_ sender: UIButton) {
    dismiss(animated: true)
  }
  
  var asset: PHAsset?

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if let asset = asset {
      PHImageManager.default().requestLivePhoto(for: asset, targetSize: livePhotoView.bounds.size, contentMode: .aspectFill, options: .none, resultHandler: { (livePhoto, info) in
        DispatchQueue.main.async {
          self.livePhotoView.livePhoto = livePhoto
        }
      })
    }
  }
  
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
          
          let output = PHContentEditingOutput(contentEditingInput: input)
          output.adjustmentData = PHAdjustmentData(formatIdentifier: "PhotoMe", formatVersion: "1.0", data: "Comicify".data(using: .utf8)!)
          editingContext?.saveLivePhoto(to: output, options: nil) {
            success, error in
            PHPhotoLibrary.shared().performChanges({
              let request = PHAssetChangeRequest(for: asset)
              request.contentEditingOutput = output
              }, completionHandler: { (success, error) in
                print("\(success), \(error)")
            })
          }
      }
    }
  }
  
  
}
