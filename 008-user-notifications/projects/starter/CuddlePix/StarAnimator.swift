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

extension UIImageView {
  public func showStars() {
    let particleEmitter = CAEmitterLayer()
    
    particleEmitter.emitterPosition = CGPoint(x: frame.width / 2.0, y: -25)
    particleEmitter.emitterShape = kCAEmitterLayerLine
    particleEmitter.emitterSize = CGSize(width: frame.width, height: 1)
    particleEmitter.renderMode = kCAEmitterLayerAdditive
    
    let cell = CAEmitterCell()
    cell.contents = #imageLiteral(resourceName: "star@2x").cgImage
    cell.color = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1).cgColor
    cell.birthRate = 20
    cell.lifetime = 5.0
    cell.velocity = 100
    cell.velocityRange = 50
    cell.emissionLongitude = .pi
    cell.spinRange = 5
    cell.scale = 0.1
    cell.scaleRange = 0.25
    cell.alphaSpeed = -0.025
    particleEmitter.emitterCells = [cell]
    
    layer.addSublayer(particleEmitter)
  }
}

