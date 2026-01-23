//
//  ScheduleFormView.swift
//  TravelBallRating
//
//  Created by Brian Romero on 7/30/24.
//

import SwiftUI
import CoreData
import UIKit
import Combine


// MARK: - Date <-> String conversions using centralized formatter
extension Date {
    func toTimeString() -> String {
        AppDateFormatter.twelveHour.string(from: self)
    }
}

extension String {
    func toTimeDate() -> Date? {
        AppDateFormatter.twelveHour.date(from: self)
    }
}

// MARK: - MatTime description
extension MatTime {
    override public var description: String {
        guard let timeString = time,
              let date = timeString.toTimeDate() else { return "" }

        return """
        \(date.toTimeString()) \
        - Gi: \(gi), \
        No Gi: \(noGi), \
        Open Mat: \(openMat), \
        Restrictions: \(restrictions), \
        Good for Beginners: \(goodForBeginners), \
        Kids: \(kids)
        """
    }
}


struct ScheduleFormView: View {
    @Environment(\.managedObjectContext) private var viewContext

    let teams: [Team]

    @State private var selectedTeamID: UUID?

    var selectedTeam: Team? {
        teams.first { $0.teamID == selectedTeamID }
    }

    let initialSelectedTeam: Team?

    @Binding var matTimes: [MatTime]

    @ObservedObject var viewModel: AppDayOfWeekViewModel

    @State private var selectedDay: DayOfWeek?
    @State private var selectedAppDayOfWeek: AppDayOfWeek?

    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    @State private var showReview = false

    @State private var isLoading = false
    @State private var isAppDayOfWeekLoaded = false
    
    
    var body: some View {
        Form {

            // MARK: - Team Selection
            TeamSection(
                teams: teams,
                selectedTeamID: $selectedTeamID,
                showReview: $showReview
            )

            .onAppear { Task { await handleOnAppear() } }
            .onChange(of: selectedTeam) { _, _ in Task { await setupInitialSelection() } }

            // MARK: - Day Selection
            daySelectionSection

            // MARK: - Add New Mat Time Section (FIELDS + BUTTON)
            Section {
                if selectedTeam != nil { // unwrap the computed property
                    AddNewMatTimeSection(
                        selectedTeamID: $selectedTeamID,
                        teams: teams,
                        selectedDay: $selectedDay,
                        viewModel: viewModel,
                        selectTeamAndDay: { team, day in await selectTeamAndDay(team, day) },
                        showAlert: $showingAlert,
                        alertTitle: $alertTitle,
                        alertMessage: $alertMessage
                    )

                } else {
                    Text("Please select a team first")
                }

                // Always enabled button
                Button(action: {
                    NotificationCenter.default.post(name: .addNewMatTimeTapped, object: nil)
                }) {
                    Text("Add New Mat Time")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }

            // MARK: - Scheduled Mat Times
            if let team = selectedTeam, let day = selectedDay {
                ScheduledMatTimesSection(
                    team: team,
                    day: day,
                    viewModel: viewModel,
                    matTimesForDay: $viewModel.matTimesForDay,
                    selectedDay: $selectedDay
                )
            } else {
                Text("Please select a day and team to view schedule.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

        }
        .navigationTitle("Schedule Entry")
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

// MARK: - Day Selection Section
private extension ScheduleFormView {

    var daySelectionSection: some View {
        Section(header: Text("Select Day")) {
            Picker("Day", selection: $selectedDay) {
                ForEach(DayOfWeek.allCases, id: \.self) { day in
                    Text(day.displayName).tag(day as DayOfWeek?)
                }
            }
            .pickerStyle(.segmented)
        }
        .onChange(of: selectedDay) { _, newDay in
            guard let newDay, let team = selectedTeam else { return }

            Task {
                isLoading = true

                if let appDay = await selectTeamAndDay(team, newDay) {
                    viewModel.selectedAppDayOfWeek = appDay
                    isAppDayOfWeekLoaded = true
                }
                isLoading = false
            }
        }
    }
}

// MARK: - Lifecycle / Setup
private extension ScheduleFormView {

    func handleOnAppear() async {

        // 🧪 DEBUG — add temporarily
        print("🧭 initialSelectedTeam:",
              initialSelectedTeam?.teamName ?? "nil")
        print("🧭 selectedTeamID (before):",
              selectedTeamID?.uuidString ?? "nil")

        if selectedTeamID == nil {
            if let initial = initialSelectedTeam {
                selectedTeamID = initial.teamID
            } else if let first = team.first {
                selectedTeamID = first.teamID
            }
        }

        print("🧭 selectedTeamID (after):",
              selectedTeamID?.uuidString ?? "nil")

        await setupInitialSelection()
    }



    func setupInitialSelection() async {
        guard let team = selectedTeam else { return }

        let day = selectedDay ?? .monday
        let (_, fetchedMatTimes) = await viewModel.fetchCurrentDayOfWeek(
            for: team,
            day: day,
            selectedDayBinding: Binding(
                get: { viewModel.selectedDay },
                set: { viewModel.selectedDay = $0 }
            )
        )

        if let fetchedMatTimes {
            viewModel.matTimesForDay[day] = fetchedMatTimes
        }

    }

}

// MARK: - Data Helpers
private extension ScheduleFormView {

    func selectTeamAndDay(_ team: Team, _ day: DayOfWeek) async -> AppDayOfWeek? {
        let request: NSFetchRequest<AppDayOfWeek> = AppDayOfWeek.fetchRequest()
        request.predicate = NSPredicate(
            format: "team.teamID == %@ AND day == %@",
            team.teamID! as CVarArg,
            day.rawValue
        )

        do {
            return try viewContext.fetch(request).first
        } catch {
            print("❌ Failed to fetch AppDayOfWeek: \(error)")
            return nil
        }
    }

    func addNewMatTime() {
        print("✅ Add New Mat Time tapped")
        // Your existing add logic lives here
    }

}



struct CornerRadiusStyle: ViewModifier {
    let radius: CGFloat
    let corners: UIRectCorner

    func body(content: Content) -> some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Color.clear, lineWidth: 0)
                    .mask(
                        Rectangle()
                            .padding(.top, corners.contains(.topLeft) || corners.contains(.topRight) ? radius : 0)
                            .padding(.bottom, corners.contains(.bottomLeft) || corners.contains(.bottomRight) ? radius : 0)
                            .padding(.leading, corners.contains(.topLeft) || corners.contains(.bottomLeft) ? radius : 0)
                            .padding(.trailing, corners.contains(.topRight) || corners.contains(.bottomRight) ? radius : 0)
                    )
            )
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        self.modifier(CornerRadiusStyle(radius: radius, corners: corners))
    }
}
