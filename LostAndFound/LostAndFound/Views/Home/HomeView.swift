//
//  HomeView.swift
//  LostAndFound
//
//  Created by Daniel You on 5/5/2026.
//

import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = HomeViewModel()
    @State private var pendingDeleteItem: Item? = nil
    @State private var isDeleting: Bool = false
    @State private var deleteErrorMessage: String? = nil

    private var filteredItems: [Item] {
        viewModel.filteredItems(from: itemRepository.items)
    }

    var body: some View {
        VStack(spacing: 0) {
            filterControls

            if itemRepository.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if filteredItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No items found")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredItems) { item in
                        NavigationLink(destination: ItemDetailView(item: item)) {
                            ItemCard(item: item)
                                .padding(.vertical, 4)
                                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        }
                        .buttonStyle(.plain)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if ItemOwnership.isOwner(item: item, currentUserUID: authService.currentUser?.uid) {
                                Button(role: .destructive) {
                                    pendingDeleteItem = item
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(.red)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Lost & Found")
        .searchable(text: $viewModel.searchText, prompt: "Search items...")
        .background(Color(.systemGroupedBackground))
        .alert(
            "Delete this item?",
            isPresented: deleteConfirmationBinding,
            presenting: pendingDeleteItem
        ) { item in
            Button("Delete", role: .destructive) {
                Task { await delete(item) }
            }
            Button("Cancel", role: .cancel) {
                pendingDeleteItem = nil
            }
        } message: { _ in
            Text("This removes the post and any uploaded photo.")
        }
        .alert("Delete Failed", isPresented: deleteErrorBinding) {
            Button("OK", role: .cancel) {
                deleteErrorMessage = nil
            }
        } message: {
            Text(deleteErrorMessage ?? "The item could not be deleted.")
        }
    }

    private var filterControls: some View {
        VStack(spacing: 12) {
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
            }

            if isDeleting {
                ProgressView("Deleting item...")
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    private var deleteConfirmationBinding: Binding<Bool> {
        Binding(
            get: { pendingDeleteItem != nil },
            set: { isPresented in
                if !isPresented {
                    pendingDeleteItem = nil
                }
            }
        )
    }

    private var deleteErrorBinding: Binding<Bool> {
        Binding(
            get: { deleteErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    deleteErrorMessage = nil
                }
            }
        )
    }

    private func delete(_ item: Item) async {
        isDeleting = true
        deleteErrorMessage = nil

        do {
            try await itemRepository.deleteItem(item)
            pendingDeleteItem = nil
        } catch {
            deleteErrorMessage = error.localizedDescription
        }

        isDeleting = false
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
