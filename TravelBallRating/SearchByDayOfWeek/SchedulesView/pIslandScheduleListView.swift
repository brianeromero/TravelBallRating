//
//  teamScheduleListView.swift
//  TravelBallRating
//
//  Created by Brian Romero on 7/12/24.
//

import SwiftUI

struct teamScheduleListView: View {
    let day: DayOfWeek
    let schedules: [MatTime]

    var body: some View {
        VStack {
            Text("Schedules for \(day.displayName)")
                .font(.title)
                .padding()

            List {
                ForEach(schedules.sorted { $0.time ?? "" < $1.time ?? "" }, id: \.self) { matTime in
                    VStack(alignment: .leading) {
                        Text("Time: \(formatTime(matTime.time ?? "Unknown"))")
                            .font(.headline)
                        HStack {
                            Label("Gi", systemImage: matTime.gi ? "checkmark.circle.fill" : "xmark.circle")
                                .foregroundColor(matTime.gi ? .green : .red)
                            Label("NoGi", systemImage: matTime.noGi ? "checkmark.circle.fill" : "xmark.circle")
                                .foregroundColor(matTime.noGi ? .green : .red)
                            Label("Open Mat", systemImage: matTime.openMat ? "checkmark.circle.fill" : "xmark.circle")
                                .foregroundColor(matTime.openMat ? .green : .red)
                        }
                        if matTime.restrictions {
                            Text("Restrictions: \(matTime.restrictionDescription ?? "Yes")")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        if matTime.goodForBeginners {
                            Text("Good for Beginners")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        if matTime.kids {
                            Text("Kids Class")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                }
            }
        }
    }

    func formatTime(_ time: String) -> String {
        if let date = AppDateFormatter.twelveHour.date(from: time) {
            return AppDateFormatter.twelveHour.string(from: date)
        } else {
            return time
        }
    }

}

struct ScheduleRow: View {
    let matTime: MatTime

    var body: some View {
        VStack(alignment: .leading) {
            Text("Time: \(matTime.time ?? "No time set")")
                .font(.body)
            Text("Gi: \(matTime.gi ? "Yes" : "No")")
                .font(.caption)
            Text("NoGi: \(matTime.noGi ? "Yes" : "No")")
                .font(.caption)
            Text("Open Mat: \(matTime.openMat ? "Yes" : "No")")
                .font(.caption)
            Text("Restrictions: \(matTime.restrictions ? "Yes" : "No")")
                .font(.caption)
            if let restrictionDesc = matTime.restrictionDescription, !restrictionDesc.isEmpty {
                Text("Restriction Description: \(restrictionDesc)")
                    .font(.caption)
            }
            Text("Good for Beginners: \(matTime.goodForBeginners ? "Yes" : "No")")
                .font(.caption)
            Text("Kids: \(matTime.kids ? "Yes" : "No")")
                .font(.caption)
        }
        .padding(.vertical, 5)
    }
}
