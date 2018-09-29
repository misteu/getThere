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
  var selectedId: String?
  var messageToast: UIView?
  var selectedAnnotation: CustomPointAnnotation?
  var topToastLabel: UILabel?
  let toastColor = UIColor.init(red: 66/255, green: 66/255, blue: 66/255, alpha: 0.8)
  var isTopToastShown = false
  var isJourneyToastShown = false
  
  @IBOutlet weak var journeyToastBottomMargin: NSLayoutConstraint!
  @IBOutlet weak var journeyLabel: UILabel!
  @IBOutlet weak var journeyToastScrollView: UIScrollView!
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
    mapView.userLocation.title = ""
    initToastColors()
  }
  
  func findAndDrawNearestStationsAsync() {
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
      self.drawLocationsForStations(distance: AppSettings.maxStationDistanceToUser)
    }
  }
  
  override func touchesBegan(_ touches: Set<UITouch>,
                             with event: UIEvent?) {
    self.view.endEditing(true)
  }
  
  @objc func jumpToFirstLocation() {
    if let location = locationSet.currentLocation {
      
      mapView.setCamera(getCameraForLocation(locValue: location, heading: 0), animated: false)
      mapView.addAnnotation(mapView.userLocation)
      
      
      locationSet.hasFoundFirstLocation = true
      locationSet.findFirstLocationTimer.invalidate()
      
    }
  }
  
  func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
    findAndDrawNearestStationsAsync()
  }
  
  
  func updateSearchTextFieldAsync(userInput: String) {
    let group = DispatchGroup()
    group.enter()
    DispatchQueue.main.async {
      Station.getStationsWithName(dispatchGroup: group, name: userInput)
    }
    // Request ist fertig
    group.notify(queue: .main) {
      print("fertig")
      
      let stations = Station.foundStationNamesAndIds
      if stations.count > 0 {
        //print(stations)
        print("update Stations")
        
        var stationNames = [String]()
        
        for station in stations {
          stationNames.append(station.value)
        }
        self.searchTextField.filterStrings(stationNames)
        self.searchTextField.stopLoadingIndicator()
      }
    }
  }
  
  func getCameraForLocation(locValue: CLLocationCoordinate2D, heading: Double) -> MKMapCamera {
    return MKMapCamera.init(lookingAtCenter: CLLocationCoordinate2D.init(latitude: locValue.latitude, longitude: locValue.longitude), fromDistance: AppSettings.zoomDistanceFirstUserLocation, pitch: 20, heading: heading)
  }
  
  @objc func textFieldDidChange(_ textField: UITextField) {
    if let text = textField.text {
      if text.count > 2 {
        if !isLocalStationList {
          updateSearchTextFieldAsync(userInput: text)
          isLocalStationList = true
          searchTextField.showLoadingIndicator()
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
      selectedId = Station.foundStationNamesAndIds.key(forValue: selectedItem)
//      if let button = getThereButton {
//        UIView.animate(withDuration: 0.2,
//                       delay: 0.0,
//                       options: UIView.AnimationOptions.curveEaseInOut,
//                       animations: {
//                        button.frame = CGRect.init(x: button.frame.minX, y: 5, width: button.frame.width, height: 50.0)
//        })
//
//      }
      print(selectedId)
    }
    
    showTopToast(withMessage: "Select a station to start from", forSeconds: nil)
//    if getThereButton == nil {
//      createGetThereButton()
//    }
  }
  
  @objc func buttonAction(sender: UIButton!) {
    print("Button tapped")
  
  }
  
  func drawLocationsForStations(distance: Int) {
    for station in Station.nearestStations {
      
      if let dist = station["distance"] as? Int {
        
        if dist < distance {
          
          let stationAnnotation = CustomPointAnnotation()
          
          if let id = station["id"] as? String {
            stationAnnotation.stationID = id
          }
          
          var loc = CLLocationCoordinate2D.init()
          
          if let location = station["location"] as? [String:Any] {
            if let lat = location["latitude"] as? Double {
              loc.latitude = lat
            }
            
            if let long = location["longitude"] as? Double {
              loc.longitude = long
            }
          }
          
          //var linesAtStation = [String]()
          var resultStr = ""
          
          if let lines = station["lines"] as? [[String:Any]] {
            
            for line in lines {
              if let name = line["name"] as? String {
                if let product = line["product"] as? String {
                  var fullName = ""
                  
                  switch product {
                  case "suburban":
                    fullName = name
                    break
                  case "subway":
                    fullName = name
                    break
                  case "regional":
                    fullName = "RE"
                    break
                  case "express":
                    fullName = "EXPRESS"
                    break
                  default:
                    fullName = "\(product.uppercased()) \(name)"
                  }
                  
                  if resultStr == "" {
                    resultStr = fullName
                  } else {
                    resultStr = "\(resultStr), \(fullName)"
                  }
                }
              }
            }
            stationAnnotation.annotationText = "\n\(resultStr.uppercased())"
          }
          
          if let products = station["products"] as? [String:Bool] {
            var multiCount = 0
            
            for product in products {
              if product.value {
                stationAnnotation.pinCustomImageName = product.key
                multiCount += 1
              }
              if multiCount > 1 {
                stationAnnotation.pinCustomImageName = AnnotationImage.multi.rawValue
              }
            }
          }
          
          if let stationName = station["name"] as? String {
            stationAnnotation.title = stationName
          }
          
          stationAnnotation.coordinate = loc
          
          self.drawLocationOnMap(location: loc, pointAnnotation: stationAnnotation)
        }
      }
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
      //print("Heading: \(newHeading.trueHeading)")
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
    
    if annotation.isKind(of: MKUserLocation.self) {
      return nil
    }
    
    let annotationIdentifier = "AnnotationIdentifier"
    
    var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier)
    
    if annotationView == nil {
      
      //Standard Annotation View
      annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
      annotationView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
      annotationView!.canShowCallout = true

      
//      annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
//      annotationView?.canShowCallout = true
//
      let label1 = UILabel(frame: CGRect.init(x: 0, y: 0, width: 200, height: 21))
      
      if let customPointAnnotation = annotation as? CustomPointAnnotation {
        
        label1.text = customPointAnnotation.annotationText
        label1.numberOfLines = 0
        annotationView!.detailCalloutAccessoryView = label1;
        
        let width = NSLayoutConstraint(item: label1, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.lessThanOrEqual, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 200)
        label1.addConstraint(width)
        
      }
      
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
  
  func showTopToast(withMessage: String, forSeconds: Double?) {
    isTopToastShown = true
    messageToast = UIView(frame: CGRect(x: 5, y: -55, width: mapView.bounds.width-10, height: 50.0))
    
    if let message = messageToast {
      message.backgroundColor = toastColor
      
      var messageLabel = topToastLabel
      messageLabel = UILabel(frame: CGRect.init(x: 5, y: 0, width: message.frame.width, height: 50.0))
      messageLabel?.text = withMessage
      messageLabel?.backgroundColor = .clear
      messageLabel?.textColor = .white
      messageLabel?.textAlignment = NSTextAlignment.center
      messageLabel?.font = UIFont.init(name: "DINAlternate-Bold", size: 14.0)
      
      
      if let label = messageLabel {
        message.addSubview(label)
      }
      self.mapView.addSubview(message)
      
      if let delay = forSeconds {
        UIView.animate(withDuration: 0.2,
                       delay: 0.0,
                       options: UIView.AnimationOptions.curveEaseInOut,
                       animations: {
                        message.frame = CGRect.init(x: 5, y: 5, width: message.frame.width, height: 50.0)
        }, completion: { (finished: Bool) in
          UIView.animate(withDuration: 0.2,
                         delay: delay,
                         options: UIView.AnimationOptions.curveEaseInOut,
                         animations: {
                          message.frame = CGRect.init(x: 5, y: -55, width: message.frame.width, height: 50.0)
          })
        })
      } else {
        UIView.animate(withDuration: 0.2,
                       delay: 0.0,
                       options: UIView.AnimationOptions.curveEaseInOut,
                       animations: {
                        message.frame = CGRect.init(x: 5, y: 5, width: message.frame.width, height: 50.0)
        })
      }
    }
  }
  
  func hideTopToast() {
    if let message = messageToast {
      UIView.animate(withDuration: 0.2,
                     delay: 0.0,
                     options: UIView.AnimationOptions.curveEaseInOut,
                     animations: {
                      message.frame = CGRect.init(x: 5, y: -55, width: self.mapView.bounds.width-10, height: 50.0)
      }, completion: { (finished: Bool) in
        self.isTopToastShown = false
        })
    }
    
  }
  
  func initToastColors() {
    if let messageLabel = journeyLabel {
      messageLabel.numberOfLines = 0
      messageLabel.backgroundColor = .clear
      messageLabel.textColor = .white
      
    }
    
    if let journeyScroll = journeyToastScrollView {
      journeyScroll.backgroundColor = toastColor
    }
  }
  
  func showJourneyToastBottom(withMessage: String) {
    isJourneyToastShown = true
    // halbtransparenten Hintergrund oder so
    
    if let messageLabel = journeyLabel {
      messageLabel.text = withMessage
      
      journeyToastBottomMargin.constant = 5
      journeyToastScrollView.isHidden = false
      UIView.animate(withDuration: 0.2) {
        self.view.layoutIfNeeded()
      }
      
    }
    
    if isTopToastShown {
      hideTopToast()
    }
    
  }
  
  func hideJourneyToast() {
    isJourneyToastShown = false
    journeyToastBottomMargin.constant = -155
    UIView.animate(withDuration: 0.2) {
      self.view.layoutIfNeeded()
    }
    
    if !isTopToastShown {
      showTopToast(withMessage: "Select a station to start from", forSeconds: nil)
    }
    
  }
  
  func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
  
    selectedAnnotation = view.annotation as? CustomPointAnnotation
    
    if let startId = selectedAnnotation?.stationID, let destId = selectedId{
      print("URL: from=\(startId)&to=\(destId)")
      let group = DispatchGroup()
      group.enter()
      
      DispatchQueue.main.async {
        
        Station.getJourney(dispatchGroup: group, fromID: startId, toID: destId)
        self.showJourneyToastBottom(withMessage: "Loading journeys...")
      }
      // Request ist fertig
      group.notify(queue: .main) {

        self.hideJourneyToast()
        print("Journeys fertig")
        
        // Immer Departure, Origin, Departure, Origin hintereinander weg im Array
        var journeyStationTimes = [(String,String,String)]()
        
        let firstJourney = Station.foundJourneys[0]
        print(firstJourney)
        if let legs = firstJourney["legs"] as? [[String:Any]] {
          for leg in legs {
            
            var legOrigin = ("","","")
            var legDestination = ("","","")
            
            // Origin
            if let origin = leg["origin"] as? [String:Any] {
              if let name = origin["name"] as? String {
                legOrigin.0 = name
              }
            }
            if let departure = leg["departure"] as? String {
              legOrigin.1 = departure
            }
            
            if let destination = leg["destination"] as? [String:Any] {
              if let name = destination["name"] as? String {
                legDestination.0 = name
              }
            }
            if let arrival = leg["arrival"] as? String {
              legDestination.1 = arrival
            }
            
            if let mode = leg["mode"] as? String {
              if mode == "walking" {
                legOrigin.2 = "🚶‍♀️"
                legDestination.2 = "🚶‍♂️"
              }
            } else {
              if let line = leg["line"] as? [String:Any] {
                if let product = line["product"] as? String {
                  switch product {
                  case "suburban":
                    legOrigin.2 = ""
                    break
                  case "subway":
                    legOrigin.2 = ""
                    break
                  case "regional":
                    legOrigin.2 = "RE "
                    break
                  case "express":
                    legOrigin.2 = "EXPRESS "
                    break
                  default:
                    legOrigin.2 = product.uppercased()
                  }
                  
                  legDestination.2 = legOrigin.2
                }
                if let linename = line["name"] as? String {
                  legOrigin.2 = "\(legOrigin.2)\(linename)"
                  legDestination.2 = "\(legDestination.2)\(linename)"
                }
              }
            }
            
            journeyStationTimes.append(legOrigin)
            journeyStationTimes.append(legDestination)
          }
        }
        
      
        var toastString = ""
        var legIndex = 0
        for leg in journeyStationTimes {
          
          // Uhrzeit aus Datumsstring holen
          let startIndex = leg.1.index(leg.1.startIndex, offsetBy: 11)
          let endIndex = leg.1.index(leg.1.startIndex, offsetBy: 16)
          let time = leg.1[startIndex ..< endIndex]
          
          if toastString == "" {
            toastString = "\(time) - \(leg.2) \(leg.0)"
          } else {
            toastString = "\(toastString)\n\(time) - \(leg.2) \(leg.0)"
          }
          legIndex += 1
          
          if legIndex%2 == 0 {
            if legIndex < journeyStationTimes.count {
              toastString = "\(toastString)\n"
            } else {
              toastString = "\(toastString)"
            }
          }
        }
        
        self.showJourneyToastBottom(withMessage: toastString)
      }
    
    }
  }
  
  func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
    hideJourneyToast()
  }
  
  func textFieldDidBeginEditing(_ textField: UITextField) {
    hideTopToast()
  }
  
}

