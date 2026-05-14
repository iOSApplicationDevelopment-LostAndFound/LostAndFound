//
//  PostView.swift
//  LostAndFound
//
//  Created by Shashank Nayak on 7/5/2026.
//

import SwiftUI
import PhotosUI
import MapKit
import CoreLocation
import FirebaseAuth
import FirebaseFirestore

struct PostView: View {
    private enum Field: Hashable {
        case title
        case description
        case location
        case buildingRoom
    }

    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var itemType: String = "lost"
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var location: String = ""
    @State private var selectedCategory: String = "other"
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var selectedPhotoData: Data? = nil
    @State private var pickedCoordinate: CLLocationCoordinate2D? = nil
    @State private var buildingRoom: String = ""
    @State private var showLocationPicker: Bool = false
    @State private var isPosting: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showSuccess: Bool = false
    @FocusState private var focusedField: Field?

    let categories = ["bag", "electronics", "keys", "clothing", "other"]

    var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !description.trimmingCharacters(in: .whitespaces).isEmpty &&
        !location.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Picker("Type", selection: $itemType) {
                    Text("I Lost it").tag("lost")
                    Text("I Found it").tag("found")
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray5))
                            .frame(height: 120)

                        if let data = selectedPhotoData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            VStack(spacing: 6) {
                                Image(systemName: "camera")
                                    .font(.system(size: 28))
                                    .foregroundColor(.secondary)
                                Text("Tap to add photo")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .onChange(of: selectedPhoto) { _, item in
                    Task {
                        selectedPhotoData = try? await item?.loadTransferable(type: Data.self)
                    }
                }

                VStack(spacing: 10) {
                    TextField("Title", text: $title)
                        .focused($focusedField, equals: .title)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .description }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)

                    TextField("Description", text: $description, axis: .vertical)
                        .focused($focusedField, equals: .description)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .location }
                        .lineLimit(3...6)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)

                    HStack {
                        TextField("Location (tap map to auto-fill)", text: $location)
                            .focused($focusedField, equals: .location)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .buildingRoom }
                        Spacer()
                        Button {
                            focusedField = nil
                            showLocationPicker = true
                        } label: {
                            Image(systemName: "map")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                    TextField("Building / Room (optional, e.g. CB04.03.01)", text: $buildingRoom)
                        .focused($focusedField, equals: .buildingRoom)
                        .submitLabel(.done)
                        .onSubmit { focusedField = nil }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.self) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                Text(category.capitalized)
                                    .font(.caption)
                                    .fontWeight(selectedCategory == category ? .semibold : .regular)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(selectedCategory == category ? Color.blue.opacity(0.15) : Color(.systemGray6))
                                    .foregroundColor(selectedCategory == category ? .blue : .secondary)
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(selectedCategory == category ? Color.blue : Color.clear, lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                Button {
                    focusedField = nil
                    Task { await postItem() }
                } label: {
                    if isPosting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Post Item")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? Color.blue : Color(.systemGray4))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .disabled(!isFormValid || isPosting)
                .padding(.horizontal)
            }
            .padding(.vertical, 14)
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Post an Item")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
            }
        }
        .sheet(isPresented: $showLocationPicker) {
            LocationPickerView(coordinate: $pickedCoordinate, locationName: $location)
        }
        .overlay(alignment: .top) {
            if showSuccess {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Item posted successfully!")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.12), radius: 8)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: showSuccess)
    }

    private func postItem() async {
        guard let user = authService.currentUser else { return }
        focusedField = nil
        isPosting = true
        errorMessage = nil

        let fullLocation = buildingRoom.trimmingCharacters(in: .whitespaces).isEmpty
            ? location
            : "\(location), \(buildingRoom)"

        let newItem = Item(id: UUID().uuidString, data: [
            "title": title,
            "description": description,
            "category": selectedCategory,
            "type": itemType,
            "status": "active",
            "location": fullLocation,
            "latitude": pickedCoordinate?.latitude as Any,
            "longitude": pickedCoordinate?.longitude as Any,
            "postedBy": user.uid,
            "postedByName": user.displayName ?? user.email ?? "Unknown",
            "createdAt": Timestamp(date: Date())
        ])

        do {
            if let item = newItem {
                try await itemRepository.createItem(item)
                resetForm()
                withAnimation { showSuccess = true }
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                withAnimation { showSuccess = false }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isPosting = false
    }

    private func resetForm() {
        title = ""
        description = ""
        location = ""
        buildingRoom = ""
        selectedCategory = "other"
        itemType = "lost"
        selectedPhoto = nil
        selectedPhotoData = nil
        pickedCoordinate = nil
    }
}

private struct LocationPickerView: View {
    @Binding var coordinate: CLLocationCoordinate2D?
    @Binding var locationName: String
    @Environment(\.dismiss) private var dismiss

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -33.8834, longitude: 151.2006),
            span: MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006)
        )
    )
    @State private var pinCoordinate: CLLocationCoordinate2D? = nil
    @State private var resolvedName: String = ""
    @State private var isGeocoding: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                MapReader { proxy in
                    Map(position: $cameraPosition) {
                        if let pin = pinCoordinate {
                            Annotation("", coordinate: pin) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.white, .blue)
                            }
                        }
                    }
                    .ignoresSafeArea(edges: .bottom)
                    .onTapGesture { screenPoint in
                        if let coord = proxy.convert(screenPoint, from: .local) {
                            pinCoordinate = coord
                            reverseGeocode(coord)
                        }
                    }
                }

                VStack {
                    if isGeocoding {
                        HStack(spacing: 6) {
                            ProgressView()
                            Text("Finding location...")
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.systemBackground).opacity(0.9))
                        .cornerRadius(8)
                        .padding(.top, 12)
                    } else if !resolvedName.isEmpty {
                        Text(resolvedName)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.systemBackground).opacity(0.9))
                            .cornerRadius(8)
                            .padding(.top, 12)
                    } else {
                        Text("Tap to drop a pin")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.systemBackground).opacity(0.9))
                            .cornerRadius(8)
                            .padding(.top, 12)
                    }
                    Spacer()
                }
            }
            .navigationTitle("Pick Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm") {
                        coordinate = pinCoordinate
                        locationName = resolvedName
                        dismiss()
                    }
                    .disabled(pinCoordinate == nil || isGeocoding)
                }
            }
        }
    }

    private func reverseGeocode(_ coord: CLLocationCoordinate2D) {
        isGeocoding = true
        resolvedName = ""
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        geocoder.reverseGeocodeLocation(location) { placemarks, _ in
            isGeocoding = false
            if let placemark = placemarks?.first {
                var parts: [String] = []
                if let name = placemark.name { parts.append(name) }
                if let suburb = placemark.subLocality { parts.append(suburb) }
                if let city = placemark.locality { parts.append(city) }
                resolvedName = parts.joined(separator: ", ")
            }
        }
    }
}

#Preview {
    NavigationStack {
        PostView()
    }
    .environmentObject(ItemRepository())
    .environmentObject(AuthService())
}
