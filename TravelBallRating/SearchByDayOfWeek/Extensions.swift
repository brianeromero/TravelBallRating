//
//  Extensions.swift
//  TravelBallRating
//
//  Created by Brian Romero on 8/25/24.
//

import Foundation

func == (lhs: (Team, [MatTime]), rhs: (Team, [MatTime])) -> Bool {
    lhs.0 == rhs.0 && lhs.1 == rhs.1
}

func == (lhs: [(Team, [MatTime])], rhs: [(Team, [MatTime])]) -> Bool {
    lhs.elementsEqual(rhs) { $0 == $1 }
}

func == (lhs: [DayOfWeek: [(Team, [MatTime])]], rhs: [DayOfWeek: [(Team, [MatTime])]]) -> Bool {
    lhs.elementsEqual(rhs) { $0.key == $1.key && $0.value == $1.value }
}
