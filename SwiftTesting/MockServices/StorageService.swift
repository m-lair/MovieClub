//
//  StorageService.swift
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
@testable import MovieClub

protocol StorageService {
    func uploadFile(_ data: Data, path: String) async throws -> URL
    func downloadFile(at path: String) async throws -> Data?
    func deleteFile(at path: String) async throws
}
