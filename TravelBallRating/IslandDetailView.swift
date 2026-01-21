import SwiftUI
import CoreData
import Combine
import CoreLocation
import Foundation

enum IslandDestination: String, CaseIterable {
    case schedule = "Schedule"
    case website = "Website"
}
struct IslandDetailView: View {
    let team: Team
    @Binding var selectedDestination: IslandDestination?
    @StateObject var viewModel: AllEnteredLocationsViewModel
    @State private var navigationPath = NavigationPath()

    init(team: Team, selectedDestination: Binding<IslandDestination?>) {
        self.team = team
        self._selectedDestination = selectedDestination
        
        let dataManager = TeamDataManager(viewContext: PersistenceController.shared.viewContext)
        _viewModel = StateObject(wrappedValue: AllEnteredLocationsViewModel(dataManager: dataManager))
    }

    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        IslandDetailContent(
            team: team,
            selectedDestination: $selectedDestination,
            viewModel: viewModel,
            navigationPath: $navigationPath
        )
        .onAppear(perform: fetchIsland)
    }

    private func fetchIsland() {
        guard let teamID = team.teamID else {
            print("team ID is nil.")
            return
        }

        let fetchRequest: NSFetchRequest<Team> = Team.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "teamID == %@", teamID as CVarArg)

        do {
            let results = try viewContext.fetch(fetchRequest)
            print("Fetched \(results.count) team objects.")
        } catch {
            print("Failed to fetch team: \(error.localizedDescription)")
        }
    }
}

struct IslandDetailContent: View {
    let team: Team
    @Binding var selectedDestination: IslandDestination?
    @State private var showMapView = false
    @ObservedObject var viewModel: AllEnteredLocationsViewModel
    @StateObject var mapViewModel = AppDayOfWeekViewModel(
        selectedTeam: nil,
        repository: AppDayOfWeekRepository(persistenceController: PersistenceController.shared),
        enterZipCodeViewModel: EnterZipCodeViewModel(
            repository: AppDayOfWeekRepository.shared,
            persistenceController: PersistenceController.shared
        )
    )
    @Binding var navigationPath: NavigationPath

    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        VStack(alignment: .leading) {
            // team Name
            Text(team.teamName ?? "Unnamed team")
                .font(.headline)
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 10)

            // Location Button
            Button(action: { showMapView = true }) {
                Text(team.teamLocation ?? "Unknown Location")
                    .foregroundColor(.blue)
                    .font(.system(size: 16, weight: .light))
                    .multilineTextAlignment(.leading)
                    .padding(.bottom, 10)
            }
            .sheet(isPresented: $showMapView) {
                ConsolidatedTeamMapView(
                    viewModel: mapViewModel,
                    enterZipCodeViewModel: EnterZipCodeViewModel(
                        repository: AppDayOfWeekRepository.shared,
                        persistenceController: PersistenceController.shared
                    ),
                    navigationPath: $navigationPath
                )
            }

            // Created By
            if let createdByUserId = team.createdByUserId {
                Text("Entered By: \(createdByUserId)")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 10)
                    .onChange(of: createdByUserId) { oldValue, newValue in
                        Logger.logCreatedByIdEvent(
                            createdByUserId: newValue,
                            fileName: "IslandDetailView",
                            functionName: "body"
                        )
                    }
            } else {
                Text("Entered By: Unknown")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 10)
            }

            // Added Date
            Text("Added Date: \(formattedDate(team.createdTimestamp) ?? "Unknown")")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 10)

            // Navigation Buttons
            ForEach(IslandDestination.allCases, id: \.self) { destination in
                if destination == .website {
                    Button(action: {
                        if let url = team.teamWebsite {
                            UIApplication.shared.open(url)
                        } else {
                            print("No website URL available")
                        }
                    }) {
                        Text("Go to \(destination.rawValue)")
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(.blue)
                    }
                } else if destination == .schedule {
                    NavigationLink(destination: IslandScheduleAsCal(
                        viewModel: mapViewModel,
                        team: team
                    )) {
                        Text("Go to \(destination.rawValue)")
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle("team Detail")
    }

    private func formattedDate(_ date: Date?) -> String? {
        guard let date = date else { return nil }
        return AppDateFormatter.mediumDateTime.string(from: date)
    }
}
