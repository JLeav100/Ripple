//
//  CellDetailViewController.swift
//  Ripple
//
//  Created by Jordan Leavitt on 8/31/18.
//  Copyright © 2018 Jordan Leavitt. All rights reserved.
//

import UIKit
import CoreData

protocol CellDetailVewControllerDelegate: class {
    func updatedDebt(_ debt: Debt, for indexPath: IndexPath)
}

class CellDetailViewController: UIViewController {
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var minPaymentUpdate: UITextField!
    @IBOutlet weak var extraPaymentUpdate: UITextField!
    
    var debt: Debt?
    var indexPath: IndexPath?
    weak var delegate: CellDetailVewControllerDelegate?
    
    override func viewDidLoad() {
        
        let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveButtonTapped))
        let backButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTapped))
        self.navigationItem.rightBarButtonItem = saveButton
        self.navigationItem.leftBarButtonItem = backButton
        
        saveButton.tintColor = UIColor(red:0.20, green:0.20, blue:0.24, alpha:1.0)
        backButton.tintColor = UIColor(red:0.20, green:0.20, blue:0.24, alpha:1.0)
        
        if let debt = debt {
            amountTextField.text = CurrencyFormatter.format(amount: debt.currentAmount)
            minPaymentUpdate.text = CurrencyFormatter.format(amount: debt.minimumPayment)
            extraPaymentUpdate.text = CurrencyFormatter.format(amount: debt.extraPayment)
            
             self.setupCurrencyTextFields()
            
        }
    }
    
    
    private func setupCurrencyTextFields() {
        self.amountTextField.addTarget(self, action: #selector(curencyTextFieldDidChange(_:)), for: .editingChanged)
        self.minPaymentUpdate.addTarget(self, action: #selector(curencyTextFieldDidChange(_:)), for: .editingChanged)
        self.extraPaymentUpdate.addTarget(self, action: #selector(curencyTextFieldDidChange(_:)), for: .editingChanged)
    }
    
    @objc func cancelButtonTapped() {
        _ = navigationController?.popViewController(animated: true)
    }
    
    @objc func saveButtonTapped() {
        // Save to db
        if let amount = amountTextField.text,
            let minPay = minPaymentUpdate.text,
            let extraPay = extraPaymentUpdate.text,
            let indexPath = self.indexPath {
            
            let amountDouble = Double(truncating: CurrencyFormatter.format(amount: amount) ?? 0)
            let minPayDouble = Double(truncating: CurrencyFormatter.format(amount: minPay) ?? 0)
            let extraPayDouble = Double(truncating: CurrencyFormatter.format(amount: extraPay) ?? 0)
            
            // Pass the updated amount to our delegate
            let debt = self.updateDebtAmount(amountDouble, minPayment: minPayDouble, extraPay: extraPayDouble)
            self.delegate?.updatedDebt(debt, for: indexPath)
        }
    }
    
    private func updateDebtAmount(_ amount: Double, minPayment: Double, extraPay: Double) -> Debt {
        var debtToReturn = Debt()
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let debtID = self.debt?.id?.uuidString {
            let managedContext = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Debt")
            fetchRequest.predicate = NSPredicate(format: "id = %@", debtID)
            
            do {
                
                // fetch() returns an array of Debt's that match the id we searched for.
                // we should only ever get ONE debt though since the id's are unique.
                if let debt = try managedContext.fetch(fetchRequest).first as? Debt {
                    
                    // Update the current amount to what the user entered
                    debt.currentAmount = amount
                    debt.extraPayment = extraPay
                    debt.minimumPayment = minPayment
                    
                    // Save the update to our database.
                    try managedContext.save()
                    
                    let okButton = UIAlertAction(title: "Ok", style: .default) { (action) in
                        self.navigationController?.popViewController(animated: true)
                    }
                    let alert = UIAlertController(title: "Success",
                                                  message: "Your current balance updated successfully",
                                                  preferredStyle: .alert)
                    alert.addAction(okButton)
                    
                    
                    debtToReturn = debt
                    
                    self.present(alert, animated: true, completion: nil)
                }
            } catch {
                let okButton = UIAlertAction(title: "Ok", style: .default) { (action) in
                    self.navigationController?.popViewController(animated: true)
                }
                let alert = UIAlertController(title: "Failure",
                                              message: "Your current amount failed to update",
                                              preferredStyle: .alert)
                alert.addAction(okButton)
                
                self.present(alert, animated: true, completion: nil)
            }
        }
        
        return debtToReturn
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
    
    // Hide Keyboard when user touches outside of keyboard
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    // Hide Keyboard when user presses return key
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
