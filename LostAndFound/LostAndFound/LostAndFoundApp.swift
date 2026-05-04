//
//  LostAndFoundApp.swift
//  LostAndFound
//
//  Created by Daniel You on 2/5/2026.
//

import SwiftUI
import FirebaseCore

@main
struct LostAndFoundApp: App {
    @StateObject private var authService = AuthService()
    @StateObject private var itemRepository = ItemRepository()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(itemRepository)
        }
    }
}
