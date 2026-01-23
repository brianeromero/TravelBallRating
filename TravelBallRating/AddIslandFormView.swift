//
//  AddTeamFormView.swift
//  TravelBallRating
//
//  Created by Brian Romero on 6/26/24.
//

import SwiftUI
import CoreData
import Combine
import Foundation

struct AddTeamFormView: View {
    // MARK: - Environment Variables
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss // ✅ Correct way to use @Environment(\.dismiss)

    
    // MARK: - Observed Objects
    @ObservedObject var teamViewModel: TeamViewModel
    @ObservedObject var profileViewModel: ProfileViewModel
    @State var teamDetails: TeamDetails
    @ObservedObject var authViewModel: AuthViewModel

    
    // MARK: - State Variables
    @State private var isSaveEnabled = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showToast = false // This will now control your custom toast
    @State private var toastMessage = "" // This will provide the message for your custom toast
    @State private var isGeocoding = false
    @State private var error: String?
    @State private var requiredFields: [AddressFieldType] = []

    // MARK: - Initialization
    init(
        teamViewModel: TeamViewModel,
        profileViewModel: ProfileViewModel,
        authViewModel: AuthViewModel,
        teamDetails: TeamDetails
    ) {
        self.teamViewModel = teamViewModel
        self.profileViewModel = profileViewModel
        self.authViewModel = authViewModel
        self.teamDetails = teamDetails
    }

    
    // MARK: - Body
    var body: some View {
        NavigationView {
            Form {
                teamDetailsSection
                countrySpecificFieldsSection
                enteredBySection
                instagramOrWebsiteSection
                saveButton
                cancelButton
            }
            .navigationBarTitle(teamDetails.teamName.isEmpty ? "Add New team" : "Edit team", displayMode: .inline)
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .onAppear(perform: validateForm) // Assuming validateForm exists and updates isSaveEnabled
            // Updated to match the new ToastModifier signature
            .showToast(
                isPresenting: $showToast,
                duration: 2.0,
                alignment: .top,
                verticalOffset: 0
            )
        }
    }

    
    // MARK: - Extracted Sections
    private var teamDetailsSection: some View {
        Section(header: Text("team Details")) {
            TextField("team Name", text: $teamDetails.teamName)
            TextField("team Location", text: $teamDetails.street)
            TextField("City", text: $teamDetails.city)
            TextField("State", text: $teamDetails.state)
            TextField("Postal Code", text: $teamDetails.postalCode)
        }
    }
    
    private var countrySpecificFieldsSection: some View {
        Section(header: Text("Country Specific Fields")) {
            VStack {
                if let selectedCountry = teamDetails.selectedCountry {
                    if let error = error {
                        Text("Error getting address fields for country code 252627 \(selectedCountry.cca2): \(error)")
                    } else {
                        ForEach(requiredFields, id: \.self) { field in
                            self.addressField(for: field)
                        }
                        
                        if selectedCountry.cca2.uppercased().trimmingCharacters(in: .whitespacesAndNewlines) == "IE" {
                            TextField("County", text: $teamDetails.county)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                } else {
                    Text("Please select a country")
                }
            }
            .onAppear {
                if let selectedCountry = teamDetails.selectedCountry {
                    let normalizedCountryCode = selectedCountry.cca2.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    print("Fetching address fields for normalized country code456: \(normalizedCountryCode)")

                    do {
                        requiredFields = try getAddressFields(for: normalizedCountryCode)
                    } catch {
                        self.error = "Error getting address fields for country code 282930 \(normalizedCountryCode): \(error.localizedDescription)"
                    }
                }
            }
        }
    }


    // MARK: - Address Fields
    // Ensure consistency between AddressField and AddressFieldType
    private func addressField(for field: AddressFieldType) -> some View {
        // Adjusting to use AddressFieldType
        switch field {
        case .street:
            return AnyView(TextField("Street", text: $teamDetails.street).textFieldStyle(RoundedBorderTextFieldStyle()))
        // Handle other cases similarly
        case .city:
            return AnyView(TextField("City", text: $teamDetails.city).textFieldStyle(RoundedBorderTextFieldStyle()))
        case .state:
            return AnyView(TextField("State", text: $teamDetails.state).textFieldStyle(RoundedBorderTextFieldStyle()))
        case .postalCode:
            return AnyView(TextField("Postal Code", text: $teamDetails.postalCode).textFieldStyle(RoundedBorderTextFieldStyle()))
        case .province:
            return AnyView(TextField("Province", text: $teamDetails.province).textFieldStyle(RoundedBorderTextFieldStyle()))
        case .neighborhood:
            return AnyView(TextField("Neighborhood", text: $teamDetails.neighborhood).textFieldStyle(RoundedBorderTextFieldStyle()))
        case .district:
            return AnyView(TextField("District", text: $teamDetails.district).textFieldStyle(RoundedBorderTextFieldStyle()))
        case .department:
            return AnyView(TextField("Department", text: $teamDetails.department).textFieldStyle(RoundedBorderTextFieldStyle()))
        case .governorate:
            return AnyView(TextField("Governorate", text: $teamDetails.governorate).textFieldStyle(RoundedBorderTextFieldStyle()))
        case .emirate:
            return AnyView(TextField("Emirate", text: $teamDetails.emirate).textFieldStyle(RoundedBorderTextFieldStyle()))
        case .apartment:
            return AnyView(TextField("Apartment", text: $teamDetails.apartment).textFieldStyle(RoundedBorderTextFieldStyle()))
        case .additionalInfo:
            return AnyView(TextField("Additional Info", text: $teamDetails.additionalInfo).textFieldStyle(RoundedBorderTextFieldStyle()))
        default:
            return AnyView(EmptyView())
        }
    }
    
    private var enteredBySection: some View {
        Section(header: Text("Entered By")) {
            Text(profileViewModel.name)
                .foregroundColor(.primary)
                .padding()
        }
    }

    private var instagramOrWebsiteSection: some View {
        Section(header: Text("Instagram/Facebook/Website")) {
            TextField("team Website8910", text: $teamDetails.teamWebsite)
                .keyboardType(.URL)
                // Corrected onChange signature for iOS 17+
                .onChange(of: teamDetails.teamWebsite) { oldValue, newValue in // <--- CHANGE IS HERE
                    if !newValue.isEmpty {
                        if ValidationUtility.validateURL(newValue) == nil {
                            teamDetails.teamWebsiteURL = URL(string: newValue)
                        } else {
                            showAlert = true
                            alertMessage = "Invalid website URL."
                        }
                    } else {
                        teamDetails.teamWebsiteURL = nil
                    }
                }
        }
    }

    private var saveButton: some View {
        Button("Save") {
            saveTeam()
        }
        .disabled(!isSaveEnabled)
        .padding()
    }

    private var cancelButton: some View {
        Button("Cancel") {
            dismiss()
        }
        .padding()
    }

    
    // MARK: - Private Methods
    private func saveTeam() {
        Task {
            guard let currentUser = await authViewModel.getCurrentUser() else {
                toastMessage = "You must be logged in to add a new team location."
                showToast = true
                return
            }

            if currentUser.name.isEmpty {
                toastMessage = "Your profile info is incomplete. Please log in again."
                showToast = true
                return
            }

            do {
                _ = try await teamViewModel.createTeam(
                    teamDetails: teamDetails,
                    createdByUserId: currentUser.userName,
                    teamWebsite: nil,
                    country: teamDetails.country,
                    selectedCountry: teamDetails.selectedCountry!,
                    createdByUser: currentUser
                )

                toastMessage = "Team saved successfully!"
                clearFields()
            } catch {
                toastMessage = "Error saving team: \(error.localizedDescription)"
            }

            showToast = true
        }
    }

    private func clearFields() {
        teamDetails.teamName = ""
        teamDetails.street = ""
        teamDetails.city = ""
        teamDetails.state = ""
        teamDetails.postalCode = ""
        teamDetails.teamWebsite = ""
        teamDetails.teamWebsiteURL = nil
    }

    private func validateForm() {
        let normalizedCountryCode = teamDetails.selectedCountry?.cca2.uppercased().trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let (isValid, errorMessage) = ValidationUtility.validateTeamForm(
            teamName: teamDetails.teamName,
            street: teamDetails.street,
            city: teamDetails.city,
            state: teamDetails.state,
            postalCode: teamDetails.postalCode,
            selectedCountry: Country(
                name: .init(common: teamDetails.selectedCountry?.name.common ?? ""),
                cca2: normalizedCountryCode,
                flag: ""
            ),
            teamWebsite: teamDetails.teamWebsite
        )

        if !isValid {
            alertMessage = errorMessage
            showAlert = true
        } else {
            isSaveEnabled = true
        }
    }

    
    private func binding(for field: AddressFieldType) -> Binding<String> {
        switch field {
        case .street: return $teamDetails.street
        case .city: return $teamDetails.city
        case .state: return $teamDetails.state
        case .postalCode: return $teamDetails.postalCode
        default: return .constant("")
        }
    }
}

