//
//  CandyStickerBrowserViewController.swift
//  Stickerlicious
//
//  Created by Richard Turton on 03/07/2016.
//  Copyright © 2016 Razeware. All rights reserved.
//

import Messages

let stickerNames = ["CandyCane", "Caramel", "ChocolateBar", "ChocolateChip", "DarkChocolate", "GummiBear", "JawBreaker", "Lollipop", "SourCandy"]

class CandyStickerBrowserViewController: MSStickerBrowserViewController {
  var stickers = [MSSticker]()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    loadStickers()
    stickerBrowserView.backgroundColor = #colorLiteral(red: 0.9490196078, green: 0.7568627451, blue: 0.8196078431, alpha: 1)
  }
}

extension CandyStickerBrowserViewController {
  
  private func loadStickers(_ chocoholic: Bool = false) {
    stickers = stickerNames.filter( { name in
      if chocoholic {
        return name.contains("Chocolate")
      } else {
        return true
      }
    }).map({ name in
      let url = Bundle.main.urlForResource(name, withExtension: "png")!
      return try! MSSticker(contentsOfFileURL: url, localizedDescription: name)
    })
  }
  
}

//MARK: MSStickerBrowserViewDataSource
extension CandyStickerBrowserViewController {
  override func numberOfStickers(in stickerBrowserView: MSStickerBrowserView) -> Int {
    return stickers.count
  }
  
  override func stickerBrowserView(_ stickerBrowserView: MSStickerBrowserView, stickerAt index: Int) -> MSSticker {
    return stickers[index]
  }
}

extension CandyStickerBrowserViewController: Chocoholicable {
  func setChocoholic(_ chocoholic: Bool) {
    loadStickers(chocoholic)
    stickerBrowserView.reloadData()
  }
}
