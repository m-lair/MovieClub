//
//  MembershipManager.swift
//  MovieClub
//
//  Created by Marcus Lair on 10/16/24.
//

import Foundation
import FirebaseFunctions

extension DataManager {
    
    // MARK: - Enums
    
    enum MembershipError: Error {
        case invalidMembership
        case joinFailure
        case leaveFailure
    }
    
    // MARK: - Join Club
    
    func joinClub(club: MovieClub) async throws {
        guard
            let user = currentUser,
            let clubId = club.id
        else {
            throw AuthError.invalidUser
        }
        
        let joinClub: Callable<[String: String], MovieClub> = functions.httpsCallable("memberships-joinMovieClub")
        let requestData: [String: String] = ["clubId": clubId,
                                             "username": user.name,
                                             "clubName": club.name,
                                             "image": "image"]
        do {
            _ = try await joinClub(requestData)
            await fetchUserClubs()
        } catch {
            print("error joining club: \(error.localizedDescription)")
            throw MembershipError.joinFailure
        }
    }
    
    //MARK: - Leave Club
    
    func leaveClub(club: MovieClub) async throws {
        guard
            let clubId = club.id
        else {
            throw AuthError.invalidUser
        }
        
        let leaveClub: Callable<[String: String], String?> = functions.httpsCallable("memberships-leaveMovieClub")
        let requestData: [String: String] = ["clubId": clubId]
        do {
            _ = try await leaveClub(requestData)
        } catch {
            throw MembershipError.leaveFailure
        }
    }
}
