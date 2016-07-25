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

class DrawingViewController: UIViewController {
  
  @IBOutlet weak var canvas: Canvas!
  @IBOutlet weak var progressCircle: ProgressCircle!
  @IBOutlet weak var instructionLabel: UILabel!
  @IBOutlet weak var doneButton: UIButton!
  
  var game: WenderPicGame? {
    didSet { update(forGame: game) }
  }
  var maxInkAllowed: CGFloat = 300
  var delegate: DrawingViewControllerDelegate?
  
  @IBAction func handleDoneButtonTapped(_ sender: UIButton) {
    if let drawing = canvas.image {
      game?.currentDrawing = drawing
    }
    game?.gameState = .challenge
    delegate?.handleDrawingComplete(game: game)
  }
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    canvas.delegate = self
    update(forGame: game)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    maxInkAllowed = view.bounds.width
  }
  
  private func update(forGame game: WenderPicGame?) {
    guard let game = game else { return }
    canvas?.image = game.currentDrawing
    instructionLabel?.text = game.word
  }
}

extension DrawingViewController: CanvasDelegate {
  func didUpdate(canvas: Canvas, inkUsed: CGFloat) {
    let proportion = inkUsed / maxInkAllowed
    progressCircle.progress = proportion
    
    if(proportion > 1) {
      canvas.enabled = false
    }
  }
}


protocol DrawingViewControllerDelegate {
  func handleDrawingComplete(game: WenderPicGame?)
}
