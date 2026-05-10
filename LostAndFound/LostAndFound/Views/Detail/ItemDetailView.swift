//
//  ItemDetailView.swift
//  LostAndFound
//
//  Created by Daniel You on 5/5/2026.
//

import SwiftUI
import FirebaseAuth

struct ItemDetailView: View {
    let item: Item

    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var itemRepository: ItemRepository

    @State private var isClaiming: Bool = false
    @State private var showConfirm: Bool = false
    @State private var errorMessage: String? = nil

    // Always read from the live repository so UI reflects Firestore updates instantly
    private var liveItem: Item {
        itemRepository.items.first { $0.id == item.id } ?? item
    }

    private var isOwner: Bool {
        authService.currentUser?.uid == liveItem.postedBy
    }

    private var isResolved: Bool {
        liveItem.status == "resolved"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Type + Status banner
                HStack {
                    TypeBadge(type: liveItem.type)
                    if isResolved {
                        Text("Resolved")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.gray.opacity(0.15))
                            .foregroundColor(.gray)
                            .cornerRadius(6)
                    }
                    Spacer()
                    CategoryBadge(category: liveItem.category)
                }

                // Title + Description
                VStack(alignment: .leading, spacing: 8) {
                    Text(liveItem.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(liveItem.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }

                Divider()

                // Details
                VStack(alignment: .leading, spacing: 12) {
                    DetailRow(icon: "mappin.and.ellipse", label: "Location", value: liveItem.location)
                    DetailRow(icon: "person", label: "Posted by", value: liveItem.postedByName)
                    DetailRow(
                        icon: "calendar",
                        label: "Date",
                        value: liveItem.createdAt.formatted(date: .long, time: .shortened)
                    )
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                // Claim button — only shown to non-owners on active items
                if !isOwner && !isResolved {
                    Button {
                        showConfirm = true
                    } label: {
                        if isClaiming {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text(liveItem.type == "lost" ? "I Found This" : "This Is Mine")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isClaiming)
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Item Detail")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .confirmationDialog(
            "Mark this item as resolved?",
            isPresented: $showConfirm,
            titleVisibility: .visible
        ) {
            Button("Yes, mark as resolved") {
                Task { await claimItem() }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func claimItem() async {
        isClaiming = true
        errorMessage = nil
        do {
            try await itemRepository.markResolved(liveItem)
        } catch {
            errorMessage = error.localizedDescription
        }
        isClaiming = false
    }
}

private struct DetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundColor(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
            }
        }
    }
}

private struct TypeBadge: View {
    let type: String

    var body: some View {
        Text(type.capitalized)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(type == "lost" ? Color.red.opacity(0.12) : Color.green.opacity(0.12))
            .foregroundColor(type == "lost" ? .red : .green)
            .cornerRadius(6)
    }
}

private struct CategoryBadge: View {
    let category: String

    private var icon: String {
        switch category {
        case "bag":         return "bag"
        case "electronics": return "laptopcomputer"
        case "keys":        return "key"
        case "clothing":    return "tshirt"
        default:            return "questionmark.circle"
        }
    }

    var body: some View {
        Label(category.capitalized, systemImage: icon)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color(.systemGray5))
            .cornerRadius(6)
    }
}
