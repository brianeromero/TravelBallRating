//
//  TeamSection.swift
//  TravelBallRating
//
//  Created by Brian Romero on 9/22/24.
//

import Foundation
import SwiftUI
import CoreData

struct TeamSection: View {
    var teams: [Team]
    @Binding var selectedTeamID: UUID?
    @Binding var showReview: Bool

    var body: some View {
        Section(header: Text("Select A team")) {
            Picker("Select team", selection: $selectedTeamID) {
                Text("Select a team").tag(nil as UUID?)

                ForEach(teams, id: \.teamID) { team in
                    Text(team.teamName)
                        .tag(team.teamID)
                }
            }
            .onChange(of: selectedTeamID) { oldID, newID in
                print("Selected team changed from \(oldID?.uuidString ?? "none") to \(newID?.uuidString ?? "none")")
            }
        }
    }
}
