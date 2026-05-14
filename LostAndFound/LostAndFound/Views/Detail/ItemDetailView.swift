//
//  ItemDetailView.swift
//  LostAndFound
//
//  Created by Daniel You on 5/5/2026.
//

import SwiftUI
import MapKit
import FirebaseAuth
import FirebaseFirestore

struct ItemDetailView: View {
    let item: Item

    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var itemRepository: ItemRepository
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ItemDetailViewModel()

    var body: some View {
        let liveItem = viewModel.liveItem(from: itemRepository, fallback: item)
        let isOwner = viewModel.isOwner(item: liveItem, currentUserUID: authService.currentUser?.uid)
        let isResolved = liveItem.status == "resolved"

        ScrollView {
            VStack(spacing: 0) {
                ItemHeader(item: liveItem)

                VStack(alignment: .leading, spacing: 16) {
                    // Type + Status banner
                    HStack(spacing: 8) {
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
                    Text(liveItem.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(liveItem.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Divider()

                    // Details
                    VStack(spacing: 0) {
                        DetailRow(icon: "mappin.and.ellipse", label: "Location", value: liveItem.location)
                        Divider().padding(.leading, 32)
                        DetailRow(icon: "person.fill", label: "Posted by", value: liveItem.postedByName)
                        Divider().padding(.leading, 32)
                        DetailRow(icon: "clock", label: "Posted", value: liveItem.createdAt.formatted(date: .long, time: .shortened))
                        if !isOwner && viewModel.hasNotified {
                            Divider().padding(.leading, 32)
                            ContactRow(email: liveItem.postedBy)
                        }
                    }
                    .padding(.vertical, 4)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

                    if let lat = liveItem.latitude, let lon = liveItem.longitude {
                        MiniMapView(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    if isOwner {
                        ownerActions(for: liveItem)
                    }

                    // Mark resolved — only shown to the owner on active items
                    if isOwner && !isResolved {
                        Button {
                            viewModel.showConfirm = true
                        } label: {
                            if viewModel.isClaiming {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else {
                                Text("Mark as Resolved")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                    .fontWeight(.semibold)
                            }
                        }
                        .disabled(viewModel.isClaiming)
                    }

                    // Notify owner — shown to non-owners on active items
                    if !isOwner && !isResolved {
                        if viewModel.hasNotified {
                            HStack {
                                Image(systemName: "bell.fill")
                                    .foregroundColor(.blue)
                                Text("Owner has been notified!")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        } else {
                            Button {
                                Task {
                                    let name = authService.currentUser?.displayName
                                        ?? authService.currentUser?.email
                                        ?? "Someone"
                                    let email = authService.currentUser?.email ?? ""
                                    await viewModel.notifyOwner(item: liveItem, claimerName: name, claimerEmail: email)
                                }
                            } label: {
                                if viewModel.isNotifying {
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
                            .disabled(viewModel.isNotifying)

                            Text("By tapping this, you confirm this item belongs to you or you have found it. The owner will be notified to arrange a handover.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                        }
                    }

                    if isResolved {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("This item has been resolved")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                            }
                            if let claimedBy = liveItem.claimedBy, let claimedByEmail = liveItem.claimedByEmail {
                                Divider()
                                HStack(spacing: 4) {
                                    Text("Claimed by")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(claimedBy)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                                Text(claimedByEmail)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("Item Detail")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .confirmationDialog(
            "Mark this item as resolved?",
            isPresented: $viewModel.showConfirm,
            titleVisibility: .visible
        ) {
            Button("Yes, mark as resolved") {
                Task { await viewModel.claimItem(liveItem, using: itemRepository) }
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog(
            "Remove this item?",
            isPresented: $viewModel.showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Remove Item", role: .destructive) {
                Task {
                    if await viewModel.deleteItem(liveItem, using: itemRepository) {
                        dismiss()
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently removes the post. If it has a photo, the stored image will be removed too.")
        }
        .sheet(isPresented: $viewModel.showEditSheet) {
            NavigationStack {
                PostView(editingItem: liveItem)
            }
            .environmentObject(authService)
            .environmentObject(itemRepository)
        }
    }

    @ViewBuilder
    private func ownerActions(for liveItem: Item) -> some View {
        VStack(spacing: 10) {
            Button {
                viewModel.showEditSheet = true
            } label: {
                Label("Edit", systemImage: "pencil")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(12)
                    .fontWeight(.semibold)
            }

            Button(role: .destructive) {
                viewModel.showDeleteConfirm = true
            } label: {
                if viewModel.isDeleting {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Label("Remove", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.12))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                        .fontWeight(.semibold)
                }
            }
            .disabled(viewModel.isDeleting)
        }
    }
}

private struct ItemHeader: View {
    let item: Item

    var body: some View {
        if let photoURL = item.photoURL, let url = URL(string: photoURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Color(.systemGray5)
                        ProgressView()
                    }
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    CategoryHeader(category: item.category)
                @unknown default:
                    CategoryHeader(category: item.category)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 190)
            .clipped()
        } else {
            CategoryHeader(category: item.category)
        }
    }
}

private struct CategoryHeader: View {
    let category: String

    private var icon: String {
        switch category {
        case "bag":         return "backpack.fill"
        case "electronics": return "laptopcomputer"
        case "keys":        return "key.fill"
        case "clothing":    return "tshirt.fill"
        default:            return "shippingbox.fill"
        }
    }

    private var bgColor: Color {
        switch category {
        case "bag":         return Color.orange.opacity(0.15)
        case "electronics": return Color.purple.opacity(0.15)
        case "keys":        return Color.yellow.opacity(0.2)
        case "clothing":    return Color.blue.opacity(0.12)
        default:            return Color.gray.opacity(0.12)
        }
    }

    private var iconColor: Color {
        switch category {
        case "bag":         return .orange
        case "electronics": return .purple
        case "keys":        return Color(red: 0.7, green: 0.6, blue: 0.1)
        case "clothing":    return .blue
        default:            return .gray
        }
    }

    var body: some View {
        ZStack {
            bgColor
            Image(systemName: icon)
                .font(.system(size: 72, weight: .medium))
                .foregroundColor(iconColor)
                .padding(.vertical, 40)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160)
    }
}

private struct MiniMapView: View {
    let coordinate: CLLocationCoordinate2D

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Location on map")
                .font(.caption)
                .foregroundColor(.secondary)

            Map(position: .constant(.region(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
            )))) {
                Annotation("", coordinate: coordinate) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white, .red)
                }
            }
            .mapStyle(.standard)
            .disabled(true)
            .frame(height: 160)
            .cornerRadius(12)
        }
    }
}

private struct ContactRow: View {
    let email: String
    @State private var posterEmail: String = ""

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "envelope.fill")
                .frame(width: 20)
                .foregroundColor(.blue)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 3) {
                Text("Contact poster")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if posterEmail.isEmpty {
                    Text("Loading...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Link(posterEmail, destination: URL(string: "mailto:\(posterEmail)")!)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .task { await fetchEmail() }
    }

    private func fetchEmail() async {
        let db = Firestore.firestore()
        guard let doc = try? await db.collection("users").document(email).getDocument(),
              let fetchedEmail = doc.data()?["email"] as? String else { return }
        posterEmail = fetchedEmail
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
                .foregroundColor(.blue)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
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
        case "bag":         return "backpack.fill"
        case "electronics": return "laptopcomputer"
        case "keys":        return "key.fill"
        case "clothing":    return "tshirt.fill"
        default:            return "shippingbox.fill"
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
