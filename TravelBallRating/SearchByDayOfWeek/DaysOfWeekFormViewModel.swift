//
//  DaysOfWeekFormViewModel.swift
//  Mat_Finder
//
//  Created by Brian Romero on 7/14/25.
//

import Foundation
import SwiftUI
import CoreData
import os.log

class DaysOfWeekFormViewModel: ObservableObject {
    @Published var searchQuery: String = ""
    @Published var filteredTeams: [Team] = []
    @Published var showNoMatchAlert: Bool = false
    @Published var isLoading: Bool = false

    private var debounceTimer: Timer?

    init(initialIslands: [Team]) {
        self.filteredTeams = initialIslands
    }

    func updateFilteredTeams(with teams: FetchedResults<Team>) {
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.performFiltering(with: teams)
            }
        }
    }

    func forceUpdateFilteredTeams(with teams: FetchedResults<Team>) {
        debounceTimer?.invalidate()
        DispatchQueue.main.async {
            self.performFiltering(with: teams)
        }
    }

    private func performFiltering(with teams: FetchedResults<Team>) {
        os_log("DaysOfWeekFormViewModel: performFiltering called. Query: '%{public}s'", log: OSLog.default, type: .info, searchQuery)
        self.isLoading = true // Set isLoading true here, just before filtering starts
        let lowercasedQuery = self.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if lowercasedQuery.isEmpty {
            self.filteredTeams = Array(teams)
            self.showNoMatchAlert = false
            self.isLoading = false
            return
        }

        let filtered = teams.filter { team in
            // Now, we correctly include team.teamLocation to be searched for zip codes.
            let properties = [
                team.teamName,
                team.teamLocation, // This is where the zip code would be if it's part of the address string
                team.teamWebsite?.absoluteString,
                team.country // You also have 'country' now, which could be searched
            ]

            // Filter by any of the properties that contain the lowercased query
            return properties.compactMap { $0?.lowercased() }.contains { $0.contains(lowercasedQuery) }
        }

        self.filteredTeams = filtered
        self.showNoMatchAlert = !self.searchQuery.isEmpty && self.filteredTeams.isEmpty
        os_log("DaysOfWeekFormViewModel: Filtering complete. Result count: %d. Is Loading: %{public}@", log: OSLog.default, type: .info, filtered.count, isLoading.description)
        self.isLoading = false // Set isLoading false after filtering is done
    }
}
