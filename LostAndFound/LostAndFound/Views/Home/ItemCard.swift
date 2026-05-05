//
//  ItemCard.swift
//  LostAndFound
//
//  Created by Daniel You on 5/5/2026.
//

import SwiftUI

struct ItemCard: View {
    let item: Item

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                TypeBadge(type: item.type)
            }

            Text(item.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)

            HStack(spacing: 12) {
                Label(item.location, systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(item.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                CategoryBadge(category: item.category)
                Spacer()
                Text("Posted by \(item.postedByName)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
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
