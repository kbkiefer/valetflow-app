import Foundation
import Combine
import Firebase
import FirebaseFirestore

enum FirebaseServiceError: Error, LocalizedError {
    case documentNotFound(collection: String, documentId: String)
    case decodingFailed(collection: String, documentId: String)
    case encodingFailed(collection: String)
    case operationFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .documentNotFound(let collection, let documentId):
            return "Document not found in '\(collection)' with ID '\(documentId)'"
        case .decodingFailed(let collection, let documentId):
            return "Failed to decode document in '\(collection)' with ID '\(documentId)'"
        case .encodingFailed(let collection):
            return "Failed to encode data for collection '\(collection)'"
        case .operationFailed(let error):
            return "Firebase operation failed: \(error.localizedDescription)"
        }
    }
}

@MainActor
class FirebaseService: ObservableObject {
    static let shared = FirebaseService()

    let db = Firestore.firestore()

    private init() {
        configureFirebase()
    }

    private func configureFirebase() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }

    // MARK: - Generic Firestore Operations

    func fetch<T: Decodable>(collection: String, documentId: String) async throws -> T {
        let document = try await db.collection(collection).document(documentId).getDocument()
        guard document.exists else {
            throw FirebaseServiceError.documentNotFound(collection: collection, documentId: documentId)
        }
        guard let data = try? document.data(as: T.self) else {
            throw FirebaseServiceError.decodingFailed(collection: collection, documentId: documentId)
        }
        return data
    }

    func fetchAll<T: Decodable>(collection: String, whereField: String? = nil, isEqualTo: Any? = nil) async throws -> [T] {
        var query: Query = db.collection(collection)

        if let field = whereField, let value = isEqualTo {
            query = query.whereField(field, isEqualTo: value)
        }

        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: T.self) }
    }

    func create<T: Encodable>(collection: String, data: T) async throws -> String {
        let ref = try await db.collection(collection).addDocument(from: data)
        return ref.documentID
    }

    func update<T: Encodable>(collection: String, documentId: String, data: T) async throws {
        try await db.collection(collection).document(documentId).setData(from: data, merge: true)
    }

    func delete(collection: String, documentId: String) async throws {
        try await db.collection(collection).document(documentId).delete()
    }

    // MARK: - Real-time Listeners

    func listen<T: Decodable>(
        collection: String,
        whereField: String? = nil,
        isEqualTo: Any? = nil,
        completion: @escaping ([T]) -> Void,
        onError: ((Error) -> Void)? = nil
    ) -> ListenerRegistration {
        var query: Query = db.collection(collection)

        if let field = whereField, let value = isEqualTo {
            query = query.whereField(field, isEqualTo: value)
        }

        return query.addSnapshotListener { snapshot, error in
            if let error = error {
                onError?(error)
                return
            }
            guard let documents = snapshot?.documents else { return }
            let items = documents.compactMap { try? $0.data(as: T.self) }
            completion(items)
        }
    }
}
