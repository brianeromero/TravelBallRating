import SwiftUI
import Foundation
import CoreData
import Combine
import CoreLocation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import os

public enum TeamError: Error {
    case invalidInput
    case teamExists
    case geocodingError(String)
    case savingError(String)
    case fieldMissing(String)
    case teamNameMissing
    case streetMissing
    case cityMissing
    case stateMissing
    case postalCodeMissing
    case invalidTeamWebsite

    var localizedDescription: String {
        switch self {
        case .invalidInput:
            return "Invalid input"
        case .teamExists:
            return "Team already exists"
        case .geocodingError(let message):
            return "Geocoding error: \(message)"
        case .savingError(let message):
            return "Error saving data: \(message)"
        case .fieldMissing(let field):
            return "\(field) is required"
        case .teamNameMissing:
            return "Team name is missing"
        case .streetMissing:
            return "Street address is missing"
        case .cityMissing:
            return "City is missing"
        case .stateMissing:
            return "State is missing"
        case .postalCodeMissing:
            return "Postal code is missing"
        case .invalidTeamWebsite:
            return "Confirm website validity"
        }
    }
}

@MainActor
public class TeamViewModel: ObservableObject {
    @Published var coordinates: CLLocationCoordinate2D?
    @Published var selectedDestination: TeamDestination?
    let logger = OSLog(subsystem: "TravelBallRating.Subsystem", category: "CoreData")
    
    private let persistenceController: PersistenceController

    // NO default argument here
    init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
    }


    // MARK: - Create Team
    @MainActor
    func createTeam(
        teamDetails: TeamDetails,
        createdByUserId: String,
        teamWebsite: String?,
        country: String,
        selectedCountry: Country,
        createdByUser: User
    ) async throws -> Team {

        os_log(
            "createTeam called with Team Name: %@, Location: %@",
            log: self.logger,
            type: .info,
            teamDetails.teamName,
            teamDetails.fullAddress
        )

        // Step 1: Validate
        let isValid = try validateTeamDetails(teamDetails, createdByUserId, country, selectedCountry)
        guard isValid else { throw TeamError.invalidInput }

        // Step 2: Update country
        teamDetails.country = country

        // Step 3: Check for duplicates
        guard await !teamExists(name: teamDetails.teamName) else {
            os_log("Team already exists: %@", log: self.logger, type: .error, teamDetails.teamName)
            throw TeamError.teamExists
        }

        // Step 4: Geocode
        let coordinates = try await geocodeAddress(teamDetails.fullAddress.cleanedForGeocoding)

        // Step 5: Create NSManagedObject in a background context
        let backgroundContext = persistenceController.container.newBackgroundContext()
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        // ✅ Thread-safe copies
        let teamName = teamDetails.teamName
        let fullAddress = teamDetails.fullAddress
        let countryName = selectedCountry.name.common
        let latitude = coordinates.latitude
        let longitude = coordinates.longitude
        let teamwebsiteURL = teamDetails.teamWebsiteURL
        let createdBy = createdByUserId

        var newTeamObjectID: NSManagedObjectID!

        try await backgroundContext.perform {
            let newTeam = Team(context: backgroundContext)
            newTeam.teamID = UUID()
            newTeam.teamName = teamName
            newTeam.teamLocation = fullAddress
            newTeam.country = countryName
            newTeam.latitude = latitude
            newTeam.longitude = longitude
            newTeam.createdTimestamp = Date()
            newTeam.createdByUserId = createdBy
            newTeam.lastModifiedByUserId = createdBy
            newTeam.lastModifiedTimestamp = Date()

            // team website
            if let teamwebsiteURL = teamwebsiteURL, !teamwebsiteURL.absoluteString.isEmpty {
                guard teamwebsiteURL.absoluteString.isValidURL() else {
                    os_log("Invalid team website URL: %@", log: self.logger, type: .error, teamwebsiteURL.absoluteString)
                    throw TeamError.invalidTeamWebsite
                }
                newTeam.teamWebsite = teamwebsiteURL
            }

            try backgroundContext.save()
            newTeamObjectID = newTeam.objectID
        }

        // Step 6: Fetch on main context and upload to Firestore
        let mainContextTeam = try persistenceController.container.viewContext.existingObject(with: newTeamObjectID) as! Team
        let teamData = FirestoreTeamData(from: mainContextTeam)
        try await FirestoreManager.shared.saveTeamToFirestore(
            teamData: teamData,
            selectedCountry: selectedCountry,
            createdByUser: createdByUser  // <-- Pass User, not String
            
        )

        return mainContextTeam
    }


    // MARK: - Save to Firestore
    @MainActor
    func saveTeamToFirestore(
        team: Team,
        selectedCountry: Country,
        createdByUser: User
    ) async throws {
        // Capture a safe snapshot of the Core Data object on the Main Actor
        let teamData = FirestoreTeamData(from: team)

        // Log the data being uploaded
        os_log(
            "Saving team to Firestore: %@ (id: %@) — lat: %f, long: %f",
            log: logger,
            type: .info,
            teamData.name,
            teamData.id,
            teamData.latitude,
            teamData.longitude
        )

        // Call Firestore manager (this is an async network call).
        // Running the network call while on MainActor is acceptable here because:
        //  - we've already created a value-type snapshot (teamData),
        //  - FirestoreManager methods are async and will suspend, allowing the main actor to yield.
        try await FirestoreManager.shared.saveTeamToFirestore(
            teamData: teamData,
            selectedCountry: selectedCountry,
            createdByUser: createdByUser
        )

        os_log("Finished saving team to Firestore: %@", log: logger, type: .info, teamData.name)
    }



    // MARK: - Validation
    func validateTeamDetails(
        _ details: TeamDetails,
        _ createdByUserId: String?,
        _ countryCode: String,
        _ selectedCountry: Country?
    ) throws -> Bool {
        do {
            let requiredFields = try getAddressFields(for: selectedCountry?.cca2.uppercased() ?? "")

            let fieldValues: [String: String?] = [
                "street": requiredFields.contains(.street) ? details.street : nil,
                "city": requiredFields.contains(.city) ? details.city : nil,
                "state": requiredFields.contains(.state) ? details.state : nil,
                "province": requiredFields.contains(.province) ? details.province : nil,
                "postalCode": requiredFields.contains(.postalCode) ? details.postalCode : nil,
                "department": requiredFields.contains(.department) ? details.department : nil,
                "county": requiredFields.contains(.county) ? details.county : nil,
                "neighborhood": requiredFields.contains(.neighborhood) ? details.neighborhood : nil,
                "complement": requiredFields.contains(.complement) ? details.complement : nil,
                "block": requiredFields.contains(.block) ? details.block : nil,
                "apartment": requiredFields.contains(.apartment) ? details.apartment : nil,
                "region": requiredFields.contains(.region) ? details.region : nil,
                "district": requiredFields.contains(.district) ? details.district : nil,
                "governorate": requiredFields.contains(.governorate) ? details.governorate : nil,
                "emirate": requiredFields.contains(.emirate) ? details.emirate : nil,
                "island": requiredFields.contains(.island) ? details.island : nil,
                "division": requiredFields.contains(.division) ? details.division : nil,
                "zone": requiredFields.contains(.zone) ? details.zone : nil
            ]

            for (fieldName, value) in fieldValues {
                os_log("Validating %@: %@", log: logger, fieldName, value ?? "nil")
                let camelCaseFieldName = fieldName.capitalizingFirstLetter()
                
                if let field = AddressField(rawValue: camelCaseFieldName),
                   let fieldType = AddressFieldType(rawValue: field.rawValue),
                   requiredFields.contains(fieldType) {
                    
                    if value?.trimmingCharacters(in: .whitespaces).isEmpty ?? true {
                        os_log("Validation failed: %@ is missing (%@)", log: logger, fieldName, value ?? "nil")
                        throw TeamError.fieldMissing(fieldName)
                    }
                }
            }

            return true
        } catch {
            os_log(
                "Error getting address fields for country code %@: %@",
                log: logger,
                countryCode,
                "\(error)"
            )
            throw error
        }
    }

    // MARK: - Check Existing Team
    func teamExists(name: String) async -> Bool {
        let context = persistenceController.viewContext
        let logger = self.logger

        return await context.perform {
            let fetchRequest = Team.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "teamName ==[c] %@", name)
            fetchRequest.fetchLimit = 1

            do {
                let count = try context.count(for: fetchRequest)
                return count > 0
            } catch {
                os_log("Error checking existing teams: %@", log: logger, error.localizedDescription)
                return false
            }
        }
    }

    // MARK: - Update Team
    func updateTeam(id: String, data: [String: Any]) async throws {
        if FirestoreManager.shared.disabled { return }
        print("Updating team with id: \(id)")
        try await FirestoreManager.shared.updateDocument(in: .teams, id: id, data: data)
        print("Team updated successfully")
    }

    // MARK: - Delete Team
    @MainActor
    func deleteTeam(_ team: Team) async throws {
        let context = PersistenceController.shared.viewContext

        guard let teamID = team.teamID?.uuidString else {
            throw NSError(
                domain: "TeamViewModel",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Team has no ID"]
            )
        }

        // 1️⃣ Delete from Firestore
        do {
            try await Firestore.firestore()
                .collection("teams")
                .document(teamID)
                .delete()
            print("✅ Deleted Team \(team.teamName) from Firestore.")
        } catch {
            print("❌ Failed to delete Team from Firestore: \(error.localizedDescription)")
            throw error
        }

        // 2️⃣ Delete from Core Data
        context.delete(team)
        do {
            try context.save()
            print("✅ Deleted Team \(team.teamName) from Core Data.")
        } catch {
            print("❌ Failed to delete Team from Core Data: \(error.localizedDescription)")
            throw error
        }
    }
}

// MARK: - String Helpers
extension String {
    func capitalizingFirstLetter() -> String {
        prefix(1).uppercased() + dropFirst()
    }

    var cleanedForGeocoding: String {
        replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func isValidURL() -> Bool {
        guard let url = URL(string: self), UIApplication.shared.canOpenURL(url) else {
            return false
        }
        return true
    }
}

@MainActor
extension TeamViewModel {

    /// Create a new Team for a Team
    func createTeam(
        teamName: String,
        sport: String,
        gender: String,
        ageGroup: String,
        coachName: String,
        contactEmail: String,
        createdByUser: User
    ) async throws -> Team {

        // 1️⃣ Validation
        guard !teamName.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw TeamError.fieldMissing("Team Name")
        }
        guard !contactEmail.trimmingCharacters(in: .whitespaces).isEmpty, contactEmail.contains("@") else {
            throw TeamError.fieldMissing("Valid Email")
        }

        // 2️⃣ Create Team object in Core Data (or Firestore first, if desired)
        let context = persistenceController.container.viewContext
        let newTeam = Team(context: context)
        newTeam.teamID = UUID()
        newTeam.teamName = teamName
        newTeam.sport = sport
        newTeam.gender = gender
        newTeam.ageGroup = ageGroup
        newTeam.coachName = coachName
        newTeam.contactEmail = contactEmail
        newTeam.createdByUserId = createdByUser.userID
        newTeam.createdTimestamp = Date()

        // Save to Core Data
        try context.save()

        // Optionally save to Firestore
        do {
            let teamData = FirestoreTeamData(from: newTeam)
            try await FirestoreManager.shared.saveTeamToFirestore(teamData: teamData, createdByUser: createdByUser)
        } catch {
            os_log("Failed to save Team to Firestore: %@", type: .error, "\(error)")
            throw error
        }

        os_log("Team created successfully: %@", type: .info, teamName)
        return newTeam
    }
}
