//
//  ItemRepository.swift
//  LostAndFound
//
//  Created by Daniel You on 4/5/2026.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseStorage
import UIKit

private enum ItemRepositoryError: LocalizedError {
    case invalidImageData
    case imageUploadFailed(Error)
    case itemCreateFailed(Error)
    case itemCreateFailedRollbackFailed(createError: Error, rollbackError: Error)
    case itemDeleteFailed(Error)
    case itemDeleteFailedAfterPhotoRemoval(Error)
    case itemDeleteFailedAfterPhotoRemovalCleanupFailed(deleteError: Error, cleanupError: Error)
    case itemPhotoDeleteFailed(Error)
    case itemUpdateFailed(Error)
    case itemUpdatePhotoUploadFailed(Error)

    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "Image upload failed. Please choose a different photo."
        case .imageUploadFailed:
            return "Image upload failed. Please try again or post without a photo."
        case .itemCreateFailed:
            return "Item could not be created. Please try again."
        case .itemCreateFailedRollbackFailed:
            return "Item could not be created, and the uploaded photo could not be cleaned up automatically."
        case .itemDeleteFailed:
            return "The item could not be removed. Please try again."
        case .itemDeleteFailedAfterPhotoRemoval:
            return "The item could not be removed. Its photo was removed, so please try deleting the item again."
        case .itemDeleteFailedAfterPhotoRemovalCleanupFailed:
            return "The item could not be removed, and photo metadata cleanup also failed. Please try deleting the item again."
        case .itemPhotoDeleteFailed:
            return "The item photo could not be removed. Please try again."
        case .itemUpdateFailed:
            return "Item could not be updated. Please try again."
        case .itemUpdatePhotoUploadFailed:
            return "The new photo could not be uploaded. Please try a different image or save without replacing it."
        }
    }
}

private struct UploadedItemPhoto {
    let downloadURL: String
    let storagePath: String
}

@MainActor
class ItemRepository: ObservableObject {
    @Published var items: [Item] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private var listener: ListenerRegistration? = nil

    init() {
        startListening()
    }

    deinit {
        listener?.remove()
    }

    func startListening() {
        isLoading = true
        listener = db.collection("items")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false

                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }

                guard let documents = snapshot?.documents else { return }

                self.items = documents.compactMap { doc in
                    Item(id: doc.documentID, data: doc.data())
                }
            }
    }

    func createItem(_ item: Item) async throws {
        let data = item.toFirestore()
        try await db.collection("items").document(item.id).setData(data)
    }

    func createItem(_ item: Item, photoData: Data?) async throws {
        guard let photoData else {
            try await createItem(item)
            return
        }

        let uploadedPhoto: UploadedItemPhoto
        do {
            uploadedPhoto = try await uploadItemPhoto(photoData, itemID: item.id, userID: item.postedBy)
        } catch let error as ItemRepositoryError {
            throw error
        } catch {
            throw ItemRepositoryError.imageUploadFailed(error)
        }

        var itemWithPhoto = item
        itemWithPhoto.photoURL = uploadedPhoto.downloadURL
        itemWithPhoto.photoStoragePath = uploadedPhoto.storagePath

        do {
            try await createItem(itemWithPhoto)
        } catch let createError {
            do {
                try await deleteItemPhoto(at: uploadedPhoto.storagePath)
            } catch let rollbackError {
                throw ItemRepositoryError.itemCreateFailedRollbackFailed(createError: createError, rollbackError: rollbackError)
            }
            throw ItemRepositoryError.itemCreateFailed(createError)
        }
    }

    func updateItem(_ item: Item) async throws {
        let data = item.toFirestore()
        try await db.collection("items").document(item.id).updateData(data)
    }

    func updateItem(_ item: Item, replacementPhotoData: Data?) async throws {
        var updatedItem = item

        if let replacementPhotoData {
            do {
                let uploadedPhoto = try await uploadItemPhoto(
                    replacementPhotoData,
                    itemID: item.id,
                    userID: item.postedBy
                )
                updatedItem.photoURL = uploadedPhoto.downloadURL
                updatedItem.photoStoragePath = uploadedPhoto.storagePath
            } catch let error as ItemRepositoryError {
                switch error {
                case .invalidImageData:
                    throw error
                default:
                    throw ItemRepositoryError.itemUpdatePhotoUploadFailed(error)
                }
            } catch {
                throw ItemRepositoryError.itemUpdatePhotoUploadFailed(error)
            }
        }

        do {
            try await updateItem(updatedItem)
        } catch {
            throw ItemRepositoryError.itemUpdateFailed(error)
        }
    }

    func deleteItem(_ item: Item) async throws {
        var didDeletePhoto = false

        if let photoStoragePath = item.photoStoragePath {
            do {
                try await deleteItemPhoto(at: photoStoragePath)
                didDeletePhoto = true
            } catch {
                throw ItemRepositoryError.itemPhotoDeleteFailed(error)
            }
        }

        do {
            try await db.collection("items").document(item.id).delete()
        } catch {
            if didDeletePhoto {
                do {
                    try await clearDeletedPhotoMetadata(for: item.id)
                } catch let cleanupError {
                    throw ItemRepositoryError.itemDeleteFailedAfterPhotoRemovalCleanupFailed(
                        deleteError: error,
                        cleanupError: cleanupError
                    )
                }
                throw ItemRepositoryError.itemDeleteFailedAfterPhotoRemoval(error)
            }
            throw ItemRepositoryError.itemDeleteFailed(error)
        }
    }

    func markResolved(_ item: Item) async throws {
        try await db.collection("items").document(item.id).updateData([
            "status": "resolved"
        ])
    }

    private func uploadItemPhoto(_ photoData: Data, itemID: String, userID: String) async throws -> UploadedItemPhoto {
        guard let image = UIImage(data: photoData),
              let uploadData = image.jpegData(compressionQuality: 0.82) else {
            throw ItemRepositoryError.invalidImageData
        }

        let storagePath = "item-images/\(userID)/\(itemID).jpg"
        let reference = storage.reference(withPath: storagePath)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        do {
            _ = try await reference.putDataAsync(uploadData, metadata: metadata)
            let downloadURL = try await reference.downloadURL()
            return UploadedItemPhoto(downloadURL: downloadURL.absoluteString, storagePath: storagePath)
        } catch {
            throw ItemRepositoryError.imageUploadFailed(error)
        }
    }

    private func deleteItemPhoto(at storagePath: String) async throws {
        try await storage.reference(withPath: storagePath).delete()
    }

    private func clearDeletedPhotoMetadata(for itemID: String) async throws {
        try await db.collection("items").document(itemID).updateData([
            "photoURL": FieldValue.delete(),
            "photoStoragePath": FieldValue.delete()
        ])
    }
}
