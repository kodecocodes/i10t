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
import CoreSpotlight
import MobileCoreServices

extension Product {
  var searchableAttributeSet: CSSearchableItemAttributeSet {
    let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeContent as String)
    attributeSet.contentDescription = details
    attributeSet.title = name
    attributeSet.displayName = name
    attributeSet.keywords = [name, "fruit", "shopping", "greengrocer"]
    if let thumbnail = UIImage(named: "\(photoName)_thumb") {
      attributeSet.thumbnailData = UIImageJPEGRepresentation(thumbnail, 0.7)
    }
    return attributeSet
  }
  
  var searchableItem: CSSearchableItem {
    let item = CSSearchableItem(uniqueIdentifier: id.uuidString, domainIdentifier: productDomainID, attributeSet: searchableAttributeSet)
    return item
  }
}

private var dateFormatter: DateFormatter = {
  let df = DateFormatter()
  df.dateStyle = .short
  return df
  }()

extension DataStore {
  func indexContent() {
    indexProducts(products)
  }
  
  func indexProducts(_ products: [Product]) {
    let productItems = products.map { $0.searchableItem }
    CSSearchableIndex.default().indexSearchableItems(productItems) {
      error in
      if let error = error {
        print("Error indexing products: \(error.localizedDescription)")
      } else {
        print("Indexing products successful")
      }
    }
  }
}
