//
//  ViewController.swift
//  getThere
//
//  Created by skrr on 25.09.18.
//  Copyright © 2018 skrr. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, UITextFieldDelegate, MKMapViewDelegate {
  
  let locationSet = Locations()
  var isLocalStationList = false
  var headingImageView: UIImageView?
  var getThereButton: UIButton?
  var selectedSuggestion: String?
  
  @IBOutlet weak var mapView: MKMapView!
  
  
  @IBOutlet weak var searchTextField: SearchTextField!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    searchTextField.delegate = self
    mapView.delegate = self
    locationSet.initLocating()
    
    
    locationSet.findFirstLocationTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(jumpToFirstLocation), userInfo: nil, repeats: !locationSet.hasFoundFirstLocation)
    
    searchTextField.theme.fontColor = UIColor.gray
    
    addNotificationObserver()
    
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
      
      let stations = Station.foundStationNames
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
  
  func createGetThereButton() {
    if getThereButton == nil {
      getThereButton = UIButton(frame: CGRect(x: 5, y: -55, width: mapView.bounds.width-10, height: 50.0))
      
      if let button = getThereButton {
        button.backgroundColor = .gray
        button.setTitle("Get there", for: .normal)
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        
        self.mapView.addSubview(button)
        
        UIView.animate(withDuration: 0.2,
                       delay: 0.0,
                       options: UIView.AnimationOptions.curveEaseInOut,
                       animations: {
                        button.frame = CGRect.init(x: button.frame.minX, y: 5, width: button.frame.width, height: 50.0)
        })
      }
      
    }
  }
  
  @objc func didSelectSuggestion(notification: NSNotification) {
    
    if let selectedItem = notification.userInfo?["selectedItem"] as? String {
      selectedSuggestion = selectedItem
      
      if let button = getThereButton {
        UIView.animate(withDuration: 0.2,
                       delay: 0.0,
                       options: UIView.AnimationOptions.curveEaseInOut,
                       animations: {
                        button.frame = CGRect.init(x: button.frame.minX, y: 5, width: button.frame.width, height: 50.0)
        })
      }
    }
    
    if getThereButton == nil {
      createGetThereButton()
    }
  }
  
  @objc func buttonAction(sender: UIButton!) {
    print("Button tapped")
    
    let group = DispatchGroup()
    group.enter()
    DispatchQueue.main.async {
      if let location = self.locationSet.currentLocation {
        Station.getNearestStations(dispatchGroup: group, location: location)
      }
    }
    // Request ist fertig
    group.notify(queue: .main) {
      print("fertig")
      self.drawLocationsForStations()
    }
    
  }
  
  func drawLocationsForStations() {
    for station in Station.nearestStations {
      
      let stationAnnotation = CustomPointAnnotation()
      
      var loc = CLLocationCoordinate2D.init()
      
      if let location = station["location"] as? [String:Any] {
        if let lat = location["latitude"] as? Double {
          loc.latitude = lat
        }
        
        if let long = location["longitude"] as? Double {
          loc.longitude = long
        }
      }
      
      if let products = station["products"] as? [String:Bool] {
        var resultStr = ""
        var multiCount = 0
        
        for product in products {
          if product.value {
            if resultStr == "" {
              resultStr = product.key
            } else {
              resultStr = "\(resultStr), \(product.key)"
            }
            stationAnnotation.pinCustomImageName = product.key
            multiCount += 1
          }
          if multiCount > 1 {
            stationAnnotation.pinCustomImageName = AnnotationImage.multi.rawValue
          }
        }
        stationAnnotation.subtitle = resultStr.uppercased()
      }
      
      if let stationName = station["name"] as? String {
        stationAnnotation.title = stationName
      }
      
      stationAnnotation.coordinate = loc
      
      self.drawLocationOnMap(location: loc, pointAnnotation: stationAnnotation)
    }

  }
  
  func drawLocationOnMap(location: CLLocationCoordinate2D, pointAnnotation: CustomPointAnnotation) {
    var pinAnnotationView:MKPinAnnotationView!
    
    pinAnnotationView = MKPinAnnotationView(annotation: pointAnnotation, reuseIdentifier: "pin")
    mapView.addAnnotation(pinAnnotationView.annotation!)
  }
  
  func addNotificationObserver() {
    searchTextField.addTarget(self, action: #selector(MapViewController.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
    
    NotificationCenter.default.addObserver(self, selector: #selector(didSelectSuggestion(notification:)), name: NSNotification.Name.clickedOnItem, object: nil)
    
    NotificationCenter.default.addObserver(self, selector: #selector(updateHeadingRotation(notification:)), name: NSNotification.Name.newHeading, object: nil)
  }
  
  func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
    
    
    
    if views.last?.annotation is MKUserLocation {
      print("didAdd!")
      addHeadingView(toAnnotationView: views.last!)
    }
  }
  
  func addHeadingView(toAnnotationView annotationView: MKAnnotationView) {
    let image = UIImage.init(named: "direction")
    
    if let img = image, headingImageView == nil {
      headingImageView = UIImageView(image: img)
      
      headingImageView?.frame = CGRect(x: (annotationView.frame.size.width - img.size.width/2)/2, y: (annotationView.frame.size.height - img.size.height/2)/2, width: img.size.width/2, height: img.size.height/2)
      if let headingImageView = headingImageView {
        annotationView.insertSubview(headingImageView, at: 0)
        headingImageView.isHidden = true
      }
    }
  }
  
  
  @objc func updateHeadingRotation(notification: NSNotification) {
    
    if let newHeading = notification.userInfo?["newHeading"] as? CLHeading {
      print("Heading: \(newHeading.trueHeading)")
      headingImageView?.isHidden = false
      let rotation = CGFloat(newHeading.trueHeading/180 * Double.pi)
      headingImageView?.transform = CGAffineTransform(rotationAngle: rotation)
      
      locationSet.lastHeading = newHeading
    }
  }
  
  @IBAction func didChangeSearchTextField(_ sender: Any) {
    
    print("change")
    if let button = getThereButton {
      UIView.animate(withDuration: 0.2,
                     delay: 0.0,
                     options: UIView.AnimationOptions.curveEaseInOut,
                     animations: {
                      button.frame = CGRect.init(x: button.frame.minX, y: -55, width: button.frame.width, height: 50.0)
      })
    }
    
  }
  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    
    guard !annotation.isKind(of: MKUserLocation.self) else {
      
      return nil
    }
    
    let annotationIdentifier = "AnnotationIdentifier"
    
    var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier)
    
    if annotationView == nil {
      annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
      annotationView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
      annotationView!.canShowCallout = true
    }
    else {
      annotationView!.annotation = annotation
    }
    
    if let customPointAnnotation = annotation as? CustomPointAnnotation {
      if let image = UIImage(named: customPointAnnotation.pinCustomImageName) {
        
        let imgView = UIImageView.init(frame: CGRect.init(x: 0, y: 100, width: 40, height: 40))
        imgView.contentMode = UIView.ContentMode.center
        imgView.image = image
        
        annotationView?.image = image
      }
    }
    
    return annotationView
    
  }
  
}

