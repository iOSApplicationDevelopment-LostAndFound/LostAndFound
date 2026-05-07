//
//  MainTabView.swift
//  LostAndFound
//
//  Created by Daniel You on 4/5/2026.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }

            NavigationStack {
                MapView()
            }
            .tabItem {
                Label("Map", systemImage: "map")
            }

            NavigationStack {
                PostView()
            }
            .tabItem {
                Label("Post", systemImage: "plus.circle")
            }

            NavigationStack {
                PlaceholderTabView(title: "Alerts", systemImage: "bell")
            }
            .tabItem {
                Label("Alerts", systemImage: "bell")
            }

            NavigationStack {
                ProfileTabView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.circle")
            }
        }
    }
}

private struct PlaceholderTabView: View {
    let title: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundColor(.blue)

            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(title)
    }
}

private struct ProfileTabView: View {
    @EnvironmentObject var authService: AuthService

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.circle")
                .font(.system(size: 48))
                .foregroundColor(.blue)

            Text("Profile")
                .font(.title2)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Profile")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Sign Out") {
                    authService.signOut()
                }
            }
        }
    }
}
