// AddressBindingHelper.swift
// TravelBallRating
//
// Created by Brian Romero on 11/18/24.


import Foundation
import SwiftUI

// Helper class to manage the address binding logic
class AddressBindingHelper {
    /// Creates a binding for the specified address field.
    static func binding(for field: AddressField, teamDetails: Binding<TeamDetails>) -> Binding<String> {
        return teamDetails.transform(field.keyPath)
    }
}


/// Extension on Binding for TeamDetails.
extension Binding where Value == TeamDetails {
    func transform(_ keyPath: WritableKeyPath<TeamDetails, String>) -> Binding<String> {
        Binding<String>(
            get: { self.wrappedValue[keyPath: keyPath] },
            set: { self.wrappedValue[keyPath: keyPath] = $0 }
        )
    }
}
