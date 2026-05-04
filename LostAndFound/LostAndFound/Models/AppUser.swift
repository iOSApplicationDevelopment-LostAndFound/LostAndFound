//
//  AppUser.swift
//  LostAndFound
//
//  Created by Daniel You on 2/5/2026.
//

import Foundation
import FirebaseFirestore

struct AppUser {
    let uid: String
    var displayName: String
    var email: String
    var createdAt: Date

    init?(uid: String, data: [String: Any]) {
        guard
            let displayName = data["displayName"] as? String,
            let email = data["email"] as? String,
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
        else { return nil }

        self.uid = uid
        self.displayName = displayName
        self.email = email
        self.createdAt = createdAt
    }

    func toFirestore() -> [String: Any] {
        return [
            "uid": uid,
            "displayName": displayName,
            "email": email,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
}
