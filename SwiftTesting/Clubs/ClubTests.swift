//
//  ClubTests.swift
//  MovieClub
//
//  Created by Marcus Lair on 1/29/25.
//

import Testing
import Firebase
import Foundation
import FirebaseFunctions
import FirebaseFirestore
import FirebaseStorage
import class FirebaseAuth.Auth
import class MovieClub.User
@testable import MovieClub

@Suite("Club Tests")
class ClubsTests: BaseTests {
    
    let db = Firestore.firestore()
    
    @Test("Create Club")
    func testCreateClub_Success() async throws {
        try await super.setUp()
        let userId = try await super.createTestUserAuth()
        
        
        let movieClub = MovieClub(name: "test club", ownerName: "test-owner", timeInterval: 2, ownerId: userId, isPublic: true)
        let clubId = try await mockFunctions.createMovieClub(movieClub: movieClub)
            
        #expect(clubId != nil)
        
        let clubDoc = try await db.document("movieclubs/\(clubId)").getDocument()
        #expect(clubDoc.exists)
        
    }
    
    @Test("Update Club")
    func testUpdateClub_Success() async throws {
        try await super.setUp()
        let userId = try await super.createTestUserAuth()
        
        
        let movieClub = MovieClub(name: "test club", ownerName: "test-owner", timeInterval: 2, ownerId: userId, isPublic: true)
        print("movieClub: \(movieClub)")
        let clubId = try await mockFunctions.createMovieClub(movieClub: movieClub)
        print("clubId: \(clubId)")
        
        movieClub.id = clubId
        movieClub.name = "Updated Name"
        movieClub.timeInterval = 3
        print("movieClub: \(movieClub)")
        if let updatedClubId = try await mockFunctions.updateMovieClub(movieClub: movieClub) {
            let clubDoc = try await db.document("movieclubs/\(clubId)").getDocument()
            #expect(clubDoc.exists)
            #expect(clubDoc.data()?["name"] as! String == "Updated Name")

        }
    }
}

        
