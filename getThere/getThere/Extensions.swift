//
//  Extensions.swift
//  getThere
//
//  Created by skrr on 26.09.18.
//  Copyright © 2018 skrr. All rights reserved.
//

import Foundation

extension Notification.Name {
  
  static let clickedOnItem = Notification.Name("clickedOnItem")
  static let newHeading = Notification.Name("newHeading")
  
}

extension Dictionary where Value: Equatable {
  func key(forValue value: Value) -> Key? {
    return first { $0.1 == value }?.0
  }
}
