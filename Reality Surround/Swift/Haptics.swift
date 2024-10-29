//
//  Haptics.swift
//  Reality Surround
//
//  Created by Hazem Ali on 2/13/21.
//  Copyright © 2021 Skytells, Inc. All rights reserved.
//

import Foundation
import UIKit
class Haptics {
    class func isFeedbackSupport() -> Bool {
        if let value = UIDevice.current.value(forKey: "_feedbackSupportLevel") {
            let result = value as! Int
            return result == 2 ? true : false
        }
        return false
    }
    
}
