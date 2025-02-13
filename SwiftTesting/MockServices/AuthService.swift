//
//  AuthService.swift
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

protocol AuthService {
    var currentUser: FirebaseAuth.User? { get set }
    func signIn(withEmail email: String, password: String) async throws -> FirebaseAuth.User
    func signOut() async throws
    func createUser(withEmail email: String, password: String) async throws -> FirebaseAuth.User
}
