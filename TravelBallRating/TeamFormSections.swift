import SwiftUI
import Foundation
import CoreData
import Combine
import CoreLocation
import os


// MARK: - Country Address Format
struct CountryAddressFormat {
    let requiredFields: [AddressFieldType] // Change this line
    let postalCodeValidationRegex: String?
}

let countryAddressFormats: [String: CountryAddressFormat] = addressFieldRequirements.reduce(into: [:]) { result, entry in
    let countryCode = entry.key.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
    result[countryCode] = CountryAddressFormat(
        requiredFields: entry.value,
        postalCodeValidationRegex: ValidationUtility.postalCodeRegexPatterns[countryCode]
    )
}


func getPostalCodeValidationRegex(for country: String) -> String? {
    return ValidationUtility.postalCodeRegexPatterns[country]
}

struct TeamFormationSections: View {
    @ObservedObject var viewModel: TeamViewModel
    @ObservedObject var profileViewModel: ProfileViewModel
    @ObservedObject var countryService = CountryService.shared

    @Binding var teamName: String
    @Binding var street: String
    @Binding var city: String
    @Binding var state: String
    @Binding var postalCode: String

    @Binding var teamDetails: TeamDetails
    @Binding var selectedCountry: Country?
    @Binding var teamWebsite: String
    @Binding var teamWebsiteURL: URL?
    
    // Additional Bindings
    @Binding var province: String
    @Binding var neighborhood: String
    @Binding var complement: String
    @Binding var apartment: String
    @Binding var region: String
    @Binding var county: String
    @Binding var governorate: String
    @Binding var additionalInfo: String
    @Binding var department: String
    @Binding var parish: String
    @Binding var district: String
    @Binding var entity: String
    @Binding var municipality: String
    @Binding var division: String
    @Binding var emirate: String
    @Binding var zone: String
    @Binding var block: String
    @Binding var island: String

    
    // Validation Bindings
    @Binding var isTeamNameValid: Bool
    @Binding var teamNameErrorMessage: String
    @Binding var isFormValid: Bool
    
    // Alerts and Toasts
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isPickerPresented = false
    @State private var showValidationMessage = false
    @State private var successMessage: String? = nil
    @State private var showErrorAlert = false
    @State private var showToast = false
    @State private var toastMessage = ""
    
    
    // Binding the formState
    @Binding var formState: FormState

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Country Picker Section
            countryPickerSection
            
            // Team Details Section
            teamDetailsSection
            
            // Website Section
            websiteSection
        }
        .padding(.horizontal)   // consistent padding
        .padding(.top)
        .onAppear {
            Task { await countryService.fetchCountries() }
        }
        .alert(isPresented: $showError) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    // MARK: - Country Picker Section
    var countryPickerSection: some View {
        if countryService.isLoading {
            AnyView(ProgressView("Loading countries..."))
        } else if countryService.countries.isEmpty {
            AnyView(Text("No countries found.")
                .font(.caption)
                .foregroundColor(.secondary))
        } else {
            AnyView(UnifiedCountryPickerView(
                countryService: countryService,
                selectedCountry: $selectedCountry,
                isPickerPresented: $isPickerPresented
            )
                .onChange(of: selectedCountry) { oldCountry, newCountry in // Use the new signature
                if let countryCode = newCountry?.cca2 {
                    // Normalize the country code
                    let normalizedCountryCode = countryCode.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    print("Normalized Country Code Set7896: \(normalizedCountryCode)") // Print the normalized code
                    
                    // Fetch address fields using the safe method
                    let addressFields = getAddressFieldsSafely(for: normalizedCountryCode)
                    print("Address Fields Required789: \(addressFields)")
                } else {
                    print("No country selected789")
                }
                // Update address requirements for the new selected country
                updateAddressRequirements(for: newCountry)
            })
        }
    }

    
    // MARK: - Team Details Section
    var teamDetailsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("team Name")
                .font(.headline)

            TextField("Enter team Name", text: $teamDetails.teamName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.body)
                .onChange(of: teamDetails.teamName) { oldValue, newValue in
                    print("🏝️ team Name Updated: \(newValue)")
                    validateFields()
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())

            // Address Fields View
            let requiredFields = getAddressFieldsSafely(for: selectedCountry?.cca2)

            VStack(alignment: .leading, spacing: 12) {
                // Dynamically generate address fields
                ForEach(requiredFields, id: \.self) { field in
                    addressField(for: field)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: getValue(for: field)) { oldValue, newValue in
                            print("✏️ Field '\(field.rawValue)' updated: \(newValue)")
                            validateFields()
                        }
                }
            }
            .padding(.top)
            .onAppear {
                print("📋 Required address fields for \(selectedCountry?.cca2 ?? "nil"): \(requiredFields.map { $0.rawValue })")
            }

            // Validation message
            let missingFields = getMissingRequiredFields(for: selectedCountry?.cca2)
            if !teamDetails.teamName.isEmpty && showValidationMessage && !missingFields.isEmpty {
                Text("Required fields are missing: \(missingFields.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.red)
                    .onAppear {
                        print("❌ Missing fields: \(missingFields)")
                    }
            }
        }
    }

    
    private func getMissingRequiredFields(for countryCode: String?) -> [String] {
        let requiredFields = getAddressFieldsSafely(for: countryCode)
        var missingFields: [String] = []

        for field in requiredFields {
            let value = getValue(for: field).trimmingCharacters(in: .whitespacesAndNewlines)
            if value.isEmpty {
                missingFields.append(field.rawValue)
            }
        }

        return missingFields
    }



    // MARK: - Address Field Dynamic Generation
    @ViewBuilder
    func addressField(for field: AddressFieldType) -> some View {
        switch field {
        case .street:
            TextField("Street", text: $teamDetails.street)
        case .city:
            TextField("City", text: $teamDetails.city)
        case .state:
            if selectedCountry?.cca2 == "US" {
                Picker("State", selection: $teamDetails.state) {

                    // Blank default option
                    Text("Select State").tag("")

                    // Actual US states list
                    ForEach(USStates.allCodes.sorted(), id: \.self) { code in
                        Text(code).tag(code)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            } else {
                TextField("State / Province / Region", text: $teamDetails.state)
            }


        case .postalCode:
            TextField("Postal Code", text: $teamDetails.postalCode)
        case .province:
            TextField("Province", text: $teamDetails.province)
        case .neighborhood:
            TextField("Neighborhood", text: $teamDetails.neighborhood)
        case .complement:
            TextField("Complement", text: $teamDetails.complement)
        case .apartment:
            TextField("Apartment", text: $teamDetails.apartment)
        case .region:
            TextField("Region", text: $teamDetails.region)
        case .county:
            TextField("County", text: $teamDetails.county)
        case .governorate:
            TextField("Governorate", text: $teamDetails.governorate)
        case .additionalInfo:
            TextField("Additional Info", text: $teamDetails.additionalInfo)
        case .island:
            TextField("Island", text: $teamDetails.island)
        case .department:
            TextField("Department", text: $teamDetails.department)  // Added
        case .parish:
            TextField("Parish", text: $teamDetails.parish)  // Added
        case .district:
            TextField("District", text: $teamDetails.district)  // Added
        case .entity:
            TextField("Entity", text: $teamDetails.entity)  // Added
        case .municipality:
            TextField("Municipality", text: $teamDetails.municipality)  // Added
        case .division:
            TextField("Division", text: $teamDetails.division)  // Added
        case .emirate:
            TextField("Emirate", text: $teamDetails.emirate)  // Added
        case .zone:
            TextField("Zone", text: $teamDetails.zone)  // Added
        case .block:
            TextField("Block", text: $teamDetails.block)  // Added
        default:
            EmptyView()
        }
    }

    
    // MARK: - Website Section
    var websiteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Instagram/Facebook/Website")
                .font(.headline)
            TextField("Enter Instagram/Facebook/Website", text: $teamDetails.teamWebsite)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.body)
                // Fix 3: Update onChange syntax
                .onChange(of: teamDetails.teamWebsite) { oldWebsite, newWebsite in // Use the new signature
                    processWebsiteURL(newWebsite)
                }
        }
    }

    
    private func getValue(for field: AddressFieldType) -> String {
        // Use a dictionary to map fields to values dynamically
        let fieldValues: [AddressFieldType: String] = [
            .state: teamDetails.state,
            .postalCode: teamDetails.postalCode,
            .street: teamDetails.street,
            .city: teamDetails.city,
            .province: teamDetails.province,
            .region: teamDetails.region,
            .district: teamDetails.district,
            .department: teamDetails.department,
            .governorate: teamDetails.governorate,
            .emirate: teamDetails.emirate,
            .block: teamDetails.block,
            .county: teamDetails.county,
            .neighborhood: teamDetails.neighborhood,
            .complement: teamDetails.complement,
            .apartment: teamDetails.apartment,
            .additionalInfo: teamDetails.additionalInfo,
            .multilineAddress: teamDetails.multilineAddress,
            .parish: teamDetails.parish,
            .entity: teamDetails.entity,
            .municipality: teamDetails.municipality,
            .division: teamDetails.division,
            .zone: teamDetails.zone,
            .island: teamDetails.island
        ]
        
        return fieldValues[field] ?? ""
    }


    func processWebsiteURL(_ url: String) {
        guard !url.isEmpty else {
            teamDetails.teamWebsiteURL = nil
            return
        }
        let sanitizedURL = "https://" + stripProtocol(from: url)
        if ValidationUtility.validateURL(sanitizedURL) == nil {
            teamDetails.teamWebsiteURL = URL(string: sanitizedURL)
        } else {
            errorMessage = "Invalid URL format"
            showError = true
        }
    }
    
    var requiredAddressFields: [AddressFieldType] {
        guard let countryCode = selectedCountry?.cca2 else {
            return defaultAddressFieldRequirements
        }

        return getAddressFieldsSafely(for: countryCode)
    }



    func stripProtocol(from urlString: String) -> String {
        if urlString.lowercased().starts(with: "http://") {
            return String(urlString.dropFirst(7))
        } else if urlString.lowercased().starts(with: "https://") {
            return String(urlString.dropFirst(8))
        }
        return urlString
    }
    
    func validateTeamDetails() async {
        guard !teamDetails.teamName.isEmpty else {
            setError("team name is required.")
            return
        }

        // Ensure selectedCountry is non-nil and has a valid cca2 code
        guard let selectedCountry = selectedCountry, !selectedCountry.cca2.isEmpty else {
            setError("Please select a valid country.")
            return
        }

        // Proceed to validate the address based on cca2
        if validateAddress(for: selectedCountry.cca2) {
            await updateTeamLocation()
        } else {
            setError("Please fill in all required address fields.")
        }
    }

    func validateAddress(for country: String?) -> Bool {
        guard !teamDetails.teamName.isEmpty else { return true } // Skip validation if teamName is empty

        // Ensure the country is provided and not empty
        guard let countryName = country, !countryName.isEmpty else { return false }

        // Create the Country object using countryName
        let selectedCountry = Country(name: .init(common: countryName), cca2: "", flag: "")

        // Get the required fields for the selected country (using Country object)
        _ = requiredFields(for: selectedCountry)  // Now passing the Country object
        var isValid = true

        // Create a dictionary to map AddressField enum values to FormState properties
        let errorMessages: [AddressField: (String, String)] = [
            .state: ("State is required for \(countryName).", "stateErrorMessage"),
            .postalCode: ("Postal Code is required for \(countryName).", "postalCodeErrorMessage"),
            .street: ("Street is required for \(countryName).", "streetErrorMessage"),
            .city: ("City is required for \(countryName).", "cityErrorMessage"),
            .province: ("Province is required for \(countryName).", "provinceErrorMessage"),
            .region: ("Region is required for \(countryName).", "regionErrorMessage"),
            .district: ("District is required for \(countryName).", "districtErrorMessage"),
            .department: ("Department is required for \(countryName).", "departmentErrorMessage"),
            .governorate: ("Governorate is required for \(countryName).", "governorateErrorMessage"),
            .emirate: ("Emirate is required for \(countryName).", "emirateErrorMessage"),
            .county: ("County is required for \(countryName).", "countyErrorMessage"),
            .neighborhood: ("Neighborhood is required for \(countryName).", "neighborhoodErrorMessage"),
            .complement: ("Complement is required for \(countryName).", "complementErrorMessage"),
            .block: ("Block is required for \(countryName).", "blockErrorMessage"),
            .apartment: ("Apartment is required for \(countryName).", "apartmentErrorMessage"),
            .additionalInfo: ("Additional Info is required for \(countryName).", "additionalInfoErrorMessage"),
            .multilineAddress: ("Multiline Address is required for \(countryName).", "multilineAddressErrorMessage"),
            .parish: ("Parish is required for \(countryName).", "parishErrorMessage"),
            .entity: ("Entity is required for \(countryName).", "entityErrorMessage"),
            .municipality: ("Municipality is required for \(countryName).", "municipalityErrorMessage"),
            .division: ("Division is required for \(countryName).", "divisionErrorMessage"),
            .zone: ("Zone is required for \(countryName).", "zoneErrorMessage"),
            .island: ("Island is required for \(countryName).", "islandErrorMessage"),
            .country: ("Country is required for \(countryName).", "countryErrorMessage"),
        ]

        // Iterate over all fields in the AddressField enum
        for field in AddressField.allCases {
            switch field {
            case .state:
                if teamDetails.state.isEmptyOrWhitespace {
                    formState.stateErrorMessage = errorMessages[field]?.0 ?? ""
                    isValid = false
                } else {
                    formState.stateErrorMessage = ""
                }
            case .postalCode:
                if teamDetails.postalCode.isEmptyOrWhitespace {
                    formState.postalCodeErrorMessage = errorMessages[field]?.0 ?? ""
                    isValid = false
                } else {
                    formState.postalCodeErrorMessage = ""
                }
            case .street:
                if teamDetails.street.isEmptyOrWhitespace {
                    formState.streetErrorMessage = errorMessages[field]?.0 ?? ""
                    isValid = false
                } else {
                    formState.streetErrorMessage = ""
                }
            case .city:
                if teamDetails.city.isEmptyOrWhitespace {
                    formState.cityErrorMessage = errorMessages[field]?.0 ?? ""
                    isValid = false
                } else {
                    formState.cityErrorMessage = ""
                }
            case .province:
                if teamDetails.province.isEmptyOrWhitespace {
                    formState.provinceErrorMessage = errorMessages[field]?.0 ?? ""
                    isValid = false
                } else {
                    formState.provinceErrorMessage = ""
                }
            case .region:
                if teamDetails.region.isEmptyOrWhitespace {
                    formState.regionErrorMessage = errorMessages[field]?.0 ?? ""
                    isValid = false
                } else {
                    formState.regionErrorMessage = ""
                }
            case .district:
                if teamDetails.district.isEmptyOrWhitespace {
                    formState.districtErrorMessage = errorMessages[field]?.0 ?? ""
                    isValid = false
                } else {
                    formState.districtErrorMessage = ""
                }
            case .department:
                if teamDetails.department.isEmptyOrWhitespace {
                    formState.departmentErrorMessage = errorMessages[field]?.0 ?? ""
                    isValid = false
                } else {
                    formState.departmentErrorMessage = ""
                }
            case .governorate:
                if teamDetails.governorate.isEmptyOrWhitespace {
                    formState.governorateErrorMessage = errorMessages[field]?.0 ?? ""
                    isValid = false
                } else {
                    formState.governorateErrorMessage = ""
                }
            case .emirate:
                if teamDetails.emirate.isEmptyOrWhitespace {
                    formState.emirateErrorMessage = errorMessages[field]?.0 ?? ""
                    isValid = false
                } else {
                    formState.emirateErrorMessage = ""
                }
            case .county:
                if teamDetails.county.isEmptyOrWhitespace {
                    formState.countyErrorMessage = errorMessages[field]?.0 ?? ""
                    isValid = false
                } else {
                    formState.countyErrorMessage = ""
                }
            case .neighborhood:
                if teamDetails.neighborhood.isEmptyOrWhitespace {
                    formState.neighborhoodErrorMessage = errorMessages[field]?.0 ?? ""
                    isValid = false
                } else {
                    formState.neighborhoodErrorMessage = ""
                }
            case .complement:
                if teamDetails.complement.isEmptyOrWhitespace {
                    formState.complementErrorMessage = errorMessages[field]?.0 ?? ""
                    isValid = false
                } else {
                    formState.complementErrorMessage = ""
                }
            case .block:
                if teamDetails.block.isEmptyOrWhitespace {
                    formState.blockErrorMessage = errorMessages[field]?.0 ?? ""
                    isValid = false
                } else {
                    formState.blockErrorMessage = ""
                }
            case .apartment:
                if teamDetails.apartment.isEmptyOrWhitespace {
                    formState.apartmentErrorMessage = errorMessages[field]?.0 ?? ""
                    isValid = false
                } else {
                    formState.apartmentErrorMessage = ""
                }
            case .additionalInfo:
                if teamDetails.additionalInfo.isEmptyOrWhitespace {
                    formState.additionalInfoErrorMessage = errorMessages[field]?.0 ?? ""
                    isValid = false
                } else {
                    formState.additionalInfoErrorMessage = ""
                }
            case .multilineAddress:
                if teamDetails.multilineAddress.isEmptyOrWhitespace {
                    formState.multilineAddressErrorMessage = errorMessages[field]?.0 ?? ""
                    isValid = false
                } else {
                    formState.multilineAddressErrorMessage = ""
                }
            case .parish:
                if teamDetails.parish.isEmptyOrWhitespace {
                    formState.parishErrorMessage = errorMessages[field]?.0 ?? ""
                    isValid = false
                } else {
                    formState.parishErrorMessage = ""
                }
            case .entity:
                if teamDetails.entity.isEmptyOrWhitespace {
                    formState.entityErrorMessage = errorMessages[field]?.0 ?? ""
                    isValid = false
                } else {
                    formState.entityErrorMessage = ""
                }
            case .municipality:
                if teamDetails.municipality.isEmptyOrWhitespace {
                    formState.municipalityErrorMessage = errorMessages[field]?.0 ?? ""
                    isValid = false
                } else {
                    formState.municipalityErrorMessage = ""
                }
            case .division:
                if teamDetails.division.isEmptyOrWhitespace {
                    formState.divisionErrorMessage = errorMessages[field]?.0 ?? ""
                    isValid = false
                } else {
                    formState.divisionErrorMessage = ""
                }
            case .zone:
                if teamDetails.zone.isEmptyOrWhitespace {
                    formState.zoneErrorMessage = errorMessages[field]?.0 ?? ""
                    isValid = false
                } else {
                    formState.zoneErrorMessage = ""
                }
            case .island:
                if teamDetails.team.isEmptyOrWhitespace {
                    formState.islandErrorMessage = errorMessages[field]?.0 ?? ""
                    isValid = false
                } else {
                    formState.islandErrorMessage = ""
                }
            case .country:
                if teamDetails.country.isEmptyOrWhitespace {
                    formState.countryErrorMessage = errorMessages[field]?.0 ?? ""
                    isValid = false
                } else {
                    formState.countryErrorMessage = ""
                }
            }
        }

        return isValid
    }

    func getAddressFieldsSafely(for countryCode: String?) -> [AddressFieldType] {
        guard let countryCode = countryCode?.uppercased().trimmingCharacters(in: .whitespacesAndNewlines) else {
            return defaultAddressFieldRequirements
        }
        if let format = countryAddressFormats[countryCode] {
            return format.requiredFields
        } else {
            os_log("⚠️ No specific address format found for %@", countryCode)
            return defaultAddressFieldRequirements
        }
    }


    private func validateForm() {
        print("validateForm() called: teamName = \(teamName)")
        
        // 🧠 Debugging output
        print("Validating fields for \(selectedCountry?.cca2 ?? "nil")")
        print("Required fields: \(requiredAddressFields.map { $0.rawValue })")

        // Validate team name
        let teamNameValid = !teamName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        isTeamNameValid = teamNameValid
        teamNameErrorMessage = teamNameValid ? "" : "team name cannot be empty."

        // Validate address fields if teamName is provided
        if teamNameValid {
            var allFieldsValid = true

            for field in requiredAddressFields {
                let value = getValue(for: field)
                let isEmpty = value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                if isEmpty { allFieldsValid = false }
                formState.setErrorMessage(for: field, isEmpty: isEmpty)
            }

            showValidationMessage = !allFieldsValid && teamNameValid
        } else {
            showValidationMessage = true
        }
    }



    

    func isValidPostalCode(_ postalcode: String, regex: String?) -> Bool {
        guard let regex = regex else { return true }
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: teamDetails.postalCode)
    }

    
    func validateTeamNameAndAddress() -> Bool {
        // Validate the team name
        guard !teamDetails.teamName.isEmpty else {
            setError("team name is required.")
            return false
        }

        // Validate that a country is selected
        guard let selectedCountry = selectedCountry, !selectedCountry.cca2.isEmpty else {
            setError("Select a country.")
            return false
        }

        // Pass the country's cca2 to validateAddress
        guard validateAddress(for: selectedCountry.cca2) else {
            setError("Please fill in all required address fields.")
            return false
        }

        return true
    }

    
    // MARK: - Address Fields
    func requiredFields(for country: Country?) -> [AddressFieldType] {
        guard let countryCode = country?.cca2 else {
            // If there's no country code, return the default address fields, ensuring all fallbacks are handled correctly
            return defaultAddressFieldRequirements.map { field in
                AddressFieldType(rawValue: field.rawValue) ?? .street // Provide .street as the fallback case
            }
        }
        
        // If country code exists, use the country-specific address format
        return countryAddressFormats[countryCode]?.requiredFields.map { field in
            // Ensure AddressFieldType is converted from the raw value, fallback to .street if conversion fails
            AddressFieldType(rawValue: field.rawValue) ?? .street
        } ?? defaultAddressFieldRequirements.map { field in
            // Handle case where countryAddressFormats doesn't have a valid format
            AddressFieldType(rawValue: field.rawValue) ?? .street // Fallback to .street
        }
    }


    func updateAddressRequirements(for country: Country?) {
        teamDetails.requiredAddressFields = requiredFields(for: country)
    }
    
    

    // MARK: - Validation Logic
    func validateFields() {
        // Skip validation if team Name is empty
        if teamDetails.teamName.isEmpty {
            showValidationMessage = false
            return
        }

        let requiredFields = requiredFields(for: selectedCountry)
        var invalidFields: [String] = []

        // Directly reference your formState property here
        let formState = self.formState  // Assuming formState is a property in the current context
        
        let allValid = requiredFields.allSatisfy { field in
            // Access the corresponding FormState property
            let isValid: Bool
            
            switch field {
            case .street:
                isValid = formState.isStreetValid
            case .city:
                isValid = formState.isCityValid
            case .state:
                isValid = formState.isStateValid
            case .province:
                isValid = formState.isProvinceValid
            case .postalCode:
                isValid = formState.isPostalCodeValid
            case .region:
                isValid = formState.isRegionValid
            case .district:
                isValid = formState.isDistrictValid
            case .department:
                isValid = formState.isDepartmentValid
            case .governorate:
                isValid = formState.isGovernorateValid
            case .emirate:
                isValid = formState.isEmirateValid
            case .block:
                isValid = formState.isBlockValid
            case .county:
                isValid = formState.isCountyValid
            case .neighborhood:
                isValid = formState.isNeighborhoodValid
            case .complement:
                isValid = formState.isComplementValid
            case .apartment:
                isValid = formState.isApartmentValid
            case .additionalInfo:
                isValid = formState.isAdditionalInfoValid
            case .multilineAddress:
                isValid = formState.isMultilineAddressValid
            case .parish:
                isValid = formState.isParishValid
            case .entity:
                isValid = formState.isEntityValid
            case .municipality:
                isValid = formState.isMunicipalityValid
            case .division:
                isValid = formState.isDivisionValid
            case .zone:
                isValid = formState.isZoneValid
            case .island:
                isValid = formState.isIslandValid
            }

            if !isValid {
                // Add the field name to the list of invalid fields
                switch field {
                case .street:
                    invalidFields.append("Street")
                case .city:
                    invalidFields.append("City")
                case .state:
                    invalidFields.append("State")
                case .province:
                    invalidFields.append("Province")
                case .postalCode:
                    invalidFields.append("Postal Code")
                case .region:
                    invalidFields.append("Region")
                case .district:
                    invalidFields.append("District")
                case .department:
                    invalidFields.append("Department")
                case .governorate:
                    invalidFields.append("Governorate")
                case .emirate:
                    invalidFields.append("Emirate")
                case .block:
                    invalidFields.append("Block")
                case .county:
                    invalidFields.append("County")
                case .neighborhood:
                    invalidFields.append("Neighborhood")
                case .complement:
                    invalidFields.append("Complement")
                case .apartment:
                    invalidFields.append("Apartment")
                case .additionalInfo:
                    invalidFields.append("Additional Info")
                case .multilineAddress:
                    invalidFields.append("Multiline Address")
                case .parish:
                    invalidFields.append("Parish")
                case .entity:
                    invalidFields.append("Entity")
                case .municipality:
                    invalidFields.append("Municipality")
                case .division:
                    invalidFields.append("Division")
                case .zone:
                    invalidFields.append("Zone")
                case .island:
                    invalidFields.append("Island")
                }
            }
            
            return isValid
        }

        // Show or hide validation message based on whether the fields are valid
        showValidationMessage = !allValid

        // Display the invalid fields
        if !allValid {
            toastMessage = "The following fields are invalid: \(invalidFields.joined(separator: ", "))"
            showToast = true
        }
    }
    
    
    func updateTeamLocation() async {
        Logger.logCreatedByIdEvent(createdByUserId: profileViewModel.name, fileName: "TeamFormationSections", functionName: "updateTeamLocation")

        // Ensure you have the UUID string of the team to update
        // CORRECTED: Access the wrappedValue of teamDetails, then safely unwrap teamID
        guard let teamID = teamDetails.teamID?.uuidString else {
            self.errorMessage = "Team ID is missing for update."
            self.showError = true
            return
        }

        do {
            // Create a dictionary with all the data you want to update in Firestore.
            // The keys in this dictionary should match your Firestore document field names.
            var dataToUpdate: [String: Any] = [
                "name": teamDetails.teamName,
                "location": teamDetails.fullAddress, // Assuming fullAddress is correctly compiled
                "country": selectedCountry?.name.common ?? "Unknown", // Ensure country is included
                "lastModifiedByUserId": profileViewModel.name,
                "lastModifiedTimestamp": Date(), // Always update the timestamp on modification
                // CORRECTED: Provide default values for optional Doubles
                "latitude": teamDetails.latitude ?? 0.0,
                "longitude": teamDetails.longitude ?? 0.0
            ]

            // Conditionally add teamWebsite to avoid issues if it's empty or invalid
            // CORRECTED: Check if the non-optional string is empty
            if !teamDetails.teamWebsite.isEmpty {
                let urlString = teamDetails.teamWebsite.hasPrefix("http")
                    ? teamDetails.teamWebsite
                    : "https://\(teamDetails.teamWebsite)"
                dataToUpdate["teamWebsite"] = urlString
            } else {
                dataToUpdate["teamWebsite"] = NSNull() // Explicitly set to null in Firestore if empty
            }

            // Add all other relevant address fields from teamDetails to the dictionary
            // Make sure these keys match your Firestore document structure
            dataToUpdate["street"] = teamDetails.street
            dataToUpdate["city"] = teamDetails.city
            dataToUpdate["state"] = teamDetails.state
            dataToUpdate["postalCode"] = teamDetails.postalCode
            dataToUpdate["province"] = teamDetails.province
            dataToUpdate["neighborhood"] = teamDetails.neighborhood
            dataToUpdate["complement"] = teamDetails.complement
            dataToUpdate["apartment"] = teamDetails.apartment
            dataToUpdate["region"] = teamDetails.region
            dataToUpdate["county"] = teamDetails.county
            dataToUpdate["governorate"] = teamDetails.governorate
            dataToUpdate["additionalInfo"] = teamDetails.additionalInfo
            dataToUpdate["department"] = teamDetails.department
            dataToUpdate["parish"] = teamDetails.parish
            dataToUpdate["district"] = teamDetails.district
            dataToUpdate["entity"] = teamDetails.entity
            dataToUpdate["municipality"] = teamDetails.municipality
            dataToUpdate["division"] = teamDetails.division
            dataToUpdate["emirate"] = teamDetails.emirate
            dataToUpdate["zone"] = teamDetails.zone
            dataToUpdate["block"] = teamDetails.block
            dataToUpdate["island"] = teamDetails.island
            
            // This is the updated call:
            // It now takes the team's ID as a String and a dictionary of data to update.
            try await viewModel.updateTeam(
                id: teamID,
                data: dataToUpdate
            )

            // Show success message or handle success state
            self.successMessage = "Team location updated successfully!"
            self.showToast = true

        } catch {
            self.errorMessage = "Error updating team location: \(error.localizedDescription)"
            self.showError = true
        }
    }
    
    func setError(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    private func getErrorMessage(for field: AddressFieldType, country: String) -> String {
        return "\(field.rawValue.capitalized) is required for \(country)."
    }
    



    
    func binding(for field: AddressField) -> Binding<String> {
         switch field {
         case .street:
             return $teamDetails.street
         case .city:
             return $teamDetails.city
         case .postalCode:
             return $teamDetails.postalCode
         case .state:
             return $teamDetails.state
         case .province:
             return $teamDetails.province
         case .region, .county, .governorate:
             return $teamDetails.region
         case .neighborhood:
             return $teamDetails.neighborhood
         case .complement:
             return $teamDetails.complement
         case .apartment:
             return $teamDetails.apartment
         case .additionalInfo:
             return $teamDetails.additionalInfo
         default:
             fatalError("Unhandled AddressField: \(field.rawValue)")
         }
     }
    

}

extension Binding where Value == String? {
    func defaultValue(_ defaultValue: String) -> Binding<String> {
        Binding<String>(
            get: { self.wrappedValue ?? defaultValue },
            set: { self.wrappedValue = $0 }
        )
    }
}

extension View {
    func modifierForField(_ field: AddressField) -> some View {
        switch field {
        case .postalCode:
            return self.keyboardType(.numberPad)
        case .city, .state, .street:
            return self.keyboardType(.default)
        default:
            return self.keyboardType(.default) // Default for non-specific fields
        }
    }
}


extension View {
    func eraseToAnyView() -> AnyView { AnyView(self) }
}


extension String {
    var isEmptyOrWhitespace: Bool {
        self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

