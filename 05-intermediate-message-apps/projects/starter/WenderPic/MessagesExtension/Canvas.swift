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

@IBDesignable
public class Canvas : UIView {
  
  var image: UIImage? {
    didSet {
      layer.contents = image?.cgImage
    }
  }
  
  var delegate: CanvasDelegate?
  
  var inkUsed: CGFloat = 0
  var enabled = true
  
  @IBInspectable
  public var strokeWidth: CGFloat = 4.0
  
  @IBInspectable
  public var strokeColor = UIColor.hotPink
}

extension Canvas {
  public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard enabled else { return }
    if let touch = touches.first {
      if traitCollection.forceTouchCapability == .available {
        // In the simulator, force touch-enabled device without a force touch trackpad gives a force of 0.
        let force = touch.force > 0 ? touch.force : 1
        addLine(fromPoint: touch.previousLocation(in: self),
                toPoint: touch.location(in: self), withForce: force)
      } else {
        addLine(fromPoint: touch.previousLocation(in: self), toPoint: touch.location(in: self))
      }
    }
  }
}

extension Canvas {
  func addLine(fromPoint: CGPoint, toPoint: CGPoint, withForce force: CGFloat = 1) {
    UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
    
    image?.draw(in: bounds)
    
    if let cxt = UIGraphicsGetCurrentContext() {
      cxt.move(to: fromPoint)
      cxt.addLine(to: toPoint)
      
      cxt.setLineCap(.round)
      
      cxt.setLineWidth(force * strokeWidth)
      
      strokeColor.setStroke()
      
      cxt.strokePath()
    }
    
    image = UIGraphicsGetImageFromCurrentImageContext()
    
    UIGraphicsEndImageContext()
    
    inkUsed += fromPoint.distanceTo(toPoint)
    
    delegate?.didUpdate(canvas: self, inkUsed: inkUsed)
  }
}

protocol CanvasDelegate {
  func didUpdate(canvas: Canvas, inkUsed: CGFloat)
}
