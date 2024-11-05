//
//  DataManager.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/12/24.
//

import Foundation
import FirebaseAuth
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
    var apiKey: String {
      get {
        // 1
        guard let filePath = Bundle.main.path(forResource: "TMDB-Info", ofType: "plist") else {
          fatalError("Couldn't find file 'TMDB-Info.plist'.")
        }
        // 2
        let plist = NSDictionary(contentsOfFile: filePath)
        guard let value = plist?.object(forKey: "KEY") as? String else {
          fatalError("Couldn't find key 'API_KEY' in 'TMDB-Info.plist'.")
        }
        return value
      }
    }
    
    var movie: Movie?
    
    var comments: [Comment] = []
    var commentsListener: ListenerRegistration?
    
    var suggestions: [Suggestion] = []
    var suggestionsListener: ListenerRegistration?
    
    var userSession: FirebaseAuth.User?
    
    var currentUser: User?
    var userClubs: [MovieClub] = []
    var currentClub: MovieClub?
    var currentCollection: [CollectionItem] = []
    
    var clubId: String {
        currentClub?.id ?? ""
    }
    var queue: Membership?
    var db: Firestore!
    var auth: Auth!
    var functions: Functions!
    
    
    init(){
        Task {
            db = Firestore.firestore()
            auth = Auth.auth()
            functions = Functions.functions()
            if auth.currentUser?.uid != nil {
                userSession = auth.currentUser
                try await fetchUser()
            }
        }
    }
    
    // MARK: - Collection References
    
    func movieClubCollection() -> CollectionReference {
        return db.collection("movieclubs")
    }
    
    func usersCollection() -> CollectionReference {
        return db.collection("users")
    }
}
