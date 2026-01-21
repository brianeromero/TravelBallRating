//
//  MatTime+CoreDataClass.swift
//  TravelBallRating
//
//  Created by Brian Romero on 7/15/24.
//

import Foundation
import CoreData

@objc(MatTime)
public class MatTime: NSManagedObject {

    // Automatically set ID when a new object is inserted
    override public func awakeFromInsert() {
        super.awakeFromInsert()
        
        if self.id == nil {
            self.id = UUID()
        }
        print("MatTime object created with ID: \(self.id?.uuidString ?? "unknown")")
    }

    // Equality using UUID if available, fallback to time/type
    public static func == (lhs: MatTime, rhs: MatTime) -> Bool {
        if let lhsID = lhs.id, let rhsID = rhs.id {
            return lhsID == rhsID
        }
        return lhs.time == rhs.time && lhs.type == rhs.type
    }
}
