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

let animalImages = [#imageLiteral(resourceName: "bear"), #imageLiteral(resourceName: "frog"), #imageLiteral(resourceName: "wolf"), #imageLiteral(resourceName: "cat")]

class ViewController: UIViewController {
  // Properties
  var imageMoveAnimator: UIViewPropertyAnimator?
  var imageChangeAnimator: UIViewPropertyAnimator?
  var imageDragStartPosition: CGPoint?
  
  // IBOutlets
  @IBOutlet weak var progressSlider: UISlider!
  @IBOutlet weak var stateSegment: UISegmentedControl!
  @IBOutlet weak var runningSegment: UISegmentedControl!
  @IBOutlet weak var reversedSegment: UISegmentedControl!
  @IBOutlet weak var imageContainer: UIView!
  @IBOutlet weak var animalImageView: UIImageView!
  @IBOutlet weak var stopButton: UIButton!
  
  // IBActions
  @IBAction func handleProgressSliderChanged(_ sender: UISlider) {
    imageMoveAnimator?.fractionComplete = CGFloat(sender.value)
    imageChangeAnimator?.fractionComplete = CGFloat(sender.value)
  }
  
  @IBAction func handleAnimateButtonTapped(_ sender: UIButton) {
    if let imageMoveAnimator = imageMoveAnimator, imageMoveAnimator.isRunning {
      imageMoveAnimator.isReversed = !imageMoveAnimator.isReversed
      imageChangeAnimator?.isReversed = imageMoveAnimator.isReversed
    } else {
      animateAnimalToRandomLocation()
      animateRandomAnimalChange()
    }
  }
  
  @IBAction func handleStopButtonTapped(_ sender: UIButton) {
    guard let imageMoveAnimator = imageMoveAnimator else {
      return
    }
    switch imageMoveAnimator.state {
    case .active:
      imageMoveAnimator.stopAnimation(false)
      imageChangeAnimator?.pauseAnimation()
    case .inactive:
      break
    case .stopped:
      imageMoveAnimator.finishAnimation(at: .current)
      if let imageChangeAnimator = imageChangeAnimator,
        let timing = imageChangeAnimator.timingParameters {
        imageChangeAnimator.continueAnimation(withTimingParameters: timing,
                                              durationFactor: 0.2)
      }
    }
  }
  
  @IBAction func handleTapOnImage(_ sender: UITapGestureRecognizer) {
    guard let imageMoveAnimator = imageMoveAnimator else {
      return
    }
    progressSlider.isHidden = true
    switch imageMoveAnimator.state {
    case .active:
      if imageMoveAnimator.isRunning {
        imageMoveAnimator.pauseAnimation()
        imageChangeAnimator?.pauseAnimation()
        progressSlider.isHidden = false
        progressSlider.value = Float(imageMoveAnimator.fractionComplete)
      } else {
        imageMoveAnimator.startAnimation()
        imageChangeAnimator?.startAnimation()
      }
    default:
      break
    }
    stopButton.isHidden = progressSlider.isHidden
  }
  
  @IBAction func handleDragImage(_ sender: UIPanGestureRecognizer) {
    switch sender.state {
    case .began:
      imageDragStartPosition = imageContainer.center
    case .changed:
      imageContainer.center = sender.location(in: view)
    case .ended:
      if let imageDragStartPosition = imageDragStartPosition {
        //1
        let animationVelocity = sender.velocity(in: view)
        //2
        let animationDistance = imageContainer.center.distance(toPoint: imageDragStartPosition)
        //3
        let normalisedVelocity = animationVelocity.normalise(weight: animationDistance)
        //4
        let initialVelocity = normalisedVelocity.toVector
        animateAnimalTo(location: imageDragStartPosition, initialVelocity: initialVelocity)
      }
      imageDragStartPosition = .none
    default:
      break
    }
  }
}


extension ViewController {
  private func animateAnimalTo(location: CGPoint,
                               initialVelocity: CGVector = .zero) {
    
    removeAnimatorObservers(animator: imageMoveAnimator)
    let mass: CGFloat = 1.0
    let stiffness: CGFloat = 10.0
    let criticalDamping = 2 * sqrt(mass * stiffness)
    let damping = criticalDamping * 0.5
    let parameters = UISpringTimingParameters(
      mass: mass,
      stiffness: stiffness,
      damping: damping,
      initialVelocity: initialVelocity)
    imageMoveAnimator = UIViewPropertyAnimator(duration: 10, timingParameters: parameters)
    imageMoveAnimator?.addAnimations {
      self.imageContainer.center = location
    }
    
    imageMoveAnimator?.addCompletion { position in
      switch position {
      case .end: print("End")
      case .start: print("Start")
      case .current: print("Current")
      }
    }
    
    addAnimatorObservers(animator: imageMoveAnimator)
    imageMoveAnimator?.startAnimation()
  }
  
  private func animateAnimalToRandomLocation() {
    animateAnimalTo(location: view.randomPoint)
  }
  
  private func animateRandomAnimalChange() {
    let randomImage = animalImages[Int(arc4random_uniform(UInt32(animalImages.count)))]
    
    let duration = imageMoveAnimator?.duration ?? 3.0
    
    let originalImage = animalImageView.image
    let snapshot = animalImageView.snapshotView(afterScreenUpdates: false)!
    imageContainer.addSubview(snapshot)
    animalImageView.alpha = 0
    animalImageView.image = randomImage
    
    imageChangeAnimator = UIViewPropertyAnimator(duration: duration, curve: .linear) {
      self.animalImageView.alpha = 1
      snapshot.alpha = 0
    }
    
    imageChangeAnimator?.addCompletion({ (position) in
      if position == .start {
        self.animalImageView.image = originalImage
        self.animalImageView.alpha = 1
      }
      snapshot.removeFromSuperview()
    })
    
    imageChangeAnimator?.startAnimation()
  }
}

