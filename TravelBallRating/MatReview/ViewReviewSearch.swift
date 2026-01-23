//
//  ViewReviewSearch.swift
//  TravelBallRating
//
//  Created by Brian Romero on 9/20/24.
//

import SwiftUI
import CoreData
import os

struct ViewReviewSearch: View {
    @Binding var selectedTeam: Team?
    var titleString: String

    @EnvironmentObject var enterZipCodeViewModel: AllEnteredLocationsViewModel // Corrected type name
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // IMPORTANT: This navigationPath should be a BINDING
    // It must be the same `NavigationPath` instance as in AppRootView
    @Binding var navigationPath: NavigationPath // <--- Changed from @State to @Binding

    @StateObject private var viewModel = ViewReviewSearchViewModel()

    @FetchRequest(
        entity: Team.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Team.teamName, ascending: true)]
    ) private var teams: FetchedResults<Team>

    // Make sure the init also takes the navigationPath as a binding
    init(selectedTeam: Binding<Team?>, titleString: String, navigationPath: Binding<NavigationPath>) {
        _selectedTeam = selectedTeam
        self.titleString = titleString
        _navigationPath = navigationPath // Initialize the binding
    }

    private func teamRowContent(team: Team) -> some View {
        VStack(alignment: .leading) {
            Text(team.teamName ?? "Unknown team")
                .font(.headline)
            Text(team.teamLocation ?? "")
                .foregroundColor(.secondary)
        }
    }

    var body: some View {
        // REMOVED: NavigationStack { ... }
        VStack(alignment: .leading) {
            SearchHeader()
            SearchBar(text: $viewModel.searchQuery)
                .onChange(of: viewModel.searchQuery) { _, _ in
                    viewModel.updateFilteredTeams(with: teams)
                }

            List {
                // Ensure teams are Hashable (via objectID.uriRepresentation().absoluteString)
                // ForEach needs a stable ID. `\.self` might work for NSManagedObject if they are Hashable.
                // If not, use `\.objectID` or a wrapper that makes them Hashable.
                ForEach(viewModel.searchQuery.isEmpty ? Array(teams) : viewModel.filteredTeams, id: \.objectID) { team in // Use .objectID for stable identity
                    // Changed to NavigationLink(value: ...) to push onto the shared path
                    NavigationLink(value: AppScreen.viewAllReviews(team.objectID.uriRepresentation().absoluteString)) {
                        teamRowContent(team: team)
                    }
                }
            }
            .frame(minHeight: 400, maxHeight: .infinity)
            .listStyle(.plain)
        }
        .navigationTitle(titleString)
        .alert(isPresented: $viewModel.showNoMatchAlert) {
            Alert(
                title: Text("No Match Found"),
                message: Text("No teams match your search criteria."),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            os_log("ViewReviewSearch appeared (no nested NavigationStack)", log: OSLog.default, type: .info)
            viewModel.updateFilteredTeams(with: teams)
        }
        .onChange(of: selectedTeam) { _, newTeam in
            if let teamName = newTeam?.teamName {
                os_log("Selected Team (from binding in ViewReviewSearch): %@", log: OSLog.default, type: .info, teamName)
            } else {
                os_log("Selected Team (from binding in ViewReviewSearch): nil", log: OSLog.default, type: .info)
            }
        }
        // REMOVED: private func destinationView(for team: Team) -> some View
        // REMOVED: .navigationDestination here (it belongs in AppRootView)
    }
}



class ViewReviewSearchViewModel: ObservableObject {
    @Published var searchQuery: String = ""
    @Published var filteredTeams: [Team] = []
    @Published var showNoMatchAlert: Bool = false
    @Published var showReview: Bool = false
    @Published var isLoading: Bool = false
    
    // Declare debounceTimer
    private var debounceTimer: Timer?
    
    func updateFilteredTeams(with teams: FetchedResults<Team>) {
        if searchQuery.isEmpty {
            filteredTeams = Array(teams)
        } else {
            debounceTimer?.invalidate()
            debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in // Added [weak self]
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
