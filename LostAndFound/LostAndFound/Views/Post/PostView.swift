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

    private let editingItem: Item?

    @State private var itemType: String
    @State private var itemStatus: String
    @State private var title: String
    @State private var description: String
    @State private var location: String
    @State private var selectedCategory: String
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var selectedPhotoData: Data? = nil
    @State private var pickedCoordinate: CLLocationCoordinate2D?
    @State private var shouldPreservePickedCoordinateForNextLocationChange: Bool = false
    @State private var buildingRoom: String = ""
    @State private var showLocationPicker: Bool = false
    @State private var isPosting: Bool = false
    @State private var isLoadingPhoto: Bool = false
    @State private var photoLoadID: UUID? = nil
    @State private var errorMessage: String? = nil
    @State private var showSuccess: Bool = false
    @FocusState private var focusedField: Field?

    private let categories = ["bag", "electronics", "keys", "clothing", "other"]

    init(editingItem: Item? = nil) {
        self.editingItem = editingItem
        _itemType = State(initialValue: editingItem?.type ?? "lost")
        _itemStatus = State(initialValue: editingItem?.status ?? "active")
        _title = State(initialValue: editingItem?.title ?? "")
        _description = State(initialValue: editingItem?.description ?? "")
        _location = State(initialValue: editingItem?.location ?? "")
        _selectedCategory = State(initialValue: editingItem?.category ?? "other")
        _pickedCoordinate = State(initialValue: editingItem.flatMap { item in
            guard let latitude = item.latitude, let longitude = item.longitude else { return nil }
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        })
    }

    private var isEditing: Bool {
        editingItem != nil
    }

    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !description.trimmingCharacters(in: .whitespaces).isEmpty &&
        !location.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var canSubmit: Bool {
        isFormValid && !isLoadingPhoto && !isPosting && (selectedPhoto == nil || selectedPhotoData != nil)
    }

    private var navigationTitle: String {
        isEditing ? "Edit Item" : "Post an Item"
    }

    private var submitTitle: String {
        isEditing ? "Save Changes" : "Post Item"
    }

    private var successMessage: String {
        isEditing ? "Item updated successfully!" : "Item posted successfully!"
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

                if isEditing {
                    Picker("Status", selection: $itemStatus) {
                        Text("Active").tag("active")
                        Text("Resolved").tag("resolved")
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                }

                photoPicker

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
                    Task { await submitItem() }
                } label: {
                    if isPosting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text(submitTitle)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canSubmit ? Color.blue : Color(.systemGray4))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .disabled(!canSubmit)
                .padding(.horizontal)
            }
            .padding(.vertical, 14)
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(navigationTitle)
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
        .onChange(of: location) { oldValue, newValue in
            guard oldValue != newValue else { return }

            if shouldPreservePickedCoordinateForNextLocationChange {
                shouldPreservePickedCoordinateForNextLocationChange = false
                return
            }

            pickedCoordinate = nil
        }
        .sheet(isPresented: $showLocationPicker) {
            LocationPickerView(
                coordinate: $pickedCoordinate,
                locationName: $location,
                preserveCoordinateOnLocationChange: $shouldPreservePickedCoordinateForNextLocationChange
            )
        }
        .overlay(alignment: .top) {
            if showSuccess {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(successMessage)
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

    private var photoPicker: some View {
        PhotosPicker(selection: $selectedPhoto, matching: .images) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .frame(height: 120)

                if isLoadingPhoto {
                    VStack(spacing: 8) {
                        ProgressView()
                        Text("Loading photo...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if let data = selectedPhotoData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else if let existingPhotoURL = editingItem?.photoURL, let url = URL(string: existingPhotoURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        case .failure:
                            photoPlaceholder(text: "Tap to replace photo")
                        @unknown default:
                            photoPlaceholder(text: "Tap to replace photo")
                        }
                    }
                } else {
                    photoPlaceholder(text: isEditing ? "Tap to add or replace photo" : "Tap to add photo")
                }
            }
        }
        .padding(.horizontal)
        .onChange(of: selectedPhoto) { _, item in
            let loadID = UUID()
            photoLoadID = loadID
            selectedPhotoData = nil
            guard let item else {
                isLoadingPhoto = false
                return
            }

            isLoadingPhoto = true
            errorMessage = nil

            Task {
                do {
                    guard let data = try await item.loadTransferable(type: Data.self) else {
                        throw CocoaError(.fileReadCorruptFile)
                    }
                    guard photoLoadID == loadID else { return }
                    selectedPhotoData = data
                    isLoadingPhoto = false
                } catch {
                    guard photoLoadID == loadID else { return }
                    selectedPhotoData = nil
                    selectedPhoto = nil
                    isLoadingPhoto = false
                    errorMessage = "Photo could not be loaded. Please choose a different image."
                }
            }
        }
    }

    private func photoPlaceholder(text: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: "camera")
                .font(.system(size: 28))
                .foregroundColor(.secondary)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func submitItem() async {
        guard let user = authService.currentUser else { return }
        focusedField = nil
        isPosting = true
        errorMessage = nil

        if selectedPhoto != nil && selectedPhotoData == nil {
            isPosting = false
            errorMessage = "Please wait for the selected photo to finish loading."
            return
        }

        let fullLocation = buildingRoom.trimmingCharacters(in: .whitespaces).isEmpty
            ? location
            : "\(location), \(buildingRoom)"

        do {
            if let editingItem {
                var updatedItem = editingItem
                updatedItem.title = title
                updatedItem.description = description
                updatedItem.category = selectedCategory
                updatedItem.type = itemType
                updatedItem.status = itemStatus
                updatedItem.location = fullLocation
                updatedItem.latitude = pickedCoordinate?.latitude
                updatedItem.longitude = pickedCoordinate?.longitude

                try await itemRepository.updateItem(updatedItem, replacementPhotoData: selectedPhotoData)
                await handleSuccessfulSubmit()
            } else if let newItem = Item(id: UUID().uuidString, data: [
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
            ]) {
                try await itemRepository.createItem(newItem, photoData: selectedPhotoData)
                resetForm()
                await handleSuccessfulSubmit()
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isPosting = false
    }

    private func handleSuccessfulSubmit() async {
        withAnimation { showSuccess = true }

        if isEditing {
            try? await Task.sleep(nanoseconds: 900_000_000)
            withAnimation { showSuccess = false }
            dismiss()
        } else {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            withAnimation { showSuccess = false }
        }
    }

    private func resetForm() {
        title = ""
        description = ""
        location = ""
        buildingRoom = ""
        selectedCategory = "other"
        itemType = "lost"
        itemStatus = "active"
        selectedPhoto = nil
        selectedPhotoData = nil
        isLoadingPhoto = false
        photoLoadID = nil
        pickedCoordinate = nil
    }
}

private struct LocationPickerView: View {
    @Binding var coordinate: CLLocationCoordinate2D?
    @Binding var locationName: String
    @Binding var preserveCoordinateOnLocationChange: Bool
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
                        preserveCoordinateOnLocationChange = true
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
