//
//  AddNewTeam.swift
//  TravelBallRating
//
//  Created by Brian Romero on 6/26/24.
//

import Foundation
import SwiftUI
import CoreData
import Combine
import FirebaseFirestore
import os

public struct AddNewTeam: View {
    // Environment Variables
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var teamViewModel: TeamViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @ObservedObject var countryService = CountryService.shared

    // State Variables
    @State private var teamWebsiteURL: URL? = nil
    @State private var formState = FormState()
    @State private var isSaveEnabled = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var teamWebsite = ""
    @State private var showToast = false
    @State private var toastMessage = ""
    @Binding var navigationPath: NavigationPath

    @State private var isSuccessAlert = false
    @StateObject private var teamDetails = TeamDetails()

    
    // Body
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                teamFormationSection
                teamFormSection
                enteredBySection
                actionButtons
            }
            .overlay(
                VStack {
                    Spacer()
                    if showToast {
                        Text(toastMessage)
                            .padding()
                            .background(Color.black.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    withAnimation { showToast = false }
                                }
                            }
                    }
                }
                .padding()
                .animation(.easeInOut, value: showToast)
            )
        }
        .navigationDestination(for: String.self) { _ in
            TeamMenu2(
                profileViewModel: profileViewModel,
                navigationPath: $navigationPath
            )
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text("Add New team")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("Fill in all required fields below")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(isSuccessAlert ? "Success" : "Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    if isSuccessAlert { navigationPath = NavigationPath() }
                }
            )
        }
        .onAppear {
            Task {
                await countryService.fetchCountries()
                await profileViewModel.loadProfile()
                validateForm()
            }
        }
        .onChange(of: countryService.countries) { _, newValue in
            if let usa = newValue.first(where: { $0.cca2 == "US" }) {
                teamDetails.selectedCountry = usa
            }
        }
        .onChange(of: teamDetails) { _, _ in validateForm() }
        .onChange(of: teamDetails.teamName) { _, _ in validateForm() }
        .onChange(of: teamDetails.requiredAddressFields) { _, _ in validateForm() }
    }

    // MARK: - Form Sections
    private var teamFormSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Team Details").font(.headline)

            TextField("Team Name", text: $teamDetails.teamName)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.words)

            Picker("Sport", selection: $teamDetails.sport) {
                Text("Select a Sport").tag(nil as SportType?)
                ForEach(SportType.allCases) { sport in
                    Text(sport.rawValue).tag(sport as SportType?)
                }
            }.pickerStyle(.menu)

            Picker("Gender", selection: $teamDetails.gender) {
                Text("Select Gender").tag(nil as GenderType?)
                ForEach(GenderType.allCases) { gender in
                    Text(gender.rawValue).tag(gender as GenderType?)
                }
            }.pickerStyle(.menu)

            Picker("Age Group", selection: $teamDetails.ageGroup) {
                Text("Select Age Group").tag(nil as AgeGroupType?)
                ForEach(AgeGroupType.allCases) { age in
                    Text(age.rawValue).tag(age as AgeGroupType?)
                }
            }.pickerStyle(.menu)


            TextField("Coach Name", text: $teamDetails.coachName)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.words)

            TextField("Contact Email", text: $teamDetails.contactEmail)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.emailAddress)
        }
        .padding(.vertical)
    }

    private var teamFormationSection: some View {
        TeamFormationSections(
            viewModel: teamViewModel,
            profileViewModel: profileViewModel,
            countryService: countryService,
            teamName: $teamDetails.teamName,
            street: $teamDetails.street,
            city: $teamDetails.city,
            state: $teamDetails.state,
            postalCode: $teamDetails.postalCode,
            teamDetails: teamDetails, // Pass the object directly
            selectedCountry: $teamDetails.selectedCountry,
            teamWebsite: $teamWebsite,
            teamWebsiteURL: $teamWebsiteURL,
            province: $teamDetails.province,
            neighborhood: $teamDetails.neighborhood,
            complement: $teamDetails.complement,
            apartment: $teamDetails.apartment,
            region: $teamDetails.region,
            county: $teamDetails.county,
            governorate: $teamDetails.governorate,
            additionalInfo: $teamDetails.additionalInfo,
            department: $teamDetails.department,
            parish: $teamDetails.parish,
            district: $teamDetails.district,
            entity: $teamDetails.entity,
            municipality: $teamDetails.municipality,
            division: $teamDetails.division,
            emirate: $teamDetails.emirate,
            zone: $teamDetails.zone,
            block: $teamDetails.block,
            island: $teamDetails.island,
            isTeamNameValid: $teamDetails.isTeamNameValid,
            teamNameErrorMessage: $teamDetails.teamNameErrorMessage,
            isFormValid: $isSaveEnabled,
            formState: $formState
        )
    }

    private var enteredBySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Entered By").font(.headline)
            if profileViewModel.isProfileLoaded {
                Text(profileViewModel.name.isEmpty ? "Unknown" : profileViewModel.name)
                    .font(.body)
                    .foregroundColor(.primary)
            } else {
                ProgressView().scaleEffect(0.75, anchor: .leading)
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 14) {
            saveButton
            cancelButton
        }.padding(.top, 20)
    }

    private var saveButton: some View {
        Button {
            Task {
                // 1️⃣ Validate forms
                guard validateForm(), validateTeamForm() else { return }

                // 2️⃣ Get current user
                guard let currentUser = await authViewModel.getCurrentUser() else {
                    alertMessage = "You must be logged in to add a new team location."
                    showAlert = true
                    return
                }

                // 3️⃣ Save team then team sequentially
                await saveTeam(currentUser: currentUser, onSave: {
                    await saveTeam(currentUser: currentUser)
                    navigationPath.append("TeamMenu2")
                })
            }
        } label: {
            Text("Save")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isSaveEnabled ? Color.accentColor : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
        }
        .disabled(!isSaveEnabled)
    }


    private func saveTeam(currentUser: User) async {
        do {
            let newTeam = try await teamViewModel.createTeam(
                teamName: teamDetails.teamName,
                sport: teamDetails.sport?.rawValue ?? "",
                gender: teamDetails.gender?.rawValue ?? "",
                ageGroup: teamDetails.ageGroup?.rawValue ?? "",
                coachName: teamDetails.coachName,
                contactEmail: teamDetails.contactEmail,
                createdByUser: currentUser
            )

            toastMessage = "Team '\(newTeam.teamName)' saved!"
            showToast = true
        } catch {
            toastMessage = "Failed to save team: \(error.localizedDescription)"
            showToast = true
        }
    }

    private var cancelButton: some View {
        Button {
            clearFields()
            dismiss()
        } label: {
            Text("Cancel")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .foregroundColor(.red)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 1)
        }
    }

    // MARK: - Validation & Helper Methods
    private let fieldValues: [PartialKeyPath<TeamDetails>: AddressFieldType] = [
        \.street: .street,
        \.city: .city,
        \.state: .state,
        \.province: .province,
        \.postalCode: .postalCode,
        \.region: .region,
        \.district: .district,
        \.department: .department,
        \.governorate: .governorate,
        \.emirate: .emirate,
        \.block: .block,
        \.county: .county,
        \.neighborhood: .neighborhood,
        \.complement: .complement,
        \.apartment: .apartment,
        \.additionalInfo: .additionalInfo,
        \.multilineAddress: .multilineAddress
    ]

    private func validateForm() -> Bool {
        let teamNameEmpty = teamDetails.teamName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let requiredFields = teamDetails.requiredAddressFields
        let allFieldsValid = !teamNameEmpty && requiredFields.allSatisfy { isValidField($0) }
        isSaveEnabled = allFieldsValid

        if !allFieldsValid {
            toastMessage = "Some required fields are missing"
            showToast = true
        } else {
            toastMessage = ""
        }
        return allFieldsValid
    }

    private func valueForField(_ field: AddressFieldType) -> String {
        if let keyPath = fieldValues.first(where: { $1 == field })?.0 {
            return teamDetails[keyPath: keyPath] as? String ?? ""
        }
        return ""
    }

    private func isValidField(_ field: AddressFieldType) -> Bool {
        guard let keyPath = fieldValues.first(where: { $1 == field })?.0 else { return false }
        let value = teamDetails[keyPath: keyPath] as? String ?? ""
        return !value.isEmpty
    }

    private func validateTeamForm() -> Bool {
        // Validate team name
        if teamDetails.teamName.trimmingCharacters(in: .whitespaces).isEmpty {
            toastMessage = "Team name is required"
            showToast = true
            return false
        }

        // Validate email
        if teamDetails.contactEmail.isEmpty || !teamDetails.contactEmail.contains("@") {
            toastMessage = "Valid email required"
            showToast = true
            return false
        }

        // Validate sport
        if teamDetails.sport == nil {
            toastMessage = "Please select a sport"
            showToast = true
            return false
        }

        // Validate gender
        if teamDetails.gender == nil {
            toastMessage = "Please select a gender"
            showToast = true
            return false
        }

        // Validate age group
        if teamDetails.ageGroup == nil {
            toastMessage = "Please select an age group"
            showToast = true
            return false
        }

        return true
    }


    private func saveTeam(currentUser: User, onSave: @escaping () async -> Void) async {
        guard let selectedCountry = teamDetails.selectedCountry else {
            toastMessage = "Please select a country."
            showToast = true
            return
        }

        do {
            let newTeam = try await teamViewModel.createTeam(
                teamDetails: teamDetails,
                createdByUserId: currentUser.userName,
                teamWebsite: teamWebsite,
                country: selectedCountry.cca2,
                selectedCountry: selectedCountry,
                createdByUser: currentUser
            )

            toastMessage = "Team saved successfully: \(newTeam.teamName)"
            alertMessage = "team Added Successfully!"
            isSuccessAlert = true
            showAlert = true
            clearFields()
            await onSave()
        } catch {
            toastMessage = "Error saving team: \(error.localizedDescription)"
            showToast = true
        }
    }

    private func clearFields() {
        teamDetails.teamName = ""
        teamDetails.street = ""
        teamDetails.city = ""
        teamDetails.state = ""
        teamDetails.postalCode = ""
        teamDetails.selectedCountry = nil
        teamDetails.neighborhood = ""
        teamDetails.complement = ""
        teamDetails.block = ""
        teamDetails.apartment = ""
        teamDetails.region = ""
        teamDetails.county = ""
        teamDetails.governorate = ""
        teamDetails.province = ""
        teamDetails.additionalInfo = ""
        teamDetails.coachName = ""
        teamDetails.contactEmail = ""
        teamWebsite = ""
        teamWebsiteURL = nil
    }

}
