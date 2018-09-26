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
    
    //    let pfeilImage = UIImage.init(named: "pfeil")
    //    let pfeilImgView = UIImageView.init(image: pfeilImage)
    //
    //    mapView.addSubview(pfeilImgView)
    
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
      
      //let pfeilAnnotation =
      
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
  }
  
  func addNotificationObserver() {
    searchTextField.addTarget(self, action: #selector(MapViewController.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
    
    NotificationCenter.default.addObserver(self, selector: #selector(didSelectSuggestion(notification:)), name: NSNotification.Name.clickedOnItem, object: nil)
    
    NotificationCenter.default.addObserver(self, selector: #selector(updateHeadingRotation(notification:)), name: NSNotification.Name.newHeading, object: nil)
  }
  
  func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
    
    print("didAdd!")
    
    if views.last?.annotation is MKUserLocation {
      addHeadingView(toAnnotationView: views.last!)
    }
  }
  
  func addHeadingView(toAnnotationView annotationView: MKAnnotationView) {
    let image = UIImage.init(named: "pfeil")
    
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
    }
  }
  
  func textFieldDidBeginEditing(_ textField: UITextField) {
    //    if let button = getThereButton {
    //      UIView.animate(withDuration: 0.2,
    //                     delay: 0.0,
    //                     options: UIView.AnimationOptions.curveEaseInOut,
    //                     animations: {
    //                      button.frame = CGRect.init(x: button.frame.minX, y: -55, width: button.frame.width, height: 50.0)
    //      })
    //    }
  }
  
  @objc func textFieldDidChange() {
    
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
  
}

