//
//  DebtTypeTableViewController.swift
//  
//
//  Created by Jordan Leavitt on 5/3/18.
//

import UIKit

protocol DebtTypeTableViewDelegate: class {
    func didUpdateType(type: String)
}

class DebtTypeTableViewController: UITableViewController {
    
    weak var delegate: DebtTypeTableViewDelegate?
    
    @IBOutlet var myTableView: UITableView!
    
    // Types of Debt Array
    let debtTypes = [NSLocalizedString("Auto", tableName: "Localizable", comment: ""),
                     NSLocalizedString("Bank Loan", tableName: "Localizable", comment: ""),
                     NSLocalizedString("Credit Card", tableName: "Localizable", comment: ""),
                     NSLocalizedString("Family", tableName: "Localizable", comment: ""),
                     NSLocalizedString("IRS", tableName: "Localizable", comment: ""),
                     NSLocalizedString("Medical", tableName: "Localizable", comment: ""),
                     NSLocalizedString("Mortgage", tableName: "Localizable", comment: ""),
                     NSLocalizedString("Other", tableName: "Localizable", comment: ""),
                     NSLocalizedString("Student Loan", tableName: "Localizable", comment: ""),
                     NSLocalizedString("401k Loan", tableName: "Localizable", comment: "")]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Clears empty Cells
        tableView.tableFooterView = UIView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return debtTypes.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DebtTypeCell", for: indexPath)
        
        cell.textLabel?.text = debtTypes[indexPath.row]
        cell.textLabel?.textColor = UIColor(red:0.36, green:0.55, blue:0.55, alpha:1.0)
        cell.textLabel?.font = UIFont(name: "Raleway", size: 20)
        
        
        return cell
    }
    
    // Did Select Row
    var textToBeSent: String = ""
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        textToBeSent = debtTypes[indexPath.row]
        self.delegate?.didUpdateType(type: textToBeSent)
        
        self.performSegue(withIdentifier: "unwindToNewDebtTableView", sender: nil)
    }
    
}
