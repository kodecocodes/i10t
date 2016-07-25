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
  
  private init(word: String, drawerId: UUID) {
    self.word = word
    self.drawerId = drawerId
    self.currentDrawing = .none
    self.guesses = [String]()
    self.gameId = UUID()
  }
}

// MARK: Encoding / Decoding
extension WenderPicGame {
  
  var queryItems: [URLQueryItem] {
    var items = [URLQueryItem]()
    
    items.append(URLQueryItem(name: "word", value: word))
    items.append(URLQueryItem(name: "guesses", value: guesses.joined(separator: "::-::")))
    items.append(URLQueryItem(name: "drawerId", value: drawerId.uuidString))
    items.append(URLQueryItem(name: "gameState", value: gameState.rawValue))
    items.append(URLQueryItem(name: "gameId", value: gameId.uuidString))
    return items
  }
  init?(queryItems: [URLQueryItem]) {
    var word: String?
    var guesses = [String]()
    var drawerId: UUID?
    var gameId: UUID?
    
    for item in queryItems {
      guard let value = item.value else { continue }
      
      switch item.name {
      case "word":
        word = value
      case "guesses":
        guesses = value.components(separatedBy: "::-::")
      case "drawerId":
        drawerId = UUID(uuidString: value)
      case "gameState":
        self.gameState = GameState(rawValue: value)!
      case "gameId":
        gameId = UUID(uuidString: value)
      default:
        continue
      }
    }
    
    guard
      let decodedWord = word,
      let decodedDrawerId = drawerId,
      let decodedGameId = gameId
    else {
      return nil
    }
    
    self.word = decodedWord
    self.guesses = guesses
    self.currentDrawing = DrawingStore.image(forUUID: decodedGameId)
    self.drawerId = decodedDrawerId
    self.gameId = decodedGameId
  }
  
  init?(message: MSMessage?) {
    guard
      let messageURL = message?.url,
      let urlComponents = URLComponents(url: messageURL, resolvingAgainstBaseURL: false),
      let queryItems = urlComponents.queryItems
    else {
      return nil
    }
    self.init(queryItems: queryItems)
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

