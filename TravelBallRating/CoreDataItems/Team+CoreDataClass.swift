//
//  Team+CoreDataClass.swift
//  TravelBallRating
//
//  Created by Brian Romero on 6/24/24.
//
//


import Foundation
import CoreData

@objc(Team)
public class Team: NSManagedObject {

    override public func awakeFromInsert() {
        super.awakeFromInsert()

        // Assign primary ID
        if teamID == nil {
            teamID = UUID()
        }

        // Timestamps
        let now = Date()
        createdTimestamp = now
        lastModifiedTimestamp = now

        print("Team object created with ID: \(teamID?.uuidString ?? "unknown")")
    }
}

// MARK: - Equatable
extension Team {

    public static func == (lhs: Team, rhs: Team) -> Bool {
        lhs.teamID == rhs.teamID
    }
}
