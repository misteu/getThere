//
//  CustomPointAnnotation.swift
//  getThere
//
//  Created by skrr on 27.09.18.
//  Copyright © 2018 skrr. All rights reserved.
//

import UIKit
import MapKit

class CustomPointAnnotation: MKPointAnnotation {
  var pinCustomImageName:String!
  var annotationText: String!
  var stationID: String!
}

enum AnnotationImage: String {
  case multi = "multi"
}
