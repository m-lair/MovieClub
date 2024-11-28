//
//  MockFirebaseAuth.swift
//  MovieClub
//
//  Created by Marcus Lair on 11/24/24.
//

import Testing
import Firebase
import Foundation
import FirebaseFunctions
import FirebaseFirestore
import FirebaseStorage
import class FirebaseAuth.Auth
import class FirebaseAuth.User
import class MovieClub.User
@testable import MovieClub

// MARK: - Firebase Service Protocols
protocol AuthService {
    var currentUser: FirebaseAuth.User? { get }
    func signIn(withEmail email: String, password: String) async throws -> FirebaseAuth.User
    func signOut() async throws
}

protocol DatastoreService {
    func document(_ path: String, in collection: String) async throws -> [String: Any]?
    func setDocument(_ data: [String: Any], at path: String, in collection: String) async throws
    func deleteDocument(at path: String, in collection: String) async throws
    func documentExists(path: String, in collection: String) async throws -> Bool
}

protocol FunctionsService {
    func createUserWithEmail(email: String, password: String, name: String) async throws -> String
    func createUserWithOAuth(_ email: String, signInProvider: String) async throws -> String
    func deleteUser(_ id: String) async throws
    
}

protocol StorageService {
    func uploadFile(_ data: Data, path: String) async throws -> URL
    func downloadFile(at path: String) async throws -> Data?
    func deleteFile(at path: String) async throws
}


// MARK: - Live Firebase Implementations
actor TestFirebaseAuth: @preconcurrency AuthService {
    private let auth: Auth
    
    var currentUser: FirebaseAuth.User? {
        auth.currentUser
    }
    
    init(auth: Auth = Auth.auth()) {
        self.auth = auth
    }
    
    func signIn(withEmail email: String, password: String) async throws -> FirebaseAuth.User {
        let result = try await auth.signIn(withEmail: email, password: password)
        return result.user
    }
    
    func signOut() throws {
        try auth.signOut()
    }
}

actor TestFirestore: DatastoreService {
    private let db: Firestore
    
    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }
    
    private func getCollectionReference(_ collection: String) -> CollectionReference {
        db.collection(collection)
    }
    
    func document(_ path: String, in collection: String) async throws -> [String: Any]? {
        let docRef = getCollectionReference(collection).document(path)
        let snapshot = try await docRef.getDocument()
        return snapshot.exists ? snapshot.data() : nil
    }
    
    func setDocument(_ data: [String: Any], at path: String, in collection: String) async throws {
        let docRef = getCollectionReference(collection).document(path)
        try await docRef.setData(data, merge: true)
    }
    
    func deleteDocument(at path: String, in collection: String) async throws {
        let docRef = getCollectionReference(collection).document(path)
        try await docRef.delete()
    }
    
    func documentExists(path: String, in collection: String) async throws -> Bool {
        let docRef = getCollectionReference(collection).document(path)
        let snapshot = try await docRef.getDocument()
        return snapshot.exists
    }
}

actor TestFunctions: FunctionsService {
    
    private let functions: Functions!
    
    init(functions: Functions = Functions.functions()) {
        self.functions = functions
    }
    
    func createUserWithEmail(email: String, password: String, name: String) async throws -> String {
        do {
            let result = try await functions.httpsCallable("users-createUserWithEmail").call(
                ["email": email,
                 "password": password,
                 "name": name])
            
            let uid = result.data as! String
            return uid
        } catch {
            throw error
        }
    }
    
    func createUserWithOAuth(_ email: String, signInProvider: String) async throws -> String {
        do {
            let result = try await functions.httpsCallable("users-createUserWithSignInProvider").call(["name": email, "signInProvider": signInProvider])
            let uid = result.data as! String
            return uid
        } catch {
            throw error
        }
    }
    
    func deleteUser(_ id: String) async throws {
        do {
            _ = try await functions.httpsCallable("users-deleteUser").call(["userId": id])
        } catch {
            throw error
        }
    }
}

/*
actor TestStorage: StorageService {
    private let storage: Storage!
    
    init(storage: Storage) {
        self.storage = Storage.storage()
    }
    
    func uploadFile(_ data: Data, path: String) async throws -> URL {
        let ref = getStorageReference(path)
        _ = try await ref.putDataAsync(data)
        return try await ref.downloadURL()
    }
    
    func downloadFile(at path: String) async throws -> Data? {
        let ref = getStorageReference(path)
        let maxSize: Int64 = 1 * 1024 * 1024 // 1MB
        return try await ref.data(maxSize: maxSize)
    }
    
    func deleteFile(at path: String) async throws {
        let ref = getStorageReference(path)
        try await ref.delete()
    }
    
    private func deleteRecursively(_ reference: StorageReference) async throws {
        do {
            // List all items in this reference
            let result = try await reference.listAll()
            
            // Delete all items
            for item in result.items {
                try await item.delete()
            }
            
            // Recursively delete prefixes (folders)
            for prefix in result.prefixes {
                try await deleteRecursively(prefix)
            }
        } catch {
            // If reference doesn't exist, that's fine
            if (error as NSError).domain != StorageErrorDomain ||
                (error as NSError).code != StorageErrorCode.objectNotFound.rawValue {
                throw error
            }
        }
    }*/
