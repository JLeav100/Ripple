//
//  Debt+CoreDataProperties.swift
//  
//
//  Created by Jordan Leavitt on 11/5/18.
//
//

import Foundation
import CoreData


extension Debt {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Debt> {
        return NSFetchRequest<Debt>(entityName: "Debt")
    }

    @NSManaged public var currentAmount: Double
    @NSManaged public var extraPayment: Double
    @NSManaged public var id: UUID?
    @NSManaged public var minimumPayment: Double
    @NSManaged public var name: String?
    @NSManaged public var originalAmount: Double
    @NSManaged public var type: String?
    @NSManaged public var interest: Double

}
