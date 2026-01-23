//
//  EnterZipCodeViewModel.swift
//  TravelBallRating
//
//  Created by Brian Romero on 6/29/24.
//

import Foundation
import SwiftUI
import CoreData
import Combine
import CoreLocation
import MapKit



@MainActor
class EnterZipCodeViewModel: ObservableObject {
    // MARK: - Published properties
    @Published var region: MKCoordinateRegion
    @Published var postalCode: String = ""
    @Published var enteredLocation: CustomMapMarker?
    @Published var teams: [CustomMapMarker] = []
    @Published var address: String = ""
    
    @Published var currentRadius: Double = 5.0 {
        didSet {
            if let location = locationManager.userLocation {
                updateRegion(location, radius: currentRadius)
                fetchTeamsNear(location, within: currentRadius * 1609.34)
            }
        }
    }

    // MARK: - Private properties
    private var repository: AppDayOfWeekRepository
    private var context: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()
    private let geocoder = CLGeocoder()
    private let updateQueue = DispatchQueue(label: "com.example.TravelBallRating.updateQueue")
    private let earthRadius = 6371.0088 // km

    // MARK: - Location manager
    let locationManager = UserLocationMapViewModel.shared

    // MARK: - Init
    init(repository: AppDayOfWeekRepository, persistenceController: PersistenceController) {
        self.repository = repository
        self.context = persistenceController.viewContext
        self.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )

        // Observe user location changes
        locationManager.$userLocation
            .sink { [weak self] userLocation in
                guard let self, let location = userLocation else { return }
                self.updateRegion(location, radius: self.currentRadius)
                self.fetchTeamsNear(location, within: self.currentRadius * 1609.34)
            }
            .store(in: &cancellables)

        locationManager.startLocationServices()
    }

    // MARK: - Helpers

    func isValidPostalCode() -> Bool {
        postalCode.count == 5 && postalCode.allSatisfy(\.isNumber)
    }

    func fetchLocation(for address: String) {
        Task {
            do {
                let coordinate = try await MapUtils.geocodeAddressWithFallback(address)

                await MainActor.run {
                    // Update region
                    self.region = MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(
                            latitudeDelta: currentRadius / 69.0,
                            longitudeDelta: currentRadius / 69.0
                        )
                    )

                    // Update entered location
                    self.enteredLocation = CustomMapMarker(
                        id: UUID(),
                        coordinate: coordinate,
                        title: address,
                        team: nil
                    )

                    // Fetch nearby teams
                    self.fetchTeamsNear(
                        CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude),
                        within: currentRadius * 1609.34
                    )
                }
            } catch {
                print("Geocoding error: \(error.localizedDescription)")
            }
        }
    }

    func fetchTeamsNear(_ location: CLLocation, within radius: Double) {
        let fetchRequest: NSFetchRequest<Team> = Team.fetchRequest()

        // Bounding box optimization
        let latDelta = radius / earthRadius * (180.0 / .pi)
        let lonDelta = radius / (earthRadius * cos(location.coordinate.latitude * .pi / 180.0)) * (180.0 / .pi)

        let minLat = location.coordinate.latitude - latDelta
        let maxLat = location.coordinate.latitude + latDelta
        let minLon = location.coordinate.longitude - lonDelta
        let maxLon = location.coordinate.longitude + lonDelta

        fetchRequest.predicate = NSPredicate(
            format: "latitude >= %f AND latitude <= %f AND longitude >= %f AND longitude <= %f",
            minLat, maxLat, minLon, maxLon
        )

        do {
            let teams = try context.fetch(fetchRequest)
            let filteredTeams = teams.filter { team in
                let teamLocation = CLLocation(latitude: team.latitude, longitude: team.longitude)
                return teamLocation.distance(from: location) <= radius
            }

            self.teams = filteredTeams.map { team in
                CustomMapMarker(
                    id: team.teamID ?? UUID(),
                    coordinate: CLLocationCoordinate2D(latitude: team.latitude, longitude: team.longitude),
                    title: team.teamName,
                    team: team
                )
            }
        } catch {
            print("Error fetching teams: \(error.localizedDescription)")
        }
    }

    func updateRegion(_ userLocation: CLLocation, radius: Double) {
        let span = MKCoordinateSpan(latitudeDelta: radius / 69.0, longitudeDelta: radius / 69.0)
        self.region = MKCoordinateRegion(center: userLocation.coordinate, span: span)
    }
}

// MARK: - Helper
extension EnterZipCodeViewModel {
    @MainActor
    func updateMarkersForCenter(_ center: CLLocationCoordinate2D, span: MKCoordinateSpan) {
        let radiusMeters = MapUtils.estimateVisibleRadius(from: span)

        fetchTeamsNear(
            CLLocation(latitude: center.latitude, longitude: center.longitude),
            within: radiusMeters
        )

        // 👇 Keep the map region synced with what the user is viewing
        self.region = MKCoordinateRegion(center: center, span: span)
    }

}
