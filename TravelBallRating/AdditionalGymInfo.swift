//
//  AdditionalTeamInfo.swift
//  TravelBallRating
//
//  Created by Brian Romero on 6/26/24.
//

import SwiftUI
import CoreData
import Combine
import CoreLocation
import Foundation


struct AdditionalTeamInfo: View {
    var teamName: String // Assuming teamName is passed or provided

    var body: some View {
        VStack {
            Text(teamName)
                .font(.largeTitle)
                .padding()

            // Add more content specific to the next team
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack {
                    Image(systemName: "info.square.fill")
                        .foregroundColor(.black)
                    Text("Additional team Info")
                }
            }
        }
    }
}
