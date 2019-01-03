//
//  NewDebtTableViewController.swift
//  Ripple
//
//  Created by Jordan Leavitt on 4/9/18.
//  Copyright © 2018 Jordan Leavitt. All rights reserved.
//

import UIKit
import CoreData
import Flurry_iOS_SDK

protocol NewDebtViewControllerDelegate: class {
    func didFinishAdding(debt: Debt)
}

class NewDebtTableViewController: UITableViewController, UITextFieldDelegate, DebtTypeTableViewDelegate {
    
    weak var delegate: NewDebtViewControllerDelegate?
    
    
    
    @IBOutlet weak var debtTypeTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var debtTypeLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var debtNameLeadingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var debtNameTrailingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var percentageSign: UILabel!
    @IBOutlet weak var debtNameTextField: UITextField!
    @IBOutlet weak var debtAmountTextField: UITextField!
    @IBOutlet weak var typeOfDebtLabel: UILabel!
    @IBOutlet weak var minimumPaymentTextField: UITextField!
    @IBOutlet weak var extraPaymentTextField: UITextField!
    @IBOutlet weak var interestRateTextField: UITextField!
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: "unwindSegueToTableViewController", sender: self)
    }
    
    @IBAction func unwindToMainTableView(segue:UIStoryboardSegue) { }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Clears Empty Cells
        tableView.tableFooterView = UIView()
        self.setupCurrencyTextFields()
        self.setupInterestTextFields()
        
    }
    
    /**
     Listen to the the keystrokes in certain textfields so that we can apply currency formatting.
     */
    private func setupCurrencyTextFields() {
        self.debtAmountTextField.addTarget(self, action: #selector(curencyTextFieldDidChange(_:)), for: .editingChanged)
        self.minimumPaymentTextField.addTarget(self, action: #selector(curencyTextFieldDidChange(_:)), for: .editingChanged)
        self.extraPaymentTextField.addTarget(self, action: #selector(curencyTextFieldDidChange(_:)), for: .editingChanged)
    }
    
    private func setupInterestTextFields() {
        self.interestRateTextField.addTarget(self, action: #selector(interestRateTextFieldDidChange(_:)),
                                             for: .editingChanged)
    }
    
    // Save Button
    @IBAction func saveButtonTapped(_ sender: Any) {
        if let typeOfDebt = typeOfDebtLabel.text,
            let debtName = debtNameTextField.text,
            let minimumPaymentString = minimumPaymentTextField.text,
            let minimumPaymentNumber = CurrencyFormatter.format(amount: minimumPaymentString),
            let minimumPayment = Double(exactly: minimumPaymentNumber),
            let extraPaymentString = extraPaymentTextField.text,
            let interestAmountString = interestRateTextField.text,
            let interest = Double(interestAmountString),
            let debtAmountString = debtAmountTextField.text,
            let debtAmountNumber = CurrencyFormatter.format(amount: debtAmountString),
            let debtAmount = Double(exactly: debtAmountNumber) {
            
            let extraPayment = Double(truncating: CurrencyFormatter.format(amount: extraPaymentString) ?? 0)
            
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                let managedContext = appDelegate.persistentContainer.viewContext
                
                if let entity = NSEntityDescription.entity(forEntityName: "Debt", in: managedContext) {
                    let newDebtObject = Debt(entity: entity, insertInto: managedContext)
                    
                    newDebtObject.id = UUID()
                    newDebtObject.name = debtName
                    newDebtObject.minimumPayment = minimumPayment
                    newDebtObject.originalAmount = debtAmount
                    newDebtObject.currentAmount = debtAmount
                    newDebtObject.type = typeOfDebt
                    newDebtObject.extraPayment = extraPayment
                    newDebtObject.interest = interest / 100
                    
                    //Send Analytics
                    Flurry.logEvent("Added New Debt")
                    
                    do {
                        try managedContext.save()
                        
                        let okButton = UIAlertAction(title: "Ok", style: .default) { (action) in
                            if let delegate = self.delegate {
                                delegate.didFinishAdding(debt: newDebtObject)
                                self.dismiss(animated: true, completion: nil)
                            }
                            
                            self.navigationController?.popViewController(animated: true)
                        }
                        let alert = UIAlertController(title: "Success", message: "Your debt has been saved", preferredStyle: .alert)
                        alert.addAction(okButton)
                        
                        self.present(alert, animated: true, completion: nil)
                        
                    } catch {
                        // The code inside this catch block is NOT fired if a user doesn't fill out all the fields,
                        // it is fired if something unexpected happens on the iOS side (something outside your control)
                        // catch blocks allow us to "Fail Gracefully".
                        let okButton = UIAlertAction(title: "Ok", style: .default) { (action) in
                            self.navigationController?.popViewController(animated: true)
                        }
                        
                        let alert = UIAlertController(title: "Failure", message: "Your debt was not saved", preferredStyle: .alert)
                        alert.addAction(okButton)
                        
                        self.present(alert, animated: true, completion: nil)
                        
                        print("Failed saving")
                    }
                }
            }
        } else {
            // This code is hit if the user didn't fill out all the fields
            let okButton = UIAlertAction(title: "Ok", style: .default) { (action) in
            }
            
            let alert = UIAlertController(title: "Oops!", message: "Please make sure all required fields have been filled out.", preferredStyle: .alert)
            alert.addAction(okButton)
            
            self.present(alert, animated: true, completion: nil)
        }
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? UINavigationController,
            let info = navController.topViewController as? DebtTypeTableViewController {
            info.delegate = self
        }
    }
    
    
    // Hide Keyboard when user touches outside of keyboard
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    // Hide Keyboard when user presses return key
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func didUpdateType(type: String) {
        self.typeOfDebtLabel.text = type
    }
    
    @objc func curencyTextFieldDidChange(_ textField: UITextField) {
        if let value = textField.text {
            let currencyValue = self.currencyInputFormatting(amountWithPrefix: value)
            textField.text = currencyValue
        }
    }
    
    // formatting text for currency textField
    func currencyInputFormatting(amountWithPrefix: String) -> String {
        var number: NSNumber!
        let formatter = NumberFormatter()
        formatter.numberStyle = .currencyAccounting
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        
        // remove from String: "$", ".", ","
        let regex = try! NSRegularExpression(pattern: "[^0-9]", options: .caseInsensitive)
        
        let cleanedString = regex.stringByReplacingMatches(in: amountWithPrefix,
                                                           options: NSRegularExpression.MatchingOptions(rawValue: 0),
                                                           range: NSMakeRange(0, amountWithPrefix.count),
                                                           withTemplate: "")
        
        let double = (cleanedString as NSString).doubleValue
        number = NSNumber(value: (double / 100))
        
        // if first number is 0 or all numbers were deleted
        guard number != 0 as NSNumber else {
            return ""
        }
        
        return formatter.string(from: number)!
    }
    
    @objc func interestRateTextFieldDidChange(_ textField: UITextField) {
        if let value = textField.text {
            let interestValue = self.interestRateFormatting(amountWithPrefix: value)
            textField.text = interestValue
        }
    }
    
    // formatting text for interest rate
    func interestRateFormatting(amountWithPrefix: String) -> String {
        var percent: NSDecimalNumber!
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        
        // remove from String: "$", ".", ","
        let regex = try! NSRegularExpression(pattern: "[^0-9]", options: .caseInsensitive)
        
        let cleanedString = regex.stringByReplacingMatches(in: amountWithPrefix,
                                                           options: NSRegularExpression.MatchingOptions(rawValue: 0),
                                                           range: NSMakeRange(0, amountWithPrefix.count),
                                                           withTemplate: "")
        
        let double = (cleanedString as NSString).doubleValue
        percent = NSDecimalNumber(value: (double / 100))
        
        // if first number is 0 or all numbers were deleted
        guard percent != 0 as NSDecimalNumber else {
            return ""
        }
        
        return formatter.string(from: percent)!
    }
}













