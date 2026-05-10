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
                AlertsView()
            }
            .tabItem {
                Label("Alerts", systemImage: "bell")
            }

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.circle")
            }
        }
    }
}

