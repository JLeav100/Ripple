//
//  CurrencyFormatter.swift
//  Ripple
//
//  Created by Hesham Abd-Elmegid on 10/7/18.
//  Copyright © 2018 Jordan Leavitt. All rights reserved.
//

import Foundation

class CurrencyFormatter {
    
    static func format(amount: Double) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        let amountNumber = NSNumber(value: amount)
        return numberFormatter.string(from: amountNumber)!
    }
    
    static func format(amount: String) -> NSNumber? {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        return numberFormatter.number(from: amount)
    }
}
