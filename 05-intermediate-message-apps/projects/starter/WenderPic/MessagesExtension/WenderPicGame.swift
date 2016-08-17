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
import Messages

let wordList = [ "nose", "dog", "camel", "fork", "pizza", "ray", "swift", "closure", "android", "gigabyte", "debugger", "tennis", "chocolate", "emoji", "toilet"]

enum GameState: String {
    case challenge
    case guess
}

struct WenderPicGame {
  let word: String
  var currentDrawing: UIImage?
  var guesses: [String]
  let drawerId: UUID
  let gameId: UUID
  var gameState = GameState.challenge
  
  init(word: String, drawerId: UUID) {
    self.word = word
    self.drawerId = drawerId
    self.currentDrawing = .none
    self.guesses = [String]()
    self.gameId = UUID()
  }
}

extension WenderPicGame {
  static func newGame(drawerId: UUID) -> WenderPicGame {
    let word = wordList[Int(arc4random_uniform(UInt32(wordList.count)))]
    return WenderPicGame(word: word, drawerId: drawerId)
  }
  
  func check(guess: String) -> Bool {
    return guess == word
  }
  
  func valid(guess: String) -> Bool {
    return !guesses.contains(guess)
  }
  
  var isComplete: Bool {
    return guesses.contains(word)
  }
  
  func owner(conversation: MSConversation) -> Bool {
    return conversation.localParticipantIdentifier == drawerId
  }
}

