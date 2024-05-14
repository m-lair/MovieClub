//
//  AuthService.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/14/24.
//

import Foundation
import FirebaseAuth
import Observation


@Observable class AuthService {
    var userSession: FirebaseAuth.User?
    var currentUser: User?
    
    private let shared = AuthService()
    
    init(){
        self.userSession = Auth.auth().currentUser
    }
}
