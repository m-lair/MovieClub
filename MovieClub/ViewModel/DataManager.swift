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
    var clubID: String {
        currentClub?.id ?? ""
    }
    
    var queue: Membership?
    var db: Firestore!
    
    init(){
        Task {
            self.userSession = Auth.auth().currentUser
            db = Firestore.firestore()
            //await fetchUser()
        }
    }
    func addToComingSoon(clubID: String, userID: String, date: Date) async {
        //add member object
        do {
            try await movieClubCollection().document(clubID).collection("members").document(userID).updateData(["seletor" : true, "comingSoonDate" : date])
            
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
    
    func createUser(user: User) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: user.email, password: user.password)
            self.userSession = result.user
            let user = User(id: result.user.uid, email: user.email, bio: user.bio, name: user.name, image: user.image, password: user.password)
            let encodeUser = try Firestore.Encoder().encode(user)
            try await usersCollection().document(user.id ?? "").setData(encodeUser)
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
    
    func uploadClubImage(image: UIImage, clubId: String) async -> String{
        let storageRef = Storage.storage().reference().child("Clubs/\(clubId)/_banner.jpg")
        if let imageData = image.jpegData(compressionQuality: 0.25) {
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            do {
                _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
                let url = try await storageRef.downloadURL()
                // Update clubss profile image URL
                return url.absoluteString
                
            } catch {
                print("Error uploading image: \(error.localizedDescription)")
            }
        }
        return ""
    }
    
    func joinClub(club: MovieClub) async {
        if let user = self.currentUser, let clubID = club.id {
            await addClubMember(clubID: clubID, user: user, date: Date())
            await incrementMember(clubID: clubID)
            await addClubRelationship(club: club)
        }
    }
    
    func addClubMember(clubID: String, user: User, date: Date) async {
        do{
            if let id = user.id {
                let member = Member(userID: id, userName: user.name, userAvi: user.image ?? "" , selector: false, dateAdded: date)
                let encodedMember = try Firestore.Encoder().encode(member)
                try await movieClubCollection().document(clubID).collection("members").document(id).setData(encodedMember)
            }
        } catch {
            print("couldnt add member")
        }
    }
    
    func leaveClub(club: MovieClub) async {
        if let clubID = club.id, let userID = self.currentUser?.id {
            do {
                try await movieClubCollection().document(clubID).collection("memberships").document(userID).delete()
                await decrementMember(clubID: clubID)
                self.userMovieClubs.removeAll { $0.name == club.name}
            }catch {
                print(error)
            }
        }
    }
    
    func decrementMember(clubID: String) async {
        do{
            try await movieClubCollection().document(clubID).updateData(["numMembers" : FieldValue.increment(-1.0)])
        } catch {
            print("unable to update number of members. User count may be incorrect")
        }
    }
    
    func removeClubRelationship(clubID: String, userID: String) async {
        // cant figure out a better way to do this but we know the val wont be null
        do{
            try await usersCollection().document(userID).collection("memberships").document(clubID).delete()
        } catch {
            print("could not delete club membership: \(error)")
        }
    }
    
    func incrementMember(clubID: String) async {
        do{
            try await movieClubCollection().document(clubID).updateData(["numMembers" : FieldValue.increment(1.0)])
        } catch {
            print("unable to update number of members. User count may be incorrect")
        }
    }
    
    func getProfileImage(id: String, path: String) async -> String  {
        //   print("in getter")
        let storageRef = Storage.storage().reference().child("\(path).jpeg") //Storage.storage().reference().child("Users/profile_images/\(id).jpeg")
        do {
            let url = try await storageRef.downloadURL()
            self.currentUser?.image = url.absoluteString
            return url.absoluteString
        } catch {
            print(error)
        }
        return ""
    }
    
    func loadQueue() async {
        if let clubID = self.currentClub?.id, let id = self.currentUser?.id  {
            usersCollection().document(id).collection("memberships").document(clubID).addSnapshotListener { documentSnapshot, error in
                guard let document = documentSnapshot else {
                    print("errrr fetching queue \(String(describing: error))")
                    return
                }
                if let member = try? document.data(as: Membership.self) {
                    print("#### Member object: \(member)")
                    self.queue = member
                }
            }
        }
    }
    
    func postComment(comment: Comment, movieClubID: String, movieID: String) async{
        do {
            let encodeComment = try Firestore.Encoder().encode(comment)
            try await movieClubCollection().document(movieClubID)
                .collection("movies").document(movieID)
                .collection("comments").document().setData(encodeComment)
            
            print("Comment added successfully")
        } catch {
            print("Error adding comment: \(error.localizedDescription)")
        }
    }
    
    func fetchComments(movieClubId: String, movieId: String) async -> [Comment]{
        print("in fetch comments")
        print("query clubID \(movieClubId) + movieID \(movieId)")
        do {
            let querySnapshot = try await movieClubCollection().document(movieClubId).collection("movies").document(movieId).collection("comments").getDocuments()
            
            
            let comments = querySnapshot.documents.compactMap { document in
                print("comment doc \(document)")
                do {
                    return try document.data(as: Comment.self)
                } catch {
                    print("Error decoding document \(document.documentID): \(error)")
                    return nil
                }
            }
            print("comments \(comments)")
            self.comments = comments
            return comments
            //  print("self.comments in method: \(self.comments)")
        } catch {
            print("Error fetching comments: \(error.localizedDescription)")
        }
        return []
    }
    
    func fetchMovieClubsForUser() async {
        // print("in fetchMovieClubsForUsers")
        do{
            guard let user = self.currentUser else {
                print("User not found")
                return
            }
            let snapshot = try await usersCollection().document(user.id ?? "").collection("memberships").getDocuments()
            
            let documents = snapshot.documents
            
            let clubIDs = documents.compactMap { document in
                print("document loop \(document.description)")
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
    func addMovie(movie: Movie) {
        self.movies.append(movie)
        print("current movie in method \(movie)")
    }
    
    func createMovieClub(movieClub: MovieClub) async {
        var urlString = ""
        //just to be sure
        self.currentClub = movieClub
            do {
                //commit image data
                if let banner = movieClub.banner, let id = movieClub.id {
                    if let image = UIImage(data: banner) {
                        urlString = await uploadClubImage(image: image, clubId: id)
                    
                    }
                }
                self.currentClub?.bannerUrl = urlString
                //this is the future date for the owner, would be their 2nd movie
                let futureOwnerMovieDate = Date()
                if let timeIntervalFromToday = Calendar.current.date(byAdding: .weekOfYear, value: movieClub.timeInterval, to: futureOwnerMovieDate){
                    //encode the club
                    let encodeClub = try Firestore.Encoder().encode(movieClub)
                    if let id = movieClub.id{
                        //commit club
                        try await movieClubCollection().document(id).setData(encodeClub)
                        //commit movie
                        print("2: \(movieClub.movies?.first)")
                        if let movie = self.movies.first {
                            print("in if: \(movie)")
                            await addFirstMovie(club: movieClub, movie: movie)
                        }
                        // dont need to change anything here
                        await addClubRelationship(club: movieClub)
                        //make sure owner date is being set
                        await addClubMember(clubID: id, user: self.currentUser!, date: timeIntervalFromToday)
                        self.userMovieClubs.append(movieClub)
                        self.movies = []
                        
                    }
                }
            }catch{
                print(error)
            }
    }
    func addFirstMovie(club: MovieClub, movie: Movie) async {
        print("m")
        if let clubID = club.id {
            do {
                let encodedMovie = try Firestore.Encoder().encode(movie)
                print("encoded movie \(encodedMovie)")
                try await  movieClubCollection().document(clubID).collection("movies").document().setData(encodedMovie)
            }catch{
                print(error)
            }
        }
    }
    
    //TODO: update time interval method to push movies back
    
    
    func addClubRelationship(club: MovieClub) async {
        // cant figure out a better way to do this but we know the val wont be null
        do{
            let emptyMovie = FirestoreMovie(title: "", author: "")
            let emptyQueueList = [emptyMovie, emptyMovie, emptyMovie]
            if let id = club.id, id != ""{
                //could set movie date here but might wait until they're closer to the next up
                let membership = Membership(clubID: id, clubName: club.name, queue: emptyQueueList)
                let encodeMembership = try Firestore.Encoder().encode(membership)
                try await usersCollection().document(currentUser?.id ?? "").collection("memberships").document(id).setData(encodeMembership)
            } else {
                print("error occurred adding club")
            }
        } catch {
            print("could not add club membership to user")
        }
    }
    
    func fetchMovieClub(clubID: String) async {
        // print("in fetchMovieClub")
        guard let snapshot = try? await movieClubCollection().document(clubID).getDocument() else {return}
        do {
            let movieClub = try snapshot.data(as: MovieClub.self)
            self.userMovieClubs.append(movieClub)
        } catch {
            print("Error decoding movie club: \(error)")
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
    
    func fetchNextUp(club: MovieClub) async throws -> FirestoreMovie? {
        // get small list of members and store here
        var members: [Member] = []
        // initialize date/time
        let today = Date()
        //if club has an id, proceed
        if let clubID = club.id {
            do {
                //get a max of 3 members in the roster/list
                //sort by date added to the list, this date is refreshed after a users movie becomes
                //current playing
                let querySnapshot = try await movieClubCollection()
                    .document(club.id ?? "")
                    .collection("members")
                    .whereField("selector", isEqualTo: true)
                    .order(by: "dateAdded", descending: true)
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
                            updateEndDates(memberID: member.id ?? "", club: club, counter: counter)
                            // this will likely break
                        } else {
                            // if they do match, then cycle to next movie
                            do {
                                try await movieClubCollection().document(club.id ?? "").collection("members").document(member.userID).updateData(["dateAdded" : Date()])
                                let snapshot = try await usersCollection().document(member.userID).collection("memberships").document(club.id ?? "").getDocument()
                                let membership = try snapshot.data(as: Membership.self)
                                let userQueue: [FirestoreMovie] = membership.queue
                                for movie in userQueue {
                                    //should probably change this to imdb id
                                    let fireStoreMovies = try await movieClubCollection().document(clubID).collection("movies").whereField("title", isEqualTo: movie.title)
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
    
    func updateEndDates(memberID: String, club: MovieClub, counter: Int) {
        if let clubID = club.id {
            movieClubCollection().document(clubID).collection("members").document(memberID).updateData(["movieEndDate": Calendar.current.date(byAdding: .weekOfYear, value: club.timeInterval * counter, to: club.movieEndDate) as Any])
        }
    }
    
    /*  func fetchMemberMovie(clubID: String, member: Member) async {
     let userID = member.userID
     do {
     let snapshot = try await usersCollection().document(userID).collection("memberships").document(clubID).
     }catch{
     print(error)
     }
     } */

    func fetchFirestoreMovie(club: MovieClub) async throws-> FirestoreMovie? {
        var firestoreMovies: [FirestoreMovie] = []
        let today = Date()
        do {
            let querySnapshot = try await movieClubCollection()
                .document(club.id ?? "")
                .collection("movies")
                .whereField("endDate", isGreaterThan: today)
                .order(by: "endDate", descending: true)
                .getDocuments()
            print("document\(querySnapshot)")
            firestoreMovies = try querySnapshot.documents.compactMap { document in
                try document.data(as: FirestoreMovie.self)
            }
        } catch {
            print("Error fetching Firestore movies: \(error)")
        }
        if firestoreMovies.count > 0 {
            return firestoreMovies[0]
        }else{
            do {
                return try await fetchNextUp(club: club)
            } catch {
                print("error fetching next movie")
            }
        }
        return nil
    }
    
    //fetch current playing by current end date that is greater than today
    //should only be one, everything else would be archive
    //if 0, iterate the list
    //query members
    func fetchAndMergeMovieData(club: MovieClub) async throws -> Movie? {
        do {
            if let firestoreMovie = try await fetchFirestoreMovie(club: club){
                let apiMovie = try await fetchAPIMovie(title: firestoreMovie.title)
                let combinedMovie = Movie(
                    id: firestoreMovie.id,
                    title: firestoreMovie.title,
                    poster: apiMovie.poster,
                    endDate: firestoreMovie.endDate!,
                    author: firestoreMovie.author,
                    comments: firestoreMovie.comments,
                    plot: apiMovie.plot,
                    director: apiMovie.director
                )
                //print(combinedMovie)
                self.movies = []
                self.movies.append(combinedMovie)
                return combinedMovie
            }
        }catch{
            print(error)
        }
        return nil
    }
    //self.currentClub?.movies = movies
    //print("##### \(currentClub?.movies)")
    
    func formatMovieForAPI(title: String) -> String {
            return title.replacingOccurrences(of: " ", with: "+")
        }
    func fetchMember() async {
        //TODO
    }
    
    func fetchUser() async {
      //  print("in fetch user"
      //  print("1")
        guard let uid = Auth.auth().currentUser?.uid else {return}
       // print("2")
        guard let snapshot = try? await usersCollection().document(uid).getDocument() else {return}
            //print("Document data: \(snapshot.data())")
        
            do{
                self.currentUser = try snapshot.data(as: User.self)
            }catch{
                print(error)
            }
        let path = ("Users/profile_images/\(self.currentUser?.id ?? "")")
        await self.currentUser!.image = getProfileImage(id: currentUser!.id!, path: path)
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
    static var TestData: [MovieClub] = [MovieClub(name: "FMFC Club",
                                                  created: Date(),
                                                  numMembers: 2,
                                                  description: "FMFC",
                                                  ownerName: "Duhmarcus",
                                                  timeInterval: 4,
                                                  movieEndDate: Calendar.current.date(byAdding: .weekOfYear, value: 4, to: Date())!,
                                                  ownerID: "000123",
                                                  isPublic: true,
                                                  bannerUrl: "https://firebasestorage.googleapis.com:443/v0/b/movieclub-93714.appspot.com/o/Clubs%2FH71IficmTcmCGOnF4hrn%2F_banner.jpg?alt=media&token=7c5c6c53-c1a7-4a28-a1ba-8defd431c7fa",
                                                  movies: [Movie(id: "001",
                                                                 title: "The Matrix",
                                                                 poster: "https://m.media-amazon.com/images/M/MV5BOGUyZDUxZjEtMmIzMC00MzlmLTg4MGItZWJmMzBhZjE0Mjc1XkEyXkFqcGdeQXVyMTMxODk2OTU@._V1_SX300.jpg",
                                                                 endDate: Calendar.current.date(byAdding: .weekOfYear, value: 4, to: Date())!, author: "duhmarcus")]),
                                        MovieClub(name: "Test Title 2",
                                                  created: Date(),
                                                  numMembers: 1,
                                                  description: "description",
                                                  ownerName: "darius garius",
                                                  timeInterval: 2, movieEndDate: Date(), ownerID: "1345",
                                                  isPublic: true)]
}

