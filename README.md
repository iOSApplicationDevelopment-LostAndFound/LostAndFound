# LostAndFound

**GitHub Repository:** https://github.com/iOSApplicationDevelopment-LostAndFound/LostAndFound

A UTS campus iOS app where students can report lost items, post found items, browse a live feed, and claim items that belong to them.

---

## Team

| Member | Contribution |
|---|---|
| Daniel You | Home feed, Item detail, Auth, Data layer, Firebase setup, Navigation |
| Shashank Nayak | Map view, Post item, Alerts, Profile, Data layer |

---

## Frameworks Used

| Framework | Purpose |
|---|---|
| **SwiftUI** | All UI screens and navigation |
| **Firebase Authentication** | Email and password sign-in and registration |
| **Cloud Firestore** | Real-time NoSQL database for items and user profiles |
| **MapKit** | Interactive map view with pins for item locations |
| **PhotosUI** | Photo picker for attaching images when posting an item |
| **CoreLocation** | User location for the map and location picker |

---

## Architecture

MVVM + Repository pattern:

- **Models** — `Item`, `AppUser`
- **Services** — `AuthService`, `ItemRepository`, `LocationManager`
- **ViewModels** — `HomeViewModel`, `ItemDetailViewModel`
- **Views** — SwiftUI views

---

## Features

- Register and sign in with email and password
- Browse a live feed of lost and found items, updated in real time via Firestore listeners
- Search by keyword and filter by type (Lost / Found) and category
- View full item details and claim an item
- Post a lost or found item with photo, category, and map pin
- View item locations on an interactive map
- Receive alerts for matching items
- Profile page showing your posts and stats

---

## How to Run

1. Clone the repository
2. Open `LostAndFound/LostAndFound.xcodeproj` in Xcode
3. Obtain `GoogleService-Info.plist` from a team member and place it inside `LostAndFound/LostAndFound/`
4. Build and run on a simulator or device running iOS 16 or later

> Firebase project: `lost-and-found-uts` — Firestore region: `australia-southeast1`

---

## Design Process

The app was developed following an iterative product design cycle:

1. **Concept** — defined user persona and core problem (no centralised UTS lost and found system)
2. **Prototype** — interactive HTML prototype covering all 6 screens
3. **Build** — incremental commits per feature
4. **Test** — manual testing against a live Firestore instance with real data
