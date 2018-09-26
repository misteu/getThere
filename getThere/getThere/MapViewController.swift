//
//  ViewController.swift
//  getThere
//
//  Created by skrr on 25.09.18.
//  Copyright © 2018 skrr. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, UITextFieldDelegate {
  
  let locationSet = Locations()
  var isLocalStationList = false
  
  @IBOutlet weak var mapView: MKMapView!
  
  
  @IBOutlet weak var searchTextField: SearchTextField!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    print("mapView \(mapView.userLocation.location)")
    
    searchTextField.delegate = self
    locationSet.initLocating()
    
    locationSet.findFirstLocationTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(jumpToFirstLocation), userInfo: nil, repeats: !locationSet.hasFoundFirstLocation)
    
    searchTextField.theme.fontColor = UIColor.gray
    
    searchTextField.addTarget(self, action: #selector(MapViewController.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
  }
  
  override func touchesBegan(_ touches: Set<UITouch>,
                             with event: UIEvent?) {
    self.view.endEditing(true)
  }
  
  @objc func jumpToFirstLocation() {
    if let location = locationSet.currentLocation {
      
      mapView.setCamera(getCameraForLocation(locValue: location, heading: 0), animated: true)
      mapView.addAnnotation(mapView.userLocation)
      locationSet.hasFoundFirstLocation = true
      locationSet.findFirstLocationTimer.invalidate()
    
    }
  }
  
  // test
  //  func updateSearchTextFieldAsync(location: CLLocationCoordinate2D) {
  //    let group = DispatchGroup()
  //    group.enter()
  //    DispatchQueue.main.async {
  //      Station.getNearestStations(dispatchGroup: group, location: location)
  //    }
  //    // Request ist fertig
  //    group.notify(queue: .main) {
  //      print("fertig")
  //
  //      let stations = Station.foundStations
  //      if stations.count > 0 {
  //        print(stations)
  //        self.searchTextField.filterStrings(stations)
  //      }
  //    }
  //  }
  
  
  func updateSearchTextFieldAsync(userInput: String) {
    let group = DispatchGroup()
    group.enter()
    DispatchQueue.main.async {
      Station.getStationsWithName(dispatchGroup: group, name: userInput)
    }
    // Request ist fertig
    group.notify(queue: .main) {
      print("fertig")
      
      let stations = Station.foundStations
      if stations.count > 0 {
        print(stations)
        print("update")
        self.searchTextField.filterStrings(stations)
      }
    }
  }
  
  func getCameraForLocation(locValue: CLLocationCoordinate2D, heading: Double) -> MKMapCamera {
    return MKMapCamera.init(lookingAtCenter: CLLocationCoordinate2D.init(latitude: locValue.latitude, longitude: locValue.longitude), fromDistance: 500, pitch: 20, heading: heading)
  }
  
  @objc func textFieldDidChange(_ textField: UITextField) {
    if let text = textField.text {
      if text.count > 2 {
        if !isLocalStationList {
          updateSearchTextFieldAsync(userInput: text)
          isLocalStationList = true
        }
      } else {
        searchTextField.filterStrings([])
        isLocalStationList = false
      }
    }
  }
  
}

