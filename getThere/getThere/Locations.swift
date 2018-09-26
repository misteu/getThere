//
//  LocationStuff.swift
//  getThere
//
//  Created by skrr on 26.09.18.
//  Copyright © 2018 skrr. All rights reserved.
//

import Foundation
import CoreLocation

class Locations: NSObject, CLLocationManagerDelegate {
  let locationManager = CLLocationManager()
  var currentLocation: CLLocationCoordinate2D?
  var hasFoundFirstLocation = false
  var findFirstLocationTimer: Timer!
  var foundLocations = [String]()
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
    print("locations = \(locValue.latitude) \(locValue.longitude)")
    currentLocation = locValue
  }
  
  func initLocating() {
    // Ask for Authorisation from the User.
    locationManager.requestWhenInUseAuthorization()
    
    // For use in foreground
    locationManager.requestWhenInUseAuthorization()
    
    if CLLocationManager.locationServicesEnabled() {
      locationManager.delegate = self
      locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
      locationManager.startUpdatingLocation()
    }
    
  }
  
}
