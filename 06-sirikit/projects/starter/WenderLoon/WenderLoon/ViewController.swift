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
import MapKit
import WenderLoonCore

class ViewController: UIViewController {

  @IBOutlet weak var mapView: MKMapView!
  var annotations = [Balloon: MKAnnotation]()
  var simulator: WenderLoonSimulator?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    mapView.delegate = self
    simulator = WenderLoonSimulator(renderer: self)
  }
}


extension ViewController: WenderLoonRenderer {
  func balloon(_ balloon: Balloon, didMoveTo location: CLLocation) {
    if location.distance(from: CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)) > 100_000 {
      mapView.setCenter(location.coordinate, animated: true)
    }
    
    if !annotations.keys.contains(balloon) {
      annotations[balloon] = MKPointAnnotation()
      mapView.addAnnotation(annotations[balloon]!)
    }
    if let annotation = annotations[balloon] as? MKPointAnnotation {
      annotation.coordinate = location.coordinate
      annotation.title = balloon.driver.name
    }
  }
}

extension ViewController: MKMapViewDelegate {
  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    let annotationView: MKAnnotationView
    if let av = mapView.dequeueReusableAnnotationView(withIdentifier: "balloon") {
      annotationView = av
    } else {
      annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "balloon")
    }
    // Find the balloon
    let balloon = annotations.filter { (_, ann) in
      return ann.title! == annotation.title!
    }.first!.key
    
    annotationView.image = balloon.image
    
    return annotationView
  }
}

