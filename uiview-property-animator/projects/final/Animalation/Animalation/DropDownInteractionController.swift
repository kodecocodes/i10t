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

class DropDownInteractionController: UIPercentDrivenInteractiveTransition {
  var isInteractive = false
  var hasStarted = false
  
  private weak var viewController: UIViewController?
  private let dismissGesture = UIPanGestureRecognizer()
  
  required init(viewController: UIViewController) {
    self.viewController = viewController
    super.init()
    dismissGesture.addTarget(self, action: #selector(handle(pan:)))
    viewController.view.addGestureRecognizer(dismissGesture)
  }
  
  var interruptedPercent: CGFloat = 0
  
  func handle(pan: UIPanGestureRecognizer) {
    
    let translation = pan.translation(in: pan.view).y
    let percent = (translation / pan.view!.bounds.height) + interruptedPercent
    let xVelocity = pan.velocity(in: pan.view).y
    
    switch pan.state {
    case .possible:
      break
    case .began:
      if !hasStarted {
        hasStarted = true
        isInteractive = true
        interruptedPercent = 0
        viewController?.dismiss(animated: true, completion: nil)
      } else {
        pause()
        interruptedPercent = percentComplete
      }
    case .changed:
      update(min(percent, 1.0))
    case .ended:
      isInteractive = false
      if percent > 0.5 || xVelocity > 0 {
        finish()
      } else {
        hasStarted = false
        cancel()
      }
    case .cancelled, .failed:
      isInteractive = false
      hasStarted = false
      cancel()
    }
  }
}
