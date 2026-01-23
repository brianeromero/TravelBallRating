//
//  AddressFieldView.swift
//  TravelBallRating
//
//  Created by Brian Romero on 11/22/24.
//

import Foundation
import SwiftUI

struct AddressFieldView: View {
    let field: AddressField
    @ObservedObject var teamDetails: TeamDetails

    var body: some View {
        VStack(alignment: .leading) {
            Text(field.rawValue.capitalized)
            TextField("Enter \(field.rawValue.capitalized)", text: binding(for: field))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .onChange(of: binding(for: field).wrappedValue) { oldValue, newValue in
                    print("Field \(field.rawValue) updated to: \(newValue)")
                }
        }
    }

    func binding(for field: AddressField) -> Binding<String> {
        AddressBindingHelper.binding(for: field, teamDetails: teamDetails)
    }
}
