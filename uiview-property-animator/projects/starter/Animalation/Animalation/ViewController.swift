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

class ViewController: UIViewController {
  // Properties
  var imageMoveAnimator: UIViewPropertyAnimator?
  var imageDragStartPosition: CGPoint?

  // IBOutlets
  @IBOutlet weak var progressSlider: UISlider!
  @IBOutlet weak var stateSegment: UISegmentedControl!
  @IBOutlet weak var runningSegment: UISegmentedControl!
  @IBOutlet weak var reversedSegment: UISegmentedControl!
  @IBOutlet weak var imageContainer: UIView!
  @IBOutlet weak var animalImageView: UIImageView!
  
  // IBActions
  @IBAction func handleProgressSliderChanged(_ sender: UISlider) {
    // Coming soon
  }

  @IBAction func handleAnimateButtonTapped(_ sender: UIButton) {
    animateAnimalToRandomLocation()
  }
  
  @IBAction func handleTapOnImage(_ sender: UITapGestureRecognizer) {
    // Coming Soon
  }
  
  @IBAction func handleDragImage(_ sender: UIPanGestureRecognizer) {
    switch sender.state {
    case .began:
      imageDragStartPosition = imageContainer.center
    case .changed:
      imageContainer.center = sender.location(in: view)
    case .ended:
      if let imageDragStartPosition = imageDragStartPosition {
        animateAnimalTo(location: imageDragStartPosition)
        // TODO
      }
      imageDragStartPosition = .none
    default:
      break
    }
  }
}


extension ViewController {
  private func animateAnimalTo(location: CGPoint) {
    // TODO
    UIView.animate(withDuration: 3) { 
      self.imageContainer.center = location
    }
  }
  
  private func animateAnimalToRandomLocation() {
    animateAnimalTo(location: view.randomPoint)
  }
}

