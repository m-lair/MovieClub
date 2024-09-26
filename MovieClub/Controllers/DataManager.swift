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
    
    init(){
        Task {
            print("launching datamanager")
            self.userSession = Auth.auth().currentUser
            db = Firestore.firestore()
            try await fetchUser()
        }
    }
    
    func movieClubCollection() -> CollectionReference {
        return db.collection("movieclubs")
    }
    
    func usersCollection() -> CollectionReference {
        return db.collection("users")
    }
    
    func handleError(_ error: Error) {
        switch error {
        case UploadError.invalidImageData:
            print("Error: Invalid image data.")
        case UploadError.fileTooLarge:
            print("Error: The file size exceeds the limit.")
        case UploadError.networkUnavailable:
            print("Error: Please check your network connection.")
        case UploadError.serverError(let message):
            print("Server Error: \(message)")
        default:
            print("An unexpected error occurred: \(error)")
        }
    }
    
    enum UploadError: Error {
        case invalidImageData
        case fileTooLarge
        case networkUnavailable
        case serverError(String)
        case unknown
    }
}
