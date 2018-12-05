//
//  DebtTableViewCell.swift
//  
//
//  Created by Jordan Leavitt on 4/9/18.
//

import UIKit

class DebtTableViewCell: UITableViewCell {
    
    var debt: Debt?
    
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var debtTypeLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var minimumPaymentLabel: UILabel!
}
