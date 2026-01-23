//
//  AllteamScheduleView.swift
//  TravelBallRating
//
//  Created by Brian Romero on 7/12/24.
//

import Foundation
import SwiftUI

struct pTeamScheduleView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var viewModel: AppDayOfWeekViewModel

    @State private var showAddMatTimeForm = false
    @State private var selectedMatTime: MatTime?

    let enterZipCodeViewModel: EnterZipCodeViewModel

    var body: some View {
        VStack {
            Text("All teams Schedules")
                .font(.title)
                .padding()

            List {
                ForEach(sortedDays, id: \.self) { day in
                    daySection(for: day)
                }
                .onDelete(perform: deleteMatTimes)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
            ToolbarItem {
                Button(action: {
                    selectedMatTime = nil
                    showAddMatTimeForm = true
                }) {
                    Label("Add MatTime", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddMatTimeForm) {
            DaysOfWeekFormView(
                appDayOfWeekViewModel: viewModel, // Pass your existing AppDayOfWeekViewModel instance
                selectedTeam: $viewModel.selectedTeam, // Assuming selectedTeam is part of AppDayOfWeekViewModel
                selectedMatTime: $selectedMatTime,
                showReview: .constant(false)
            )
        }
        .onAppear {
            Task {
                await viewModel.loadAllSchedules()
            }
        }
    }

    private func daySection(for day: DayOfWeek) -> some View {
        let schedulesForDay = filteredSchedules(for: day)
        
        return Group {
            if !schedulesForDay.isEmpty {
                Section(header: Text(day.displayName)) {
                    ForEach(schedulesForDay, id: \.0) { team, matTimes in
                        teamSection(team: team, matTimes: matTimes)
                    }
                }
            }
        }
    }

    private func teamSection(team: Team, matTimes: [MatTime]) -> some View {
        Group {
            if let teamName = team.teamName, !teamName.isEmpty {
                Section(header: Text(team.teamName ?? "Unknown team")) {
                    ForEach(filteredAndSortedMatTimes(matTimes), id: \.self) { matTime in
                        ScheduleRow(matTime: matTime)
                            .onTapGesture {
                                selectedMatTime = matTime
                                showAddMatTimeForm = true
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    deleteMatTime(matTime)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
    }

    var sortedDays: [DayOfWeek] {
        viewModel.teamSchedules.keys.sorted { $0.rawValue < $1.rawValue }
    }

    func filteredSchedules(for day: DayOfWeek) -> [(Team, [MatTime])] {
        guard let schedules = viewModel.teamSchedules[day] else {
            return []
        }
        return schedules.filter { !$0.1.filter { $0.appDayOfWeek != nil }.isEmpty }
    }

    func filteredAndSortedMatTimes(_ matTimes: [MatTime]) -> [MatTime] {
        matTimes
            .filter { $0.appDayOfWeek != nil && $0.time != nil && !$0.time!.isEmpty }
            .sorted {
                guard let time1 = AppDateFormatter.mediumDateTime.date(from: $0.time!),
                      let time2 = AppDateFormatter.mediumDateTime.date(from: $1.time!)
                else { return false }
                return time1 < time2

            }
    }

    private func deleteMatTimes(offsets: IndexSet) {
        withAnimation {
            offsets.map { sortedDays[$0] }.forEach { day in
                guard let schedules = viewModel.teamSchedules[day] else { return }
                schedules.forEach { team, matTimes in
                    matTimes.enumerated().filter { offsets.contains($0.offset) }.forEach { matTime in
                        viewContext.delete(matTime.element)
                    }
                }
            }

            do {
                try viewContext.save()
                // Refresh the view model's data after deletion
                Task {
                    await viewModel.loadAllSchedules()
                }
            } catch {
                print("Failed to delete MatTimes: \(error.localizedDescription)")
            }
        }
    }

    private func deleteMatTime(_ matTime: MatTime) {
        viewContext.delete(matTime)
        do {
            try viewContext.save()
            // Refresh the view model's data after deletion
            Task {
                await viewModel.loadAllSchedules()
            }
        } catch {
            print("Failed to delete MatTime: \(error.localizedDescription)")
        }
    }
}
