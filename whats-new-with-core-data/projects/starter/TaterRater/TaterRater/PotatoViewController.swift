//
//  PotatoViewController.swift
//  PotatoRater
//
//  Created by Richard Turton on 31/08/2016.
//  Copyright © 2016 Razeware. All rights reserved.
//

import UIKit

var scoreFormatter: NumberFormatter = {
    $0.numberStyle = .decimal
    $0.maximumSignificantDigits = 2
    return $0
}(NumberFormatter())

class PotatoViewController: UIViewController {

    var potato: Potato!
    var observerContext: Int?
    
    @IBOutlet weak var scoreStack: UIStackView!
    @IBOutlet weak var notesLabel: UILabel!
    @IBOutlet weak var averageScoreLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        updateUI()
        title = potato.variety
        
        for button in scoreStack.arrangedSubviews {
            guard let button = button as? UIButton else { continue }
            button.addTarget(self, action: #selector(scoreTapped(_:)), for: .touchUpInside)
        }
        
        potato.addObserver(self, forKeyPath:#keyPath(Potato.notes), options: [], context: &observerContext)
    }
    
    deinit {
        potato.removeObserver(self, forKeyPath: #keyPath(Potato.notes))
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &observerContext {
            updateUI()
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showNote" {
            guard let nav = segue.destination as? UINavigationController,
            let noteVC = nav.topViewController as? NoteViewController
            else { return }
            noteVC.potato = potato
        }
    }

    func scoreTapped(_ sender: UIButton) {
        guard let stack = sender.superview as? UIStackView else { return }
        potato.userRating = Int16((stack.arrangedSubviews.index(of: sender) ?? 0) + 1)
        updateUI()
    }
    
        
    private func updateUI() {
        update(buttonStack: scoreStack, score: Int(potato.userRating))
        averageScoreLabel.text = scoreFormatter.string(from: NSNumber(value:potato.crowdRating))
        if let notes = potato.notes {
            notesLabel.text = notes
            notesLabel.textColor = .black
        } else {
            notesLabel.textColor = .lightGray
            notesLabel.text = "No notes"
        }
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

