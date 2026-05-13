//
//  Item.swift
//  LostAndFound
//
//  Created by Daniel You on 2/5/2026.
//

import Foundation
import FirebaseFirestore

struct Item: Identifiable {
    let id: String
    var title: String
    var description: String
    var category: String   // "bag" | "electronics" | "keys" | "clothing" | "other"
    var type: String       // "lost" | "found"
    var status: String     // "active" | "resolved"
    var location: String
    var latitude: Double?
    var longitude: Double?
    var photoURL: String?
    var postedBy: String
    var postedByName: String
    var createdAt: Date
    var claimedBy: String?
    var claimedByEmail: String?

    init?(id: String, data: [String: Any]) {
        guard
            let title = data["title"] as? String,
            let description = data["description"] as? String,
            let category = data["category"] as? String,
            let type = data["type"] as? String,
            let status = data["status"] as? String,
            let location = data["location"] as? String,
            let postedBy = data["postedBy"] as? String,
            let postedByName = data["postedByName"] as? String,
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
        else { return nil }

        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.type = type
        self.status = status
        self.location = location
        self.latitude = data["latitude"] as? Double
        self.longitude = data["longitude"] as? Double
        self.photoURL = data["photoURL"] as? String
        self.postedBy = postedBy
        self.postedByName = postedByName
        self.createdAt = createdAt
        self.claimedBy = data["claimedBy"] as? String
        self.claimedByEmail = data["claimedByEmail"] as? String
    }

    func toFirestore() -> [String: Any] {
        var dict: [String: Any] = [
            "title": title,
            "description": description,
            "category": category,
            "type": type,
            "status": status,
            "location": location,
            "postedBy": postedBy,
            "postedByName": postedByName,
            "createdAt": Timestamp(date: createdAt)
        ]
        if let latitude = latitude { dict["latitude"] = latitude }
        if let longitude = longitude { dict["longitude"] = longitude }
        if let photoURL = photoURL { dict["photoURL"] = photoURL }
        return dict
    }
}
