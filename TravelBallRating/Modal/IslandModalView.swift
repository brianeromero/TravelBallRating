//
//  TeamModalView.swift
//  TravelBallRating
//
//  Created by Brian Romero on 8/29/24.
//

import Foundation
import SwiftUI
import CoreLocation


struct TeamModalView: View {
    @Environment(\.managedObjectContext) var viewContext
    @ObservedObject var enterZipCodeViewModel: EnterZipCodeViewModel
    @Binding var selectedDay: DayOfWeek?
    @Binding var showModal: Bool
    @State private var isLoadingData: Bool = false
    @State private var showReview: Bool = false
    
    @State private var currentAverageStarRating: Double = 0.0
    @State private var currentReviews: [Review] = []
    
    @Binding var navigationPath: NavigationPath
    @State private var showNoScheduleAlert = false
    
    var isLoading: Bool {
        teamSchedules.isEmpty && !scheduleExists || isLoadingData
    }
    
    let customMapMarker: CustomMapMarker?
    @State private var scheduleExists: Bool = false
    @State private var teamSchedules: [(Team, [MatTime])] = []
    let teamName: String
    let teamLocation: String
    let formattedCoordinates: String
    let createdTimestamp: String
    let formattedTimestamp: String
    let teamWebsite: URL?
    let dayOfWeekData: [DayOfWeek]
    
    @Binding var selectedTeam: Team?
    @ObservedObject var viewModel: AppDayOfWeekViewModel
    @Binding var selectedAppDayOfWeek: AppDayOfWeek?
    @ObservedObject private var authViewModel = AuthViewModel.shared
    
    init(
        customMapMarker: CustomMapMarker?,
        teamName: String,
        teamLocation: String,
        formattedCoordinates: String,
        createdTimestamp: String,
        formattedTimestamp: String,
        teamWebsite: URL?,
        dayOfWeekData: [DayOfWeek],
        selectedAppDayOfWeek: Binding<AppDayOfWeek?>,
        selectedTeam: Binding<Team?>,
        viewModel: AppDayOfWeekViewModel,
        selectedDay: Binding<DayOfWeek?>,
        showModal: Binding<Bool>,
        enterZipCodeViewModel: EnterZipCodeViewModel,
        navigationPath: Binding<NavigationPath>
    ) {
        self.customMapMarker = customMapMarker
        self.teamName = teamName
        self.teamLocation = teamLocation
        self.formattedCoordinates = formattedCoordinates
        self.createdTimestamp = createdTimestamp
        self.formattedTimestamp = formattedTimestamp
        self.teamWebsite = teamWebsite
        self.dayOfWeekData = dayOfWeekData
        self._selectedAppDayOfWeek = selectedAppDayOfWeek
        self._selectedTeam = selectedTeam
        self.viewModel = viewModel
        self._selectedDay = selectedDay
        self._showModal = showModal
        self.enterZipCodeViewModel = enterZipCodeViewModel
        self._navigationPath = navigationPath
    }


    var body: some View {
        ZStack {
            // Dimmed blurred background
            Rectangle()
                .fill(.ultraThinMaterial)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture { showModal = false }

            contentView
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Dismiss") { showModal = false }
            }
        }
        .navigationTitle(selectedTeam?.teamName ?? "Team Details")
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(false)
        .onAppear {
            loadTeamData()
        }
    }
    
    // MARK: - Async loading
    private func loadTeamData() {
        isLoadingData = true
        
        guard let team = selectedTeam else {
            isLoadingData = false
            return
        }
        
        Task {
            let hasSchedule = await viewModel.loadSchedules(for: team)
            
            async let fetchedAvgRating = ReviewUtils.fetchAverageRating(
                for: team,
                in: viewContext,
                callerFunction: "TeamModalView.onAppear"
            )
            
            async let fetchedReviews = ReviewUtils.fetchReviews(
                for: team,
                in: viewContext,
                callerFunction: "TeamModalView.onAppear"
            )
            
            let avgRating = Double(await fetchedAvgRating)
            let reviews = await fetchedReviews
            
            await MainActor.run {
                scheduleExists = hasSchedule
                currentAverageStarRating = avgRating
                currentReviews = reviews
                isLoadingData = false
            }
        }
    }


    // MARK: - Content Views
    @ViewBuilder
    private var contentView: some View {
        if isLoadingData {
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .cornerRadius(12)
                    .shadow(radius: 10)
                    .frame(width: 200, height: 80)
                ProgressView("Loading schedules...")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let team = selectedTeam, selectedDay != nil {
            modalContent(team: team)
        } else {
            Text("Error: selectedTeam or selectedDay is nil.")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.primary)
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .shadow(radius: 5)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    
    private func modalContent(team: Team) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(teamName)
                .font(.system(size: 20, weight: .bold))
                .fontDesign(.rounded)
                .foregroundColor(.primary)

            locationSection
            teamwebsiteSection
            scheduleSection(for: team)
            reviewsSection

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .frame(maxWidth: 600, maxHeight: 600)
        .overlay(alignment: .topTrailing) {
            closeButton
        }
    }

    
    private var locationSection: some View {
        Button(action: { openInMaps(address: teamLocation) }) {
            Text(teamLocation)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.accentColor)
                .underline() // optional, looks more like a typical hyperlink
        }
        .buttonStyle(.plain)
    }
    
    private var teamwebsiteSection: some View {
        Group {
            if let teamWebsite = teamWebsite {
                HStack {
                    Text("Website:")
                        .foregroundColor(.primary)
                        .font(.system(size: 16, weight: .semibold))
                        .fontDesign(.rounded)

                    Spacer()

                    Link("Visit Website", destination: teamWebsite)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.accentColor)
                        .underline() // optional, looks more like a typical hyperlink
                }
                .padding(.top, 10)
            } else {
                Text("No website available.")
                    .font(.system(size: 16, weight: .semibold))
                    .fontDesign(.rounded)
                    .foregroundColor(.secondary)
                    .padding(.top, 10)
            }
        }
    }

    private func scheduleSection(for team: Team) -> some View {
        let hasSchedules = (team.appDayOfWeeks as? Set<AppDayOfWeek>)?
            .contains(where: { $0.hasMatTimes }) ?? false
        
        return AnyView(
            content(for: team, hasSchedules: hasSchedules)
                .alert(
                    "Schedule Not Available",
                    isPresented: $showNoScheduleAlert
                ) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("There are no scheduled mat times associated with this team.")
                }
        )
    }
    

    @ViewBuilder
    private func content(for team: Team, hasSchedules: Bool) -> some View {
        if hasSchedules {
            NavigationLink(
                destination: ViewScheduleForTeam(viewModel: viewModel, team: team)
            ) {
                Text("View Schedule")
                    .font(.system(size: 16, weight: .semibold))
                    .fontDesign(.rounded)
                    .foregroundColor(.accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentColor.opacity(0.1)) // optional visual styling
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
        } else {
            Button {
                showNoScheduleAlert = true
            } label: {
                Text("View Schedule")
                    .font(.system(size: 16, weight: .semibold))
                    .fontDesign(.rounded)
                    .foregroundColor(.accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.gray.opacity(0.2)) // optional styling for disabled
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
    }
    

    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 12) {

            // WHEN REVIEWS EXIST
            if !currentReviews.isEmpty {
                HStack {
                    Text("Average Rating:")
                        .foregroundColor(.primary)
                        .font(.system(size: 16, weight: .semibold))
                        .fontDesign(.rounded)

                    Spacer()

                    HStack(spacing: 2) {
                        let starIcons = StarRating.getStars(for: currentAverageStarRating)
                        ForEach(starIcons, id: \.self) { iconName in
                            Image(systemName: iconName)
                                .foregroundColor(.yellow)
                        }
                    }
                }

                if let team = selectedTeam {
                    Button {
                        navigationPath.append(
                            AppScreen.viewAllReviews(
                                team.objectID.uriRepresentation().absoluteString
                            )
                        )
                        showModal = false
                    } label: {
                        Text("View All Reviews")
                            .font(.system(size: 16, weight: .semibold))
                            .fontDesign(.rounded)
                            .foregroundColor(.accentColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }

            } else {
                // WHEN NO REVIEWS EXIST
                Text("No reviews available.")
                    .font(.system(size: 16, weight: .semibold))
                    .fontDesign(.rounded)
                    .foregroundColor(.secondary)

                if let team = selectedTeam {
                    Button {
                        navigationPath.append(
                            AppScreen.review(
                                team.objectID.uriRepresentation().absoluteString
                            )
                        )
                        showModal = false
                    } label: {
                        Text("Be the first to write a review!")
                            .font(.system(size: 16, weight: .semibold))
                            .fontDesign(.rounded)
                            .foregroundColor(.accentColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.top, 20)
    }



    private var closeButton: some View {
        Button {
            showModal = false
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(8)
        }
    }

    
    private func openInMaps(address: String) {
        let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let googleURL = URL(string: "comgooglemaps://?q=\(encoded)"),
           UIApplication.shared.canOpenURL(googleURL) {
            UIApplication.shared.open(googleURL)
            return
        }

        if let appleURL = URL(string: "http://maps.apple.com/?address=\(encoded)") {
            UIApplication.shared.open(appleURL)
        }
    }
}
