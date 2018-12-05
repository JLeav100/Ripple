//
//  TableViewController.swift
//  Ripple
//
//  Created by Jordan Leavitt on 4/5/18.
//  Copyright © 2018 Jordan Leavitt. All rights reserved.
//

import UIKit
import CoreData
import CloudKit
import Flurry_iOS_SDK
import GoogleMobileAds
import CloudKit
import Seam3

var items = [Debt]()

class TableViewController: UIViewController, UITableViewDelegate {
    
    var smStore: SMStore?
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var totalsView: UIView!
    @IBOutlet weak var TRBLabel: UILabel!
    @IBOutlet weak var TMPLabel: UILabel!
    @IBOutlet weak var debtFinishDate: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var bannerView: GADBannerView!
    
    @IBAction func unwindToTableViewController(segue:UIStoryboardSegue) { }
    
    // Test
    //iCloud Database
    let database = CKContainer.default().privateCloudDatabase
    
    //Alex
    private func updateTotalProgressBar() {
        let totalCurrentDebt = self.calculateTotalDebtAmount()
        let totalOriginalDebt = self.calculateTotalOriginalDebtAmount()
        
        let totalProgress = (totalOriginalDebt - totalCurrentDebt) / totalOriginalDebt
        
        self.progressBar.setProgress(Float(totalProgress), animated: true)
    }
    
    func testDataBase() {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        smStore = appDelegate.persistentContainer.persistentStoreCoordinator.persistentStores.first as? SMStore
        
        self.smStore?.verifyCloudKitConnectionAndUser() { (status, user, error) in
            guard status == .available, error == nil else {
                NSLog("Unable to verify CloudKit Connection \(error)")
                return
            }
            
            guard let currentUser = user else {
                NSLog("No current CloudKit user")
                return
            }
            
            var completeSync = false
            
            let previousUser = UserDefaults.standard.string(forKey: "CloudKitUser")
            if  previousUser != currentUser {
                do {
                    print("New user")
                    try self.smStore?.resetBackingStore()
                    completeSync = true
                } catch {
                    NSLog("Error resetting backing store - \(error.localizedDescription)")
                    return
                }
            }
            
            UserDefaults.standard.set(currentUser, forKey:"CloudKitUser")
            
            self.smStore?.triggerSync(complete: completeSync)
        }
    }
    
    //Alex
    private func calculateFinishDate() {
        let remainingDebt = self.calculateTotalDebtAmount()
        let monthlyPayments = self.calculateTotalPayment()
        let interestTotal = self.calculateInterestAmount()
        
        if (monthlyPayments > 0) {
            let numberMonthsRemaining: Int = Int(ceil(remainingDebt / (monthlyPayments - interestTotal)))
            
            if let futureFinishDate = Calendar.current.date(byAdding: .month, value: numberMonthsRemaining, to: Date()) {
                let dateFormatter = DateFormatter()
                dateFormatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
                
                self.debtFinishDate.text = "\(dateFormatter.string(from: futureFinishDate))"
            }
        } else {
            self.debtFinishDate.text = "You're Debt Free!"
        }
    }
    
    private func calculateTotalOriginalDebtAmount() -> Double {
        var total = 0.0
        
        for debt in items {
            total = total + debt.originalAmount
        }
        
        return total
    }
    
    // Swipe To Delete
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                let context = appDelegate.persistentContainer.viewContext
                context.delete(items[indexPath.row])
                
                //Send Analytics
                Flurry.logEvent("Debt Cell Deleted")
                
                do {
                    try context.save()
                } catch {
                    
                }
                
                items.remove(at: indexPath.row)
            }
            
            // Refresh tableview when cell is deleted
            self.updateEverything()
        }
    }
    
    private func updateEverything() {
        tableView.reloadData()
        self.updateTotalProgressBar()
        self.calculateFinishDate()
        
        
        // Refresh totalsView when cell is deleted
        TRBLabel.text = CurrencyFormatter.format(amount: calculateTotalDebtAmount())
        TMPLabel.text = CurrencyFormatter.format(amount: calculateTotalPayment())
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Clears Empty Cells
        tableView.tableFooterView = UIView()
        
        //AdMob Ad Placement
        bannerView.adUnitID = "ca-app-pub-5887632756905876/4920354346"
        bannerView.rootViewController = self
        let request = GADRequest()
        request.testDevices = [kGADSimulatorID]
        bannerView.load(request)
        
        //Test to see if syncing with iCloud
        testDataBase()

        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.loadDebtFromCoreData()
        
        // Totals Labels
        TRBLabel.text = "\(CurrencyFormatter.format(amount:calculateTotalDebtAmount()))"
        TMPLabel.text = "\(CurrencyFormatter.format(amount:calculateTotalPayment()))"
        
        //Total Progress Bar Update and Finish Date
        self.updateTotalProgressBar()
        self.calculateFinishDate()
        
        // Cell Animation
        animateTable()
        //self.updateEverything()
    }
    
    func loadDebtFromCoreData() {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            let managedContext = appDelegate.persistentContainer.viewContext
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Debt")
            
            
            do {
                request.sortDescriptors = [NSSortDescriptor(key: "currentAmount", ascending: true)]
                let result = try managedContext.fetch(request)
                items = result as! [Debt]
                
                let total = calculateTotalDebtAmount()
                print("total \(total)")
                
            } catch {}
        }
    }
    
    func calculateTotalDebtAmount() -> Double {
        var total = 0.0
        
        for debt in items {
            total = total + debt.currentAmount
        }
        
        return total
    }
    
    func calculateTotalPayment() -> Double {
        var totalPayment = 0.0
        
        for debt in items {
            totalPayment = totalPayment + debt.minimumPayment + debt.extraPayment
        }
        
        return totalPayment
    }
    
    func calculateInterestAmount() -> Double {
        var interestAmount = 0.0
        
        for debt in items {
            interestAmount = (debt.interest / 12) * debt.originalAmount
        }
        
        return interestAmount
    }
    
    func calculateTotalInterest() -> Double {
        var totalInterest = 0.0
        
        for debt in items {
            totalInterest = totalInterest + debt.interest
        }
        
        return totalInterest
    
    }
    
    
    func delete(object: DataItem) -> Void {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            let managedContext = appDelegate.persistentContainer.viewContext
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Debt")
            // request.sortDescriptors = [NSSortDescriptor(key: "currentAmount", ascending: true)]
            
            do {
                let result = try managedContext.fetch(request)
                for data in result as! [NSManagedObject] {
                    if let name = data.value(forKey: "name") as? String,
                        let amount = data.value(forKey: "amount") as? Double,
                        //let minPayment = data.value(forKey: "minimumPayment") as? Double,
                        let type = data.value(forKey: "type") as? Double {
                        // Check if this is the object we're looking for by seeing if all its properties match.
                        if name == object.name && amount == object.amount && type == object.amount {
                            managedContext.delete(data)
                            try managedContext.save()
                        }
                    }
                }
            } catch {}
        }
    }
    
    // Table View Animation
    
    func animateTable() {
        tableView.reloadData()
        let cells = tableView.visibleCells
        
        let tableViewHeight = tableView.bounds.size.height
        
        for cell in cells {
            cell.transform = CGAffineTransform(translationX: 0, y: tableViewHeight)
        }
        
        var delayCounter = 0
        for cell in cells {
            UIView.animate(withDuration: 1.5, delay: Double(delayCounter) * 0.05, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
                cell.transform = CGAffineTransform.identity
            }, completion: nil)
            delayCounter += 1
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let index = tableView.indexPathForSelectedRow {
            print(index.row)
        }
        
        if let detailVC = segue.destination.children.first as? NewDebtTableViewController {
            detailVC.delegate = self
        }
        
        
    }
    
    // TableView Rows and Sections
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
}

extension TableViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "debtCell", for: indexPath) as! DebtTableViewCell
        let item = items[indexPath.row]
        
        cell.contentView.isUserInteractionEnabled = true
        cell.debt = item
        cell.debtTypeLabel.text = item.type
        cell.nameLabel.text = item.name
        cell.amountLabel.text = CurrencyFormatter.format(amount: item.currentAmount)
        cell.minimumPaymentLabel.text = CurrencyFormatter.format(amount: item.minimumPayment + item.extraPayment)
        
        let progress = (item.originalAmount - item.currentAmount)/item.originalAmount
        cell.progressBar.setProgress(Float(progress), animated: true)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        let viewController = self.navigationController?.storyboard?.instantiateViewController(withIdentifier: "CellDetailsViewController") as! CellDetailViewController
        viewController.debt = item
        viewController.indexPath = indexPath
        self.navigationController?.pushViewController(viewController, animated: true)
    }
}

extension TableViewController: NewDebtViewControllerDelegate {
    
    func didFinishAdding(debt: Debt) {
        items.append(debt)
        tableView.reloadData()
    }
    
}

extension TableViewController: CellDetailVewControllerDelegate {
    func updatedDebt(_ debt: Debt, for indexPath: IndexPath) {
        guard indexPath.row < items.count else {
            return
        }
        self.tableView.reloadData()
    }
    
}










