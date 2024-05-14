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
import Observation

@MainActor
@Observable class DataManager: Identifiable{
    
    var movies: [Movie] = []
    var userSession: FirebaseAuth.User?
    var currentUser: User?
    var userMovieClubs: [MovieClub] = []
    private let service = AuthService.shared
    
    init(){
        
    }
    
    func createUser(user: User) async throws {
        /* let db =  Firestore.firestore()
         let ref = db.collection("users").document(user.name)
         ref.setData(["id": UUID(), "name": user.name, "password": user.password]) { error in
         if let error = error {
         print(error.localizedDescription)
         }
         
         }*/
        do {
            let result = try await Auth.auth().createUser(withEmail: user.email, password: user.password)
            self.userSession = result.user
            let user = User(id: result.user.uid, email: user.email, name: user.name, password: user.password)
            let encodeUser = try Firestore.Encoder().encode(user)
            try await Firestore.firestore().collection("users").document(user.id ?? "").setData(encodeUser)
            await fetchUser()
        } catch {
            print(error)
        }
        
    }
    
    func signIn(email: String, password: String) async throws {
        print("in sign in")
        do{
            
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.userSession = result.user
            await fetchUser()
            
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func fetchMovieClubsForUser() async {
        print("in fetchMovieClubsForUsers")
        do{
            let db = Firestore.firestore()
            guard let user = self.currentUser else {
                print("User not found")
                return
            }
            
            let snapshot = try await db.collection("users").document(user.id ?? "").collection("memberships").getDocuments()
            
            let documents = snapshot.documents
            
            
            let clubIDs = documents.compactMap { document in
                print("document loop\(document.description)")
                return document.data()["clubID"] as? String ?? "error"
                
            }
            
            for clubID in clubIDs {
                print(clubID)
                await self.fetchMovieClub(clubID: clubID)
            }
        }catch{
            print(error.localizedDescription)
        }
        
    }
    
    
    func fetchMovieClub(clubID: String) async {
        print("in fetchMovieClub")
        
        let db = Firestore.firestore()
        guard let snapshot = try? await db.collection("movieclubs").document(clubID).getDocument() else {return}
        do {
            let movieClub = try snapshot.data(as: MovieClub.self)
            self.userMovieClubs.append(movieClub)
        } catch {
            print("Error decoding movie club: \(error)")
        }
        
    }
    
    
    
    func fetchUser() async {
        Task{
            print("in fetch user")
            let db = Firestore.firestore()
            guard let uid = Auth.auth().currentUser?.uid else {return}
            guard let snapshot = try? await db.collection("users").document(uid).getDocument() else {return}
            self.currentUser = try? snapshot.data(as: User.self)
        }
        
    }
    
    func signOut(){
        do{
            try Auth.auth().signOut() //sign out user on firebase
            self.userSession = nil //remove user session and go back to login
            self.currentUser = nil
            
        } catch {
            print(error.localizedDescription)
        }
    }
}
