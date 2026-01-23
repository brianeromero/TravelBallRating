//
//  TeamView.swift
//  TravelBallRating
//
//  Created by Brian Romero on 6/26/24.
//

import Foundation
import SwiftUI
import CoreData
import Combine

struct TeamView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        Group {
            if appState.showWelcomeScreen {
                Text("TravelBallRating")
                    .font(.largeTitle)
                    .padding()
                    .onAppear {
                        print("👀 TeamView showing TravelBallRating at \(Date())")
                    }
                    .onDisappear {
                        print("👋 TravelBallRating disappeared at \(Date())")
                    }
            } else {
                NavigationView {
                    Text("Where All Your Mat Dreams Come True!!!")
                        .padding()
                        .navigationBarTitle("Mat Finder")
                        .onAppear {
                            print("✅ NavigationView appeared at \(Date())")
                        }
                }
            }
        }
    }
}
