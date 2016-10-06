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

import Foundation

let emoji = "🐍,👍,💄,🎏,🐠,🍔,🏩,🎈,🐷,👠,🐣,🐙,✈️,💅,⛑,👑,👛,🐝,🌂,🌻,🎼,🎧,🚧,📎,🍻".components(separatedBy: ",")


class DataStore {
  private var emojiRatings = emoji.map { EmojiRating(emoji: $0, rating: "") }
  
  public var numberOfEmoji: Int {
    return emojiRatings.count
  }
  
  public func loadEmojiRating(at index: Int) -> DataLoadOperation? {
    if (0..<emojiRatings.count).contains(index) {
      return DataLoadOperation(emojiRatings[index])
    }
    return .none
  }
  
  public func update(emojiRating: EmojiRating) {
    if let index = emojiRatings.index(where: { $0.emoji == emojiRating.emoji }) {
      emojiRatings.replaceSubrange(index...index, with: [emojiRating])
    }
  }
}


class DataLoadOperation: Operation {
  var emojiRating: EmojiRating?
  var loadingCompleteHandler: ((EmojiRating) -> ())?
  
  private let _emojiRating: EmojiRating
  
  init(_ emojiRating: EmojiRating) {
    _emojiRating = emojiRating
  }
  
  override func main() {
    if isCancelled { return }
    
    let randomDelayTime = arc4random_uniform(2000) + 500
    usleep(randomDelayTime * 1000)
    
    if isCancelled { return }
    self.emojiRating = _emojiRating
    
    if let loadingCompleteHandler = loadingCompleteHandler {
      DispatchQueue.main.async {
        loadingCompleteHandler(self._emojiRating)
      }
    }
  }
  
}
