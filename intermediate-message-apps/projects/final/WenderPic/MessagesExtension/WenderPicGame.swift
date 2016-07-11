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

struct WenderPicGame {
  let word: String
  let currentDrawing: UIImage?
  var guesses: [String]
  let drawerId: UUID
  
  init(word: String, drawerId: UUID) {
    self.word = word
    self.drawerId = drawerId
    self.currentDrawing = .none
    self.guesses = [String]()
  }
  
  private init(word: String, currentDrawing: UIImage?, guesses: [String], drawerId: UUID) {
    self.word = word
    self.currentDrawing = currentDrawing
    self.guesses = guesses
    self.drawerId = drawerId
  }
}

extension WenderPicGame {
  func newGuess(_ guess: String) -> WenderPicGame {
    return WenderPicGame(word: word, currentDrawing: currentDrawing, guesses: guesses + [guess], drawerId: drawerId)
  }
  
  func updateDrawing(_ drawing: UIImage) -> WenderPicGame {
    return WenderPicGame(word: word, currentDrawing: drawing, guesses: guesses, drawerId: drawerId)
  }
}

// MARK: Encoding / Decoding
extension WenderPicGame {
  
  var queryItems: [URLQueryItem] {
    var items = [URLQueryItem]()
    
    items.append(URLQueryItem(name: "word", value: word))
    items.append(URLQueryItem(name: "guesses", value: guesses.joined(separator: "::-::")))
    items.append(URLQueryItem(name: "drawerId", value: drawerId.uuidString))
    
    return items
  }
  init?(queryItems: [URLQueryItem], drawing: UIImage?) {
    var word: String?
    var guesses = [String]()
    var drawerId: UUID?
    
    for item in queryItems {
      guard let value = item.value else { continue }
      
      switch item.name {
      case "word":
        word = value
      case "guesses":
        guesses = value.components(separatedBy: "::-::")
      case "drawerId":
        drawerId = UUID(uuidString: value)
      default:
        continue
      }
    }
    
    guard let decodedWord = word, decodedDrawerId = drawerId else {
      return nil
    }
    
    self.word = decodedWord
    self.guesses = guesses
    self.currentDrawing = drawing
    self.drawerId = decodedDrawerId
  }
  
  init?(message: MSMessage?) {
    //TODO: radar 27263740 file because the layout property is nil on any selected message as of beta 2. If this isn't resolved we'll have to encode the image as part of the URL instead (though when I tried this, the message refused to send). If resolved uncomment the line below and send the image as suggested.
    guard let
//    layout = message?.layout as? MSMessageTemplateLayout,
    messageURL = message?.url,
    urlComponents = URLComponents(url: messageURL, resolvingAgainstBaseURL: false),
    queryItems = urlComponents.queryItems
    else {
      return nil
    }
    self.init(queryItems: queryItems, drawing: nil)//layout.image)
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

