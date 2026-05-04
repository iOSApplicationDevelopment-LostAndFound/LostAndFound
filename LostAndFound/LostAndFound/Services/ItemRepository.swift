//
//  ItemRepository.swift
//  LostAndFound
//
//  Created by Daniel You on 4/5/2026.
//

import Foundation
import Combine
import FirebaseFirestore

@MainActor
class ItemRepository: ObservableObject {
    @Published var items: [Item] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration? = nil

    init() {
        startListening()
    }

    deinit {
        listener?.remove()
    }

    func startListening() {
        isLoading = true
        listener = db.collection("items")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false

                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }

                guard let documents = snapshot?.documents else { return }

                self.items = documents.compactMap { doc in
                    Item(id: doc.documentID, data: doc.data())
                }
            }
    }

    func createItem(_ item: Item) async throws {
        let data = item.toFirestore()
        try await db.collection("items").document(item.id).setData(data)
    }

    func updateItem(_ item: Item) async throws {
        let data = item.toFirestore()
        try await db.collection("items").document(item.id).updateData(data)
    }

    func deleteItem(_ item: Item) async throws {
        try await db.collection("items").document(item.id).delete()
    }

    func markResolved(_ item: Item) async throws {
        try await db.collection("items").document(item.id).updateData([
            "status": "resolved"
        ])
    }
}
