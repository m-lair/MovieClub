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
import SwiftUI
import FirebaseMessaging
import FirebaseFunctions


@MainActor
@Observable 
class DataManager: Identifiable {
    
    var movies: [Movie] = []
    var poster: String {
        movies.first?.poster ?? ""
    }
    var userSession: FirebaseAuth.User?
    var currentUser: User?
    var userMovieClubs: [MovieClub] = []
    var comments: [Comment] = []
    var currentClub: MovieClub?
    var clubId: String {
        currentClub?.id ?? ""
    }
    var queue: Membership?
    var db: Firestore!
    
    init(){
        Task {
            // print("auth curr user \(String(describing: Auth.auth().currentUser))")
            self.userSession = Auth.auth().currentUser
            db = Firestore.firestore()
            try await fetchUser()
        }
    }
    
    func addToComingSoon(clubId: String, userId: String, date: Date) async {
        //add member object
        do {
            try await movieClubCollection().document(clubId).collection("members").document(userId).updateData(["seletor" : true, "comingSoonDate" : date])
            
            //add date from greatest current roster date, could be movieclub.movies to get this easier
            //allow user to select queue of movies now
            //display roster by sorting on date
        } catch {
            print(error)
        }
    }
    
    func movieClubCollection() -> CollectionReference {
        return db.collection("movieclubs")
    }
    
    func usersCollection() -> CollectionReference {
        return db.collection("users")
    }
    
    func createUser(email: String, password: String, displayName: String) async throws -> String {
        do {
            let functions = Functions.functions()
            let result = try await functions.httpsCallable("createUser").call([
                "email": email,
                "password": password,
                "displayName": displayName
            ])
            guard let data = result.data as? [String: Any],
                  let uid = data["uid"] as? String else {
                throw NSError(domain: "UserService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response from server"])
            }
            return uid
        } catch {
            throw error
        }
    }
    
    func signIn(email: String, password: String) async throws {
        print("in sign in")
        do{
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.userSession = result.user
            print("signed in user \(result.user)")
            try await fetchUser()
            
        } catch {
            throw error
        }
    }
    
    enum UploadError: Error {
        case invalidImageData
    }

    func uploadClubImage(image: UIImage, clubId: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.25) else {
            throw UploadError.invalidImageData
        }

        let storageRef = Storage.storage().reference().child("Clubs/\(clubId)/banner.jpg")
        var metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let url = try await storageRef.downloadURL()
        print("URL: \(url)")
        return url.absoluteString
    }
    
    func joinClub(club: MovieClub) async {
        if let user = self.currentUser, let clubId = club.id {
            await addClubMember(clubId: clubId, user: user, date: Date())
            await incrementMember(clubId: clubId)
            await addClubRelationship(club: club)
        }
    }
    
    func addClubMember(clubId: String, user: User, date: Date) async {
        do{
            if let id = user.id {
                let member = Member(userId: id, userName: user.name, userAvi: user.image ?? "" , selector: false, dateAdded: date)
                let encodedMember = try Firestore.Encoder().encode(member)
                try await movieClubCollection().document(clubId).collection("members").document(id).setData(encodedMember)
            }
        } catch {
            print("couldnt add member")
        }
    }
    
    func leaveClub(club: MovieClub) async {
        if let clubId = club.id, let userId = self.currentUser?.id {
            do {
                try await movieClubCollection().document(clubId).collection("memberships").document(userId).delete()
                await decrementMember(clubId: clubId)
                self.userMovieClubs.removeAll { $0.name == club.name}
            }catch {
                print(error)
            }
        }
    }
    
    func decrementMember(clubId: String) async {
        do{
            try await movieClubCollection().document(clubId).updateData(["numMembers" : FieldValue.increment(-1.0)])
        } catch {
            print("unable to update number of members. User count may be incorrect")
        }
    }
    
    func removeClubRelationship(clubId: String, userId: String) async {
        // cant figure out a better way to do this but we know the val wont be null
        do{
            try await usersCollection().document(userId).collection("memberships").document(clubId).delete()
        } catch {
            print("could not delete club membership: \(error)")
        }
    }
    
    func incrementMember(clubId: String) async {
        do{
            try await movieClubCollection().document(clubId).updateData(["numMembers" : FieldValue.increment(1.0)])
        } catch {
            print("unable to update number of members. User count may be incorrect")
        }
    }
    
    func getProfileImage(path: String) async -> String {
        //   print("in getter")
        let storageRef = Storage.storage().reference().child(path) //Storage.storage().reference().child("Users/profile_images/\(id)")
        do {
            let url = try await storageRef.downloadURL()
            self.currentUser?.image = url.absoluteString
            print("url.absoluteString \(url.absoluteString)")
            //return url to image in the cloud as a String
            return url.absoluteString
        } catch {
            print(error)
        }
        return ""
    }
    
    func getProfileImage(userId: String) async -> String {
        let db = Firestore.firestore()
        do {
            // Fetch the document
            let document = try await usersCollection().document(userId).getDocument()
            
            // Retrieve the `profileImageURL` field
            if let url = document.get("image") as? String {
                return url
            } else {
                print("profileImageURL not found in document")
                return ""
            }
        } catch {
            print("Error fetching profile image URL: \(error)")
            return ""
        }
    }
    
    func updateQueue(membership: Membership) async {
        do{
            let encodedMembership = try Firestore.Encoder().encode(membership)
            try await usersCollection().document(currentUser?.id ?? "" ).collection("memberships").document(currentClub?.id ?? "").setData(encodedMembership)
        }catch{
            print("error updating queue \(error)")
        }
    }
    
    func loadQueue() async {
       // print("clubId \(currentClub?.id)")
      //  print("clubId \(currentUser?.id)")
        if let clubId = self.currentClub?.id, let id = self.currentUser?.id  {
            do {
                let document = try await usersCollection().document(id).collection("memberships").document(clubId).getDocument()
                if let member = try? document.data(as: Membership.self) {
                   // print("#### Member object: \(member)")
                    self.queue = member
                }
            } catch {
                print("error getting membership")
            }
        }
    }
    
    func fetchComments(movieClubId: String, movieId: String) async -> [Comment]{
       // print("in fetch comments")
       // print("query clubId \(movieClubId) + movieId \(movieId)")
        do {
            let querySnapshot = try await movieClubCollection().document(movieClubId).collection("movies").document(movieId).collection("comments")
                .order(by: "date", descending: true)
                .getDocuments()
            let comments = querySnapshot.documents.compactMap { document in
                //print("comment doc \(document)")
                do {
                    return try document.data(as: Comment.self)
                } catch {
                    print("Error decoding document \(document.documentID): \(error)")
                    return nil
                }
            }
          //  print("comments \(comments)")
            
            self.comments = comments
            return comments
            //  print("self.comments in method: \(self.comments)")
        } catch {
            print("Error fetching comments: \(error.localizedDescription)")
        }
        return []
    }
    
    func fetchUserClubs() async {
        var clubList: [MovieClub] = []
        do{
            guard let user = self.currentUser else {
                print("No user logged in")
                return
            }
            let snapshot = try await usersCollection().document(user.id ?? "").collection("memberships").getDocuments()
            let clubIds = snapshot.documents.compactMap { document in
                return document.data()["clubId"] as? String
            }
            for clubId in clubIds {
                print(clubId)
                if let movieClub = await fetchMovieClub(clubId: clubId) {
                    clubList.append(movieClub)
                }
            }
            self.userMovieClubs = clubList
        }catch{
            print(error.localizedDescription)
        }
    }
    
    func fetchMovieClub(clubId: String) async -> MovieClub? {
        guard
            let snapshot = try? await movieClubCollection().document(clubId).getDocument()
        else {
            print("Can't find movie club: \(clubId)")
            return nil
        }
        do {
            print(snapshot.data())
            let movieClub = try snapshot.data(as: MovieClub.self)
            /*let moviesSnapshot = try await movieClubCollection()
                .document(clubId)
                .collection("movies")
                .order(by: "endDate" , descending: false)
                .limit(to: 1)
                .getDocuments()
            for document in moviesSnapshot.documents {
                print("current movie in method \(document.data())")
                movieClub.movies = [try document.data(as: Movie.self)]
            }*/
            return movieClub
        } catch {
            print("Error decoding movie: \(error)")
        }
        return nil
    }
    
    func addMovie(movie: Movie) {
        self.movies.append(movie)
        print("current movie in method \(movie)")
    }
    
    func createMovieClub(movieClub: MovieClub, movie: Movie?) async {
            do {
                //this is the future date for the owner, would be their 2nd movie
                let futureOwnerMovieDate = Date()
                if let timeIntervalFromToday = Calendar.current.date(byAdding: .weekOfYear, value: movieClub.timeInterval, to: futureOwnerMovieDate){
                    //encode the club
                    let encodeClub = try Firestore.Encoder().encode(movieClub)
                    if let id = movieClub.id {
                        //commit club
                        print("endcoded club \(encodeClub)")
                        try await movieClubCollection().document(id).setData(encodeClub)
                        //commit movie
                        // print("2: \(movieClub.movies?.first)"
                        if let movie {
                            await addFirstMovie(club: movieClub, movie: movie)
                        }
                        
                        // dont need to change anything here
                        await addClubRelationship(club: movieClub)
                        //make sure owner date is being set
                        await addClubMember(clubId: id, user: self.currentUser!, date: timeIntervalFromToday)
                        self.userMovieClubs.append(movieClub)
                    }
                }
            }catch{
                print(error)
            }
    }
    
    func addFirstMovie(club: MovieClub, movie: Movie) async {
       // print("Adding first movie: \(movie)")
        if let clubId = club.id {
            do {
                let encodedMovie = try Firestore.Encoder().encode(movie)
                print("encoded movie \(encodedMovie)")
                try await  movieClubCollection().document(clubId).collection("movies").document().setData(encodedMovie)
            }catch{
                print(error)
            }
        }
    }
    
    func addClubRelationship(club: MovieClub) async {
        // cant figure out a better way to do this but we know the val wont be null
        do{
            let emptyMovie = FirestoreMovie(title: "", poster: "", userId: currentUser?.name ?? "", author: currentUser?.id ?? "", authorAvi: currentUser?.image ?? "")
            let emptyQueueList = [emptyMovie, emptyMovie, emptyMovie]
            if let id = club.id, id != ""{
                //could set movie date here but might wait until they're closer to the next up
                let membership = Membership(clubId: id, clubName: club.name, queue: emptyQueueList)
                let encodeMembership = try Firestore.Encoder().encode(membership)
                try await usersCollection().document(currentUser?.id ?? "").collection("memberships").document(id).setData(encodeMembership)
            } else {
                print("error occurred adding club")
            }
        } catch {
            print("could not add club membership to user")
        }
    }
    
    func fetchAPIMovie(title: String) async throws -> APIMovie {
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
            return try decoder.decode(APIMovie.self, from: data)
        } catch {
            print("Failed to decode API response: \(error)")
            throw URLError(.cannotParseResponse)
        }
    }

    func fetchFirestoreMovie(id: String) async throws-> FirestoreMovie? {
        var firestoreMovies: [FirestoreMovie] = []
        do {
            let querySnapshot = try await movieClubCollection()
                .document(id)
                .collection("movies")
                //.order(by: "created", descending: false)
                .getDocuments()
            print(querySnapshot.documents)
            
            firestoreMovies = try querySnapshot.documents.compactMap {
                document in
                try document.data(as: FirestoreMovie.self)
            }
            print("movie data \(firestoreMovies)")
        } catch {
            print("Error fetching Firestore movies: \(error)")
        }

        return firestoreMovies[0]
    }
    
    func fetchAndMergeMovieData(id: String) async throws -> Movie? {
        do {
            if let firestoreMovie = try await fetchFirestoreMovie(id: id){
                let apiMovie = try await fetchAPIMovie(title: firestoreMovie.title)
                let combinedMovie = Movie(
                    id: firestoreMovie.id,
                    created: Date(),
                    title: firestoreMovie.title,
                    poster: apiMovie.poster,
                    endDate: firestoreMovie.endDate!,
                    author: firestoreMovie.author,
                    userId: firestoreMovie.userId,
                    authorAvi: firestoreMovie.authorAvi,
                    comments: firestoreMovie.comments,
                    plot: apiMovie.plot,
                    director: apiMovie.director
                )
                //print(combinedMovie)
                self.movies = []
                self.movies.append(combinedMovie)
                print("combined movie \(combinedMovie)")
                return combinedMovie
            }
        }catch{
            print(error)
        }
        return nil
    }

    func fetchUser() async throws {
        guard let uid = Auth.auth().currentUser?.uid else {return}
        guard let snapshot = try? await usersCollection().document(uid).getDocument() else {return}
        do{
            self.currentUser = try snapshot.data(as: User.self)
            print(String(describing: self.currentUser?.id ?? ""))
            await fetchUserClubs()
        }
    }
    
    func updateProfilePicture(imageData: Data) async throws {
        let path = ("Users/profile_images/\(self.currentUser?.id ?? "")")
        let storageRef = Storage.storage().reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        do {
            _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
            let url = try await storageRef.downloadURL()
            try await usersCollection().document(currentUser?.id ?? "").updateData(["image" : url.absoluteString])
            //update movies with new image
        }catch{
            throw error
        }
    }
    
    func updateUserDetails(changes: [String: Any]) async throws{
        do{
            print("in update")
           try await usersCollection().document(currentUser?.id ??
                                            "").updateData(changes)
            
            let commentsQuery = db.collectionGroup("comments").whereField("userId", isEqualTo: currentUser?.id ?? "")
            do {
                    let commentsSnapshot = try await commentsQuery.getDocuments()
                    let batch = db.batch()

                    for document in commentsSnapshot.documents {
                        // Update each comment document with the new username and profile image URL
                        batch.updateData([
                            "username": changes["name"],
                        ], forDocument: document.reference)
                    }
                    // Commit the batch write
                    try await batch.commit()
                    print("Successfully updated all relevant comments.")
                } catch {
                    print("Error updating comments: \(error)")
                }
            
            let moviesQuery = db.collectionGroup("movies").whereField("authorId", isEqualTo: currentUser?.id ?? "")
            do {
                let movieSnapshot = try await moviesQuery.getDocuments()
                let batch = db.batch()
                
                for document in movieSnapshot.documents {
                    batch.updateData([
                        "author": changes["name"] as Any,
                    ], forDocument: document.reference)
                }
                try await batch.commit()
                print("successfully updated all relevant movies")
            } catch {
                print(error)
            }
            
            let membersQuery = db.collectionGroup("members").whereField("userId", isEqualTo: currentUser?.id ?? "")
            do {
                let membersSnapshot = try await membersQuery.getDocuments()
                let batch = db.batch()
                
                for document in membersSnapshot.documents {
                    batch.updateData([
                        "userName": changes["name"] as Any,
                    ], forDocument: document.reference)
                }
                try await batch.commit()
                print("successfully updated all relevant members")
            } catch {
                print(error)
            }
            print("fetching user")
            try await fetchUser()
            
        }catch{
            throw error
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
