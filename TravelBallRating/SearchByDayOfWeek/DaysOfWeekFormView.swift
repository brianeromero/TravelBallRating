//
//  DaysOfWeekFormView.swift
//  Mat_Finder
//
//  Created by Brian Romero on 6/26/24.
//

import SwiftUI
import CoreData

extension Binding where Value == String? {
    func toNonOptional() -> Binding<String> {
        Binding<String>(
            get: { self.wrappedValue ?? "" },
            set: { self.wrappedValue = $0 }
        )
    }
}


// MARK: - DaysOfWeekFormView
struct DaysOfWeekFormView: View {
    @ObservedObject var appDayOfWeekViewModel: AppDayOfWeekViewModel // Keep this for its other functions if needed
    
    // ✅ StateObject for the new search ViewModel
    @StateObject private var viewModel: DaysOfWeekFormViewModel
    
    @Binding var selectedTeam: Team?
    @Binding var selectedMatTime: MatTime?
    @Binding var showReview: Bool // This might not be needed in this particular view, depends on your flow
    
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isSelected = false // Review if this is still needed
    @State private var navigationSelectedTeam: Team? // Review if this is still needed
    @State private var selectedDay: DayOfWeek? = nil // Review if this is still needed
    @State private var selectedMatTimes: [MatTime] = [] // Review if this is still needed
    
    // ✅ Correct placement for @FetchRequest
    @FetchRequest(
        entity: Team.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Team.teamName, ascending: true)]
    )
    private var teams: FetchedResults<Team> // Assign the FetchRequest to a property
    
    
    // Convenience property to observe changes to the fetched results' object IDs
    private var teamObjectIDs: [NSManagedObjectID] {
        teams.map { $0.objectID }
    }
    
    // Custom initializer to pass initial teams to the ViewModel
    init(appDayOfWeekViewModel: AppDayOfWeekViewModel, selectedTeam: Binding<Team?>, selectedMatTime: Binding<MatTime?>, showReview: Binding<Bool>) {
        self.appDayOfWeekViewModel = appDayOfWeekViewModel
        self._selectedTeam = selectedTeam
        self._selectedMatTime = selectedMatTime
        self._showReview = showReview
        
        // Initialize the StateObject viewModel with an empty array.
        // The actual data will be loaded and filtered in .onAppear once 'teams' is ready.
        _viewModel = StateObject(wrappedValue: DaysOfWeekFormViewModel(initialTeams: []))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: - Search Bar
            SearchBar(text: $viewModel.searchQuery)
                .padding(.horizontal, 16)
                .onChange(of: viewModel.searchQuery) {
                    viewModel.updateFilteredTeams(with: teams)
                }
            
            // MARK: - Content
            content
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text("team Schedules")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Select team to View/Add Schedule")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .onAppear {
            viewModel.forceUpdateFilteredTeams(with: teams)
        }
        .onChange(of: teams.count) {
            viewModel.updateFilteredTeams(with: teams)
        }
        .onChange(of: teamObjectIDs) {
            viewModel.updateFilteredTeams(with: teams)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name.NSManagedObjectContextDidSave)) { _ in
            viewModel.forceUpdateFilteredTeams(with: teams)
        }
    }
    
    // MARK: - Subviews
    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView("Searching...")
                .padding()
        } else if viewModel.filteredTeams.isEmpty && !viewModel.searchQuery.isEmpty {
            Spacer()
            Text("No teams match your search criteria.")
                .foregroundColor(.secondary)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .center)
            Spacer()
        } else {
            List(viewModel.filteredTeams, id: \.self) { team in
                teamRow(for: team)
            }
            .listStyle(PlainListStyle())
        }
    }
    
    @ViewBuilder
    private func teamRow(for team: Team) -> some View {
        NavigationLink(
            destination: ScheduleFormView(
                teams: Array(teams),
                initialSelectedTeam: team,   // ✅ REQUIRED
                matTimes: .constant([]),
                viewModel: appDayOfWeekViewModel
            )
        ) {
            VStack(alignment: .leading) {
                Text(team.teamName ?? "Unknown team")
                    .font(.headline)
                Text(team.teamLocation ?? "")
                    .foregroundColor(.secondary)
            }
        }
    }


}
