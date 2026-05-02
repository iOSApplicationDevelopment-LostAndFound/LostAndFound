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

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
