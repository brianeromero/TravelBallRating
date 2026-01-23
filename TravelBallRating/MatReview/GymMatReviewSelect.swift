//
//  TeamPracticereReviewSelect.swift
//  TravelBallRating
//
//  Created by Brian Romero on 8/23/24.
//

import Foundation
import SwiftUI
import CoreData
import os.log // For logging, matching ViewReviewSearch

struct TeamPracticeReviewSelect: View {
    @Binding var selectedTeam: Team?

    @Environment(\.managedObjectContext) private var viewContext
    // Ensure this matches the type passed from AppRootView
    @EnvironmentObject var enterZipCodeViewModel: AllEnteredLocationsViewModel // Changed to AllEnteredLocationsViewModel
    @EnvironmentObject var authViewModel: AuthViewModel

    @Binding var navigationPath: NavigationPath

    @StateObject private var viewModel = TeamPracticeReviewSelectViewModel()

    @FetchRequest(
        entity: Team.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Team.teamName, ascending: true)]
    ) private var teams: FetchedResults<Team>

    init(
        selectedTeam: Binding<Team?>,
        navigationPath: Binding<NavigationPath>
    ) {
        _selectedTeam = selectedTeam
        _navigationPath = navigationPath
    }

    private var displayedTeams: [Team] {
        if viewModel.searchQuery.isEmpty {
            return Array(teams)
        } else {
            return viewModel.filteredTeams
        }
    }

    private func teamRowContent(team: Team) -> some View {
        VStack(alignment: .leading) {
            Text(team.teamName)
                .font(.headline)
            Text(team.teamLocation)
                .foregroundColor(.secondary)
        }
    }
 
    var body: some View {
        VStack(alignment: .leading) {
            Text("Search by: team name, Postal Code, or Address/Location")
                .font(.headline)
                .foregroundColor(.gray)
                .padding(.leading)
                .padding(.top, 8)

            SearchBar(text: $viewModel.searchQuery)
                .onChange(of: viewModel.searchQuery) { _, _ in
                    viewModel.updateFilteredTeams(with: teams)
                }

            List {
                ForEach(displayedTeams, id: \.objectID) { team in
                    // This NavigationLink is correct. It pushes an AppScreen value
                    // onto the navigationPath, which AppRootView's .navigationDestination
                    // will then handle by presenting AppRootDestinationView.
                    NavigationLink(value: AppScreen.review(team.objectID.uriRepresentation().absoluteString)) {
                        teamRowContent(team: team)
                            .onAppear {
                                print("🧭 NavigationLink triggered for team: \(team.teamName ?? "nil")")
                            }
                    }
                }
            }
            .frame(minHeight: 400, maxHeight: .infinity)
            .listStyle(.plain)

        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Select team to Review")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
        }
        .alert(isPresented: $viewModel.showNoMatchAlert) {
            Alert(
                title: Text("No Match Found"),
                message: Text("No teams match your search criteria."),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            print("🟢 TeamPracticeReviewSelect appeared")
            os_log("TeamPracticeReviewSelect appeared", log: OSLog.default, type: .info)
            viewModel.updateFilteredTeams(with: teams)
        }
        .onDisappear {
            print("🔴 TeamPracticeReviewSelect disappeared")
            os_log("TeamPracticereReviewSelect disappeared", log: OSLog.default, type: .info)
        }
        .onChange(of: selectedTeaam) { oldTeam, newTeam in
            print("SelectedTeam changed in TeamPracticeReviewSelect from \(oldTeam?.teamName ?? "nil") to \(newTeam?.teamName ?? "nil")")
            os_log("SelectedTeam changed in TeamPracticeReviewSelect from %{public}@ to %{public}@", log: OSLog.default, type: .info, oldTeam?.teamName ?? "nil", newTeam?.teamName ?? "nil")
        }
        // REMOVE THIS LINE: The navigationDestination modifier should NOT be here.
        // It belongs on the NavigationStack in AppRootView.
        // .navigationDestination(for: AppScreen.self) { screen in
        //     destinationView(for: screen)
        // }
    }
}

// MARK: - TeamPracticeReviewSelectViewModel (No changes needed here)

class TeamPracticeReviewSelectViewModel: ObservableObject {
    @Published var searchQuery: String = ""
    @Published var filteredTeams: [Team] = []
    @Published var showNoMatchAlert: Bool = false
    @Published var isLoading: Bool = false

    private var debounceTimer: Timer?

    func updateFilteredTeams(with teams: FetchedResults<Team>) {
        if searchQuery.isEmpty {
            filteredTeams = Array(teams)
            showNoMatchAlert = false
        } else {
            debounceTimer?.invalidate()
            debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                self?.performFiltering(with: teams)
            }
        }
    }

    private func performFiltering(with teams: FetchedResults<Team>) {
        isLoading = true

        DispatchQueue.global(qos: .userInitiated).async {
            let lowercasedQuery = self.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let filteredTeams = self.filterTeams(teams, query: lowercasedQuery)

            DispatchQueue.main.async {
                self.filteredTeams = filteredTeams
                self.showNoMatchAlert = !self.searchQuery.isEmpty && self.filteredTeams.isEmpty
                self.isLoading = false
            }
        }
    }

    private func filterTeams(_ teams: FetchedResults<Team>, query: String) -> [Team] {
        teams.compactMap { team -> Team? in
            guard let teamName = team.teamName?.lowercased(),
                  let teamLocation = team.teamLocation?.lowercased() else {
                return nil
            }

            let nameMatch = teamName.contains(query)
            let locationMatch = teamLocation.contains(query)

            return nameMatch || locationMatch ? team : nil
        }
    }
}
