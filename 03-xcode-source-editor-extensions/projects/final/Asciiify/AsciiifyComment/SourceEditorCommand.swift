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
import XcodeKit
import Figlet

class SourceEditorCommand: NSObject, XCSourceEditorCommand {
  
  let figlet = FigletRenderer()
  func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
    
    var newSelections = [XCSourceTextRange]()
    let buffer = invocation.buffer
    let selectedFont = font(from: invocation.commandIdentifier)
    
    buffer.selections.forEach({ selection in
      guard let selection = selection as? XCSourceTextRange,
        selection.start.line == selection.end.line else { return }
      
      let line = buffer.lines[selection.start.line] as! String
      let startIndex = line.characters.index(
        line.startIndex, offsetBy: selection.start.column)
      let endIndex = line.characters.index(
        line.startIndex, offsetBy: selection.end.column)
      
      let selectedText = line.substring(with:
        startIndex..<line.index(after: endIndex))
      if let asciiified = figlet.render(input: selectedText, withFont: selectedFont) {
        let newLines = asciiified.components(separatedBy: "\n").map { "// \($0)" }
        let startLine = selection.start.line
        
        buffer.lines.removeObject(at: startLine)
        buffer.lines.insert(
          newLines,
          at: IndexSet(startLine ..< startLine + newLines.count))
        
        let startPosition = XCSourceTextPosition(line: startLine, column: 0)
        
        var endLine = startLine
        if newLines.count > 0 {
          endLine = startLine + newLines.count - 1
        }
        
        var endColumn = 0
        if let lastLine = newLines.last {
          endColumn = lastLine.characters.count
        }
        
        let endPosition = XCSourceTextPosition(line: endLine, column: endColumn)
        
        let selection = XCSourceTextRange(start: startPosition, end: endPosition)
        newSelections.append(selection)
      }
    })
    
    if newSelections.count > 0 {
      buffer.selections.setArray(newSelections)
    } else {
      let insertionPosition = XCSourceTextPosition(line: 0, column: 0)
      let selection = XCSourceTextRange(start: insertionPosition, end: insertionPosition)
      buffer.selections.setArray([selection])
    }
    
    completionHandler(.none)
  }
  
  private func font(from commandIdentifier: String) -> String {
    let bundleIdentifier = Bundle(for: type(of: self)).bundleIdentifier!.components(separatedBy: ".")
    let command = commandIdentifier.components(separatedBy: ".")
    
    if command.count == bundleIdentifier.count + 1 {
      return command.last!
    } else {
      return "standard"
    }
  }
}
