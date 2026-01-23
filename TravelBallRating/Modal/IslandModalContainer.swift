//
//  TeamModalContainer.swift
//  TravelBallRating
//
//  Created by Brian Romero on 9/20/24.
//

import Foundation
import SwiftUI

struct TeamModalContainer: View {
    @Binding var selectedTeam: Team?
    @ObservedObject var viewModel: AppDayOfWeekViewModel
    @Binding var selectedDay: DayOfWeek?
    @Binding var showModal: Bool
    @ObservedObject var enterZipCodeViewModel: EnterZipCodeViewModel
    @Binding var selectedAppDayOfWeek: AppDayOfWeek?
    @Binding var navigationPath: NavigationPath

    // NEW — smooth fade/scale for the modal
    @State private var animateModal: Bool = false

    var body: some View {
        if let selectedTeam = selectedTeam {
            TeamModalView(
                customMapMarker: nil,
                teamName: selectedTeam.teamName ?? "",
                teamLocation: selectedTeam.teamLocation ?? "",
                formattedCoordinates: selectedTeam.formattedCoordinates,
                createdTimestamp: selectedTeam.createdTimestamp?.description ?? "No timestamp available",
                formattedTimestamp: selectedTeam.formattedTimestamp,
                teamWebsite: selectedTeam.teamWebsite,
                dayOfWeekData: [],
                selectedAppDayOfWeek: $selectedAppDayOfWeek,
                selectedTeam: $selectedTeam,
                viewModel: viewModel,
                selectedDay: $selectedDay,
                showModal: $showModal,
                enterZipCodeViewModel: enterZipCodeViewModel,
                navigationPath: $navigationPath
            )
            .opacity(animateModal ? 1 : 0)
            .scaleEffect(animateModal ? 1 : 0.92)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.25)) {
                    animateModal = true
                }
            }
            .onDisappear {
                animateModal = false
            }
        } else {
            EmptyView()
        }
    }
}
