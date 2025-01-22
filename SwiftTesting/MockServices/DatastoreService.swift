//
//  DatastoreService.swift
//  MovieClub
//
//  Created by Marcus Lair on 1/22/25.
//
import Testing
import Firebase
import Foundation
import FirebaseFunctions
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

protocol DatastoreService {
    func document(_ path: String, in collection: String) async throws -> [String: Any]?
    func setDocument(_ data: [String: Any], at path: String, in collection: String) async throws
    func deleteDocument(at path: String, in collection: String) async throws
    func documentExists(path: String, in collection: String) async throws -> Bool
}
