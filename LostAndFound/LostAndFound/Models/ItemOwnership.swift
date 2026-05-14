//
//  ItemOwnership.swift
//  LostAndFound
//
//  Created by Codex on 14/5/2026.
//

import Foundation

enum ItemOwnership {
    static func isOwner(item: Item, currentUserUID: String?) -> Bool {
        guard let currentUserUID else { return false }
        return item.postedBy == currentUserUID
    }
}
