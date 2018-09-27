//
//  RequestStations.swift
//  getThere
//
//  Created by skrr on 25.09.18.
//  Copyright © 2018 skrr. All rights reserved.
//

import Foundation
import CoreLocation


class Station {
  
  static var nearestStations = [[String:Any]]()
  static var foundStationNames = [String]()
  
  static func getNearestStations(dispatchGroup: DispatchGroup, location: CLLocationCoordinate2D) {
    // Set up the URL request
    let todoEndpoint: String = "https://1.bvg.transport.rest/stations/nearby?latitude=\(location.latitude)&longitude=\(location.longitude)"
    guard let url = URL(string: todoEndpoint) else {
      print("Error: cannot create URL")
      return
    }
    let urlRequest = URLRequest(url: url)
    
    // set up the session
    let config = URLSessionConfiguration.default
    let session = URLSession(configuration: config)
    
    
      // make the request
      let task = session.dataTask(with: urlRequest) {
        (data, response, error) in
        // check for any errors
        guard error == nil else {
          print("error calling GET on /todos/1")
          print(error!)
          return
        }
        // make sure we got data
        guard let responseData = data else {
          print("Error: did not receive data")
          return
        }
        // parse the result as JSON, since that's what the API provides
        
        do {
          let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [[String:Any]]
          
          if let stations = json {
//            for station in stations {
//              if let stationName = station["location"] as? String{
//                //print(stationName)
//                foundStations.append(stationName)
//              }
//            }
            
            nearestStations = stations
          
          }
          
        } catch {
          print("irgendein Fehler")
        }
        dispatchGroup.leave()
      }
      
      task.resume()
  }
  
  static func getStationsWithName(dispatchGroup: DispatchGroup, name: String) {
    // Set up the URL request
    let todoEndpoint: String = "https://1.bvg.transport.rest/locations?query=\(name)"
    guard let url = URL(string: todoEndpoint) else {
      print("Error: cannot create URL")
      return
    }
    let urlRequest = URLRequest(url: url)
    
    // set up the session
    let config = URLSessionConfiguration.default
    let session = URLSession(configuration: config)
    
    
    // make the request
    let task = session.dataTask(with: urlRequest) {
      (data, response, error) in
      // check for any errors
      guard error == nil else {
        print("error calling GET on /todos/1")
        print(error!)
        return
      }
      // make sure we got data
      guard let responseData = data else {
        print("Error: did not receive data")
        return
      }
      // parse the result as JSON, since that's what the API provides
      
      do {
        let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [[String:Any]]
        
        if let stations = json {
          for station in stations {
            if let stationName = station["name"] as? String{
              //print(stationName)
              foundStationNames.append(stationName)
            }
          }
        }
        
      } catch {
        print("irgendein Fehler")
      }
      dispatchGroup.leave()
    }
    
    task.resume()
  }
  
  
}
