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
class ProgressCircle: UIView {
  
  @IBInspectable
  var progress: CGFloat = 0 {
    didSet {
      updateProgress()
    }
  }
  
  let outerCircleLayer = CAShapeLayer()
  let innerCicleLayer = CAShapeLayer()
}


extension ProgressCircle {
  override func layoutSubviews() {
    super.layoutSubviews()
    layoutLayers()
  }
  
  override func tintColorDidChange() {
    styleLayers()
  }
}


extension ProgressCircle {
  func layoutLayers() {
    let squareSize = min(bounds.width, bounds.height)
    let square = bounds.insetBy(dx: (bounds.width - squareSize) / 2, dy: (bounds.height - squareSize) / 2)
    for l in [outerCircleLayer, innerCicleLayer] {
      l.bounds = square
      l.position = CGPoint(x: bounds.midX, y: bounds.midY)
      layer.addSublayer(l)
    }
    
    outerCircleLayer.path = UIBezierPath(ovalIn: outerCircleLayer.bounds).cgPath
    innerCicleLayer.path = innerPath
    
    styleLayers()
  }
  
  func styleLayers() {
    outerCircleLayer.lineWidth = 1
    outerCircleLayer.fillColor = UIColor.clear.cgColor
    
    innerCicleLayer.lineWidth = 0
    
    outerCircleLayer.strokeColor = tintColor.cgColor
    innerCicleLayer.fillColor = tintColor.withAlphaComponent(0.8).cgColor
  }
  
  func updateProgress() {
    innerCicleLayer.path = innerPath
  }
  
  var innerPath: CGPath {
    let path = UIBezierPath()
    
    let endAngle = 2 * .pi * progress - .pi / 2
    
    path.addArc(withCenter: innerCicleLayer.position, radius: innerCicleLayer.bounds.width / 2, startAngle: -.pi / 2, endAngle: endAngle, clockwise: true)
    path.addLine(to: CGPoint(x: innerCicleLayer.bounds.midX, y: innerCicleLayer.bounds.midY))
    path.addLine(to: CGPoint(x: innerCicleLayer.bounds.midX, y: 0))
    
    return path.cgPath
  }
}
