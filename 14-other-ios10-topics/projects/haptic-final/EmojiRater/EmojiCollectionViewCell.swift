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

class EmojiCollectionViewCell: UICollectionViewCell {
  @IBOutlet weak var emojiLabel: UILabel!
  @IBOutlet weak var ratingLabel: UILabel!
  @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
  
  var emojiRating: EmojiRating?
  
  override func prepareForReuse() {
    DispatchQueue.main.async {
      self.displayEmojiRating(.none)
    }
  }
  
  func updateAppearanceFor(_ emojiRating: EmojiRating?, animated: Bool = true) {
    DispatchQueue.main.async {
      if animated {
        UIView.animate(withDuration: 0.5) {
          self.displayEmojiRating(emojiRating)
        }
      } else {
        self.displayEmojiRating(emojiRating)
      }
    }
  }
  
  private func displayEmojiRating(_ emojiRating: EmojiRating?) {
    self.emojiRating = emojiRating
    if let emojiRating = emojiRating {
      self.emojiLabel?.text = emojiRating.emoji
      self.ratingLabel?.text = emojiRating.rating
      self.emojiLabel?.alpha = 1
      self.ratingLabel?.alpha = 1
      self.loadingIndicator?.alpha = 0
      self.loadingIndicator?.stopAnimating()
      self.backgroundColor = #colorLiteral(red: 0.9338415265, green: 0.9338632822, blue: 0.9338515401, alpha: 1)
      self.layer.cornerRadius = 10
    } else {
      self.emojiLabel?.alpha = 0
      self.ratingLabel?.alpha = 0
      self.loadingIndicator?.alpha = 1
      self.loadingIndicator?.startAnimating()
      self.backgroundColor = #colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1)
      self.layer.cornerRadius = 10
    }
  }
}
