//
//  ItemDetailViewModel.swift
//  LostAndFound
//
//  Created by Daniel You on 11/5/2026.
//

import Foundation
import Combine
import FirebaseFirestore

@MainActor
class ItemDetailViewModel: ObservableObject {
    @Published var isClaiming: Bool = false
    @Published var showConfirm: Bool = false
    @Published var showEditSheet: Bool = false
    @Published var showDeleteConfirm: Bool = false
    @Published var isDeleting: Bool = false
    @Published var isNotifying: Bool = false
    @Published var hasNotified: Bool = false
    @Published var errorMessage: String? = nil

    private let db = Firestore.firestore()

    func liveItem(from repository: ItemRepository, fallback: Item) -> Item {
        repository.items.first { $0.id == fallback.id } ?? fallback
    }

    func isOwner(item: Item, currentUserUID: String?) -> Bool {
        ItemOwnership.isOwner(item: item, currentUserUID: currentUserUID)
    }

    func claimItem(_ item: Item, using repository: ItemRepository) async {
        isClaiming = true
        errorMessage = nil
        do {
            try await repository.markResolved(item)
        } catch {
            errorMessage = error.localizedDescription
        }
        isClaiming = false
    }

    func notifyOwner(item: Item, claimerName: String, claimerEmail: String) async {
        isNotifying = true
        errorMessage = nil
        let title = item.type == "lost" ? "Someone found your item!" : "Someone claims this is theirs!"
        let message = item.type == "lost"
            ? "\(claimerName) says they found your \(item.title). Contact them at \(claimerEmail)"
            : "\(claimerName) says your \(item.title) belongs to them. Contact them at \(claimerEmail)"

        let notifData: [String: Any] = [
            "userId": item.postedBy,
            "type": "match",
            "title": title,
            "message": message,
            "createdAt": Timestamp(date: Date()),
            "isRead": false
        ]
        do {
            try await db.collection("notifications").addDocument(data: notifData)
            try await db.collection("items").document(item.id).updateData([
                "claimedBy": claimerName,
                "claimedByEmail": claimerEmail
            ])
            hasNotified = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isNotifying = false
    }

    func deleteItem(_ item: Item, using repository: ItemRepository) async -> Bool {
        isDeleting = true
        errorMessage = nil

        do {
            try await repository.deleteItem(item)
            isDeleting = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isDeleting = false
            return false
        }
    }
}
