//
//  ItemDetailViewModel.swift
//  LostAndFound
//
//  Created by Daniel You on 11/5/2026.
//

import Foundation
import Combine
@MainActor
class ItemDetailViewModel: ObservableObject {
    @Published var isClaiming: Bool = false
    @Published var showConfirm: Bool = false
    @Published var errorMessage: String? = nil

    func liveItem(from repository: ItemRepository, fallback: Item) -> Item {
        repository.items.first { $0.id == fallback.id } ?? fallback
    }

    func isOwner(item: Item, currentUserUID: String?) -> Bool {
        currentUserUID == item.postedBy
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
}
