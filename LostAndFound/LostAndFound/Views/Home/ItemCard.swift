//
//  ItemCard.swift
//  LostAndFound
//
//  Created by Daniel You on 5/5/2026.
//

import SwiftUI

struct ItemCard: View {
    let item: Item

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: item.createdAt, relativeTo: Date())
    }

    var body: some View {
        HStack(spacing: 12) {
            CategoryThumbnail(category: item.category)

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(item.title)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    TypeBadge(type: item.type)
                }

                Label(item.location, systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Text(item.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                HStack {
                    Text("Posted by \(item.postedByName)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(timeAgo)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.07), radius: 6, x: 0, y: 3)
    }
}

private struct CategoryThumbnail: View {
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
            RoundedRectangle(cornerRadius: 12)
                .fill(bgColor)
                .frame(width: 54, height: 54)
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(iconColor)
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
