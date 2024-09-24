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
            print("auth curr user \(String(describing: Auth.auth().currentUser))")
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
            try await fetchUser()
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
                    print("Error decoding document \(document.documentId): \(error)")
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
    
    func fetchMovieClubsForUser() async {
        var clubList: [MovieClub] = []
        do{
            guard let user = self.currentUser else {
                print("User not found")
                return
            }
            print("user id: \(user.id)")
            let snapshot = try await usersCollection().document(user.id ?? "").collection("memberships").getDocuments()
            
            let documents = snapshot.documents
            
            let clubIds = documents.compactMap { document in
                print("document loop \(document.documentId)")
                return document.data()["clubId"] as? String ?? "error"
                
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
    
    func addMovie(movie: Movie) {
        self.movies.append(movie)
        print("current movie in method \(movie)")
    }
    
    func createMovieClub(movieClub: MovieClub, movie: Movie?) async {
        
        print("movieclub bannerURL: \(movieClub.bannerUrl)")
        //just to be sure
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
                        self.movies = []
                        
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
            let emptyMovie = FirestoreMovie(title: "", poster: "", author: currentUser?.name ?? "", authorId: currentUser?.id ?? "", authorAvi: currentUser?.image ?? "")
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
    
    func fetchMovieClub(clubId: String) async -> MovieClub? {
        // print("in fetchMovieClub")
        guard let snapshot = try? await movieClubCollection().document(clubId).getDocument() else {return nil}
        do {
            var movieClub = try snapshot.data(as: MovieClub.self)
            print("decoded movieClub \(movieClub)")
            let moviesSnapshot = try await movieClubCollection().document(clubId).collection("movies").order(by: "endDate" , descending: false).limit(to: 1).getDocuments()
            print("snapshot count: \(moviesSnapshot.count)")
       
            for document in moviesSnapshot.documents {
                print("document data \(document.documentId)")
                movieClub.movies = [try document.data(as: Movie.self)]
            }
            return movieClub
        } catch {
            print("Error decoding movie: \(error)")
        }
        return nil
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
    
    func fetchNextUp(club: MovieClub) async throws -> FirestoreMovie? {
        // get small list of members and store here
        var members: [Member] = []
        // initialize date/time
        let today = Date()
        //if club has an id, proceed
        if let clubId = club.id {
            do {
                //get a max of 3 members in the roster/list
                //sort by date added to the list, this date is refreshed after a users movie becomes
                //current playing
                let querySnapshot = try await movieClubCollection()
                    .document(club.id ?? "")
                    .collection("members")
                    .whereField("selector", isEqualTo: true)
                    .order(by: "dateAdded", descending: false)
                    .limit(to: 3)
                    .getDocuments()
                // get next up members based on how long ago they joined club
                // this date is sorting oldest to the top
                members = try querySnapshot.documents.compactMap { document in
                    try document.data(as: Member.self)
                }
                //this counter should be an easy way to handle most of the date manipulation.
                //start at 1 since its used as a multiplyer
                var counter = 1
                for member in members {
                    if let endDate = member.movieDate {
                        let nextEndDate = Calendar.current.date(byAdding: .weekOfYear, value: club.timeInterval * counter, to: club.movieEndDate)
                        // if the end date of the next users movie doesnt match the predicted next date based on the clubs current club interval, update the 3
                        if endDate != nextEndDate {
                            updateEndDates(memberId: member.id ?? "", club: club, counter: counter)
                            // this will likely break
                        } else {
                            // if they do match, then cycle to next movie
                            do {
                                try await movieClubCollection().document(club.id ?? "").collection("members").document(member.userId).updateData(["dateAdded" : Date()])
                                let snapshot = try await usersCollection().document(member.userId).collection("memberships").document(club.id ?? "").getDocument()
                                let membership = try snapshot.data(as: Membership.self)
                                let userQueue: [FirestoreMovie] = membership.queue
                                for movie in userQueue {
                                    //should probably change this to imdb id
                                    let fireStoreMovies = try await movieClubCollection().document(clubId).collection("movies").whereField("title", isEqualTo: movie.title)
                                        .whereField("dateEnded", isLessThan: Date()).getDocuments()
                                    if fireStoreMovies.count == 0 {
                                        return movie
                                    }
                                }
                            }catch{
                                print("unable to add user to list")
                            }
                        }
                        counter += 1
                    }
                }
            } catch {
                print("Error fetching Firestore movies: \(error)")
            }
        }
        return nil
    }
    
    func updateEndDates(memberId: String, club: MovieClub, counter: Int) {
        if let clubId = club.id {
            movieClubCollection().document(clubId).collection("members").document(memberId).updateData(["movieEndDate": Calendar.current.date(byAdding: .weekOfYear, value: club.timeInterval * counter, to: club.movieEndDate) as Any])
        }
    }
    
    /*  func fetchMemberMovie(clubId: String, member: Member) async {
     let userId = member.userId
     do {
     let snapshot = try await usersCollection().document(userId).collection("memberships").document(clubId).
     }catch{
     print(error)
     }
     } */

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
    
    //fetch current playing by current end date that is greater than today
    //should only be one, everything else would be archive
    //if 0, iterate the list
    //query members
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
                    authorId: firestoreMovie.authorId,
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
    //self.currentClub?.movies = movies
    //print("##### \(currentClub?.movies)")

    
    func fetchUser() async throws {
      print("in fetch user")
        guard let uid = Auth.auth().currentUser?.uid else {return}
        guard let snapshot = try? await usersCollection().document(uid).getDocument() else {return}
            do{
                self.currentUser = try snapshot.data(as: User.self)
            }catch{
                print(error)
            }
        let path = ("Users/profile_images/\(uid)")
              
        if userMovieClubs.isEmpty {
            await fetchMovieClubsForUser()
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

extension MovieClub {
    static var TestData: [MovieClub] = [MovieClub(name: "FMFC Club",
                                                  created: Date(),
                                                  numMembers: 2,
                                                  description: "FMFC",
                                                  ownerName: "Duhmarcus",
                                                  timeInterval: 4,
                                                  movieEndDate: Calendar.current.date(byAdding: .weekOfYear, value: 4, to: Date())!,
                                                  ownerId: "000123",
                                                  isPublic: true,
                                                  bannerUrl: "https://firebasestorage.googleapis.com:443/v0/b/movieclub-93714.appspot.com/o/Clubs%2FH71IficmTcmCGOnF4hrn%2F_banner.jpg?alt=media&token=7c5c6c53-c1a7-4a28-a1ba-8defd431c7fa",
                                                  movies: [Movie(id: "001", created: Date(),
                                                                 title: "The Matrix",
                                                                 poster: "https://m.media-amazon.com/images/M/MV5BOGUyZDUxZjEtMmIzMC00MzlmLTg4MGItZWJmMzBhZjE0Mjc1XkEyXkFqcGdeQXVyMTMxODk2OTU@._V1_SX300.jpg",
                                                                 endDate: Calendar.current.date(byAdding: .weekOfYear, value: 4, to: Date())!, author: "duhmarcus", authorId: "tUM5fRuYZSUs86ud8tydTqjKcC43", authorAvi: "https://firebasestorage.googleapis.com/v0/b/movieclub-93714.appspot.com/o/Users%2Fprofile_images%2FtUM5fRuYZSUs86ud8tydTqjKcC43.jpeg?alt=media&token=1abbcce9-e460-48b8-9770-04f2a75be20f")]),
                                        MovieClub(name: "Test Title 2",
                                                  created: Date(),
                                                  numMembers: 1,
                                                  description: "description",
                                                  ownerName: "darius garius",
                                                  timeInterval: 2, movieEndDate: Date(), ownerId: "1345",
                                                  isPublic: true)]
}

