// AllEnteredLocations.swift
// TravelBallRating
//
// Created by Brian Romero on 6/17/24.

import SwiftUI
import CoreData
import CoreLocation
import MapKit

struct AllEnteredLocations: View {
    @ObservedObject var viewModel: AllEnteredLocationsViewModel
    @State private var selectedDay: DayOfWeek? = .monday
    @State private var showModal = false
    @State private var selectedTeam: Team?
    @State private var selectedAppDayOfWeek: AppDayOfWeek?

    @StateObject private var enterZipCodeViewModel: EnterZipCodeViewModel
    @StateObject private var appDayOfWeekViewModel: AppDayOfWeekViewModel
    @StateObject private var userLocationVM = UserLocationMapViewModel.shared

    @Binding var navigationPath: NavigationPath

    init(navigationPath: Binding<NavigationPath>) {
        self._navigationPath = navigationPath

        let dataManager = TeamDataManager(viewContext: PersistenceController.shared.viewContext)
        let mainViewModel = AllEnteredLocationsViewModel(dataManager: dataManager)
        self._viewModel = ObservedObject(wrappedValue: mainViewModel)

        let sharedPersistenceController = PersistenceController.shared
        let appDayOfWeekRepository = AppDayOfWeekRepository(persistenceController: sharedPersistenceController)

        let zipCodeVM = EnterZipCodeViewModel(
            repository: appDayOfWeekRepository,
            persistenceController: sharedPersistenceController
        )
        _enterZipCodeViewModel = StateObject(wrappedValue: zipCodeVM)

        _appDayOfWeekViewModel = StateObject(wrappedValue: AppDayOfWeekViewModel(
            repository: appDayOfWeekRepository,
            enterZipCodeViewModel: zipCodeVM
        ))
    }

    var body: some View {
        VStack {
            if !viewModel.isDataLoaded {
                ProgressView("Loading Open Mats...").padding()
            } else if let error = viewModel.errorMessage {
                Text(error).foregroundColor(.red).padding()
            } else if viewModel.teamMarkers.isEmpty {
                Text("No Open Mats found.").padding()
            } else {
                Map(position: $viewModel.region, interactionModes: .all) {
                    ForEach(viewModel.teamMarkers) { marker in
                        if let team = marker.team {
                            Annotation(
                                "", // empty string, nothing will show
                                coordinate: CLLocationCoordinate2D(latitude: team.latitude, longitude: team.longitude),
                                anchor: .center
                            ) {
                                TeamAnnotationView(team: team) {
                                    handleTeamTap(team: team)
                                }
                            }

                        }
                    }
                    UserAnnotation()
                }
                .onAppear { viewModel.logTileInformation() }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("All teams")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
        }
        .onAppear {
            if !viewModel.isDataLoaded && viewModel.errorMessage == nil {
                viewModel.fetchTeams()
            }
            userLocationVM.startLocationServices()
        }

        .onReceive(userLocationVM.$userLocation) { location in
            guard let location = location else { return }
            viewModel.setRegionToUserLocation(location.coordinate)
        }
        .onReceive(NotificationCenter.default.publisher(for: .didSyncTeams)) { _ in
            viewModel.fetchTeams()
        }
        .floatingModal(isPresented: $showModal) {
            TeamModalContainer(
                selectedTeam: $selectedTeam,
                viewModel: appDayOfWeekViewModel,
                selectedDay: $selectedDay,
                showModal: $showModal,
                enterZipCodeViewModel: enterZipCodeViewModel,
                selectedAppDayOfWeek: $selectedAppDayOfWeek,
                navigationPath: $navigationPath
            )
        }
    }

    private func handleTeamTap(team: Team?) {
        guard let team = team else { return }
        selectedTeam = team
        showModal = true
    }
}
