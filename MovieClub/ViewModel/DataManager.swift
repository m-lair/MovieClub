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

@MainActor
@Observable class DataManager: Identifiable{
    
    var movies: [MovieClub.Movie] = []
    var userSession: FirebaseAuth.User?
    var currentUser: User?
    var userMovieClubs: [MovieClub] = []
    var comments: [MovieClub.Comment] = []
    var currentClub: MovieClub?
    
    init(){
        Task {
            self.userSession = Auth.auth().currentUser
            //await fetchUser()
        }
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
            let user = User(id: result.user.uid, email: user.email, bio: user.bio, name: user.name, image: user.image, password: user.password)
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
            
            
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func uploadProfileImage(image: UIImage, userId: String) async throws {
        let storageRef = Storage.storage().reference().child("profileImages/\(userId).jpg")
        if let imageData = image.jpegData(compressionQuality: 0.75) {
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            do {
                _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
                let url = try await storageRef.downloadURL()
                // Update user's profile image URL
                if var currentUser = currentUser {
                    currentUser.image = url.absoluteString
                    try await Firestore.firestore().collection("users").document(userId).updateData(["image": url.absoluteString])
                    self.currentUser = currentUser
                }
            } catch {
                print("Error uploading image: \(error.localizedDescription)")
            }
        }
    }
    
    func getProfileImage(id: String) async -> String  {
        //   print("in getter")
        let storageRef = Storage.storage().reference().child("Users/profile_images/\(id).jpeg")
        do {
            let url = try await storageRef.downloadURL()
            if var currentUser = currentUser {
                self.currentUser?.image = url.absoluteString
            }
            return url.absoluteString
        } catch {
            print(error)
        }
        return ""
    }
    
    func postComment(comment: MovieClub.Comment, movieClubID: String, movieID: String) async{
        do{
            let db = Firestore.firestore()
            
            do {
                let encodeComment = try Firestore.Encoder().encode(comment)
                try await db.collection("movieclubs").document(movieClubID)
                    .collection("movies").document(movieID)
                    .collection("comments").document().setData(encodeComment)
                
                print("Comment added successfully")
            } catch {
                print("Error adding comment: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchComments(movieClubId: String, movieId: String) async {
        print("in fetch comments")
        let db = Firestore.firestore()
        
        do {
            let querySnapshot = try await db.collection("movieclubs")
                .document(movieClubId)
                .collection("movies")
                .document(movieId)
                .collection("comments")
                .getDocuments()
            self.comments = querySnapshot.documents.compactMap { document in
                do {
                    return try document.data(as: MovieClub.Comment.self)
                } catch {
                    print("Error decoding document \(document.documentID): \(error)")
                    return nil
                }
            }
            //  print("self.comments in method: \(self.comments)")
        } catch {
            print("Error fetching comments: \(error.localizedDescription)")
        }
    }
    
    func fetchMovieClubsForUser() async {
        // print("in fetchMovieClubsForUsers")
        self.userMovieClubs = []
        do{
            let db = Firestore.firestore()
            guard let user = self.currentUser else {
                print("User not found")
                return
            }
            
            let snapshot = try await db.collection("users").document(user.id ?? "").collection("memberships").getDocuments()
            
            let documents = snapshot.documents
            
            let clubIDs = documents.compactMap { document in
                print("document loop \(document.description)")
                return document.data()["clubID"] as? String ?? "error"
                
            }
            
            for clubID in clubIDs {
                
                await self.fetchMovieClub(clubID: clubID)
            }
        }catch{
            print(error.localizedDescription)
        }
        
    }
    
    func createMovieClub(movieClub: MovieClub){
        Task{
            //let movieClub = MovieClub(name: movieClub.name, ownerName: movieClub.ownerName, ownerID: movieClub.ownerID, isPublic: movieClub.isPublic)
            let encodeClub = try Firestore.Encoder().encode(movieClub)
            try await Firestore.firestore().collection("movieclubs").document().setData(encodeClub)
            self.userMovieClubs.append(movieClub)
            await addClubRelationship(movieClub: movieClub)
            await fetchUser()
        }
    }
    
    func addClubRelationship(movieClub: MovieClub) async {
        Task{
            let db = Firestore.firestore()
            let snapshot = try await db.collection("users").document(currentUser?.id ?? "").getDocument()
            if movieClub.id != "" {
                // cant figure out a better way to do this but we know the val wont be null
                let membership = Membership(clubID: movieClub.id ?? "")
                let encodeMembership = try Firestore.Encoder().encode(membership)
                try await db.collection("users").document(currentUser?.id ?? "").collection("memberships").document(currentUser?.id ?? "").setData(encodeMembership)
            } else {
                print("error occurred adding club for \(currentUser?.id ?? "")")
            }
            
        }
    }
    
    
    func fetchMovieClub(clubID: String) async {
        // print("in fetchMovieClub")
        
        let db = Firestore.firestore()
        guard let snapshot = try? await db.collection("movieclubs").document(clubID).getDocument() else {return}
        do {
            let movieClub = try snapshot.data(as: MovieClub.self)
            self.userMovieClubs.append(movieClub)
        } catch {
            print("Error decoding movie club: \(error)")
        }
        
    }
    
    func fetchAPIMovie(title: String) async throws -> MovieClub.APIMovie {
        let formattedTitle = title.replacingOccurrences(of: " ", with: "+")
        let urlString = "https://omdbapi.com/?t=\(formattedTitle)&apikey=ab92d369"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("Bad server response: \(response)")
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        
        do {
            return try decoder.decode(MovieClub.APIMovie.self, from: data)
        } catch {
            print("Failed to decode API response: \(error)")
            throw URLError(.cannotParseResponse)
        }
    }
    
    func fetchFirestoreMovies() async -> [MovieClub.FirestoreMovie]{
        let db = Firestore.firestore()
        do {
            let moviesRef = try await db.collection("movieclubs").document(self.currentClub?.id ?? "").collection("movies").getDocuments()
            
            
            let firestoreMovies = moviesRef.documents.compactMap { document in
                try? document.data(as: MovieClub.FirestoreMovie.self)
            }
            return firestoreMovies
        } catch {
            print("Error fetching Firestore movies: \(error)")
        }
        return []
    }
    
    func fetchAndMergeMovies() async -> [MovieClub.Movie] {
        var movies: [MovieClub.Movie] = []
        do {
            let firestoreMovies = await fetchFirestoreMovies()
            print("firestore movies \(firestoreMovies)")
            for firestoreMovie in firestoreMovies {
                
                let apiMovie = try await fetchAPIMovie(title: firestoreMovie.title)
                
                let combinedMovie = MovieClub.Movie(
                    id: firestoreMovie.id ?? UUID().uuidString,
                    title: firestoreMovie.title,
                    startDate: firestoreMovie.startDate,
                    poster: apiMovie.poster,
                    endDate: firestoreMovie.endDate,
                    author: firestoreMovie.author,
                    comments: firestoreMovie.comments, plot: apiMovie.plot, director: apiMovie.director
                    
                )
                print(combinedMovie)
                movies.append(combinedMovie)
            }
            return movies
            
            
            
        }catch {
            print("Failed to fetch or merge movie data: \(error)")
        }
        return []
    }



    func fetchMovies(for movieClubId: String) async -> [MovieClub.Movie] {
        
        
        let db = Firestore.firestore()
        
        do {
            let querySnapshot = try await db.collection("movieclubs").document(movieClubId).collection("movies").getDocuments()
            
            let movieTitles = querySnapshot.documents.compactMap { document in
                do {
                    return try document.data(as: MovieClub.Movie.self)
                } catch {
                    print("Error decoding movie document: \(error.localizedDescription), Document: \(document.documentID)")
                    return nil
                }
            }
            return movieTitles
        } catch {
            print("Error fetching movie documents: \(error.localizedDescription)")
            return []
        }
    }

    
    func decodeMovie(title: String) async throws-> MovieClub.Movie {
        let title = formatMovieForAPI(title: title)
        let urlString = "https://omdbapi.com/?t=\(title)&h=600&apikey=ab92d369"
        print(urlString)
        guard let url = URL(string: urlString) else{
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        print("return data: \(data)")
        let movie = try! JSONDecoder().decode(MovieClub.Movie.self, from: data)
        
        return movie
        
    }
    
    func fetchPoster(title: String) async throws -> String {
        
        let formattedTitle = formatMovieForAPI(title: title)
        
        let urlString = "https://omdbapi.com/?t=\(formattedTitle)&apikey=ab92d369"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
       
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("error")
            throw URLError(.badServerResponse)
        }
        
        
    
        do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let poster = json["Poster"] as? String {
                    return poster
                } else {
                    print("The key 'Poster' does not exist or is not a string.")
                    throw URLError(.cannotParseResponse)
                }
            } catch let error {
                print("Failed to parse JSON: \(error.localizedDescription)")
                throw URLError(.cannotParseResponse)
            }
        
        
    }
    
    func formatMovieForAPI(title: String) -> String {
            return title.replacingOccurrences(of: " ", with: "+")
        }
    
    
    func fetchUser() async {
        
      //  print("in fetch user")
        
        let db = Firestore.firestore()
      //  print("1")
        guard let uid = Auth.auth().currentUser?.uid else {return}
       // print("2")
      print("uid\(uid)")
        guard let snapshot = try? await db.collection("users").document(uid).getDocument() else {return}
       print("Document data: \(snapshot.data())")
        
            do{
                self.currentUser = try snapshot.data(as: User.self)
            }catch{
                print(error)
            }
        
        
        await self.currentUser!.image = getProfileImage(id: currentUser!.id!)
        await fetchMovieClubsForUser()
        
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

extension MovieClub {
    static var TestData: [MovieClub] = [MovieClub(name: "Test Title 1",
                                                  created: Date(),
                                                  numMembers: 2,
                                                  description: "description",
                                                  ownerName: "Duhmarcus",
                                                  ownerID: "000123",
                                                  isPublic: true,
                                                  movies: [Movie(id: "001",
                                                                 title: "The Matrix",
                                                                 startDate: Date(),
                                                                 poster: "test",
                                                                 endDate: Date(),
                                                                 
                                                                 author: "duhmarcus")]),
                                        MovieClub(name: "Test Title 2",
                                                  created: Date(),
                                                  numMembers: 1,
                                                  description: "description",
                                                  ownerName: "darius garius",
                                                  ownerID: "1345",
                                                  isPublic: true)]
}

