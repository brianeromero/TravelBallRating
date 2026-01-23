//
//  teamScheduleView.swift
//  TravelBallRating
//
//  Created by Brian Romero on 7/12/24.
//

import SwiftUI

struct teamScheduleView: View {
    @ObservedObject var viewModel: AppDayOfWeekViewModel
    @State private var selectedTeam: Team?
    @State private var selectedDay: DayOfWeek?

    var body: some View {
        VStack {
            if let selectedTeam = selectedTeam {
                Text("Schedules for \(selectedTeam.teamName ?? "Unknown team")")
                    .font(.title)
                    .padding()

                // Display a list of days to choose from
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(DayOfWeek.allCases) { day in
                            Button(action: {
                                self.selectedDay = day // Update selectedDay
                                viewModel.fetchAppDayOfWeekAndUpdateList(for: selectedTeam, day: day, context: viewModel.viewContext)
                            }) {
                                Text(day.displayName)
                                    .font(.headline)
                                    .foregroundColor(selectedDay == day ? .blue : .black)
                                    .padding()
                            }
                        }
                    }
                }

                // Display schedules for the selected day
                if let day = selectedDay {
                    if let matTimes = viewModel.matTimesForDay[day], !matTimes.isEmpty {
                        List {
                            ForEach(matTimes.sorted { $0.time ?? "" < $1.time ?? "" }, id: \.self) { matTime in
                                VStack(alignment: .leading) {
                                    Text("Time: \(formatTime(matTime.time ?? "Unknown"))")
                                        .font(.headline)
                                    HStack {
                                        Label("Gi", systemImage: matTime.gi ? "checkmark.circle.fill" : "xmark.circle")
                                            .foregroundColor(matTime.gi ? .green : .red)
                                        Label("NoGi", systemImage: matTime.noGi ? "checkmark.circle.fill" : "xmark.circle")
                                            .foregroundColor(matTime.noGi ? .green : .red)
                                        Label("Open Mat", systemImage: matTime.openMat ? "checkmark.circle.fill" : "xmark.circle")
                                            .foregroundColor(matTime.openMat ? .green : .red)
                                    }
                                    if matTime.restrictions {
                                        Text("Restrictions: \(matTime.restrictionDescription ?? "Yes")")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                    if matTime.goodForBeginners {
                                        Text("Good for Beginners")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                    if matTime.kids {
                                        Text("Kids Class")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding()
                            }
                        }
                    } else {
                        Text("No mat times available for1 \(day.displayName)")
                            .foregroundColor(.gray)
                            .padding()
                    }
                }
            } else {
                Text("Select a team")
                    .font(.title)
                    .foregroundColor(.gray)
                    .padding()

                // Example list of teams to choose from
                List(viewModel.allTeams, id: \.self) { team in
                    Button(action: {
                        self.selectedTeam = team
                        Task {
                            await viewModel.loadSchedules(for: team)
                        }
                    }) {
                        Text(team.teamName)
                    }
                }
                .padding()
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchTeams()
            }
        }
    }

    // Function to format time
    func formatTime(_ time: String) -> String {
        if let date = AppDateFormatter.twelveHour.date(from: time) {
            return AppDateFormatter.twelveHour.string(from: date)
        } else {
            return time
        }
    }

}
