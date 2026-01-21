//
//  AddressFieldsView.swift
//  TravelBallRating
//
//  Created by Brian Romero on 11/22/24.
//

import Foundation
import SwiftUI

struct AddressFieldsView: View {
    let requiredFields: [AddressFieldType]
    @Binding var teamDetails: TeamDetails

    var body: some View {
        VStack {
            ForEach(requiredFields, id: \.self) { field in
                getTextField(for: field)
            }
        }
    }

    @ViewBuilder
    private func getTextField(for field: AddressFieldType) -> some View {
        switch field {
        case .street:
            TextField("Street", text: $teamDetails.street)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        case .city:
            TextField("City", text: $teamDetails.city)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        case .state:
            TextField("State", text: $teamDetails.state)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        case .county:
            TextField("County", text: $teamDetails.county)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        case .province:
            TextField("Province", text: $teamDetails.province)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        case .postalCode:
            TextField("Postal Code", text: $teamDetails.postalCode)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        case .region:
            TextField("Region", text: $teamDetails.region)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        case .district:
            TextField("District", text: $teamDetails.district)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        case .department:
            TextField("Department", text: $teamDetails.department)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        case .governorate:
            TextField("Governorate", text: $teamDetails.governorate)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        case .emirate:
            TextField("Emirate", text: $teamDetails.emirate)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        case .parish:
            TextField("Parish", text: $teamDetails.region) // Assuming 'region' can represent parish
                .textFieldStyle(RoundedBorderTextFieldStyle())
        case .entity:
            TextField("Entity", text: $teamDetails.region) // Assuming 'region' can represent entity
                .textFieldStyle(RoundedBorderTextFieldStyle())
        case .municipality:
            TextField("Municipality", text: $teamDetails.region) // Assuming 'region' can represent municipality
                .textFieldStyle(RoundedBorderTextFieldStyle())
        case .division:
            TextField("Division", text: $teamDetails.region) // Assuming 'region' can represent division
                .textFieldStyle(RoundedBorderTextFieldStyle())
        case .zone:
            TextField("Zone", text: $teamDetails.region) // Assuming 'region' can represent zone
                .textFieldStyle(RoundedBorderTextFieldStyle())
        case .neighborhood:
            TextField("Neighborhood", text: $teamDetails.neighborhood)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        case .complement:
            TextField("Complement", text: $teamDetails.complement)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        case .apartment:
            TextField("Apartment", text: $teamDetails.apartment)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        case .additionalInfo:
            TextField("Additional Info", text: $teamDetails.additionalInfo)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        case .island:
            TextField("Island", text: $teamDetails.island)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        case .block:
            TextField("Block", text: $teamDetails.block)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        case .multilineAddress:
            // You may want to use a TextEditor instead of a TextField for multiline addresses
            TextEditor(text: $teamDetails.multilineAddress)
                .frame(height: 100)
                .border(Color.gray)
        }
    }
}

struct AddressFieldsView_Previews: PreviewProvider {
    static var previews: some View {
        AddressFieldsView(
            requiredFields: [.street, .city, .state, .postalCode],
            teamDetails: .constant(TeamDetails())
        )
        .previewLayout(.sizeThatFits)
    }
}
