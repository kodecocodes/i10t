//
//  AnimalsViewController.swift
//  Animalation
//
//  Created by Richard Turton on 24/07/2016.
//  Copyright © 2016 Razeware. All rights reserved.
//

import UIKit

class AnimalsViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        transitioningDelegate = UIApplication.shared().delegate as! AppDelegate
    }
}
