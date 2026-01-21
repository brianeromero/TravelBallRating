//
//  TeamDetails.swift
//  Mat_Finder
//

import Foundation
import Combine
import os


public class TeamDetails: ObservableObject, Equatable {
    // MARK: - Published Properties
    @Published var teamName: String = "" { didSet { validateForm() } }
    @Published var street: String = "" { didSet { validateForm() } }
    @Published var city: String = "" { didSet { validateForm() } }
    @Published var state: String = "" { didSet { validateForm() } }
    @Published var postalCode: String = "" { didSet { validateForm() } }
    @Published var requiredAddressFields: [AddressFieldType] = []
            
    @Published var selectedCountry: Country? {
        didSet {
            updateRequiredAddressFields()
        }
    }
            
    @Published var teamWebsite: String = "" { didSet { validateForm() } }
    @Published var teamWebsiteURL: URL?

    @Published var neighborhood: String = "" { didSet { validateForm() } }
    @Published var complement: String = "" { didSet { validateForm() } }
    @Published var block: String = "" { didSet { validateForm() } }
    @Published var apartment: String = "" { didSet { validateForm() } }
    @Published var region: String = "" { didSet { validateForm() } }
    @Published var country: String = "" { didSet { validateForm() } }
    @Published var county: String = "" { didSet { validateForm() } }
    @Published var governorate: String = "" { didSet { validateForm() } }
    @Published var province: String = "" { didSet { validateForm() } }
    @Published var district: String = "" { didSet { validateForm() } }
    @Published var department: String = "" { didSet { validateForm() } }
    @Published var emirate: String = "" { didSet { validateForm() } }
    @Published var parish: String = "" { didSet { validateForm() } }
    @Published var entity: String = "" { didSet { validateForm() } }
    @Published var municipality: String = "" { didSet { validateForm() } }
    @Published var division: String = "" { didSet { validateForm() } }
    @Published var zone: String = "" { didSet { validateForm() } }
    @Published var island: String = "" { didSet { validateForm() } }
    
    // MARK: - Validation Properties
    @Published var isTeamNameValid: Bool = true
    @Published var teamNameErrorMessage: String = ""
    @Published var isFormValid: Bool = false

    // Callback to notify parent views of validation state
    var onValidationChange: ((Bool) -> Void)?

    // MARK: - Other Properties
    @Published var latitude: Double?
    @Published var longitude: Double?
    @Published var multilineAddress: String = ""
    @Published var additionalInfo: String = ""

    // ADD THIS NEW PROPERTY:
    @Published var teamID: UUID? // This is crucial for linking to an existing Team

    // MARK: - Computed Properties
    var teamLocation: String {
        let locationComponents = requiredAddressFields.compactMap { field -> String? in
            switch field {
            case .street: return street
            case .city: return city
            case .state: return state
            case .postalCode: return postalCode
            case .county: return county
            case .parish: return parish
            case .entity: return entity
            case .municipality: return municipality
            case .division: return division
            case .zone: return zone
            case .island: return island
            default: return nil
            }
        }
        return locationComponents.filter { !$0.isEmpty }.joined(separator: ", ")
    }
    
    var fullAddress: String {
        var address = [teamLocation]

        if let selectedCountry = selectedCountry, !selectedCountry.name.common.isEmpty {
            address.append(selectedCountry.name.common)  // Use selectedCountry
        } else if !country.isEmpty {
            address.append(country)  // Fallback to manually entered country
        }

        let computedAddress = address.filter { !$0.isEmpty }.joined(separator: "\n")
        os_log("Computed fullAddress: %@", log: .default, type: .debug, computedAddress)
        return computedAddress
    }

    // MARK: - Initializer
    init(teamName: String = "",
         street: String = "",
         city: String = "",
         state: String = "",
         postalCode: String = "",
         latitude: Double? = nil,
         longitude: Double? = nil,
         selectedCountry: Country? = nil,
         country: String = "",
         county: String = "",
         additionalInfo: String = "",
         requiredAddressFields: [AddressFieldType] = [],
         teamWebsite: String = "",
         teamWebsiteURL: URL? = nil,
         teamID: UUID? = nil) { // ADD THIS PARAMETER TO THE INITIALIZER
        self.teamName = teamName
        self.street = street
        self.city = city
        self.state = state
        self.postalCode = postalCode
        self.latitude = latitude
        self.longitude = longitude
        self.selectedCountry = selectedCountry
        self.country = country
        self.county = county
        self.additionalInfo = additionalInfo
        self.requiredAddressFields = requiredAddressFields
        self.teamWebsite = teamWebsite
        self.teamWebsiteURL = teamWebsiteURL
        self.teamID = teamID // ASSIGN THE NEW PROPERTY
        validateForm()
    }
    
    // MARK: - Validation Logic
    private func validateForm() {
        //os_log("Validating form 789: teamName = %@", log: .default, type: .debug, teamName)

        let fieldsValid = requiredAddressFields.allSatisfy { field in
            switch field {
            case .street: return !street.isEmpty
            case .city: return !city.isEmpty
            case .state: return !state.isEmpty
            case .postalCode: return !postalCode.isEmpty
            case .county: return !county.isEmpty
            case .province: return !province.isEmpty
            case .region: return !region.isEmpty
            case .district: return !district.isEmpty
            case .department: return !department.isEmpty
            case .governorate: return !governorate.isEmpty
            case .emirate: return !emirate.isEmpty
            case .block: return !block.isEmpty
            case .neighborhood: return !neighborhood.isEmpty
            case .complement: return !complement.isEmpty
            case .apartment: return !apartment.isEmpty
            case .additionalInfo: return !additionalInfo.isEmpty
            case .multilineAddress: return !multilineAddress.isEmpty
            case .parish: return !parish.isEmpty
            case .entity: return !entity.isEmpty
            case .municipality: return !municipality.isEmpty
            case .division: return !division.isEmpty
            case .zone: return !zone.isEmpty
            case .island: return !island.isEmpty
            }
        }

        isTeamNameValid = !teamName.isEmpty
        teamNameErrorMessage = isTeamNameValid ? "" : "Team name cannot be empty."

        isFormValid = fieldsValid && isTeamNameValid
        onValidationChange?(isFormValid)
    }

    
    // MARK: - Update Required Address
    func updateRequiredAddressFields() {
        guard let countryCode = selectedCountry?.cca2 else {
            requiredAddressFields = defaultAddressFieldRequirements
            return
        }

        do {
            requiredAddressFields = try getAddressFields(for: countryCode)
            validateForm()
        } catch {
            os_log("Error getting address fields for country code: %@", log: OSLog.default, type: .error, countryCode)
            requiredAddressFields = defaultAddressFieldRequirements
            validateForm()
        }
    }
    
    // MARK: - Equatable Protocol
    public static func == (lhs: TeamDetails, rhs: TeamDetails) -> Bool {
        lhs.teamName == rhs.teamName &&
        lhs.street == rhs.street &&
        lhs.city == rhs.city &&
        lhs.state == rhs.state &&
        lhs.postalCode == rhs.postalCode &&
        lhs.selectedCountry?.cca2 == rhs.selectedCountry?.cca2 &&
        lhs.latitude == rhs.latitude &&
        lhs.longitude == rhs.longitude &&
        lhs.additionalInfo == rhs.additionalInfo &&
        lhs.country == rhs.country &&
        lhs.county == rhs.county &&
        lhs.province == rhs.province &&  // Added province
        lhs.region == rhs.region &&      // Added region
        lhs.island == rhs.island &&
        lhs.teamWebsite == rhs.teamWebsite && // Added teamWebsite
        lhs.teamID == rhs.teamID // ADD THIS FOR EQUATABLE
    }

}

extension TeamDetails: CustomStringConvertible {
    public var description: String {
        return """
        TeamDetails:
        - ID: \(teamID?.uuidString ?? "nil")
        - Name: \(teamName)
        - Street: \(street)
        - City: \(city)
        - State: \(state)
        - Postal Code: \(postalCode)
        - Country Code: \(selectedCountry?.cca2 ?? country)
        - team Website: \(teamWebsite)
        - County: \(county)
        - Region: \(region)
        - Province: \(province)
        - District: \(district)
        - Latitude: \(latitude?.description ?? "nil")
        - Longitude: \(longitude?.description ?? "nil")
        - Required Fields: \(requiredAddressFields.map { "\($0)" }.joined(separator: ", "))
        """
    }
}
