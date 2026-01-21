//
//  CustomMapMarker.swift
//  Mat_Finder
//
//  Created by Brian Romero on 6/26/24.
//

import Foundation
import CoreLocation
import MapKit


struct CustomMapMarker: Identifiable {
    let id: UUID
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var team: Team?
    
    // Manual Equatable conformance
    static func == (lhs: CustomMapMarker, rhs: CustomMapMarker) -> Bool {
        lhs.id == rhs.id &&
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude &&
        lhs.title == rhs.title &&
        lhs.team == rhs.team
    }

    static func forTeam(_ team: Team) -> CustomMapMarker {
        CustomMapMarker(
            id: team.teamID ?? UUID(),
            coordinate: CLLocationCoordinate2D(latitude: team.latitude, longitude: team.longitude),
            title: team.teamName,
            team: team
        )
    }

    func distance(from location: CLLocation) -> CLLocationDistance {
        let teamLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return teamLocation.distance(from: location)
    }
}
