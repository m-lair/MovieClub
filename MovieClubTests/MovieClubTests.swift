//
//  MovieClubTests.swift
//  MovieClubTests
//
//  Created by Marcus Lair on 10/4/24.
//

import Testing
import Foundation
@testable import MovieClub

struct MovieClubTests {
    let id = UUID()
    @Test func example() async throws {
        let user = User(id: "\(id)", email: "\(id)@test.com", name: "test\(id)")
        #expect(user.id == "\(id)")
    }

}
