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
        case custom(message: String)
    }
    
    struct MembershipResponse: Codable {
        let success: Bool
        let message: String?
    }
    
    // MARK: - Join Club
    
    func joinClub(club: MovieClub) async throws {
        guard
            let user = currentUser,
            let clubId = club.id
        else {
           return
        }
        
        let joinClub: Callable<Membership, MembershipResponse> = functions.httpsCallable("memberships-joinMovieClub")
        let membership = Membership(clubId: clubId, clubName: club.name, userName: user.name, image: "image")
        do {
            let result = try await joinClub(membership)
            if result.success {
                print("club joined successfully")
            } else {
                print("Failed to join club: \(result.message ?? "Unknown error")")
                throw MembershipError.custom(message: result.message ?? "Unknown error")
            }
        } catch {
            print("Network error: \(error)")
            throw SuggestionError.networkError(error)
        }
    }
    
    //MARK: - Leave Club
    
    func leaveClub(club: MovieClub) async throws {
        guard
            let clubId = club.id
        else {
            return
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
