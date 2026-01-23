//
//  TeamMap.swift
//  TravelBallRating
//
//  Created by Brian Romero on 6/26/24.
//

import SwiftUI
import CoreData
import Combine
import CoreLocation
import Foundation
import MapKit


struct TeamMap: View {
    var teams: [CustomMapMarker]
    @Binding var region: MKCoordinateRegion

    init(teams: [CustomMapMarker], region: Binding<MKCoordinateRegion>) {
        self.teams = teams
        self._region = region
    }

    var body: some View {
        Map(position: .constant(.region(region))) {
            ForEach(teams) { marker in
                Annotation(marker.title ?? "team", coordinate: marker.coordinate) {
                    MapAnnotationContent()
                }
            }
        }
        .navigationTitle("team Map")
        .onAppear {
            print("team Map appeared with teams count: \(teams.count)")
            for marker in teams {
                print("team: \(marker.title ?? "Unknown team"), Latitude: \(marker.coordinate.latitude), Longitude: \(marker.coordinate.longitude)")
            }
        }
    }
}

struct MapAnnotationContent: View {
    var body: some View {
        Image(systemName: "mappin.circle.fill")
            .resizable()
            .frame(width: 30, height: 30)
            .foregroundColor(.red)
    }
}
