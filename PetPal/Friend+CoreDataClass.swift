//
//  Friend+CoreDataClass.swift
//  PetPal
//
//  Created by Brian on 9/20/17.
//  Copyright © 2017 Razeware. All rights reserved.
//
//

import Foundation
import CoreData
import UIKit

public class Friend: NSManagedObject {

    var eyeColorString : String {
        switch eyeColor as! UIColor {
            case .black : return "Black"
            case .gray : return "Gray"
            case .blue : return "Blue"
            case .green : return "Green"
            case .brown : return "Brown"
        default:
            return "unknown"
        }
    }
    
  var age: Int {
    if let dob = dob as Date? {
      return Calendar.current.dateComponents([.year], from: dob, to: Date()).year!
    }
    return 0
  }

}
