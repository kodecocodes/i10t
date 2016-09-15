//
//  IntentViewController.swift
//  LoonUIExtension
//
//  Created by Richard Turton on 15/09/2016.
//  Copyright © 2016 Razeware. All rights reserved.
//

import IntentsUI
import WenderLoonCore

class IntentViewController: UIViewController, INUIHostedViewControlling {
  
  @IBOutlet weak var balloonImageView: UIImageView!
  @IBOutlet weak var driverImageView: UIImageView!
  @IBOutlet weak var subtitleLabel: UILabel!
  
  // MARK: - INUIHostedViewControlling
  
  // Prepare your view controller for the interaction to handle.
  func configure(with interaction: INInteraction!, context: INUIHostedViewContext, completion: ((CGSize) -> Void)!) {
    
    guard let response = interaction.intentResponse as? INRequestRideIntentResponse
      else {
        driverImageView.image = nil
        balloonImageView.image = nil
        subtitleLabel.text = ""
        completion?(self.desiredSize)
        return
    }

    if let driver = response.rideStatus?.driver {
      let name = driver.displayName
      driverImageView.image = WenderLoonSimulator.imageForDriver(name: name)
      balloonImageView.image = WenderLoonSimulator.imageForBallon(driverName: name)
      subtitleLabel.text = "\(name) will arrive soon!"
    } else {
      driverImageView.image = nil
      balloonImageView.image = nil
      subtitleLabel.text = "Preparing..."
    }

    completion?(self.desiredSize)
  }
  
  
  var desiredSize: CGSize {
    return self.extensionContext!.hostedViewMaximumAllowedSize
  }
  
}
