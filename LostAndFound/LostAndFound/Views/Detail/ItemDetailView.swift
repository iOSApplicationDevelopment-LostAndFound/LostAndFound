//
//  ItemDetailView.swift
//  LostAndFound
//
//  Created by Daniel You on 5/5/2026.
//

import SwiftUI
import MapKit
import FirebaseAuth

struct ItemDetailView: View {
    let item: Item

    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var itemRepository: ItemRepository
    @StateObject private var viewModel = ItemDetailViewModel()

    var body: some View {
        let liveItem = viewModel.liveItem(from: itemRepository, fallback: item)
        let isOwner = viewModel.isOwner(item: liveItem, currentUserUID: authService.currentUser?.uid)
        let isResolved = liveItem.status == "resolved"

        ScrollView {
            VStack(spacing: 0) {
                CategoryHeader(category: liveItem.category)

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

                    if isResolved {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("This item has been resolved")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                        .frame(maxWidth: .infinity)
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
