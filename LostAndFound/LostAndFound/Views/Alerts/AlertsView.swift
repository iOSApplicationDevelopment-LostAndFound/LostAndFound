//
//  AlertsView.swift
//  LostAndFound
//
//  Created by Shashank Nayak on 7/5/2026.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AlertNotification: Identifiable {
    let id: String
    let type: String
    let title: String
    let message: String
    let createdAt: Date
    var isRead: Bool

    init?(id: String, data: [String: Any]) {
        guard
            let type = data["type"] as? String,
            let title = data["title"] as? String,
            let message = data["message"] as? String,
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
        else { return nil }

        self.id = id
        self.type = type
        self.title = title
        self.message = message
        self.createdAt = createdAt
        self.isRead = data["isRead"] as? Bool ?? false
    }
}

struct AlertsView: View {
    @State private var notifications: [AlertNotification] = []
    @State private var isLoading = false
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if notifications.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bell.slash")
                        .font(.system(size: 44))
                        .foregroundColor(.secondary)
                    Text("No alerts yet")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(notifications) { notification in
                        AlertRow(notification: notification)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowSeparator(.hidden)
                            .onTapGesture {
                                markAsRead(notification)
                            }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Alerts")
        .navigationBarTitleDisplayMode(.large)
        .background(Color(.systemGroupedBackground))
        .onAppear { startListening() }
    }

    private func startListening() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        db.collection("notifications")
            .whereField("userId", isEqualTo: uid)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, _ in
                isLoading = false
                guard let docs = snapshot?.documents else { return }
                notifications = docs.compactMap { AlertNotification(id: $0.documentID, data: $0.data()) }
            }
    }

    private func markAsRead(_ notification: AlertNotification) {
        guard !notification.isRead else { return }
        db.collection("notifications").document(notification.id).updateData(["isRead": true])
    }
}

private struct AlertRow: View {
    let notification: AlertNotification

    var borderColor: Color {
        switch notification.type {
        case "match":    return .blue
        case "resolved": return .green
        case "nearby":   return Color.orange
        default:         return Color(.systemGray4)
        }
    }

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: notification.createdAt, relativeTo: Date())
    }

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(borderColor)
                .frame(width: 3)
                .cornerRadius(2)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(notification.isRead ? .secondary : .primary)
                    Spacer()
                    if !notification.isRead {
                        Circle()
                            .fill(.blue)
                            .frame(width: 8, height: 8)
                    }
                }
                Text(notification.message)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                Text(timeAgo)
                    .font(.caption2)
                    .foregroundColor(Color(.systemGray3))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

#Preview {
    NavigationStack {
        AlertsView()
    }
}
