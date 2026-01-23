//
//  AppDayOfWeek+CoreDataClass.swift
//  TravelBallRating
//
//  Created by Brian Romero on 6/24/24.
//
//

import Foundation
import CoreData

@objc(AppDayOfWeek)
public class AppDayOfWeek: NSManagedObject {

    // Automatically assign UUID when inserting
    override public func awakeFromInsert() {
        super.awakeFromInsert()
        if self.id == nil {
            self.id = UUID()
        }
    }

    // Equality using UUID if available, fallback to objectID
    public static func == (lhs: AppDayOfWeek, rhs: AppDayOfWeek) -> Bool {
        if let lhsID = lhs.id, let rhsID = rhs.id {
            return lhsID == rhsID
        }
        return lhs.objectID == rhs.objectID
    }
}
