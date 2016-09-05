//
//  NoteViewController.swift
//  TaterRater
//
//  Created by Richard Turton on 02/09/2016.
//  Copyright © 2016 Razeware. All rights reserved.
//

import UIKit
import CoreData

class NoteViewController: UIViewController {

    var context: NSManagedObjectContext!
    var potato: Potato!
    
    @IBOutlet weak var textView: UITextView!
    
    @IBAction func save(_ sender: AnyObject) {
        potato.notes = textView.text
        try? context.save()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancel(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        textView.text = potato.notes
        textView.becomeFirstResponder()
        navigationItem.title = potato.variety
    }
}
