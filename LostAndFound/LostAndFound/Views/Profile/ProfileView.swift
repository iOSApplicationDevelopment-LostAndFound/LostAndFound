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
    var foundCount: Int { myItems.filter { $0.type == "found" }.count }
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
            VStack(spacing: 20) {
                VStack(spacing: 0) {
                    ZStack(alignment: .bottomTrailing) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.blue, .blue.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 80, height: 80)
                                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                            Text(initials.isEmpty ? "?" : initials)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }

                        ZStack {
                            Circle()
                                .fill(Color(.systemBackground))
                                .frame(width: 26, height: 26)
                            Image(systemName: "camera.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.blue)
                        }
                        .offset(x: 2, y: 2)
                    }
                    .padding(.bottom, 12)

                    Text(displayName)
                        .font(.title3)
                        .fontWeight(.bold)

                    Text(authService.currentUser?.email ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)

                HStack(spacing: 12) {
                    StatCard(value: lostCount, label: "Lost", color: .red)
                    StatCard(value: foundCount, label: "Found", color: .green)
                    StatCard(value: totalCount, label: "Total", color: .blue)
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 12) {
                    Text("My Posts")
                        .font(.headline)
                        .padding(.horizontal)

                    if myItems.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "tray")
                                .font(.system(size: 36))
                                .foregroundColor(.secondary)
                            Text("No posts yet")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                            Text("Start by posting a lost or found item")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(myItems) { item in
                                NavigationLink(destination: ItemDetailView(item: item)) {
                                    MyItemRow(item: item)
                                        .padding(.horizontal)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Button {
                    authService.signOut()
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Sign Out")
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.04), radius: 4)
                    .padding(.horizontal)
                }
                .padding(.bottom, 20)
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

    private var categoryIcon: String {
        switch item.category {
        case "bag":         return "backpack.fill"
        case "electronics": return "laptopcomputer"
        case "keys":        return "key.fill"
        case "clothing":    return "tshirt.fill"
        default:            return "shippingbox.fill"
        }
    }

    private var categoryColor: Color {
        switch item.category {
        case "bag":         return .orange
        case "electronics": return .purple
        case "keys":        return Color(red: 0.7, green: 0.6, blue: 0.1)
        case "clothing":    return .blue
        default:            return .gray
        }
    }

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: item.createdAt, relativeTo: Date())
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(categoryColor.opacity(0.12))
                    .frame(width: 46, height: 46)
                Image(systemName: categoryIcon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(categoryColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Label(item.location, systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
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
                Text(item.status == "resolved" ? "Resolved" : timeAgo)
                    .font(.caption2)
                    .foregroundColor(item.status == "resolved" ? .green : .secondary)
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
