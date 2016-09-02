//
//  PotatoViewController.swift
//  PotatoRater
//
//  Created by Richard Turton on 31/08/2016.
//  Copyright © 2016 Razeware. All rights reserved.
//

import UIKit

class PotatoViewController: UIViewController {

    var potato: Potato!
    
    @IBOutlet weak var boilStack: UIStackView!
    @IBOutlet weak var fryStack: UIStackView!
    @IBOutlet weak var roastStack: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        updateScores()
        title = potato.variety
        
        for button in ([boilStack, roastStack, fryStack].flatMap{ $0.arrangedSubviews }) {
            guard let button = button as? UIButton else { continue }
            button.addTarget(self, action: #selector(scoreTapped(_:)), for: .touchUpInside)
        }
    }

    func scoreTapped(_ sender: UIButton) {
        guard let stack = sender.superview as? UIStackView else { return }
        let score = Int16((stack.arrangedSubviews.index(of: sender) ?? 0) + 1)
        switch stack {
        case boilStack: potato.boil = score
        case fryStack: potato.fry = score
        case roastStack: potato.roast = score
        default: break
        }
        updateScores()
    }
    
    private func updateScores() {
        update(buttonStack: fryStack, score: Int(potato.fry))
        update(buttonStack: boilStack, score: Int(potato.boil))
        update(buttonStack: roastStack, score: Int(potato.roast))
    }
    
    private func update(buttonStack: UIStackView, score: Int) {
        for (index, button) in buttonStack.arrangedSubviews.enumerated() {
            if index < score {
                button.alpha = 1
            } else {
                button.alpha = 0.3
            }
        }
    }
    

    

}
