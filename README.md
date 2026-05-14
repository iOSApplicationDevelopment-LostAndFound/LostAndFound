# LostAndFound

**GitHub Repository:** https://github.com/iOSApplicationDevelopment-LostAndFound/LostAndFound

A UTS campus iOS app where students can report lost items, post found items, browse a live feed, manage their own posts, and claim items that belong to them.

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
| **Firebase Storage** | Stores uploaded item photos |
| **MapKit** | Interactive map view with pins for item locations |
| **PhotosUI** | Photo picker for attaching images when posting an item |
| **CoreLocation** | User location for the map and location picker |

---

## Architecture

MVVM + Repository pattern:

- **Models** — `Item`, `AppUser`, `ItemOwnership`
- **Services** — `AuthService`, `ItemRepository`, `LocationManager`
- **ViewModels** — `HomeViewModel`, `ItemDetailViewModel`
- **Views** — SwiftUI views

---

## Features

- Register and sign in with email and password
- Browse a live feed of lost and found items, updated in real time via Firestore listeners
- Search by keyword and filter by type (Lost / Found) and category
- View full item details and notify the owner when an item may be matched
- Post a lost or found item with photo, category, and map pin
- Edit your own posts from the item detail page
- Delete your own posts from the item detail page or by swiping left on owned rows in Home/Profile
- Delete item photos from Firebase Storage when removing a post
- View active item locations on an interactive map
- Pan and zoom around the map freely, then use the map's user-location button to return to your location
- Receive in-app alerts when another user taps the detail-page match/claim action for one of your posts
- Mark alerts as read by tapping them
- Profile page showing your posts and stats

---

## Notifications Status

The Alerts tab is implemented as an in-app Firestore notification list:

- `ItemDetailViewModel.notifyOwner(...)` writes documents into the `notifications` collection.
- `AlertsView` listens for notifications where `userId` matches the signed-in Firebase Auth user.
- Alerts are sorted newest-first and can be marked as read by tapping the row.
- The current implementation is not a push-notification system; alerts appear when the app is open and the Firestore listener receives updates.
- Notification delivery depends on Firestore/Auth being configured and the app having permission to read/write the `notifications` collection.

---

## How to Run

1. Clone the repository
2. Open `LostAndFound/LostAndFound.xcodeproj` in Xcode
3. Obtain `GoogleService-Info.plist` from a team member and place it inside `LostAndFound/LostAndFound/`
4. Build and run on a simulator or device running iOS 16 or later

> Firebase project: `lost-and-found-uts` — Firestore region: `australia-southeast1`

Firebase services used by the app:

- Authentication: email/password users
- Firestore: `items`, `users`, and `notifications`
- Storage: uploaded item images under `item-images/{userID}/{itemID}.jpg`

---

## Design Process

The app was developed following an iterative product design cycle:

1. **Concept** — defined user persona and core problem (no centralised UTS lost and found system)
2. **Prototype** — interactive HTML prototype covering all 6 screens
3. **Build** — incremental commits per feature
4. **Test** — manual testing against a live Firestore instance with real data
