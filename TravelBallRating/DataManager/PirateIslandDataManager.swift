//
//  TeamDataManager.swift
//  TravelBallRating
//
//  Created by Brian Romero on 8/5/24.
//

import Foundation
import CoreData

public class TeamDataManager: ObservableObject {
    internal var viewContext: NSManagedObjectContext

    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }

    enum FetchError: Error {
        case failedFetchingTeam(Error)
        case unknownError(Error)
        case coreDataError(Error)
    }

    enum PersistenceError: Error {
        case invalidRecordId(String)
        case recordNotFound(String)
        case mockError(String)
    }

    func fetchTeams(sortDescriptors: [NSSortDescriptor]? = nil,
                             predicate: NSPredicate? = nil,
                             fetchLimit: Int? = nil) -> Result<[Team], FetchError> {
        var result: Result<[Team], FetchError>!
        
        viewContext.performAndWait {
            let fetchRequest: NSFetchRequest<Team> = Team.fetchRequest()
            fetchRequest.sortDescriptors = sortDescriptors
            fetchRequest.predicate = predicate
            if let fetchLimit = fetchLimit {
                fetchRequest.fetchLimit = fetchLimit
            }
            do {
                let teams = try self.viewContext.fetch(fetchRequest)
                print("💾 TeamDataManager: fetched \(teams.count) teams: \(teams.map { $0.teamName ?? "Unknown" })")
                result = .success(teams)
            } catch let error {
                result = .failure(.failedFetchingTeams(error))
            }
        }
        return result
    }

    func fetchLocalTeam(withId id: String) async throws -> Team? {
        guard let uuid = UUID(uuidString: id) else {
            throw PersistenceError.invalidRecordId(id)
        }
        return try await fetchTeam(uuid: uuid)
    }

    private func fetchTeam(uuid: UUID) async throws -> Team? {
        let predicate = NSPredicate(format: "teamID == %@", uuid as CVarArg)
        let result = fetchTeams(predicate: predicate, fetchLimit: 1)
        switch result {
        case .success(let teams):
            if !teams.isEmpty { return teams.first }
            else { throw PersistenceError.recordNotFound(uuid.uuidString) }
        case .failure(let error):
            throw error
        }
    }
}

// MARK: - Async wrapper extension
extension TeamDataManager {
    /// Async wrapper around the existing synchronous fetchTeams
    func fetchTeamsAsync(sortDescriptors: [NSSortDescriptor]? = nil,
                                 predicate: NSPredicate? = nil,
                                 fetchLimit: Int? = nil) async throws -> [Team] {
        try await withCheckedThrowingContinuation { continuation in
            let result = self.fetchTeams(sortDescriptors: sortDescriptors,
                                                 predicate: predicate,
                                                 fetchLimit: fetchLimit)
            switch result {
            case .success(let teams):
                continuation.resume(returning: teams)
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
    }
}
