// TeamMapView.swift
// Mat_Finder
// Created by Brian Romero on 6/26/24.

import SwiftUI
import CoreData
import Combine
import CoreLocation
import Foundation
import MapKit


// MARK: - TeamMapView (Modern Map API)
struct TeamMapView: View {
    @ObservedObject var viewModel: AppDayOfWeekViewModel
    @Binding var selectedTeam: Team?
    @Binding var showModal: Bool
    @Binding var selectedAppDayOfWeek: AppDayOfWeek?
    @Binding var selectedDay: DayOfWeek?
    @ObservedObject var allEnteredLocationsViewModel: AllEnteredLocationsViewModel
    @ObservedObject var enterZipCodeViewModel: EnterZipCodeViewModel

    // Modern MapKit API bindings
    @Binding var cameraPosition: MapCameraPosition
    @Binding var searchResults: [Team]

    var onMapRegionChange: (MKCoordinateRegion) -> Void

    @State private var navigationPath = NavigationPath()
    @State private var mapUpdateTask: Task<(), Never>? = nil

    var body: some View {
        Map(position: $cameraPosition) {
            ForEach(searchResults, id: \.teamID) { team in
                Annotation(
                    "", // empty string, nothing will show
                    coordinate: CLLocationCoordinate2D(latitude: team.latitude, longitude: team.longitude),
                    anchor: .center
                ) {
                    AnnotationMarkerView(team: team, handleTap: handleTap)
                }
            }
        }
        .frame(height: 400)
        .edgesIgnoringSafeArea(.all)
        .onMapCameraChange(frequency: .continuous) { context in
            let region = context.region
            mapUpdateTask?.cancel()
            mapUpdateTask = Task {
                try? await Task.sleep(nanoseconds: 400_000_000)
                if !Task.isCancelled {
                    await MainActor.run {
                        // Directly update markers for current center + span
                        enterZipCodeViewModel.updateMarkersForCenter(region.center, span: region.span)
                    }
                }
            }
        }

        .floatingModal(isPresented: $showModal) {
            IslandModalContainer(
                selectedTeam: $selectedTeam,
                viewModel: viewModel,
                selectedDay: $selectedDay,
                showModal: $showModal,
                enterZipCodeViewModel: enterZipCodeViewModel,
                selectedAppDayOfWeek: $selectedAppDayOfWeek,
                navigationPath: $navigationPath
            )
        }
    }

    private func handleTap(team: Team) {
        selectedTeam = team
        showModal = true
    }
}

// MARK: - AnnotationMarkerView (Custom Marker)
struct AnnotationMarkerView: View {
    let team: Team
    let handleTap: (Team) -> Void

    var body: some View {
        VStack {
            Text(team.teamName)
                .font(.caption)
                .padding(5)
                .background(Color(.systemBackground))
                .cornerRadius(5)
                .foregroundColor(.primary)
            CustomMarkerView()
        }
        .onTapGesture {
            handleTap(team)
        }
    }
}

// MARK: - TeamMapViewMap (For Single Team)
struct TeamMapViewMap: View {
    // ✅ Use the modern API as well for consistency
    @State private var cameraPosition: MapCameraPosition
    var coordinate: CLLocationCoordinate2D
    var teamName: String
    var teamLocation: String
    var onTap: (Team) -> Void
    var team: Team
    @State private var showConfirmationDialog = false

    init(
        coordinate: CLLocationCoordinate2D,
        teamName: String,
        teamLocation: String,
        onTap: @escaping (Team) -> Void,
        team: Team
    ) {
        self.coordinate = coordinate
        self.teamName = teamName
        self.teamLocation = teamLocation
        self.onTap = onTap
        self.team = team

        _cameraPosition = State(initialValue: .region(MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )))
    }

    var body: some View {
        Map(position: $cameraPosition) {
            Annotation(
                "", // empty string — satisfies compiler, nothing is shown by MapKit
                coordinate: coordinate,
                anchor: .center
            ) {
                VStack {
                    Text(teamName)
                        .font(.caption)
                        .padding(5)
                        .background(Color(.systemBackground))
                        .cornerRadius(5)
                        .foregroundColor(.primary)
                    CustomMarkerView()
                }
                .onTapGesture {
                    onTap(team)
                    showConfirmationDialog = true
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
        .alert(isPresented: $showConfirmationDialog) {
            Alert(
                title: Text("Open in Maps?"),
                message: Text("Do you want to open \(teamName) in Maps?"),
                primaryButton: .default(Text("Open")) {
                    ReviewUtils.openInMaps(
                        latitude: coordinate.latitude,
                        longitude: coordinate.longitude,
                        teamName: teamName,
                        teamLocation: teamLocation
                    )
                },
                secondaryButton: .cancel()
            )
        }
    }
}
