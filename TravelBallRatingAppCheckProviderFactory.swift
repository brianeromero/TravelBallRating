//
// TravelBallRatingAppCheckProviderFactory.swift
// TravelBallRating
//
//  Created by Brian Romero on 10/21/24.
//

import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseAppCheck

class TravelBallRatingAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        #if targetEnvironment(simulator)
          let provider = AppCheckDebugProvider(app: app)
          print("Firebase App Check debug token: \(provider?.localDebugToken() ?? "" )")
          return provider
        #else
          guard let provider = AppAttestProvider(app: app) else {
              print("TravelBallRatingAppCheckProviderFactory: Failed to create AppAttestProvider")
              return nil
          }
          print("TravelBallRatingAppCheckProviderFactory: AppAttestProvider created successfully")
          return provider
        #endif
    }
}
