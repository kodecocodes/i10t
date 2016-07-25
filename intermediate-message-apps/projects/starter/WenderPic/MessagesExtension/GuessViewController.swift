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

class GuessViewController: UIViewController {
  
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var guessTextField: UITextField!
  @IBOutlet weak var guessButton: UIButton!
  
  var game: WenderPicGame? {
    didSet { update(forGame: game) }
  }
  var delegate: GuessViewControllerDelegate?
  
  @IBAction func handleGuessSubmission(_ sender: UIButton) {
    guard var game = game else { return }
    guard let guess = guessTextField.text else { return }
    
    if game.valid(guess: guess) {
      game.gameState = .guess
      delegate?.handleGuessSubmission(forGame: game, guess: guess)
    } else {
      self.game?.guesses.append(guess)
      print("This has already been guessed! Try again!")
    }
  }
  
  private func update(forGame game: WenderPicGame?) {
    guard let game = game else { return }
    imageView?.image = game.currentDrawing
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    update(forGame: game)
  }
}

protocol GuessViewControllerDelegate {
  func handleGuessSubmission(forGame game: WenderPicGame, guess: String)
}

