//
//  AuthService.swift
//  LostAndFound
//
//  Created by Daniel You on 4/5/2026.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
class AuthService: ObservableObject {
    @Published var currentUser: FirebaseAuth.User? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let db = Firestore.firestore()
    private var authStateListener: AuthStateDidChangeListenerHandle? = nil

    init() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
            }
        }
    }

    deinit {
        if let handle = authStateListener {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    var isSignedIn: Bool {
        currentUser != nil
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            if result.user.displayName == nil || result.user.displayName!.isEmpty {
                await syncDisplayNameFromFirestore(uid: result.user.uid)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func syncDisplayNameFromFirestore(uid: String) async {
        guard let doc = try? await db.collection("users").document(uid).getDocument(),
              let name = doc.data()?["displayName"] as? String, !name.isEmpty else { return }
        let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
        changeRequest?.displayName = name
        try? await changeRequest?.commitChanges()
        currentUser = Auth.auth().currentUser
    }

    func signUp(email: String, password: String, displayName: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let uid = result.user.uid

            // Set display name on the Firebase Auth profile so user.displayName is available
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()

            // Save user profile to Firestore
            let userData: [String: Any] = [
                "uid": uid,
                "displayName": displayName,
                "email": email,
                "createdAt": Timestamp(date: Date())
            ]
            try await db.collection("users").document(uid).setData(userData)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
