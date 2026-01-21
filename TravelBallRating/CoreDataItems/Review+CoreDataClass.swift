//
//  Review+CoreDataClass.swift
//  Mat_Finder
//
//  Created by Brian Romero on 8/23/24.
//
//



import Foundation
import CoreData

@objc(Review)
public class Review: NSManagedObject {

    // Automatically set reviewID when a new object is inserted
    override public func awakeFromInsert() {
        super.awakeFromInsert()
        
        // Set a new UUID for the review
        self.reviewID = UUID()
        
        // Set createdTimestamp if not set
        if self.createdTimestamp == nil {
            self.createdTimestamp = Date()
        }
        
        print("Review object created with ID: \(self.reviewID.uuidString)")
    }


    // Firestore conversion helper
    func toFirestoreData() -> [String: Any] {
        return [
            "reviewID": self.reviewID.uuidString,
            "review": self.review ?? "",
            "stars": self.stars,
            "userName": self.userName ?? "",
            "createdTimestamp": self.createdTimestamp ?? Date(),
            "teamID": self.team?.teamID?.uuidString ?? ""
        ]
    }
}
