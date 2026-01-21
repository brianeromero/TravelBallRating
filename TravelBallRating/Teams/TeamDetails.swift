//
//  TeamFormData.swift
//  TravelBallRating
//
//  Created by Brian Romero on 1/14/26.
//

import Foundation


enum SportType: String, CaseIterable, Identifiable {
    case baseball = "Baseball"
    case softball = "Softball"
    case soccer = "Soccer"
    case basketball = "Basketball"
    case waterpolo = "Water Polo"
    case volleyball = "Volleyball"
    case hockey = "Hockey"
    case other = "Other"

    var id: String { rawValue }

    var allowsCustomEntry: Bool {
        self == .other
    }
}


enum GenderType: String, CaseIterable, Identifiable {
    case girls = "Girls"
    case boys = "Boys"
    case coed = "Co-Ed"
    
    var id: String { rawValue }
}

enum AgeGroupType: String, CaseIterable, Identifiable {
    case u5 = "5U"
    case u6 = "6U"
    case u7 = "7U"
    case u8 = "8U"
    case u9 = "9U"
    case u10 = "10U"
    case u11 = "11U"
    case u12 = "12U"
    case u13 = "13U"
    case u14 = "14U"
    case u15 = "15U"
    case u16 = "16U"
    case u17 = "17U"
    case u18 = "18U"
    
    var id: String { rawValue }
}

struct TeamFormData {
    var sport: SportType = .baseball
    var customSportName: String = ""
}

extension TeamFormData {
    var resolvedSportName: String {
        sport == .other && !customSportName.isEmpty
            ? customSportName
            : sport.rawValue
    }
}
