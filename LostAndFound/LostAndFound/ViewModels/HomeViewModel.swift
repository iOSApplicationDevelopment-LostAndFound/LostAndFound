//
//  HomeViewModel.swift
//  LostAndFound
//
//  Created by Daniel You on 11/5/2026.
//

import Foundation

@MainActor
class HomeViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var selectedType: String? = nil
    @Published var selectedCategory: String? = nil

    let categories = ["bag", "electronics", "keys", "clothing", "other"]

    func filteredItems(from items: [Item]) -> [Item] {
        items.filter { item in
            let matchesSearch = searchText.isEmpty
                || item.title.localizedCaseInsensitiveContains(searchText)
                || item.description.localizedCaseInsensitiveContains(searchText)
                || item.location.localizedCaseInsensitiveContains(searchText)

            let matchesType = selectedType == nil || item.type == selectedType
            let matchesCategory = selectedCategory == nil || item.category == selectedCategory

            return matchesSearch && matchesType && matchesCategory && item.status == "active"
        }
    }
}
