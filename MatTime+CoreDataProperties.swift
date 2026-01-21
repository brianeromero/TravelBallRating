//
//  MatTime+CoreDataProperties.swift
//  TravelBallRating
//
//  Created by Brian Romero on 7/15/24.
//

import Foundation
import CoreData

extension MatTime {

    // MARK: - Fetch Request
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MatTime> {
        return NSFetchRequest<MatTime>(entityName: "MatTime")
    }

    // MARK: - Attributes
    @NSManaged public var id: UUID?
    @NSManaged public var type: String?
    @NSManaged public var time: String?
    @NSManaged public var gi: Bool
    @NSManaged public var noGi: Bool
    @NSManaged public var openMat: Bool
    @NSManaged public var restrictions: Bool
    @NSManaged public var restrictionDescription: String?
    @NSManaged public var goodForBeginners: Bool
    @NSManaged public var kids: Bool
    @NSManaged public var createdTimestamp: Date?

    // MARK: - Relationships
    @NSManaged public var appDayOfWeek: AppDayOfWeek?
}

// MARK: - Identifiable
extension MatTime: Identifiable {}

// MARK: - Firestore Conversion
extension MatTime {
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "time": self.time ?? "",
            "type": self.type ?? "",
            "gi": self.gi,
            "noGi": self.noGi,
            "openMat": self.openMat,
            "restrictions": self.restrictions,
            "restrictionDescription": self.restrictionDescription ?? "",
            "goodForBeginners": self.goodForBeginners,
            "kids": self.kids,
            "createdTimestamp": self.createdTimestamp ?? Date()
        ]
        if let id = self.id {
            data["id"] = id.uuidString
        }
        return data
    }
}
