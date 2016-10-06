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

class EmojiCollectionViewController: UICollectionViewController {
  
  let dataStore = DataStore()
  let loadingQueue = OperationQueue()
  var loadingOperations = [IndexPath : DataLoadOperation]()
  var ratingOverlayView: RatingOverlayView?
  var previewInteraction: UIPreviewInteraction?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    collectionView?.prefetchDataSource = self
    
    ratingOverlayView = RatingOverlayView(frame: view.bounds)
    if let ratingOverlayView = ratingOverlayView {
      view.addSubview(ratingOverlayView)
      view.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        ratingOverlayView.leftAnchor.constraint(equalTo: view.leftAnchor),
        ratingOverlayView.rightAnchor.constraint(equalTo: view.rightAnchor),
        ratingOverlayView.topAnchor.constraint(equalTo: view.topAnchor),
        ratingOverlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
      ratingOverlayView.isUserInteractionEnabled = false
      
      if let collectionView = collectionView {
        previewInteraction = UIPreviewInteraction(view: collectionView)
        previewInteraction?.delegate = self
      }
    }
  }
}

// MARK: UICollectionViewDataSource
extension EmojiCollectionViewController {
  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }
  
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return dataStore.numberOfEmoji
  }
  
  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCell", for: indexPath)
    
    if let cell = cell as? EmojiCollectionViewCell {
      cell.updateAppearanceFor(.none, animated: false)
    }
    return cell
  }
}

// MARK: UICollectionViewDelegate
extension EmojiCollectionViewController {
  override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    guard let cell = cell as? EmojiCollectionViewCell else { return }
    
    // How should the operation update the cell once the data has been loaded?
    let updateCellClosure: (EmojiRating?) -> () = { [unowned self] (emojiRating) in
      cell.updateAppearanceFor(emojiRating, animated: true)
      self.loadingOperations.removeValue(forKey: indexPath)
    }
    
    // Try to find an existing data loader
    if let dataLoader = loadingOperations[indexPath] {
      // Has the data already been loaded?
      if let emojiRating = dataLoader.emojiRating {
        cell.updateAppearanceFor(emojiRating, animated: false)
        loadingOperations.removeValue(forKey: indexPath)
      } else {
        // No data loaded yet, so add the completion closure to update the cell once the data arrives
        dataLoader.loadingCompleteHandler = updateCellClosure
      }
    } else {
      // Need to create a data loaded for this index path
      if let dataLoader = dataStore.loadEmojiRating(at: indexPath.item) {
        // Provide the completion closure, and kick off the loading operation
        dataLoader.loadingCompleteHandler = updateCellClosure
        loadingQueue.addOperation(dataLoader)
        loadingOperations[indexPath] = dataLoader
      }
    }
  }
  
  override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    // If there's a data loader for this index path we don't need it any more. Cancel and dispose
    if let dataLoader = loadingOperations[indexPath] {
      dataLoader.cancel()
      loadingOperations.removeValue(forKey: indexPath)
    }
  }
}

// Mark: UICollectionViewDataSourcePrefetching
extension EmojiCollectionViewController: UICollectionViewDataSourcePrefetching {
  func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
    for indexPath in indexPaths {
      if let _ = loadingOperations[indexPath] {
        return
      }
      if let dataLoader = dataStore.loadEmojiRating(at: indexPath.item) {
        loadingQueue.addOperation(dataLoader)
        loadingOperations[indexPath] = dataLoader
      }
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
    for indexPath in indexPaths {
      if let dataLoader = loadingOperations[indexPath] {
        dataLoader.cancel()
        loadingOperations.removeValue(forKey: indexPath)
      }
    }
  }
}

// Mark: UIPreviewInteractionDelegate
extension EmojiCollectionViewController: UIPreviewInteractionDelegate {
  func previewInteractionShouldBegin(_ previewInteraction: UIPreviewInteraction) -> Bool {
    if let indexPath = collectionView?.indexPathForItem(at: previewInteraction.location(in: collectionView!)),
      let cell = collectionView?.cellForItem(at: indexPath) {
      ratingOverlayView?.beginPreview(forView: cell)
      collectionView?.isScrollEnabled = false
      return true
    } else {
      return false
    }
  }
  
  func previewInteractionDidCancel(_ previewInteraction: UIPreviewInteraction) {
    ratingOverlayView?.endInteraction()
    collectionView?.isScrollEnabled = true
  }
  
  func previewInteraction(_ previewInteraction: UIPreviewInteraction, didUpdatePreviewTransition transitionProgress: CGFloat, ended: Bool) {
    ratingOverlayView?.updateAppearance(forPreviewProgress: transitionProgress)
  }
  
  func previewInteraction(_ previewInteraction: UIPreviewInteraction, didUpdateCommitTransition transitionProgress: CGFloat, ended: Bool) {
    let hitPoint = previewInteraction.location(in: ratingOverlayView!)
    if ended {
      let updatedRating = ratingOverlayView?.completeCommit(at: hitPoint)
      if let indexPath = collectionView?.indexPathForItem(at: previewInteraction.location(in: collectionView!)),
        let cell = collectionView?.cellForItem(at: indexPath) as? EmojiCollectionViewCell,
        let oldEmojiRating = cell.emojiRating {
        let newEmojiRating = EmojiRating(emoji: oldEmojiRating.emoji, rating: updatedRating!)
        dataStore.update(emojiRating: newEmojiRating)
        cell.updateAppearanceFor(newEmojiRating)
        collectionView?.isScrollEnabled = true
      }
    } else {
      ratingOverlayView?.updateAppearance(forCommitProgress: transitionProgress, touchLocation: hitPoint)
    }
  }
}


