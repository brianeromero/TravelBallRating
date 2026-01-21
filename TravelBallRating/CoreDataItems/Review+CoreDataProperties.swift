//
//  Review+CoreDataProperties.swift
//  Mat_Finder
//
//  Created by Brian Romero on 8/23/24.
//
//



import Foundation
import CoreData
import os

extension Review: Identifiable {

    @nonobjc public class func fetchRequest(context: NSManagedObjectContext, selectedTeam: Team?) -> NSFetchRequest<Review> {
        let fetchRequest = NSFetchRequest<Review>(entityName: "Review")

        if let team = selectedTeam {
            fetchRequest.predicate = NSPredicate(format: "team == %@ OR team == nil", team)
        }

        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdTimestamp", ascending: false)]
        return fetchRequest
    }

    // MARK: - Attributes
    @NSManaged public var stars: Int16  // default 0
    @NSManaged public var review: String?  // now optional
    @NSManaged public var createdTimestamp: Date?  // now optional
    @NSManaged public var reviewID: UUID
    @NSManaged public var userName: String?

    // MARK: - Relationships
    @NSManaged public var team: Team?  // was 'team' before

    // Identifiable conformance
    public var id: NSManagedObjectID { self.objectID }
}
