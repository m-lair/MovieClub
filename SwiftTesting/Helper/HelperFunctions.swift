//
//  HelperFunctions.swift
//  MovieClub
//
//  Created by Marcus Lair on 10/13/24.
//

import Foundation
import Testing
import Firebase
import FirebaseFirestore
import class MovieClub.User
import class FirebaseAuth.User
import class FirebaseAuth.Auth
@testable import MovieClub

extension AppTests {
    @Suite struct LocalTests {
        let db = Firestore.firestore()
        let auth = Auth.auth()
        
    @Test func setupLocal() async throws {
            let userCollection = db.collection("users")
            let clubCollection = db.collection("movieclubs")
            let uid = Auth.auth().currentUser!.uid
            
            // test club
            let club = MovieClub(name: "test-club",
                                 desc: "test-desc",
                                 ownerName: "test-user",
                                 timeInterval: 2,
                                 ownerId: "\(uid)",
                                 isPublic: true,
                                 banner: Data(count: 10),
                                 bannerUrl: "no-image")
            
            // current test user
            let user = User(id: "\(auth.currentUser!.uid)",
                            email: "test@test.com",
                            bio: auth.currentUser!.uid,
                            name: "test-user")
            
            do {
                try clubCollection.document("test-club").setData(from: club)
                try userCollection.document(uid).setData(from: user)
                try await userCollection.document(uid).collection("memberships").document("test-club").setData([
                    "clubId": "test-club",
                    "userId": "\(uid)",
                    "clubName": "test-club"
                ])
            } catch {
                print("error setting up local test data: \(error)")
            }
            #expect(true)
            
        }
    }
}
