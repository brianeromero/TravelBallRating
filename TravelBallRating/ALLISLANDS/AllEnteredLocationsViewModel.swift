//
//  AllEnteredLocationsViewModel.swift
//  Mat_Finder
//
//  Created by Brian Romero on 6/29/24.
//

import Foundation
import SwiftUI
import CoreData
import Combine
import CoreLocation
import MapKit

final class AllEnteredLocationsViewModel: NSObject, ObservableObject {
    @Published var allIslands: [Team] = []
    @Published var pirateMarkers: [CustomMapMarker] = []
    @Published var errorMessage: String?
    @Published var isDataLoaded = false
    @Published var region: MapCameraPosition = .automatic

    private let dataManager: TeamDataManager
    private var hasSetInitialRegion = false

    init(dataManager: TeamDataManager) {
        self.dataManager = dataManager
        super.init()
        fetchTeams()
    }

    func fetchTeams() {
        isDataLoaded = false
        errorMessage = nil

        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.dataManager.fetchTeams()
            DispatchQueue.main.async {
                switch result {
                case .success(let islands):
                    self.allTeams = teams
                    self.pirateMarkers = teams.map { team in
                        CustomMapMarker(
                            id: team.teamID ?? UUID(),
                            coordinate: CLLocationCoordinate2D(latitude: team.latitude, longitude: team.longitude),
                            title: team.teamName ?? "Unknown Team",
                            team: team
                        )
                    }
                    self.isDataLoaded = true
                    self.setRegionToFitMarkersOrDefault()
                case .failure(let error):
                    self.errorMessage = "Failed to load pirate islands: \(error.localizedDescription)"
                    self.pirateMarkers = []
                    self.region = .automatic
                    self.isDataLoaded = true
                }
            }
        }
    }

    /// Sets the map region to fit all markers if available, otherwise uses a default zoomed-out span
    func setRegionToFitMarkersOrDefault() {
        guard !hasSetInitialRegion else { return }

        if !pirateMarkers.isEmpty {
            let coordinates = pirateMarkers.map { $0.coordinate }
            let mkRegion = MapUtils.calculateRegionToFit(coordinates: coordinates)
            region = .region(mkRegion)
        } else {
            // Default global zoom (~1000 miles)
            let zoomedOutSpan = MKCoordinateSpan(latitudeDelta: 15.0, longitudeDelta: 15.0)
            region = .region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -95.0), span: zoomedOutSpan))
        }

        hasSetInitialRegion = true
    }

    /// Updates the map region based on user location (if we haven’t set it already)
    func setRegionToUserLocation(_ location: CLLocationCoordinate2D) {
        guard !hasSetInitialRegion else { return }

        let zoomedOutSpan = MKCoordinateSpan(latitudeDelta: 15.0, longitudeDelta: 15.0)
        region = .region(MKCoordinateRegion(center: location, span: zoomedOutSpan))
        hasSetInitialRegion = true
    }

    func logTileInformation() {
        for marker in pirateMarkers {
            print("Marker ID: \(marker.id), Coordinate: \(marker.coordinate), Title: \(marker.title ?? "Unknown")")
        }
    }

    func getTeam(from marker: CustomMapMarker) -> Team? {
        marker.team
    }
}
