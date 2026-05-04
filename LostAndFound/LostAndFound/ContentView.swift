//
//  ContentView.swift
//  LostAndFound
//
//  Created by Daniel You on 2/5/2026.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService

    var body: some View {
        Group {
            if authService.isSignedIn {
                MainTabView()
            } else {
                LoginView()
            }
        }
    }
}
