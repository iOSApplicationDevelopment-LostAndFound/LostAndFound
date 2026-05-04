//
//  LoginView.swift
//  LostAndFound
//
//  Created by Daniel You on 4/5/2026.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showRegister: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Text("Lost & Found")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("UTS Campus")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer().frame(height: 16)

                VStack(spacing: 12) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)

                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }

                if let error = authService.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task {
                        await authService.signIn(email: email, password: password)
                    }
                } label: {
                    if authService.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Sign In")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .disabled(email.isEmpty || password.isEmpty || authService.isLoading)

                Button {
                    showRegister = true
                } label: {
                    Text("Don't have an account? Register")
                        .font(.footnote)
                }

                Spacer()
            }
            .padding(.horizontal, 32)
            .navigationDestination(isPresented: $showRegister) {
                RegisterView()
            }
        }
    }
}
