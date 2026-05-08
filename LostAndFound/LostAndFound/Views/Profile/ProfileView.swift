//
//  ProfileView.swift
//  LostAndFound
//
//  Created by Shashank Nayak on 8/5/2026.
//

import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var itemRepository: ItemRepository

    var myItems: [Item] {
        guard let uid = authService.currentUser?.uid else { return [] }
        return itemRepository.items.filter { $0.postedBy == uid }
    }

    var lostCount: Int { myItems.filter { $0.type == "lost" }.count }
    var returnedCount: Int { myItems.filter { $0.status == "resolved" }.count }
    var totalCount: Int { myItems.count }

    var displayName: String {
        authService.currentUser?.displayName ?? authService.currentUser?.email ?? "User"
    }

    var initials: String {
        let name = authService.currentUser?.displayName ?? ""
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(1)).uppercased()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 64, height: 64)
                        Text(initials.isEmpty ? "?" : initials)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    Text(displayName)
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text(authService.currentUser?.email ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)

                HStack(spacing: 12) {
                    StatCard(value: lostCount, label: "Items Lost", color: .red)
                    StatCard(value: returnedCount, label: "Returned", color: .green)
                    StatCard(value: totalCount, label: "Posts Total", color: .blue)
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 10) {
                    Text("My Posts")
                        .font(.headline)
                        .padding(.horizontal)

                    if myItems.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "tray")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary)
                            Text("No posts yet")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(myItems) { item in
                                MyItemRow(item: item)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }

                Button {
                    authService.signOut()
                } label: {
                    Text("Sign Out")
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
                .padding(.bottom, 16)
            }
        }
        .navigationTitle("Profile")
        .background(Color(.systemGroupedBackground))
    }
}

private struct StatCard: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

private struct MyItemRow: View {
    let item: Item

    var typeColor: Color { item.type == "lost" ? .red : .green }
    var statusColor: Color { item.status == "resolved" ? .secondary : typeColor }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Label(item.location, systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(item.type.capitalized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(typeColor.opacity(0.12))
                    .foregroundColor(typeColor)
                    .cornerRadius(6)
                Text(item.status.capitalized)
                    .font(.caption2)
                    .foregroundColor(item.status == "resolved" ? .secondary : typeColor)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
    .environmentObject(AuthService())
    .environmentObject(ItemRepository())
}
