import Foundation
import Combine
import Firebase
import FirebaseFirestore

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
        guard let data = try? document.data(as: T.self) else {
            throw NSError(domain: "FirebaseService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Document not found"])
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
        let ref = try db.collection(collection).addDocument(from: data)
        return ref.documentID
    }

    func update<T: Encodable>(collection: String, documentId: String, data: T) async throws {
        try db.collection(collection).document(documentId).setData(from: data, merge: true)
    }

    func delete(collection: String, documentId: String) async throws {
        try await db.collection(collection).document(documentId).delete()
    }

    // MARK: - Real-time Listeners

    func listen<T: Decodable>(
        collection: String,
        whereField: String? = nil,
        isEqualTo: Any? = nil,
        completion: @escaping ([T]) -> Void
    ) -> ListenerRegistration {
        var query: Query = db.collection(collection)

        if let field = whereField, let value = isEqualTo {
            query = query.whereField(field, isEqualTo: value)
        }

        return query.addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else { return }
            let items = documents.compactMap { try? $0.data(as: T.self) }
            completion(items)
        }
    }
}
