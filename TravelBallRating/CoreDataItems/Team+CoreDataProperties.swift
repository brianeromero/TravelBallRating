//
// Team+CoreDataProperties.swift
// TravelBallRating
//
// Created by Brian Romero on 6/24/24.
//
import Foundation
import CoreData

extension Team: Identifiable {}

extension Team {

    // MARK: - Fetch Request
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Team> {
        NSFetchRequest<Team>(entityName: "Team")
    }

    // MARK: - Attributes
    @NSManaged public var teamID: UUID?
    @NSManaged public var teamName: String
    @NSManaged public var teamLocation: String
    @NSManaged public var teamDescription: String?
    @NSManaged public var teamWebsite: URL?

    @NSManaged public var sport: String?
    @NSManaged public var gender: String?
    @NSManaged public var ageGroup: String?

    @NSManaged public var rosterCount: Int16
    @NSManaged public var dues: Double
    @NSManaged public var feederTeam: Bool

    @NSManaged public var coachName: String?
    @NSManaged public var contactEmail: String?

    @NSManaged public var country: String?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double

    @NSManaged public var createdByUserId: String?
    @NSManaged public var createdTimestamp: Date?
    @NSManaged public var lastModifiedByUserId: String?
    @NSManaged public var lastModifiedTimestamp: Date?

    // MARK: - Relationships
    @NSManaged public var appDayOfWeeks: NSSet?
    @NSManaged public var reviews: NSOrderedSet?

    // MARK: - Review Relationship Helpers
    public var reviewsArray: [Review] {
        reviews?.array as? [Review] ?? []
    }

    func addReview(_ review: Review) {
        let set = mutableOrderedSetValue(forKey: "reviews")
        set.add(review)
    }

    func removeReview(_ review: Review) {
        let set = mutableOrderedSetValue(forKey: "reviews")
        set.remove(review)
    }

    // MARK: - Day Helpers
    public var daysOfWeekArray: [AppDayOfWeek] {
        let set = appDayOfWeeks as? Set<AppDayOfWeek> ?? []
        return set.sorted { $0.day < $1.day }
    }

    // MARK: - Computed / Safe Values
    public var safeCountry: String {
        country ?? "Unknown Country"
    }

    public var formattedCoordinates: String {
        String(format: "%.6f, %.6f", latitude, longitude)
    }

    public var formattedCreatedTimestamp: String {
        AppDateFormatter.mediumDateTime.string(from: createdTimestamp ?? Date())
    }

    public var formattedUpdatedTimestamp: String {
        AppDateFormatter.full.string(from: lastModifiedTimestamp ?? Date())
    }

    // MARK: - Generated Accessors (AppDayOfWeeks)
    @objc(addAppDayOfWeeksObject:)
    @NSManaged public func addToAppDayOfWeeks(_ value: AppDayOfWeek)

    @objc(removeAppDayOfWeeksObject:)
    @NSManaged public func removeFromAppDayOfWeeks(_ value: AppDayOfWeek)

    @objc(addAppDayOfWeeks:)
    @NSManaged public func addToAppDayOfWeeks(_ values: NSSet)

    @objc(removeAppDayOfWeeks:)
    @NSManaged public func removeFromAppDayOfWeeks(_ values: NSSet)

    // MARK: - Generated Accessors (Reviews)
    @objc(insertObject:inReviewsAtIndex:)
    @NSManaged public func insertIntoReviews(_ value: Review, at idx: Int)

    @objc(removeObjectFromReviewsAtIndex:)
    @NSManaged public func removeFromReviews(at idx: Int)

    @objc(replaceObjectInReviewsAtIndex:withObject:)
    @NSManaged public func replaceReviews(at idx: Int, with value: Review)

    // MARK: - Firestore Conversion
    func toFirestoreData() -> [String: Any] {
        [
            "teamID": teamID?.uuidString as Any,
            "teamName": teamName,
            "teamLocation": teamLocation,
            "teamDescription": teamDescription as Any,
            "sport": sport as Any,
            "gender": gender as Any,
            "ageGroup": ageGroup as Any,
            "rosterCount": Int(rosterCount),
            "dues": dues,
            "feederTeam": feederTeam,
            "coachName": coachName as Any,
            "contactEmail": contactEmail as Any,
            "latitude": latitude,
            "longitude": longitude,
            "country": country as Any,
            "createdByUserId": createdByUserId as Any,
            "createdTimestamp": createdTimestamp as Any,
            "lastModifiedByUserId": lastModifiedByUserId as Any,
            "lastModifiedTimestamp": lastModifiedTimestamp as Any
        ]
    }
}
