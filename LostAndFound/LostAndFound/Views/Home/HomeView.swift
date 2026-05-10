//
//  HomeView.swift
//  LostAndFound
//
//  Created by Daniel You on 5/5/2026.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var itemRepository: ItemRepository
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Type filter toggle
                HStack(spacing: 8) {
                    TypeFilterButton(label: "All", isSelected: viewModel.selectedType == nil) {
                        viewModel.selectedType = nil
                    }
                    TypeFilterButton(label: "Lost", isSelected: viewModel.selectedType == "lost") {
                        viewModel.selectedType = viewModel.selectedType == "lost" ? nil : "lost"
                    }
                    TypeFilterButton(label: "Found", isSelected: viewModel.selectedType == "found") {
                        viewModel.selectedType = viewModel.selectedType == "found" ? nil : "found"
                    }
                    Spacer()
                }
                .padding(.horizontal)

                // Category pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.categories, id: \.self) { category in
                            CategoryPill(
                                label: category.capitalized,
                                isSelected: viewModel.selectedCategory == category
                            ) {
                                viewModel.selectedCategory = viewModel.selectedCategory == category ? nil : category
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Item list
                if itemRepository.isLoading {
                    ProgressView()
                        .padding(.top, 40)
                } else if viewModel.filteredItems(from: itemRepository.items).isEmpty {
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
                        ForEach(viewModel.filteredItems(from: itemRepository.items)) { item in
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
        .searchable(text: $viewModel.searchText, prompt: "Search items...")
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
