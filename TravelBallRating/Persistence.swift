// Persistence.swift
// Mat_Finder
// Created by Brian Romero on 6/24/24.

@preconcurrency
import CoreData
import Combine
import Foundation
import UIKit
import FirebaseFirestore
import FirebaseCore
import FirebaseAuth

@MainActor
final class PersistenceController: ObservableObject {

    // MARK: - Singleton Instance
    static let shared = PersistenceController() // ✅ Fix: allow access outside @MainActor

    // MARK: - Core Data & Firestore
    let container: NSPersistentContainer
    let firestoreManager: FirestoreManager

    var viewContext: NSManagedObjectContext { container.viewContext }

    // MARK: - Preview Provider
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        let dummyTeam = Team(context: viewContext)
        dummyTeam.teamID = UUID()
        dummyTeam.teamName = "Preview Team"
        dummyTeam.teamLocation = "Fictional Place"
        dummyTeam.country = "Imagination Land"
        dummyTeam.createdByUserId = "preview_user"
        dummyTeam.createdTimestamp = Date()
        dummyTeam.lastModifiedByUserId = "preview_user"
        dummyTeam.lastModifiedTimestamp = Date()
        dummyTeam.latitude = 34.0522
        dummyTeam.longitude = -118.2437
        dummyTeam.teamWebsite = URL(string: "https://example.com")

        let dummyAppDayOfWeek = AppDayOfWeek(context: viewContext)
        dummyAppDayOfWeek.id = UUID()
        dummyAppDayOfWeek.day = DayOfWeek.monday.rawValue
        dummyAppDayOfWeek.team = dummyTeam

        do { try viewContext.save() }
        catch { fatalError("Unresolved error \(error)") }

        return result
    }()

    // MARK: - Initializer
    private init(inMemory: Bool = false) {
        self.firestoreManager = FirestoreManager.shared
        container = NSPersistentContainer(name: "TravelBallRating")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
            FirestoreManager.shared.disabled = true
        }

        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        // 🔥 REQUIRED FIXES — prevent SwiftUI "background thread publishing" errors
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.perform {
            print("✅ ViewContext access is safe — running on \(Thread.isMainThread ? "Main Thread" : "Background Thread")")
        }
    }


    
    // MARK: - Core Data Methods
    func fetch<T: NSManagedObject>(_ request: NSFetchRequest<T>) async throws -> [T] {
        try viewContext.fetch(request)
    }

    func create<T: NSManagedObject>(entityName: String) -> T? {
        guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: viewContext) else { return nil }
        return T(entity: entity, insertInto: viewContext)
    }

    // MARK: - Save Context
    @MainActor
    func saveContext() async throws {
        guard viewContext.hasChanges else {
            print("💤 No Core Data changes to save — skipping saveContext()")
            return
        }

        do {
            try viewContext.save()
            print("💾 Successfully saved context on main actor.")
        } catch {
            viewContext.rollback()
            print("❌ Core Data save failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Team CRUD
    func fetchAllTeams() async throws -> [Team] {
        let request: NSFetchRequest<Team> = Team.fetchRequest()
        return try await fetch(request)
    }
    
    func createOrUpdateTeam(
        teamID: UUID, name: String, location: String, country: String,
        createdByUserId: String, createdTimestamp: Date,
        lastModifiedByUserId: String, lastModifiedTimestamp: Date,
        latitude: Double, longitude: Double, teamWebsiteURL: URL?
    ) async throws -> Team {
        let request: NSFetchRequest<Team> = Team.fetchRequest()
        request.predicate = NSPredicate(format: "teamID == %@", teamID as CVarArg)

        if let existing = try await fetch(request).first {
            existing.teamName = name
            existing.teamLocation = location
            existing.country = country
            existing.createdByUserId = createdByUserId
            existing.createdTimestamp = createdTimestamp
            existing.lastModifiedByUserId = lastModifiedByUserId
            existing.lastModifiedTimestamp = lastModifiedTimestamp
            existing.latitude = latitude
            existing.longitude = longitude
            existing.teamWebsite = teamWebsiteURL
            try await saveContext()
            return existing
        } else {
            let newTeam = Team(context: viewContext)
            newTeam.teamID = teamID
            newTeam.teamName = name
            newTeam.teamLocation = location
            newTeam.country = country
            newTeam.createdByUserId = createdByUserId
            newTeam.createdTimestamp = createdTimestamp
            newTeam.lastModifiedByUserId = lastModifiedByUserId
            newTeam.lastModifiedTimestamp = lastModifiedTimestamp
            newTeam.latitude = latitude
            newTeam.longitude = longitude
            newTeam.teamWebsite = teamWebsiteURL
            try await saveContext()
            return newTeam
        }
    }
    
    func cacheTeamsFromFirestore() async throws {
        let snapshot = try await firestoreManager.getDocuments(in: .teams)
        for document in snapshot {
            let teamID = UUID(uuidString: document.documentID) ?? UUID()
            let name = document.get("name") as? String ?? ""
            let location = document.get("location") as? String ?? ""
            let country = document.get("country") as? String ?? ""
            let createdByUserId = document.get("createdByUserId") as? String ?? ""
            let createdTimestamp = (document.get("createdTimestamp") as? Timestamp)?.dateValue() ?? Date()
            let lastModifiedByUserId = document.get("lastModifiedByUserId") as? String ?? ""
            let lastModifiedTimestamp = (document.get("lastModifiedTimestamp") as? Timestamp)?.dateValue() ?? Date()
            let latitude = document.get("latitude") as? Double ?? 0
            let longitude = document.get("longitude") as? Double ?? 0
            let teamWebsiteURL = URL(string: document.get("teamWebsite") as? String ?? "")
            
            _ = try await createOrUpdateTeam(
                teamID: teamID, name: name, location: location, country: country,
                createdByUserId: createdByUserId, createdTimestamp: createdTimestamp,
                lastModifiedByUserId: lastModifiedByUserId, lastModifiedTimestamp: lastModifiedTimestamp,
                latitude: latitude, longitude: longitude, teamWebsiteURL: teamWebsiteURL
            )
        }
    }
    
    func fetchSingle(entityName: String) async throws -> NSManagedObject? {
        if entityName == "Team" {
            guard let snapshot = try await firestoreManager.getDocuments(in: .teams).first else { return nil }
            let team = Team(context: viewContext)
            team.teamID = UUID(uuidString: snapshot.documentID) ?? UUID()
            team.teamName = (snapshot.get("teamName") as? String)!
            try await saveContext()
            return team
        }

        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        request.fetchLimit = 1
        // Direct fetch without perform { ... } avoids Sendable/main-actor issues
        return try viewContext.fetch(request).first
    }

    
    // MARK: - Local Fetch Helpers
    func fetchLocalRecord(forCollection collectionName: String, recordId: UUID) throws -> NSManagedObject? {
        let entityMap = [
            "teams": "Team",
            "reviews": "Review",
            "matTimes": "MatTime",
            "appDayOfWeeks": "AppDayOfWeek"
        ]
        guard let entityName = entityMap[collectionName] else { return nil }
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)

        // Normalize both forms of the ID
        let idString = recordId.uuidString
        let idNoHyphen = idString.replacingOccurrences(of: "-", with: "")

        switch collectionName {
        case "teams":
            request.predicate = NSPredicate(format: "teamID == %@ OR teamID == %@", idString, idNoHyphen)
        case "reviews":
            request.predicate = NSPredicate(format: "reviewID == %@ OR reviewID == %@", idString, idNoHyphen)
        case "matTimes":
            request.predicate = NSPredicate(format: "id == %@ OR id == %@", idString, idNoHyphen)
        case "appDayOfWeeks":
            request.predicate = NSPredicate(format: "appDayOfWeekID == %@ OR appDayOfWeekID == %@", idString, idNoHyphen)
        default:
            return nil
        }

        request.fetchLimit = 1
        return try viewContext.fetch(request).first
    }


    // MARK: - Generic Record Fetchers
    // For entities where the UUID is optional (UUID?)
    func fetchLocalRecords<T: NSManagedObject>(
        forEntity entity: T.Type,
        keyPath: KeyPath<T, UUID?>
    ) throws -> [String] {
        let request = NSFetchRequest<T>(entityName: String(describing: entity))
        return try viewContext.fetch(request).compactMap { $0[keyPath: keyPath]?.uuidString }
    }

    // For entities where the UUID is non-optional (UUID)
    func fetchLocalRecords<T: NSManagedObject>(
        forEntity entity: T.Type,
        keyPath: KeyPath<T, UUID>
    ) throws -> [String] {
        let request = NSFetchRequest<T>(entityName: String(describing: entity))
        return try viewContext.fetch(request).map { $0[keyPath: keyPath].uuidString }
    }

    
    // MARK: - Firestore Sync Helpers
    private func getFirestoreCollection(for record: NSManagedObject) -> FirestoreManager.Collection? {
        switch record.entity.name {
        case "Team": return .teams
        case "Review": return .reviews
        case "MatTime": return .matTimes
        case "AppDayOfWeek": return .appDayOfWeeks
        default: return nil
        }
    }
    
    private func getDocumentID(for record: NSManagedObject) -> String? {
        switch record {
        case let team as Team: return team.teamID?.uuidString
        case let review as Review: return review.reviewID.uuidString
        case let matTime as MatTime: return matTime.id?.uuidString
        case let appDay as AppDayOfWeek: return appDay.id?.uuidString
        default: return nil
        }
    }
    
    // MARK: - Delete/Edit Records
    func deleteRecord(record: NSManagedObject) async throws {
        viewContext.delete(record)
        try await saveContext()
        if let docID = getDocumentID(for: record),
           let collection = getFirestoreCollection(for: record) {
            try await firestoreManager.deleteDocument(in: collection, id: docID)
        }
    }
    
    func editRecord(record: NSManagedObject, updates: [String: Any]) async throws {
        for (key, value) in updates { record.setValue(value, forKey: key) }
        try await saveContext()
        if let docID = getDocumentID(for: record),
           let collection = getFirestoreCollection(for: record) {
            try await firestoreManager.updateDocument(in: collection, id: docID, data: updates)
        }
    }
    
    // MARK: - Error Enum
    enum PersistenceError: Error, CustomStringConvertible {
        case fetchError(Error), saveError(Error), invalidCollectionName(String),
             entityNotFound(String), invalidUUID(String), recordNotFound(String),
             invalidRecordId(String)
        
        var description: String {
            switch self {
            case .fetchError(let error): return "Fetch error: \(error.localizedDescription)"
            case .saveError(let error): return "Save error: \(error.localizedDescription)"
            case .invalidCollectionName(let name): return "Invalid collection name: \(name)"
            case .entityNotFound(let entityName): return "Entity not found: \(entityName)"
            case .invalidUUID(let uuid): return "Invalid UUID: \(uuid)"
            case .recordNotFound(let id): return "Record not found: \(id)"
            case .invalidRecordId(let id): return "Invalid record ID: \(id)"
            }
        }
    }
}

// MARK: - Schedule Extensions
extension PersistenceController {
    @MainActor
    func fetchSchedules(for predicate: NSPredicate) throws -> [AppDayOfWeek] {
        let request: NSFetchRequest<AppDayOfWeek> = AppDayOfWeek.fetchRequest()
        request.predicate = predicate
        return try viewContext.fetch(request)
    }
}


extension PersistenceController {
    func fetchLocalRecords(forCollection collectionName: String) async throws -> [String]? {
        switch collectionName {
        case "teams":
            // ✅ Correct property name: teamID (UUID?)
            return try fetchLocalRecords(forEntity: Team.self, keyPath: \Team.teamID)
        case "reviews":
            // ✅ Non-optional UUID, will use the second overload automatically
            return try fetchLocalRecords(forEntity: Review.self, keyPath: \Review.reviewID)
        case "AppDayOfWeek":
            return try fetchLocalRecords(forEntity: AppDayOfWeek.self, keyPath: \AppDayOfWeek.id)
        case "MatTime":
            return try fetchLocalRecords(forEntity: MatTime.self, keyPath: \MatTime.id)
        default:
            print("⚠️ Unknown collection: \(collectionName)")
            return nil
        }
    }

    /// Ensures Core Data background merges complete before dependent downloads begin
    func waitForBackgroundSaves() async throws {
        await container.viewContext.perform {
            // Forces all background context changes to merge
            self.container.viewContext.refreshAllObjects()
        }
    }
}
