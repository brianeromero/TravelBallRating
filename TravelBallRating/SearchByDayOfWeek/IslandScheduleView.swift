//
//  IslandScheduleView.swift
//  Mat_Finder
//
//  Created by Brian Romero on 7/8/24.
//

import SwiftUI
import CoreData

struct IslandScheduleView: View {
    @ObservedObject var viewModel: AppDayOfWeekViewModel
    var team: Team?

    @State private var selectedDay: DayOfWeek?
    @State private var selectedMatTime: MatTime?
    @StateObject private var enterZipCodeViewModel: EnterZipCodeViewModel

    init(viewModel: AppDayOfWeekViewModel, team: Team?) {
        self.viewModel = viewModel
        self.team = team
        _enterZipCodeViewModel = StateObject(wrappedValue: EnterZipCodeViewModel(
            repository: AppDayOfWeekRepository.shared,
            persistenceController: PersistenceController.shared
        ))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let teamName = team?.teamName {
                        Text("Schedule for \(teamName)")
                            .font(.headline)
                            .padding(.bottom)

                        ForEach(DayOfWeek.allCases, id: \.self) { day in
                            let schedules = viewModel.appDayOfWeekList.filter { $0.day == day.displayName }
                            if !schedules.isEmpty {
                                DisclosureGroup(
                                    content: {
                                        ForEach(schedules, id: \.self) { schedule in
                                            scheduleView(for: schedule)
                                                .onTapGesture {
                                                    selectedDay = day
                                                    selectedMatTime = (schedule.matTimes?.allObjects.first as? MatTime)
                                                }
                                        }
                                    },
                                    label: {
                                        Text(day.displayName)
                                            .font(.subheadline)
                                            .padding(.top)
                                    }
                                )
                                .padding(.horizontal)
                            }
                        }
                    } else {
                        Text("No team selected.")
                            .foregroundColor(.red)
                    }
                }
                .padding()
            }
            .navigationBarTitle("Mat Schedule", displayMode: .inline)
            .sheet(item: $selectedDay) { day in
                ScheduleDetailModal(
                    viewModel: AppDayOfWeekViewModel(
                        selectedTeam: team,
                        repository: AppDayOfWeekRepository.shared,
                        enterZipCodeViewModel: enterZipCodeViewModel
                    ),
                    day: day
                )
            }
        }
        .onAppear {
            if let team = team {
                // Use a default or previously selected day here
                let dayToFetch: DayOfWeek = selectedDay ?? .monday
                
                Task {
                    _ = await viewModel.fetchCurrentDayOfWeek(
                        for: team,
                        day: dayToFetch,
                        selectedDayBinding: Binding(
                            get: { viewModel.selectedDay },
                            set: { viewModel.selectedDay = $0 }
                        )
                    )
                }
            }
        }
    }

    private func scheduleView(for schedule: AppDayOfWeek) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(schedule.matTimes?.allObjects as? [MatTime] ?? [], id: \.self) { matTime in
                HStack {
                    Text(matTime.time ?? "Unknown time")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                    Text(matTime.goodForBeginners ? "Beginners" : "")
                        .font(.caption)
                        .foregroundColor(.green)
                }
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
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
    }
}

/*
struct IslandScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        let persistenceController = PersistenceController.preview
        
        // Create a mock Team
        let mockIsland = Team(context: persistenceController.container.viewContext)
        mockIsland.teamName = "Mock team"
        
        // Create a mock EnterZipCodeViewModel
        let enterZipCodeViewModel = EnterZipCodeViewModel(
            repository: AppDayOfWeekRepository.shared,
            persistenceController: persistenceController
        )
        
        // Create a mock AppDayOfWeekViewModel with mock data
        let viewModel = AppDayOfWeekViewModel(
 selectedTeam: mockIsland,
            repository: MockAppDayOfWeekRepository(persistenceController: persistenceController),
            enterZipCodeViewModel: enterZipCodeViewModel
        )
        
        // Populate viewModel with mock AppDayOfWeek data
        for day in DayOfWeek.allCases {
            let mockSchedule = AppDayOfWeek(context: persistenceController.container.viewContext)
            let mockMatTime = MatTime(context: persistenceController.container.viewContext)
            mockMatTime.time = "10:00 AM"
            mockMatTime.gi = true
            mockMatTime.noGi = false
            mockMatTime.openMat = true
            mockMatTime.restrictions = false
            mockMatTime.restrictionDescription = nil
            mockMatTime.goodForBeginners = true
            mockMatTime.kids = false
            mockSchedule.day = day.displayName
            mockSchedule.matTimes = [mockMatTime] as NSSet
            viewModel.appDayOfWeekList.append(mockSchedule)
        }
        
        return NavigationView {
            IslandScheduleView(viewModel: viewModel, team: mockIsland)
        }
    }
}
*/
