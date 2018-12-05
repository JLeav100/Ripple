//
//  DataItem.swift
//  Ripple
//
//  Created by Jordan Leavitt on 4/5/18.
//  Copyright © 2018 Jordan Leavitt. All rights reserved.
//

import UIKit

class DataItem {
    var type: String
    var name: String
    var amount: Double
    
    init(type: String, name: String, amount: Double) {
        self.type = type
        self.name = name
        self.amount = amount
    }
}
