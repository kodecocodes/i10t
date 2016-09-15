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

class MultilineLabelThatWorks: UILabel {
  override func layoutSubviews() {
    super.layoutSubviews()
    preferredMaxLayoutWidth = bounds.width
    super.layoutSubviews()
  }
  
  override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
    var rect = layoutMargins.apply(bounds)
    rect = super.textRect(forBounds: rect, limitedToNumberOfLines: numberOfLines)
    return layoutMargins.inverse.apply(rect)
  }
  
  override func drawText(in rect: CGRect) {
    super.drawText(in: layoutMargins.apply(rect))
  }
}

extension UIEdgeInsets {
  var inverse: UIEdgeInsets {
    return UIEdgeInsets(top: -top, left: -left, bottom: -bottom, right: -right)
  }
  func apply(_ rect: CGRect) -> CGRect {
    return UIEdgeInsetsInsetRect(rect, self)
  }
}
