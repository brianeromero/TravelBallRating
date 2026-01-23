//  CreateAccountView.swift
//  TravelBallRating
//
//  Created by Brian Romero on 10/8/24.
//

import Foundation
import SwiftUI
import CoreData
import CryptoKit
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseAppCheck
import CryptoSwift
import Combine
import os.log

extension String {
    var isAlphanumeric: Bool {
        let alphanumericSet = CharacterSet.alphanumerics
        return self.rangeOfCharacter(from: alphanumericSet.inverted) == nil
    }
}

enum CreateAccountError: Int {
    case invalidEmailOrPassword = 17011
    case userNotFound = 17008
    case missingPermissions = 7
    case emailAlreadyInUse = 17007
}

struct CreateAccountView: View {
    // Environment and Context
    @EnvironmentObject var authenticationState: AuthenticationState
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    // Navigation and Routing
    @Binding var isUserProfileActive: Bool
    @Binding var selectedTabIndex: LoginViewSelection
    @Binding var navigationPath: NavigationPath
    
    // Form State and Validation
    @State private var formState: FormState = FormState()
    @State private var bypassValidation = false
    @State private var isFormValid: Bool = false
    
    // Form Validation Variables
    @State private var isTeamNameValid: Bool = true
    @State private var teamNameErrorMessage: String = ""
    
    // Account & Address Info
    @State private var teamDetails = TeamDetails()
    @State private var selectedCountry: Country? = Country(name: Country.Name(common: "United States"), cca2: "US", flag: "")
    
    // Account and Profile Information
    @State private var belt: String = ""
    let beltOptions = ["", "White", "Blue", "Purple", "Brown", "Black"]
    
    // Alerts
    @Binding var showAlert: Bool
    @Binding var alertTitle: String   // <-- NEW
    @Binding var alertMessage: String
    @Binding var currentAlertType: AccountAlertType?   // <-- new binding

    
    // Button State
    @State private var isButtonDisabled = false
    
    // Observed / StateObjects
    @ObservedObject var teamViewModel: TeamViewModel
    @StateObject var profileViewModel: ProfileViewModel
    @ObservedObject var countryService: CountryService
    
    let emailManager: UnifiedEmailManager
    
    init(
        teamViewModel: TeamViewModel,
        isUserProfileActive: Binding<Bool>,
        selectedTabIndex: Binding<LoginViewSelection>,
        navigationPath: Binding<NavigationPath>,
        persistenceController: PersistenceController,
        countryService: CountryService = .shared,
        emailManager: UnifiedEmailManager,
        showAlert: Binding<Bool>,
        alertTitle: Binding<String>,
        alertMessage: Binding<String>,
        currentAlertType: Binding<AccountAlertType?>      // <-- ADD THIS
    ) {
        self._teamViewModel = ObservedObject(wrappedValue: teamViewModel)
        self._isUserProfileActive = isUserProfileActive
        self._selectedTabIndex = selectedTabIndex
        self._navigationPath = navigationPath
        self.countryService = countryService
        self.emailManager = emailManager
        _profileViewModel = StateObject(wrappedValue: ProfileViewModel(viewContext: persistenceController.container.viewContext))
        
        self._showAlert = showAlert
        self._alertTitle = alertTitle
        self._alertMessage = alertMessage
        self._currentAlertType = currentAlertType      // <-- SET IT HERE
    }


    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Create Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.horizontal, 20)
                
                UserInformationView(formState: $formState)
                
                PasswordField(
                    password: $formState.password,
                    isValid: $formState.isPasswordValid,
                    errorMessage: $formState.passwordErrorMessage,
                    bypassValidation: $bypassValidation,
                    validateField: { password in
                        if let validationMessage = ValidationUtility.validateField(password, type: .password) {
                            return (false, validationMessage.rawValue)
                        }
                        return (true, "")
                    }
                )
                
                ConfirmPasswordField(
                    confirmPassword: $formState.confirmPassword,
                    isValid: $formState.isConfirmPasswordValid,
                    password: $formState.password
                )
                
                BeltSection(belt: $belt, beltOptions: beltOptions, usePickerStyle: true)
                
                Section(header: HStack {
                    Text("Team Information")
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("(Optional)")
                        .foregroundColor(.secondary)
                        .opacity(0.7)
                }.padding(.horizontal, 20)) {
                    TeamFormationSections(
                        viewModel: teamViewModel,
                        profileViewModel: profileViewModel,
                        countryService: countryService,
                        teamName: $teamDetails.teamName,
                        street: $teamDetails.street,
                        city: $teamDetails.city,
                        state: $teamDetails.state,
                        postalCode: $teamDetails.postalCode,
                        teamDetails: $teamDetails,
                        selectedCountry: $selectedCountry,
                        teamWebsite: $teamDetails.teamWebsite,
                        teamWebsiteURL: $teamDetails.teamWebsiteURL,
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
                        isTeamNameValid: $isTeamNameValid,
                        teamNameErrorMessage: $teamNameErrorMessage,
                        isFormValid: $isFormValid,
                        formState: $formState
                    )
                }
                
                Button(action: handleCreateAccountButtonTapped) {
                    Text("Create Account")
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .shadow(radius: 5)
                }
                .padding(.horizontal, 24)
                .padding(.bottom)
                .disabled(isButtonDisabled)
                .onAppear {
                    Task {
                        await countryService.fetchCountries()
                    }
                }
            }
            .padding(.vertical)
            .background(Color(uiColor: .systemBackground))
        }
        .onChange(of: selectedCountry) { newCountry, _ in
            teamDetails.selectedCountry = newCountry
            formState.selectedCountry = newCountry
        }
    }
    
    // MARK: - Button Action
    private func handleCreateAccountButtonTapped() {
        Task {
            isButtonDisabled = true
            let (isValid, errorMsg) = isValidForm()
            if isValid {
                await createAccount(country: selectedCountry?.name.common ?? "United States")
            } else {
                alertTitle = "Notice"
                alertMessage = errorMsg ?? "Please complete all required fields."
                showAlert = true
                isButtonDisabled = false
            }
        }
    }
    
    // MARK: - Account Creation
    private func createAccount(country: String) async {
        do {
            // Check if user exists
            if await AuthViewModel.shared.userAlreadyExists(
                email: formState.email.lowercased(),
                userName: formState.userName
            ) {
                await MainActor.run {
                    alertTitle = "Notice"
                    alertMessage = "An account with this email or username already exists."
                    showAlert = true
                    isButtonDisabled = false
                }
                return
            }

            // Create user
            let createdUser = try await AuthViewModel.shared.createUser(
                withEmail: formState.email,
                password: formState.password,
                userName: formState.userName,
                name: formState.name,
                belt: belt
            )

            // Only create team if team name exists
            if !teamDetails.teamName.isEmpty {
                _ = await createTeam(for: createdUser)
            }

            // Show alert on main thread using AccountAlertType
            await MainActor.run {
                AuthViewModel.shared.currentUser = createdUser

                // 🚫 NEW — Block automatic navigation
                authenticationState.navigateUnrestricted = false

                if !teamDetails.teamName.isEmpty {
                    currentAlertType = .successAccountAndTeam
                } else {
                    currentAlertType = .successAccount
                }

                alertTitle = currentAlertType?.title ?? "Notice"
                alertMessage = currentAlertType?.defaultMessage ?? ""
                showAlert = true
            }

        } catch {
            await MainActor.run {
                handleCreateAccountError(error)
            }
        }

        await MainActor.run {
            isButtonDisabled = false
        }
    }


    // MARK: - Team Creation
    private func createTeam(for user: User) async -> String? {
        let (isValid, _) = ValidationUtility.validateTeamForm(
            teamName: teamDetails.teamName,
            street: teamDetails.street,
            city: teamDetails.city,
            state: teamDetails.state,
            postalCode: teamDetails.postalCode,
            neighborhood: teamDetails.neighborhood,
            complement: teamDetails.complement,
            province: teamDetails.province,
            region: teamDetails.region,
            governorate: teamDetails.governorate,
            selectedCountry: teamDetails.selectedCountry,
            teamWebsite: teamDetails.teamWebsite
        )
        guard isValid else { return nil }

        do {
            let newTeam = try await teamViewModel.createTeam(
                teamDetails: teamDetails,
                createdByUserId: user.userID,
                teamWebsite: teamDetails.teamWebsite,
                country: teamDetails.selectedCountry?.cca2 ?? "US",
                selectedCountry: teamDetails.selectedCountry!,
                createdByUser: user
            )

            if !teamDetails.teamWebsite.isEmpty {
                let urlString = teamDetails.teamWebsite.trimmingCharacters(in: .whitespacesAndNewlines)
                guard let url = URL(string: urlString),
                      url.scheme == "http" || url.scheme == "https" else {
                    return nil
                }
            }

            return newTeam.teamName
        } catch {
            return nil
        }
    }

    // MARK: - Error Handling
    private func handleCreateAccountError(_ error: Error) {
        alertTitle = "Notice"
        alertMessage = getErrorMessage(error)
        showAlert = true
        resetAuthenticationState()
    }

    // MARK: - Form Validation
    func isValidForm() -> (isValid: Bool, message: String?) {
        if !formState.isUserNameValid { return (false, "Username is missing/invalid.") }
        if !formState.isNameValid { return (false, "Full name is missing/invalid.") }
        if !formState.isEmailValid { return (false, "Email address is missing/invalid.") }
        if !formState.isPasswordValid { return (false, "Password is missing/invalid.") }
        if formState.password != formState.confirmPassword { return (false, "Passwords do not match.") }

        if !teamDetails.teamName.isEmpty && !isAddressValid(for: selectedCountry?.cca2 ?? "") {
            return (false, "Please complete all required address fields for the selected country.")
        }

        return (true, nil)
    }

    func isAddressValid(for countryCode: String) -> Bool {
        guard !countryCode.isEmpty else { return false }
        do {
            let requiredFields = try getAddressFields(for: countryCode)
            return !requiredFields.contains(where: { isTeamFieldEmpty($0) })
        } catch {
            return false
        }
    }

    private func isTeamFieldEmpty(_ field: AddressFieldType) -> Bool {
        switch field {
        case .street: return teamDetails.street.trimmingCharacters(in: .whitespaces).isEmpty
        case .city: return teamDetails.city.trimmingCharacters(in: .whitespaces).isEmpty
        case .state: return teamDetails.state.trimmingCharacters(in: .whitespaces).isEmpty
        case .postalCode: return teamDetails.postalCode.trimmingCharacters(in: .whitespaces).isEmpty
        case .province: return teamDetails.province.trimmingCharacters(in: .whitespaces).isEmpty
        case .neighborhood: return teamDetails.neighborhood.trimmingCharacters(in: .whitespaces).isEmpty
        case .complement: return teamDetails.complement.trimmingCharacters(in: .whitespaces).isEmpty
        case .region: return teamDetails.region.trimmingCharacters(in: .whitespaces).isEmpty
        case .county: return teamDetails.county.trimmingCharacters(in: .whitespaces).isEmpty
        case .governorate: return teamDetails.governorate.trimmingCharacters(in: .whitespaces).isEmpty
        case .additionalInfo: return teamDetails.additionalInfo.trimmingCharacters(in: .whitespaces).isEmpty
        case .department: return teamDetails.department.trimmingCharacters(in: .whitespaces).isEmpty
        case .parish: return teamDetails.parish.trimmingCharacters(in: .whitespaces).isEmpty
        case .district: return teamDetails.district.trimmingCharacters(in: .whitespaces).isEmpty
        case .entity: return teamDetails.entity.trimmingCharacters(in: .whitespaces).isEmpty
        case .municipality: return teamDetails.municipality.trimmingCharacters(in: .whitespaces).isEmpty
        case .division: return teamDetails.division.trimmingCharacters(in: .whitespaces).isEmpty
        case .emirate: return teamDetails.emirate.trimmingCharacters(in: .whitespaces).isEmpty
        case .zone: return teamDetails.zone.trimmingCharacters(in: .whitespaces).isEmpty
        case .block: return teamDetails.block.trimmingCharacters(in: .whitespaces).isEmpty
        case .apartment: return teamDetails.apartment.trimmingCharacters(in: .whitespaces).isEmpty
        case .multilineAddress: return teamDetails.multilineAddress.trimmingCharacters(in: .whitespaces).isEmpty
        case .island: return teamDetails.team.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    private func resetAuthenticationState() {
        authenticationState.reset()
        isUserProfileActive = false
    }

    func getErrorMessage(_ error: Error) -> String {
        if let teamError = error as? TeamError {
            switch teamError {
            case .invalidInput: return "Invalid input"
            case .teamExists: return "Team already exists"
            case .geocodingError(let message): return "Geocoding error: \(message)"
            case .savingError: return "Saving error"
            case .teamNameMissing: return "Team name is missing"
            case .streetMissing: return "Street address is missing"
            case .cityMissing: return "City is missing"
            case .stateMissing: return "State is missing"
            case .postalCodeMissing: return "Postal code is missing"
            case .fieldMissing(let fieldName): return "\(fieldName) is missing."
            case .invalidTeamWebsite: return "Team Website appears to be invalid"
            }
        } else {
            let errorCode = (error as NSError).code
            switch CreateAccountError(rawValue: errorCode) {
            case .invalidEmailOrPassword: return "Invalid email or password."
            case .userNotFound: return "User not found."
            case .missingPermissions: return "Missing or insufficient permissions."
            case .emailAlreadyInUse: return AccountAuthViewError.userAlreadyExists.errorDescription ?? "Email already in use."
            default: return "Error creating account: \(error.localizedDescription)"
            }
        }
    }
}
