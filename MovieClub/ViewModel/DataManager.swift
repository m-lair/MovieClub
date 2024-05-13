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
    var clubs: [MovieClub] = []
    var userSession: FirebaseAuth.User?
    var currentUser: User?
    
    func createUser(user: User) async throws {
            /* let db =  Firestore.firestore()
             let ref = db.collection("Users").document(user.name)
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
                print(error.localizedDescription)
            }
            
    }
    
    func signIn(email: String, password: String) async throws {
        do{
            print("in signIn method")
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.userSession = result.user
            print("before fetch User \(result.user)")
            await fetchUser()
            
        } catch {
            print(error.localizedDescription)
        }
    }
        
    func fetchUser() async {
            guard let uid = Auth.auth().currentUser?.uid else {return}
            guard let snapshot = try? await Firestore.firestore().collection("users").document(uid).getDocument() else { return }
            self.currentUser = try? snapshot.data(as: User.self)
       
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
