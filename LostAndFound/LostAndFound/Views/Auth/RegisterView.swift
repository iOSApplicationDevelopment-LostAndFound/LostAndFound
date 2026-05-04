//
//  RegisterView.swift
//  LostAndFound
//
//  Created by Daniel You on 4/5/2026.
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var displayName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Create Account")
                .font(.largeTitle)
                .fontWeight(.bold)

            Spacer().frame(height: 16)

            VStack(spacing: 12) {
                TextField("Display Name", text: $displayName)
                    .autocapitalization(.words)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

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
                    await authService.signUp(
                        email: email,
                        password: password,
                        displayName: displayName
                    )
                }
            } label: {
                if authService.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text("Create Account")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .disabled(displayName.isEmpty || email.isEmpty || password.isEmpty || authService.isLoading)

            Button {
                dismiss()
            } label: {
                Text("Already have an account? Sign In")
                    .font(.footnote)
            }

            Spacer()
        }
        .padding(.horizontal, 32)
        .navigationBarBackButtonHidden(true)
    }
}
