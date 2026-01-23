// DayOfWeekSearchView.swift
// TravelBallRating
//
// Created by Brian Romero on 8/21/24.
//

import SwiftUI
import MapKit
import CoreLocation
import CoreData
import Combine


struct DayOfWeekSearchView: View {
    @State var selectedTeam: Team?
    @State var selectedAppDayOfWeek: AppDayOfWeek?
    
    @State private var equatableRegionWrapper = EquatableMKCoordinateRegion(
        region: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )
    
    @State private var navigationPath = NavigationPath()
    @ObservedObject private var userLocationMapViewModel = UserLocationMapViewModel.shared
    @EnvironmentObject var viewModel: AppDayOfWeekViewModel
    @EnvironmentObject var enterZipCodeViewModel: EnterZipCodeViewModel
    
    @State private var radius: Double = 10.0
    @State private var errorMessage: String?
    @State private var selectedDay: DayOfWeek? = .monday
    @State private var showModal: Bool = false

    var body: some View {
        NavigationView {
            VStack {
                // 🗓️ Day Picker
                DayPickerView(selectedDay: $selectedDay)
                    .onChange(of: selectedDay) { oldValue, newValue in
                        print("selectedDay changed from \(oldValue?.rawValue ?? "nil") to \(newValue?.rawValue ?? "nil")")
                        Task { await dayOfWeekChanged() }
                    }

                // ⚠️ Error View
                ErrorView(errorMessage: $errorMessage)

                // 🗺️ Map
                MapViewContainer(
                    region: $equatableRegionWrapper,
                    appDayOfWeekViewModel: viewModel
                ) { team in
                    handleTeamTap(team: team)
                }

                // 🎯 Radius Picker
                RadiusPicker(selectedRadius: $radius)
                    .onChange(of: radius) { oldValue, newValue in
                        print("RadiusPicker: radius changed from \(oldValue) to \(newValue)")
                        Task { await radiusChanged() }
                    }
            }
            .floatingModal(isPresented: $showModal) {
                TeamModalContainer(
                    selectedTeam: $selectedTeam,
                    viewModel: viewModel,
                    selectedDay: $selectedDay,
                    showModal: $showModal,
                    enterZipCodeViewModel: enterZipCodeViewModel,
                    selectedAppDayOfWeek: $selectedAppDayOfWeek,
                    navigationPath: $navigationPath
                )
            }

            .onAppear {
                print("DayOfWeekSearchView: onAppear triggered.")

                // ✅ Try to use existing user location first
                if let userLocation = userLocationMapViewModel.userLocation {
                    print("Using existing user location.")
                    updateRegion(center: userLocation.coordinate)
                    Task { await updateTeamsAndRegion() }
                } else {
                    print("No user location yet — requesting location.")
                    userLocationMapViewModel.requestLocation()
                }
            }
            .onChange(of: userLocationMapViewModel.userLocation) { oldValue, newValue in
                if let location = newValue {
                    print("User location updated to \(location.coordinate.latitude), \(location.coordinate.longitude)")
                    updateRegion(center: location.coordinate)
                    Task { await updateTeamsAndRegion() }
                } else {
                    print("User location is nil.")
                }
            }
            .onChange(of: selectedTeam) { oldValue, newValue in
                print("Selected team changed from \(oldValue?.teamName ?? "nil") to \(newValue?.teamName ?? "nil")")
                updateSelectedTeam(from: newValue)
            }
        }
    }

    
    // MARK: - Helper Methods
    
    private func requestUserLocation() {
        userLocationMapViewModel.requestLocation()
    }
    
    private func dayOfWeekChanged() async {
        await updateTeamsAndRegion()
    }
    
    private func radiusChanged() async {
        await updateTeamsAndRegion()
    }
    
    private func updateSelectedTeam(from newTeam: Team?) {
        guard let newTeam = newTeam else {
            print("updateSelectedTeam: newTeam is nil.")
            return
        }
        
        if let matchingTeam = viewModel.teamsWithMatTimes.map({ $0.0 }).first(where: { $0.teamID == newTeam.teamID }) {
            selectedTeam = matchingTeam
            print("updateSelectedTeam: Found matching team \(matchingTeam.teamName) in current selection.")
        } else {
            errorMessage = "Team not found in the current selection."
            print("updateSelectedTeam: Error - Team \(newTeam.teamName) not found in current selection.")
        }
    }
    
    private func handleTeamTap(team: Team) {
        selectedTeam = team
        showModal = true
        print("handleTeamTap: Tapped on team \(team.teamName). Showing modal.")
    }
    
    private func updateTeamsAndRegion() async {
        guard let selectedDay = selectedDay else {
            errorMessage = "Day of week is not selected."
            print("updateTeamsAndRegion: Error - Day of week is not selected.")
            return
        }
        
        print("updateTeamsAndRegion: Fetching teams for day: \(selectedDay)")
        await viewModel.fetchTeams(forDay: selectedDay)
        print("updateTeamsAndRegion: Finished fetching teams. ViewModel has \(viewModel.teamsWithMatTimes.count) teams.")
        
        if let location = userLocationMapViewModel.userLocation {
            updateRegion(center: location.coordinate)
        } else {
            print("updateTeamsAndRegion: User location not available for region update.")
        }
    }
    
    private func updateRegion(center: CLLocationCoordinate2D) {
        print("updateRegion: Updating region around \(center.latitude), \(center.longitude)")
        
        withAnimation {
            equatableRegionWrapper.region = MapUtils.updateRegion(
                markers: viewModel.teamsWithMatTimes.map {
                    CustomMapMarker(
                        id: $0.0.teamID ?? UUID(),
                        coordinate: CLLocationCoordinate2D(latitude: $0.0.latitude, longitude: $0.0.longitude),
                        title: $0.0.teamName,
                        team: $0.0
                    )
                },
                selectedRadius: radius,
                center: center
            )
        }
    }
}

// MARK: - Error View

struct ErrorView: View {
    @Binding var errorMessage: String?
    
    var body: some View {
        if let errorMessage = errorMessage {
            Text(errorMessage)
                .foregroundColor(.red)
        } else {
            EmptyView()
        }
    }
}



// MARK: - MapViewContainer
struct MapViewContainer: View {
    @Binding var region: EquatableMKCoordinateRegion
    @ObservedObject var appDayOfWeekViewModel: AppDayOfWeekViewModel
    let handleTeamTap: (Team) -> Void

    @State private var cameraPosition: MapCameraPosition

    init(
        region: Binding<EquatableMKCoordinateRegion>,
        appDayOfWeekViewModel: AppDayOfWeekViewModel,
        handleTeamTap: @escaping (Team) -> Void
    ) {
        _region = region
        self.appDayOfWeekViewModel = appDayOfWeekViewModel
        self.handleTeamTap = handleTeamTap
        _cameraPosition = State(initialValue: .region(region.wrappedValue.region))
    }

    var body: some View {
        let currentTeams = appDayOfWeekViewModel.teamsWithMatTimes.map { $0.0 }

        Map(position: $cameraPosition) {
            ForEach(currentTeams) { team in
                Annotation("", coordinate: CLLocationCoordinate2D(latitude: team.latitude, longitude: team.longitude), anchor: .center) {
                    TeamAnnotationView(team: team) {
                        handleTeamTap(team)
                    }
                }
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapPitchToggle()
        }
        .onChange(of: region) { oldValue, newValue in
            print("MapViewContainer: region changed.")
            cameraPosition = .region(newValue.region)
        }

        .onAppear {
            print("MapViewContainer.onAppear: Map container appeared.")
            print("  - \(currentTeams.count) teams loaded.")
        }
    }
}



// MARK: - TeamAnnotationView

struct TeamAnnotationView: View {
    let team: Team
    let handleTeamTap: () -> Void

    var body: some View {
        Button(action: handleTeamTap) {
            VStack(spacing: 4) {
                Text(team.teamName)
                    .font(.caption2)
                    .padding(4)
                    // --- KEY CHANGE HERE for background ---
                    .background(Color(.systemBackground).opacity(0.85)) // Use adaptive system background
                    .cornerRadius(4)
                    // --- KEY CHANGE HERE for foreground text color ---
                    .foregroundColor(.primary) // Use adaptive primary text color

                CustomMarkerView()
            }
            .shadow(radius: 3)
        }
    }
}

