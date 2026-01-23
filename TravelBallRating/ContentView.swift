//
//  ContentView.swift
//  TravelBallRating
//
//  Created by Brian Romero on 6/24/24.
//

import SwiftUI
import CoreData


struct ContentView: View {
    @EnvironmentObject var persistenceController: PersistenceController
    @StateObject private var viewModel: TeamViewModel
    @StateObject private var profileViewModel = ProfileViewModel(
        viewContext: PersistenceController.shared.viewContext,
        authViewModel: AuthViewModel.shared
    )
    
    private let authViewModel = AuthViewModel.shared

    // MARK: - UI State
    @State private var showAddTeamForm = false
    @State private var sortByName = false   // ✅ New state for sorting

    // MARK: - team Fields
    @State private var teamName = ""
    @State private var createdByUserId = ""
    @State private var teamWebsite = ""
    @State private var teamWebsiteURL: URL?
    @State private var teamLocation = ""
    @State private var street = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zip = ""
    @State private var selectedCountry: Country?

    // MARK: - Fetched Results
    @FetchRequest(
        entity: Team.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Team.teamName, ascending: true)]
    ) private var teams: FetchedResults<Team>

    // MARK: - Init
    init(persistenceController: PersistenceController) {
        _viewModel = StateObject(wrappedValue: TeamViewModel(persistenceController: persistenceController))
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack {
                // ✅ Sort toggle
                Toggle("Sort by Name", isOn: $sortByName)
                    .padding(.horizontal)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))

                List {
                    ForEach(sortedTeams(), id: \.self) { team in
                        NavigationLink(
                            destination: TeamDetailView(
                                team: team,
                                selectedDestination: $viewModel.selectedDestination
                            )
                        ) {
                            teamRowView(team: team)
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
                .navigationTitle("teams")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showAddTeamForm.toggle()
                        } label: {
                            Label("Add team", systemImage: "plus")
                        }
                        .accessibilityLabel("Add team")
                    }
                }
                .sheet(isPresented: $showAddTeamForm) {
                    AddTeamFormView(
                        teamViewModel: viewModel,
                        profileViewModel: profileViewModel,
                        authViewModel: authViewModel,
                        teamDetails: teamDetails(
                            teamName: teamName,
                            street: street,
                            city: city,
                            state: state,
                            postalCode: zip,
                            selectedCountry: selectedCountry,
                            country: selectedCountry?.name.common ?? "US"
                        )
                    )
                    .environment(\.managedObjectContext, persistenceController.viewContext)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // iPhone-style on iPad
    }

    // MARK: - Helper for Sorting
    private func sortedTeams() -> [Team] {
        let teamArray = Array(teams)
        if sortByName {
            return teamArray.sorted { ($0.teamName) < ($1.teamName) }
        } else {
            return teamArray.sorted { ($0.createdTimestamp ?? Date()) < ($1.createdTimestamp ?? Date()) }
        }
    }

    // MARK: - Subviews
    private func teamRowView(team: Team) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(team.teamName ?? "Unknown team")
                .font(.headline)
            Text(team.teamLocation ?? "Unknown Location") // ✅ show location
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Added: \(team.formattedTimestamp)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Actions
    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let team = teams[index]
            Task {
                do {
                    try await viewModel.deleteTeam(team)
                    print("🗑️ Deleted team \(team.teamName) successfully")
                } catch {
                    print("❌ Error deleting team: \(error.localizedDescription)")
                }
            }
        }
    }
}
