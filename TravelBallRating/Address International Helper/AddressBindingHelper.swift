// AddressBindingHelper.swift
// TravelBallRating
//
// Created by Brian Romero on 11/18/24.


import Foundation
import SwiftUI

/// Helper class to manage the address binding logic
class AddressBindingHelper {
    static func binding(for field: AddressField, teamDetails: TeamDetails) -> Binding<String> {
        switch field {
        case .street:
            return Binding(get: { teamDetails.street }, set: { teamDetails.street = $0 })
        case .city:
            return Binding(get: { teamDetails.city }, set: { teamDetails.city = $0 })
        case .state:
            return Binding(get: { teamDetails.state }, set: { teamDetails.state = $0 })
        case .postalCode:
            return Binding(get: { teamDetails.postalCode }, set: { teamDetails.postalCode = $0 })
        case .province:
            return Binding(get: { teamDetails.province }, set: { teamDetails.province = $0 })
        case .region:
            return Binding(get: { teamDetails.region }, set: { teamDetails.region = $0 })
        case .district:
            return Binding(get: { teamDetails.district }, set: { teamDetails.district = $0 })
        case .department:
            return Binding(get: { teamDetails.department }, set: { teamDetails.department = $0 })
        case .governorate:
            return Binding(get: { teamDetails.governorate }, set: { teamDetails.governorate = $0 })
        case .emirate:
            return Binding(get: { teamDetails.emirate }, set: { teamDetails.emirate = $0 })
        case .county:
            return Binding(get: { teamDetails.county }, set: { teamDetails.county = $0 })
        case .neighborhood:
            return Binding(get: { teamDetails.neighborhood }, set: { teamDetails.neighborhood = $0 })
        case .complement:
            return Binding(get: { teamDetails.complement }, set: { teamDetails.complement = $0 })
        case .apartment:
            return Binding(get: { teamDetails.apartment }, set: { teamDetails.apartment = $0 })
        case .additionalInfo:
            return Binding(get: { teamDetails.additionalInfo }, set: { teamDetails.additionalInfo = $0 })
        case .multilineAddress:
            return Binding(get: { teamDetails.multilineAddress }, set: { teamDetails.multilineAddress = $0 })
        case .parish:
            return Binding(get: { teamDetails.parish }, set: { teamDetails.parish = $0 })
        case .entity:
            return Binding(get: { teamDetails.entity }, set: { teamDetails.entity = $0 })
        case .municipality:
            return Binding(get: { teamDetails.municipality }, set: { teamDetails.municipality = $0 })
        case .division:
            return Binding(get: { teamDetails.division }, set: { teamDetails.division = $0 })
        case .zone:
            return Binding(get: { teamDetails.zone }, set: { teamDetails.zone = $0 })
        case .island:
            return Binding(get: { teamDetails.island }, set: { teamDetails.island = $0 })
        case .block:
            return Binding(get: { teamDetails.block }, set: { teamDetails.block = $0 })
        case .country:
            return Binding(get: { teamDetails.country }, set: { teamDetails.country = $0 })
        }
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
