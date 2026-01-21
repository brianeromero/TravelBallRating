//
//  FirestoreTeamData.swift
//  Mat_Finder
//
//  Created by Brian Romero on 10/30/25.
//

import Foundation

struct FirestoreTeamData {
    let id: String
    let name: String
    let location: String
    let country: String
    let createdByUserId: String
    let createdTimestamp: Date
    let lastModifiedByUserId: String
    let lastModifiedTimestamp: Date
    let latitude: Double
    let longitude: Double
    let teamWebsite: String

    init(from team: Team) {
        self.id = team.teamID?.uuidString ?? UUID().uuidString
        self.name = team.teamName
        self.location = team.teamLocation
        self.country = team.country ?? "Unknown Country"
        self.createdByUserId = team.createdByUserId ?? "Unknown"
        self.createdTimestamp = team.createdTimestamp ?? Date()
        self.lastModifiedByUserId = team.lastModifiedByUserId ?? ""
        self.lastModifiedTimestamp = team.lastModifiedTimestamp ?? Date()
        self.latitude = team.latitude
        self.longitude = team.longitude
        self.teamWebsite = team.teamWebsite?.absoluteString ?? ""
    }
}
