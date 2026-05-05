//
//  HomeView.swift
//  LostAndFound
//
//  Created by Daniel You on 5/5/2026.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var itemRepository: ItemRepository

    @State private var searchText: String = ""
    @State private var selectedType: String? = nil      // nil = all, "lost", "found"
    @State private var selectedCategory: String? = nil

    let categories = ["bag", "electronics", "keys", "clothing", "other"]

    var filteredItems: [Item] {
        itemRepository.items.filter { item in
            let matchesSearch = searchText.isEmpty
                || item.title.localizedCaseInsensitiveContains(searchText)
                || item.description.localizedCaseInsensitiveContains(searchText)
                || item.location.localizedCaseInsensitiveContains(searchText)

            let matchesType = selectedType == nil || item.type == selectedType
            let matchesCategory = selectedCategory == nil || item.category == selectedCategory

            return matchesSearch && matchesType && matchesCategory && item.status == "active"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Type filter toggle
                HStack(spacing: 8) {
                    TypeFilterButton(label: "All", isSelected: selectedType == nil) {
                        selectedType = nil
                    }
                    TypeFilterButton(label: "Lost", isSelected: selectedType == "lost") {
                        selectedType = selectedType == "lost" ? nil : "lost"
                    }
                    TypeFilterButton(label: "Found", isSelected: selectedType == "found") {
                        selectedType = selectedType == "found" ? nil : "found"
                    }
                    Spacer()
                }
                .padding(.horizontal)

                // Category pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.self) { category in
                            CategoryPill(
                                label: category.capitalized,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = selectedCategory == category ? nil : category
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Item list
                if itemRepository.isLoading {
                    ProgressView()
                        .padding(.top, 40)
                } else if filteredItems.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No items found")
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 60)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredItems) { item in
                            NavigationLink(destination: ItemDetailView(item: item)) {
                                ItemCard(item: item)
                                    .padding(.horizontal)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.vertical, 12)
        }
        .navigationTitle("Lost & Found")
        .searchable(text: $searchText, prompt: "Search items...")
        .background(Color(.systemGroupedBackground))
    }
}

private struct TypeFilterButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
    }
}

private struct CategoryPill: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSelected ? Color.blue.opacity(0.15) : Color(.systemGray6))
                .foregroundColor(isSelected ? .blue : .secondary)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
                )
        }
    }
}
