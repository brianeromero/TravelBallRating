//
//  SearchComponents.swift
//  TravelBallRating
//
//  Created by Brian Romero on 9/28/24.
//

import Foundation
import SwiftUI
import os.log


// Create a logger
let logger = OSLog(subsystem: "MF-inder.Seas-3", category: "SearchComponents")


enum NavigationDestination {
    case review
    case editExistingTeam
    case viewReviewForTeam
}

struct SearchHeader: View {
    var body: some View {
        Text("Search by: team name, Postal Code, or Address/Location")
            .font(.headline)
            .padding(.bottom, 4)
            .foregroundColor(.gray)
            .padding(.horizontal, 8)
    }
}


struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            GrayPlaceholderTextField("Search...", text: $text)
            if !text.isEmpty {
                Button(action: {
                    os_log("Clear button tapped", log: logger)
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .onAppear {
            os_log("SearchBar appeared", log: logger)
        }
    }
}

struct GrayPlaceholderTextField: View {
    private let placeholder: String
    @Binding private var text: String

    init(_ placeholder: String, text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.gray)
            }
            TextField("", text: $text)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(.systemGray6))
                .cornerRadius(8.0)
                .textFieldStyle(PlainTextFieldStyle())
                .onChange(of: text) { newText, _ in
                    os_log("Text changed: %@", log: logger, newText)
                }
        }
        .onAppear {
            os_log("GrayPlaceholderTextField appeared", log: logger)
        }
    }
}

@MainActor
class TeamListViewModel: ObservableObject {
    static let shared = TeamListViewModel(persistenceController: PersistenceController.shared)
    
    let repository: AppDayOfWeekRepository
    let enterZipCodeViewModel: EnterZipCodeViewModel
    private let persistenceController: PersistenceController
    
    init(persistenceController: PersistenceController) {
        os_log("Initializing TeamListViewModel", log: logger)
        self.persistenceController = persistenceController
        self.repository = AppDayOfWeekRepository(persistenceController: persistenceController)
        self.enterZipCodeViewModel = EnterZipCodeViewModel(
            repository: repository,
            persistenceController: persistenceController
        )
        os_log("Initialized TeamListViewModel", log: logger)
    }
}


struct TeamListItem: View {
    @ObservedObject var team: Team // <-- CHANGE THIS!
    @Binding var selectedTeam: Team?

    var body: some View {
        os_log("Rendering TeamListItem for %@", log: logger, team.teamName)
        return VStack(alignment: .leading) {
            Text(team.teamName) // Now this Text view will re-render
                .font(.headline)
            Text(team.teamLocation)       // when team.teamLocation changes
                .font(.subheadline)
                .lineLimit(nil)
        }
    }
}



struct TeamList: View {
    let teams: [Team]
    @Binding var selectedTeam: Team?
    @Binding var searchText: String
    let navigationDestination: NavigationDestination
    let title: String
    
    // ✅ Change these to @EnvironmentObject as they are shared app-wide
    @EnvironmentObject var enterZipCodeViewModel: EnterZipCodeViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var teamViewModel: TeamViewModel // Needed for EditExistingTeam
    @EnvironmentObject var profileViewModel: ProfileViewModel // Needed for EditExistingTeam

    let onTeamChange: (Team?) -> Void
    
    // ✅ NEW: Receive navigationPath as a Binding from the parent view
    @Binding var navigationPath: NavigationPath // <--- CRUCIAL CHANGE!

    // !!! NEW: Bindings to control the toast from the parent view (EditExistingTeamListContent) !!!
    @Binding var showSuccessToast: Bool
    @Binding var successToastMessage: String
    @Binding var successToastType: ToastView.ToastType // <<< NEW: Add this binding

    init(
        teams: [Team],
        selectedTeam: Binding<Team?>,
        searchText: Binding<String>,
        navigationDestination: NavigationDestination,
        title: String,
        onTeamChange: @escaping (Team?) -> Void,
        navigationPath: Binding<NavigationPath>, // Receive navigationPath here
        // !!! NEW: Add the new toast bindings to the initializer !!!
        showSuccessToast: Binding<Bool>,
        successToastMessage: Binding<String>,
        successToastType: Binding<ToastView.ToastType> // <<< NEW: Add the new toast binding
    ) {
        self.teams = teams
        self._selectedTeam = selectedTeam
        self._searchText = searchText
        self.navigationDestination = navigationDestination
        self.title = title
        self.onTeamChange = onTeamChange
        self._navigationPath = navigationPath // Initialize the binding
        self._showSuccessToast = showSuccessToast // Initialize the new toast binding
        self._successToastMessage = successToastMessage // Initialize the new toast binding
        self._successToastType = successToastType // <<< NEW: Initialize the new toast binding
    }

    var filteredTeams: [Team] {
        if searchText.isEmpty {
            return team
        } else {
            return teams.filter { team in
                team.teamName?.lowercased().contains(searchText.lowercased()) ?? false ||
                team.teamLocation?.lowercased().contains(searchText.lowercased()) ?? false
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) { // ✅ spacing: 0 for no space between elements
            // The title is now part of this view's layout, not the parent's navigationTitle.
            Text(title)
                .font(.title2)
                .bold()
                .padding(.horizontal, 16) // Padding for title
                .padding(.bottom, 8) // Spacing below title

            List {
                ForEach(filteredTeams, id: \.objectID) { team in // ✅ Use .objectID for stable identity
                    // ✅ Replaced Button with NavigationLink(value: ...)
                    NavigationLink(value: AppScreen.editExistingTeam(team.objectID.uriRepresentation().absoluteString)) {
                        TeamListItem(team: team, selectedTeam: $selectedTeam)
                            // Apply styling to the row content itself
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)) // ✅ CRITICAL: Removes row padding
                            .listRowBackground(Color(.systemBackground)) // ✅ CRITICAL: Dynamic background for row
                    }
                    .buttonStyle(PlainButtonStyle()) // Ensures the whole row is tappable and removes default blue tint
                }
            }

            .listStyle(.plain) // ✅ CRITICAL: Flat list style
            .background(Color(.systemBackground)) // ✅ CRITICAL: List background matches system theme
            .padding(.horizontal, 0) // ✅ CRITICAL: No horizontal padding on the List itself
            .ignoresSafeArea(.all, edges: .horizontal) // ✅ CRITICAL: Extends list content to screen edges
        }
        // ✅ REMOVED: .navigationTitle(title) // This should be on the parent view that contains this list (e.g., EditExistingTeamListContent)
        // ✅ REMOVED: .navigationDestination(isPresented: ...) // This is now handled by AppRootView's .navigationDestination(for:)
    }
}

struct ReviewDestinationView: View {
    @ObservedObject var viewModel: TeamListViewModel
    let selectedTeam: Team?
    @State private var showReview: Bool = false
    
    // Add NavigationPath here
    @State private var navigationPath = NavigationPath()
    
    init(viewModel: TeamListViewModel, selectedTeam: Team?) {
        os_log("ReviewDestinationView initialized with team: %@", log: logger, selectedTeam?.teamName ?? "Unknown")
        self.viewModel = viewModel
        self.selectedTeam = selectedTeam
    }

    var body: some View {
        os_log("Rendering ReviewDestinationView", log: logger)
        return VStack {
            if let selectedTeam = selectedTeam {
                ViewReviewforTeam(
                    showReview: $showReview,
                    selectedTeam: selectedTeam,
                    navigationPath: $navigationPath
                )
            } else {
                EmptyView()
            }
        }
    }
}


// New View for Selected Team
enum DestinationView {
    case teamPracticereReview
    case viewReviewForTeam
}


struct SelectedTeamView: View {
    let team: Team

    @Binding var selectedTeamID: UUID?

    var enterZipCodeViewModel: EnterZipCodeViewModel
    var onTeamChange: (Team?) -> Void
    var authViewModel: AuthViewModel
    var destinationView: DestinationView

    @State private var navigationPath = NavigationPath()

    var body: some View {
        switch destinationView {

        case .teamPracticeReview:
            TeamPracticeReviewView(
                selectedTeamID: selectedTeamID
            )

        case .viewReviewForTeam:
            ViewReviewforTeam(
                showReview: .constant(false),
                selectedTeam: team,
                navigationPath: $navigationPath
            )
        }
    }
}

