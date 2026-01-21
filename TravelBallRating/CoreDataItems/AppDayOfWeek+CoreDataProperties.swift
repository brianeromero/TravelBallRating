//
//  AppDayOfWeek+CoreDataProperties.swift
//  Mat_Finder
//
//  Created by Brian Romero on 6/24/24.
//
//


import Foundation
import CoreData

extension AppDayOfWeek {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AppDayOfWeek> {
        NSFetchRequest<AppDayOfWeek>(entityName: "AppDayOfWeek")
    }

    // MARK: - Attributes
    @NSManaged public var day: String
    @NSManaged public var name: String?
    @NSManaged public var appDayOfWeekID: String?
    @NSManaged public var createdTimestamp: Date?
    @NSManaged public var id: UUID?

    // MARK: - Relationships
    @NSManaged public var team: Team?
    @NSManaged public var matTimes: NSSet?
}

// MARK: - Generated Accessors for matTimes
extension AppDayOfWeek {

    @objc(addMatTimesObject:)
    @NSManaged public func addToMatTimes(_ value: MatTime)

    @objc(removeMatTimesObject:)
    @NSManaged public func removeFromMatTimes(_ value: MatTime)

    @objc(addMatTimes:)
    @NSManaged public func addToMatTimes(_ values: NSSet)

    @objc(removeMatTimes:)
    @NSManaged public func removeFromMatTimes(_ values: NSSet)
}

// MARK: - Identifiable
extension AppDayOfWeek: Identifiable {}
