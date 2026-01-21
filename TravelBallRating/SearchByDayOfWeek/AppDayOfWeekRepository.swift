// AppDayOfWeekRepository.swift
// Mat_Finder
//
// Created by Brian Romero on 6/25/24.


import Foundation
import SwiftUI
import CoreData
import CoreLocation
import os
import OSLog // For better logging in production, though print is fine for debugging


@MainActor
class AppDayOfWeekRepository: ObservableObject {
    @State private var errorMessage: String?
    private var currentAppDayOfWeek: AppDayOfWeek?
    private var selectedTeam: Team?
    let logger = OSLog(subsystem: "TravelBallRating.Subsystem", category: "CoreData")
    
    private var persistenceController: PersistenceController
    
    // Custom initializer to accept PersistenceController
    init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
        print("AppDayOfWeekRepository initialized with PersistenceController")
    }
    
    // Access the view context from the passed persistence controller
    public func getViewContext() -> NSManagedObjectContext {
        return persistenceController.viewContext
    }
    
    static let shared: AppDayOfWeekRepository = {
        let persistenceController = PersistenceController.shared
        return AppDayOfWeekRepository(persistenceController: persistenceController)
    }()
    
    func setSelectedIsland(_ team: Team) {
        self.selectedTeam = team
    }
    
    func setCurrentAppDayOfWeek(_ appDayOfWeek: AppDayOfWeek) {
        self.currentAppDayOfWeek = appDayOfWeeks
    }
    
    // Modify other functions to use the shared PersistenceController instance instead of the local persistenceController variable
    func performActionThatDependsOnIslandAndDay() {
        guard let team = selectedTeam, let appDay = currentAppDayOfWeek else {
            print("Selected team or current day of week is not set.")
            return
        }
        
        if appDay.day.isEmpty {
            print("Invalid day of week.")
            return
        }
        
        guard DayOfWeek(rawValue: appDay.day.lowercased()) != nil else {
            print("Invalid day of week.")
            return
        }
        
        let context = PersistenceController.shared.viewContext
        _ = getAppDayOfWeek(for: appDay.day, team: team, context: context)
    }
    
    
    func saveData() async {
        print("AppDayOfWeekRepository - Saving data")
        do {
            try await PersistenceController.shared.saveContext()
        } catch {
            print("Error saving data: \(error)")
        }
    }
    
    func generateName(for team: Team, day: DayOfWeek) -> String {
        let teamName = team.teamName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown team"
        let name = "\(teamName) -\(day.rawValue.lowercased())"
        print("Generated name: \(name)")
        return name
    }
    
    
    func generateAppDayOfWeekID(for team: Team, day: DayOfWeek) -> String {
        return "\(team.teamName)-\(day.rawValue)"
    }
    
    
    func getAppDayOfWeek(for day: String, team: Team, context: NSManagedObjectContext) -> AppDayOfWeek? {
        return fetchOrCreateAppDayOfWeek(for: day, team: team, context: context)
    }
    
    
    func updateAppDayOfWeekName(_ appDayOfWeek: AppDayOfWeek, with team: Team, dayOfWeek: DayOfWeek, context: NSManagedObjectContext) {
        // ✅ Explicitly update all related fields
        appDayOfWeek.day = dayOfWeek.rawValue
        appDayOfWeek.team = team
        appDayOfWeek.name = generateName(for: team, day: dayOfWeek)
        appDayOfWeek.appDayOfWeekID = generateAppDayOfWeekID(for: team, day: dayOfWeek)
        
        // Optional: safeguard against nil (but generateName should prevent that)
        if appDayOfWeek.name == nil {
            print("⚠️ Warning: AppDayOfWeek name is nil! Setting fallback.")
            appDayOfWeek.name = "Default Name"
        }
        
        // ✅ Save context
        do {
            try context.save()
        } catch {
            print("❌ Failed to save context: \(error)")
        }
    }
    
    
    
    func updateAppDayOfWeek(_ appDayOfWeek: AppDayOfWeek?, with team: Team, dayOfWeek: DayOfWeek, context: NSManagedObjectContext) {
        if let unwrappedAppDayOfWeek = appDayOfWeek {
            updateAppDayOfWeekName(unwrappedAppDayOfWeek, with: team, dayOfWeek: dayOfWeek, context: context)
        } else {
            // Handle the case where appDayOfWeek is nil
            print("AppDayOfWeek is nil")
        }
    }
    
    
    func fetchAllAppDayOfWeeks() -> [AppDayOfWeek] {
        print("AppDayOfWeekRepository - Fetching all AppDayOfWeeks")
        let fetchRequest: NSFetchRequest<AppDayOfWeek> = AppDayOfWeek.fetchRequest()
        fetchRequest.entity = NSEntityDescription.entity(forEntityName: "AppDayOfWeek", in: PersistenceController.shared.viewContext)!
        fetchRequest.relationshipKeyPathsForPrefetching = ["matTimes"]
        return performFetch(request: fetchRequest) ?? []
    }
    
    func fetchAppDayOfWeek(for day: String, team: Team, context: NSManagedObjectContext) -> AppDayOfWeek? {
        let fetchRequest: NSFetchRequest<AppDayOfWeek> = AppDayOfWeek.fetchRequest()
        fetchRequest.entity = NSEntityDescription.entity(forEntityName: "AppDayOfWeek", in: context)!
        fetchRequest.predicate = NSPredicate(format: "team == %@ AND day == %@", team, day)
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try context.fetch(fetchRequest)
            return results.first
        } catch {
            print("Error fetching AppDayOfWeek: \(error.localizedDescription)")
            return nil
        }
    }
    
    func fetchOrCreateAppDayOfWeek(for day: String, team: team, context: NSManagedObjectContext) -> AppDayOfWeek? {
        let fetchRequest: NSFetchRequest<AppDayOfWeek> = AppDayOfWeek.fetchRequest()
        fetchRequest.entity = NSEntityDescription.entity(forEntityName: "AppDayOfWeek", in: context)!
        fetchRequest.predicate = NSPredicate(format: "day == %@ AND team == %@", day, team)
        
        do {
            let appDayOfWeeks = try context.fetch(fetchRequest)
            if let appDayOfWeek = appDayOfWeeks.first {
                return appDayOfWeek
            } else {
                let newAppDayOfWeek = AppDayOfWeek(context: context)
                newAppDayOfWeek.day = day
                newAppDayOfWeek.team = team
                
                if let dayOfWeek = DayOfWeek(rawValue: day) {
                    newAppDayOfWeek.appDayOfWeekID = generateAppDayOfWeekID(for: team, day: dayOfWeek)
                    newAppDayOfWeek.name = generateName(for: team, day: dayOfWeek)
                }
                
                newAppDayOfWeek.createdTimestamp = Date()
                newAppDayOfWeek.matTimes = nil
                
                try context.save()
                return newAppDayOfWeek
            }
        } catch {
            print("Error fetching or creating AppDayOfWeek: \(error.localizedDescription)")
            return nil
        }
    }
    
    
    // MARK: - fetchOrCreateAppDayOfWeek AS COMBO OF selectTeamAndDay and fetchCurrentDayOfWeek
    func fetchOrCreateAppDayOfWeek(for day: DayOfWeek, team: Team, context: NSManagedObjectContext) -> AppDayOfWeek? {
        let fetchRequest: NSFetchRequest<AppDayOfWeek> = AppDayOfWeek.fetchRequest()
        fetchRequest.entity = NSEntityDescription.entity(forEntityName: "AppDayOfWeek", in: context)!
        fetchRequest.predicate = NSPredicate(format: "team == %@ AND day == %@", team, day.displayName)
        
        do {
            let results = try context.fetch(fetchRequest)
            if let existingAppDayOfWeek = results.first {
                return existingAppDayOfWeek
            } else {
                let newAppDayOfWeek = AppDayOfWeek(context: context)
                newAppDayOfWeek.team = team
                newAppDayOfWeek.day = day.displayName
                
                // Generate name and appDayOfWeekID using your existing methods
                newAppDayOfWeek.name = generateName(for: team, day: day) // Assign the generated name
                newAppDayOfWeek.appDayOfWeekID = generateAppDayOfWeekID(for: team, day: day) // Assign the generated ID
                
                try context.save()
                return newAppDayOfWeek
            }
        } catch {
            print("Error fetching or creating AppDayOfWeek: \(error.localizedDescription)")
            return nil
        }
    }
    
    
    // MARK:
    func addNewAppDayOfWeek(for day: DayOfWeek) {
        guard let selectedTeam = selectedTeam else {
            print("Error: selected team is nil")
            return
        }
        
        let context = PersistenceController.shared.viewContext
        
        // Fetch or create the AppDayOfWeek using the updated method
        let newAppDayOfWeek = fetchOrCreateAppDayOfWeek(for: day.rawValue, team: selectedTeam, context: context)
        currentAppDayOfWeek = newAppDayOfWeek
        
        print("Created or fetched AppDayOfWeek: \(newAppDayOfWeek.debugDescription)")
    }
    
    func deleteSchedule(at indexSet: IndexSet, for day: DayOfWeek, team: Team) async {
        let fetchRequest: NSFetchRequest<AppDayOfWeek> = AppDayOfWeek.fetchRequest()
        fetchRequest.entity = NSEntityDescription.entity(forEntityName: "AppDayOfWeek", in: PersistenceController.shared.viewContext)!
        fetchRequest.predicate = NSPredicate(format: "team == %@ AND day == %@", team, day.rawValue)
        
        do {
            let results = try PersistenceController.shared.viewContext.fetch(fetchRequest)
            for index in indexSet {
                let dayToDelete = results[index]
                if let matTimes = dayToDelete.matTimes as? Set<MatTime> {
                    for matTime in matTimes {
                        PersistenceController.shared.viewContext.delete(matTime)
                    }
                }
                PersistenceController.shared.viewContext.delete(dayToDelete)
            }
            await saveData()
        } catch {
            print("Error deleting schedule: \(error.localizedDescription)")
        }
    }
    
    // MARK: - AppDayOfWeekRepository fetchSchedules
    func fetchSchedules(for team: Team) async -> [AppDayOfWeek] {
        print("AppDayOfWeekRepository.fetchSchedules - START")
        
        let backgroundContext = PersistenceController.shared.container.newBackgroundContext()
        let islandObjectID = team.objectID

        return await withCheckedContinuation { continuation in
            backgroundContext.perform {
                do {
                    guard let islandInContext = try backgroundContext.existingObject(with: islandObjectID) as? Team else {
                        continuation.resume(returning: [])
                        return
                    }

                    let fetchRequest: NSFetchRequest<AppDayOfWeek> = AppDayOfWeek.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "team == %@", islandInContext)

                    let schedules = try backgroundContext.fetch(fetchRequest)
                    print("AppDayOfWeekRepository.fetchSchedules - END - Fetched \(schedules.count) schedules")
                    continuation.resume(returning: schedules)
                } catch {
                    print("AppDayOfWeekRepository.fetchSchedules - ERROR - \(error.localizedDescription)")
                    continuation.resume(returning: [])
                }
            }
        }
    }


    
    // Your other fetchSchedules function (overload)
    func fetchSchedules(for team: Team, day: DayOfWeek) async -> [AppDayOfWeek] {
        print("AppDayOfWeekRepository.fetchSchedules (with day) - START")
        
        let backgroundContext = PersistenceController.shared.container.newBackgroundContext()
        let islandObjectID = team.objectID
        let dayValue = day.rawValue

        return await withCheckedContinuation { continuation in
            backgroundContext.perform {
                do {
                    guard let islandInContext = try backgroundContext.existingObject(with: islandObjectID) as? Team else {
                        continuation.resume(returning: [])
                        return
                    }

                    let fetchRequest: NSFetchRequest<AppDayOfWeek> = AppDayOfWeek.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "team == %@ AND day == %@", islandInContext, dayValue)

                    let schedules = try backgroundContext.fetch(fetchRequest)
                    print("AppDayOfWeekRepository.fetchSchedules (with day) - END - Fetched \(schedules.count) schedules")
                    continuation.resume(returning: schedules)
                } catch {
                    print("AppDayOfWeekRepository.fetchSchedules (with day) - ERROR - \(error.localizedDescription)")
                    continuation.resume(returning: [])
                }
            }
        }
    }

    
    func deleteRecord(for appDayOfWeek: AppDayOfWeek) async {
        print("AppDayOfWeekRepository - Deleting record for AppDayOfWeek: \(appDayOfWeek.appDayOfWeekID ?? "Unknown")")
        if let matTimes = appDayOfWeek.matTimes as? Set<MatTime> {
            for matTime in matTimes {
                PersistenceController.shared.viewContext.delete(matTime)
            }
        }
        PersistenceController.shared.viewContext.delete(appDayOfWeek)
        await saveData()
    }
    
    private func performFetch(request: NSFetchRequest<AppDayOfWeek>) -> [AppDayOfWeek]? {
        do {
            let results = try PersistenceController.shared.viewContext.fetch(request)
            print("Fetch successful: \(results.count) AppDayOfWeek objects fetched.")
            return results
        } catch {
            print("Fetch error: \(error.localizedDescription)")
            return nil
        }
    }
    
    func fetchTeams(day: String, radius: Double, locationManager: UserLocationMapViewModel) -> [Team] {
        var fetchedIslands: [Teams] = []
        
        guard let userLocation = locationManager.getCurrentUserLocation() else {
            print("Failed to get current user location.")
            return fetchedIslands
        }
        
        let fetchRequest: NSFetchRequest<AppDayOfWeek> = AppDayOfWeek.fetchRequest()
        fetchRequest.entity = NSEntityDescription.entity(forEntityName: "AppDayOfWeek", in: PersistenceController.shared.container.viewContext)!
        fetchRequest.predicate = NSPredicate(format: "day BEGINSWITH[c] %@", day.lowercased())
        fetchRequest.relationshipKeyPathsForPrefetching = ["team"]
        
        do {
            let appDayOfWeeks = try PersistenceController.shared.container.viewContext.fetch(fetchRequest)
            
            for appDayOfWeek in appDayOfWeeks {
                guard let team = appDayOfWeek.team else { continue }
                
                let distance = locationManager.calculateDistance(from: userLocation, to: CLLocation(latitude: team.latitude, longitude: team.longitude))
                print("Distance to Team: \(distance)")
                
                fetchedIslands.append(team)
            }
        } catch {
            print("Failed to fetch AppDayOfWeek: \(error.localizedDescription)")
        }
        
        return fetchedIslands
    }
    
    
    
    func fetchTeams(day: DayOfWeek?, radius: Double, locationManager: UserLocationMapViewModel) -> [Team] {
        guard let day = day else {
            print("Day is nil")
            return []
        }
        
        var fetchedIslands: [Team] = []
        
        let fetchRequest = AppDayOfWeek.fetchRequest()
        fetchRequest.entity = NSEntityDescription.entity(forEntityName: "AppDayOfWeek", in: PersistenceController.shared.container.viewContext)!
        fetchRequest.predicate = NSPredicate(format: "day ==[c] %@", day.rawValue)
        fetchRequest.relationshipKeyPathsForPrefetching = ["team", "matTimes"]
        
        do {
            let appDayOfWeeks = try PersistenceController.shared.container.viewContext.fetch(fetchRequest)
            print("Fetched \(appDayOfWeeks.count) AppDayOfWeek objects")
            
            fetchedIslands = appDayOfWeeks.compactMap { appDayOfWeek in
                guard let team = appDayOfWeek.team,
                      appDayOfWeek.day.lowercased() == day.displayName.lowercased(),
                      appDayOfWeek.matTimes?.count ?? 0 > 0 else { return nil }
                return team
            }
        } catch {
            print("Failed to fetch AppDayOfWeek: \(error.localizedDescription)")
            errorMessage = "Error fetching pirate islands: \(error.localizedDescription)"
        }
        
        print("Fetched \(fetchedIslands.count) pirate islands")
        return fetchedIslands
    }
    
   
    // MARK: - New fetchAllIslands Method
    func fetchAllIslands(forDay day: String) async throws -> [NSManagedObjectID] {
        let backgroundContext = PersistenceController.shared.container.newBackgroundContext()
        
        let dayLowercased = day.lowercased() // Sendable primitive
        
        return try await withCheckedThrowingContinuation { continuation in
            backgroundContext.perform {
                do {
                    let fetchRequest: NSFetchRequest<Team> = Team.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "ANY appDayOfWeeks.day == %@", dayLowercased)
                    fetchRequest.relationshipKeyPathsForPrefetching = ["appDayOfWeeks", "appDayOfWeeks.matTimes"]
                    
                    let islands = try backgroundContext.fetch(fetchRequest)
                    
                    let filteredTeams = teams.filter { team in
                        guard let appDayOfWeeks = team.appDayOfWeeks as? Set<AppDayOfWeek> else { return false }
                        return appDayOfWeeks.contains { appDayOfWeek in
                            guard appDayOfWeek.day.lowercased() == dayLowercased else { return false }
                            return (appDayOfWeek.matTimes?.count ?? 0) > 0
                        }
                    }
                    
                    print("Fetched and filtered islands count: \(filteredTeams.count). Returning ObjectIDs.")
                    continuation.resume(returning: filteredTeams.map { $0.objectID })
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - NEW: fetchSchedulesObjectIDs for a specific team
    func fetchSchedulesObjectIDs(for team: Team) async -> [NSManagedObjectID] {
        let backgroundContext = PersistenceController.shared.container.newBackgroundContext()
        let islandObjectID = team.objectID
        
        return await withCheckedContinuation { continuation in
            backgroundContext.perform {
                do {
                    guard let islandInContext = try backgroundContext.existingObject(with: islandObjectID) as? Team else {
                        continuation.resume(returning: [])
                        return
                    }
                    
                    let request: NSFetchRequest<AppDayOfWeek> = AppDayOfWeek.fetchRequest()
                    request.predicate = NSPredicate(format: "team == %@", islandInContext)
                    request.returnsObjectsAsFaults = false
                    request.includesPropertyValues = false // we only need objectIDs
                    
                    let results = try backgroundContext.fetch(request)
                    let objectIDs = results.map { $0.objectID }
                    continuation.resume(returning: objectIDs)
                } catch {
                    print("fetchSchedulesObjectIDs error: \(error.localizedDescription)")
                    continuation.resume(returning: [])
                }
            }
        }
    }
}

