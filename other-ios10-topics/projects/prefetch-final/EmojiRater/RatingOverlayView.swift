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

class RatingOverlayView: UIView {
  var blurView: UIVisualEffectView?
  var animator: UIViewPropertyAnimator?
  private var overlaySnapshot: UIView?
  private var ratingStackView: UIStackView?

  
  func updateAppearance(forPreviewProgress progress: CGFloat) {
    animator?.fractionComplete = progress
  }
  
  func updateAppearance(forCommitProgress progress: CGFloat, touchLocation: CGPoint) {
    // During the commit phase the user can select a rating based on touch location
    if let ratingStackView = ratingStackView {
      for subview in ratingStackView.arrangedSubviews {
        let translatedPoint = convert(touchLocation, to: subview)
        if subview.point(inside: translatedPoint, with: .none) {
          subview.backgroundColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1).withAlphaComponent(0.6)
        } else {
          subview.backgroundColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1).withAlphaComponent(0.2)
        }
      }
    }
  }
  
  func completeCommit(at touchLocation: CGPoint) -> String {
    // At commit, find the selected rating and pass it back
    var selectedRating = ""
    if let ratingStackView = ratingStackView {
      for subview in ratingStackView.arrangedSubviews where subview is UILabel {
        let subview = subview as! UILabel
        let translatedPoint = convert(touchLocation, to: subview)
        if subview.point(inside: translatedPoint, with: .none) {
          selectedRating = subview.text!
        }
      }
    }
    
    // Tidy everything away
    endInteraction()
    
    return selectedRating
  }
  
  func beginPreview(forView view: UIView) {
    // Reset any previous animations / blurs
    animator?.stopAnimation(false)
    self.blurView?.removeFromSuperview()
    // Create the visual effect
    prepareBlurView()
    // Create and configure the snapshot of the view we are picking out
    overlaySnapshot?.removeFromSuperview()
    overlaySnapshot = view.snapshotView(afterScreenUpdates: false)
    if let overlaySnapshot = overlaySnapshot {
      blurView?.contentView.addSubview(overlaySnapshot)
      // Calculate the position (adjusted for scroll views)
      let adjustedCenter = view.superview?.convert(view.center, to: self)
      overlaySnapshot.center = adjustedCenter!
      // Create ratings labels
      prepareRatings(for: overlaySnapshot)
    }
    // Create the animator that'll track the preview progress
    animator = UIViewPropertyAnimator(duration: 0.3, curve: .linear) {
      // Specifying a blur type animates the blur radius
      self.blurView?.effect = UIBlurEffect(style: .regular)
      // Pull out the snapshot
      self.overlaySnapshot?.layer.shadowRadius = 8
      self.overlaySnapshot?.layer.shadowColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1).cgColor
      self.overlaySnapshot?.layer.shadowOpacity = 0.3
      // Fade the ratings in
      self.ratingStackView?.alpha = 1
    }
    animator?.addCompletion { (position) in
      // Remove the blur view when animation gets back to the beginning
      switch position {
      case .start:
        self.blurView?.removeFromSuperview()
      default:
        break
      }
    }
  }
  
  func endInteraction() {
    // Animate back to the beginning (no blur)
    animator?.isReversed = true
    animator?.startAnimation()
  }
  
  private func prepareBlurView() {
    // Create a visual effect view and make it completely fill self. Start with no effect - will animate the blur in.
    blurView = UIVisualEffectView(effect: .none)
    if let blurView = blurView {
      addSubview(blurView)
      blurView.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        blurView.leftAnchor.constraint(equalTo: leftAnchor),
        blurView.rightAnchor.constraint(equalTo: rightAnchor),
        blurView.topAnchor.constraint(equalTo: topAnchor),
        blurView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
  }
  
  private func prepareRatings(for view: UIView) {
    // Build the two ratings labels
    let 👍label = UILabel()
    👍label.text = "👍"
    👍label.font = UIFont.systemFont(ofSize: 50)
    👍label.textAlignment = .center
    👍label.backgroundColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1).withAlphaComponent(0.2)
    let 👎label = UILabel()
    👎label.text = "👎"
    👎label.font = UIFont.systemFont(ofSize: 50)
    👎label.textAlignment = .center
    👎label.backgroundColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1).withAlphaComponent(0.2)
    
    // Pop them in a stack view
    ratingStackView = UIStackView(arrangedSubviews: [👍label, 👎label])
    if let ratingStackView = ratingStackView {
      ratingStackView.axis = .vertical
      ratingStackView.alignment = .fill
      ratingStackView.distribution = .fillEqually
      // Ratings should completely cover the supplied view
      view.addSubview(ratingStackView)
      ratingStackView.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        view.leftAnchor.constraint(equalTo: ratingStackView.leftAnchor),
        view.rightAnchor.constraint(equalTo: ratingStackView.rightAnchor),
        view.topAnchor.constraint(equalTo: ratingStackView.topAnchor),
        view.bottomAnchor.constraint(equalTo: ratingStackView.bottomAnchor)
      ])
      ratingStackView.alpha = 0
    }
  }
}
