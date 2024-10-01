//
//  DataManager.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/12/24.
//

import Foundation
import FirebaseAuth
import FirebaseFirestoreSwift
import AuthenticationServices
import FirebaseFirestore
import UIKit
import FirebaseStorage
import Observation
import SwiftUI
import FirebaseMessaging
import FirebaseFunctions


@MainActor
@Observable 
class DataManager: Identifiable {
    var movie: Movie?
    var poster: String {
        movie?.poster ?? ""
    }
    var comments: [Comment] = []
    var commentsListener: ListenerRegistration?
    var userSession: FirebaseAuth.User?
    var currentUser: User?
    var userClubs: [MovieClub] = []
    var currentClub: MovieClub?
    var clubId: String {
        currentClub?.id ?? ""
    }
    var queue: Membership?
    var db: Firestore!
   var auth: Auth!
    
    
    init(){
        Task {
            db = Firestore.firestore()
            auth = Auth.auth()
            self.userSession = auth.currentUser
            try await fetchUser()
            
        }
    }
    
    func movieClubCollection() -> CollectionReference {
        return db.collection("movieclubs")
    }
    
    func usersCollection() -> CollectionReference {
        return db.collection("users")
    }
    
    enum UploadError: LocalizedError {
        case unauthorized
        case functionError(code: FunctionsErrorCode, message: String)
        case invalidResponse
        case unknownError(Error)

        var errorDescription: String? {
            switch self {
            case .unauthorized:
                return "Unauthorized access."
            case .functionError(let code, let message):
                return "Function error (\(code.rawValue)): \(message)"
            case .invalidResponse:
                return "Invalid response from the server."
            case .unknownError(let error):
                return error.localizedDescription
            }
        }
    }
}
