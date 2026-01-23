//
//  AllMapView.swift
//  TravelBallRating
//
//  Created by Brian Romero on 6/26/24.
//

import Foundation
import SwiftUI
import MapKit
import CoreLocation

struct CoordinateWrapper: Equatable {
    let coordinate: CLLocationCoordinate2D
    
    static func == (lhs: CoordinateWrapper, rhs: CoordinateWrapper) -> Bool {
        return lhs.coordinate.latitude == rhs.coordinate.latitude &&
               lhs.coordinate.longitude == rhs.coordinate.longitude
    }
}

struct AllMapView: View {
    @State private var region: MKCoordinateRegion
    let teams: [Team]
    let userLocation: CoordinateWrapper

    init(teams: [Team], userLocation: CLLocationCoordinate2D) {
        self.teams = teams
        self.userLocation = CoordinateWrapper(coordinate: userLocation)
        
        let initialRegion = MKCoordinateRegion(
            center: userLocation,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        self._region = State(initialValue: initialRegion)
    }

    var body: some View {
        Map(coordinateRegion: $region, annotationItems: teams.compactMap { team -> CustomMapMarker? in
            // Use optional coalescing to provide default values for optional properties
            let title = team.teamName
            let latitude = team.latitude
            let longitude = team.longitude
            
            // Use ReviewUtils to get the reviews for the team, with added caller function logging
            let reviews = ReviewUtils.getReviews(from: team.reviews, callerFunction: #function)
            
            // Example: Printing reviews for debugging
            print("Reviews for \(title): \(reviews)")

            // Create a CustomMapMarker for each team
            return CustomMapMarker(
                id: team.teamID ?? UUID(), // Use default UUID if teamID is nil
                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                title: title,
                team: team
            )
        }) { marker in
            MapAnnotation(coordinate: marker.coordinate) {
                VStack {
                    Text(marker.title ?? "Unnamed team")
                        .font(.caption)
                        .padding(5)
                        .background(Color.white)
                        .cornerRadius(5)
                    CustomMarkerView() // Use your custom marker view here
                }
            }
        }
        .frame(height: 300) // Adjust as needed
        .padding()
        .onAppear {
            updateRegion()
            print("Map appeared with region: \(region)")
        }
        .onChange(of: CoordinateWrapper(coordinate: region.center)) { oldValue, newValue in
            print("Region center changed from \(oldValue.coordinate.latitude), \(oldValue.coordinate.longitude) to \(newValue.coordinate.latitude), \(newValue.coordinate.longitude)")
            
        }
    }

    private func updateRegion() {
        let radius: Double = 5.0 // Replace with your desired radius
        region = MapUtils.updateRegion(markers: [CustomMapMarker(id: UUID(), coordinate: userLocation.coordinate, title: "", team: nil)], selectedRadius: radius, center: userLocation.coordinate)
        print("Updated region to: \(region.center.latitude), \(region.center.longitude)")
    }
}
