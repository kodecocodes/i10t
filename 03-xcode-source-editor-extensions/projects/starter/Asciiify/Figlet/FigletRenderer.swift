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
import JavaScriptCore

public class FigletRenderer {
  fileprivate let context = JSContext()
  public lazy var availableFonts: [String] = {
    return self.findFontFiles()
  }()
  
  public static let topFonts = ["standard", "doh", "drpepper", "epic", "smslant"]
  
  public func render(input: String, withFont font: String? = .none) -> String? {
    let font = font ?? "standard"
    return self.process(input: input, withFont: font)
  }
  
  public init() {
    prepareJSContext()
  }
}


extension FigletRenderer {
  fileprivate func prepareJSContext() {
    if let figletSource = loadStringFromFile(name: "figlet", ext: "js") {
      let _ = context?.evaluateScript(figletSource)
      let loadFont: @convention(block) (String) -> (String) = {
        [unowned self] (name) in
        if let fontString = self.loadStringFromFile(name: name, ext: "flf") {
          return fontString
        } else {
          return ""
        }
      }
      context?.objectForKeyedSubscript("Figlet").setObject(unsafeBitCast(loadFont, to: AnyObject.self), forKeyedSubscript: "loadFont" as NSString)
    }
  }
  
  fileprivate func findFontFiles() -> [String] {
    let currentBundle = Bundle(for: type(of: self))
    return currentBundle.paths(forResourcesOfType: "flf", inDirectory: .none)
  }
  
  fileprivate func process(input: String, withFont font: String) -> String? {
    if let figlet = context?.objectForKeyedSubscript("Figlet"),
      let write = figlet.objectForKeyedSubscript("write")
        .call(withArguments: [input, font]) {
      return write.isString ? write.toString() : .none
    }
    return .none
  }
  
  private func loadStringFromFile(name: String, ext: String) -> String? {
    do {
      let fileString = try String(contentsOfFile: Bundle(for: type(of: self)).path(forResource: name, ofType: ext)!, encoding: .utf8)
      return fileString
    } catch let error {
      print("There was a problem: \(error.localizedDescription)")
      return .none
    }
  }
}

