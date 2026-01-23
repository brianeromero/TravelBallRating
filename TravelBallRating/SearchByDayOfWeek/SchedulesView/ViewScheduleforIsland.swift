//
//  ViewScheduleForTeam.swift
//  TravelBallRating
//
//  Created by Brian Romero on 8/28/24.
//

import Foundation
import SwiftUI
import CoreData


struct ViewScheduleForTeam: View {
    @ObservedObject var viewModel: AppDayOfWeekViewModel
    let team: Team
    
    var body: some View {
        VStack(spacing: 0) {

            // MARK: - Header
            Text("Schedules for \(team.teamName)")
                .font(.title)
                .padding()

            // MARK: - Day Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(DayOfWeek.allCases, id: \.self) { day in
                        Button {
                            viewModel.selectedDay = day
                            Task {
                                await viewModel.loadSchedules(for: team)
                            }
                        } label: {
                            Text(day.displayName)
                                .font(.headline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    viewModel.selectedDay == day
                                    ? Color.accentColor
                                    : Color.clear
                                )
                                .foregroundColor(
                                    viewModel.selectedDay == day
                                    ? .white
                                    : .primary
                                )
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            viewModel.selectedDay == day
                                            ? Color.accentColor
                                            : Color.secondary.opacity(0.5),
                                            lineWidth: 1
                                        )
                                )
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)

            // MARK: - Section Title
            Text("Schedule Mat Times for \(viewModel.selectedDay?.displayName ?? "Select a Day")")
                .font(.title2)
                .padding(.bottom, 8)

            Divider()

            // MARK: - Schedule Area (Top-Aligned, No Jumping)
            Group {
                if let day = viewModel.selectedDay {
                    if !viewModel.matTimesForDay.isEmpty {

                        ScheduledMatTimesSection(
                            team: team,
                            day: day,
                            viewModel: viewModel,
                            matTimesForDay: $viewModel.matTimesForDay,
                            selectedDay: $viewModel.selectedDay
                        )
                        .layoutPriority(1)

                    } else {
                        VStack(alignment: .leading) {
                            Text("No mat times available for \(day.displayName) at \(team.teamName ?? "Unknown team").")
                                .foregroundColor(.secondary)
                                .padding(.top, 16)

                            Spacer()
                        }
                    }
                } else {
                    VStack(alignment: .leading) {
                        Text("Please select a day to view the schedule.")
                            .foregroundColor(.secondary)
                            .padding(.top, 16)

                        Spacer()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(UIColor.systemGroupedBackground))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            if viewModel.selectedDay == nil {
                viewModel.selectedDay = .monday
            }

            Task {
                await viewModel.loadSchedules(for: team)
            }

            print("Loaded schedules for team: \(team.teamName ?? "Unknown")")
            print("Loaded schedules: \(viewModel.matTimesForDay.count) mat times")
        }
    }
}
