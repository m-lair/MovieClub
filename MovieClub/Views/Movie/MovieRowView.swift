//
//  MovieRow.swift
//  Movie Club
//
//  Created by Marcus Lair on 5/6/24.
//

import SwiftUI
import Observation
import FirebaseFirestore


struct MovieRow: View {
    @Environment(DataManager.self) var data: DataManager
    @Environment(\.dismiss) var dismiss
    let index: Int = 0
    let date: Date = Date()
    let movie: APIMovie
    @State var sheetPresented = false
    var body: some View {
        HStack {
            if let poster = movie.poster, let url = URL(string: poster) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                    }else {
                        ProgressView()
                            .frame(width: 100, height: 100)
                    }
                }
                VStack(alignment: .leading) {
                    Text(movie.title)
                        .font(.headline)
                    Text("\(movie.released)")
                        .font(.subheadline)
                }
            } else {
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 50, height: 75)
                    .overlay(Text("No Image")
                        .foregroundColor(.white)
                        .font(.caption))
            }
            Spacer()
            //gonna change to a navlink to an add sheet or something
            Button {
                Task{
                    await addMovie(apiMovie: movie)
                    dismiss()
                }
            } label: {
                Image(systemName: "plus")
                    .padding()
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    //check to see if the club exists and then create it if not
    
    private func addMovie(apiMovie: APIMovie) async {
        if let user = await data.currentUser, let clubID = await data.currentClub?.id {
            let firestoreMovie = FirestoreMovie(title: movie.title, poster: movie.poster, author: user.name)
            let movie = Movie(
                id: firestoreMovie.id,
                title: firestoreMovie.title,
                poster: apiMovie.poster,
                endDate: firestoreMovie.endDate!,
                author: firestoreMovie.author,
                comments: firestoreMovie.comments,
                plot: apiMovie.plot,
                director: apiMovie.director)
                await data.addMovie(movie: movie)
          /* saving this for updating the queue
            do{
                let snapshot = await data.usersCollection()
                    .document(user.id ?? "").collection("memberships").document(clubID)
                var queue = try await snapshot.getDocument().data(as: Membership.self)
                queue.queue[index] = firesotoreMovie
                let encodedQueue = try Firestore.Encoder().encode(queue)
                try await snapshot.setData(encodedQueue)
            } catch {
                print("error getting details: \(error)")
            }*/
        }
    }
    
    
}
    
    
    
//}

