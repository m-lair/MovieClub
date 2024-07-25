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
    let index: Int
    let date: Date
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
                    await addMovie(movie: movie)
                    dismiss()
                }
            } label: {
                Image(systemName: "plus")
                    .padding()
            }
            .buttonStyle(PlainButtonStyle())
        }
        .sheet(isPresented: $sheetPresented, content: {
            NewMovieForm(movie: movie)})
        .padding()
    }
    
    private func addMovie(movie: APIMovie) async{
        
        if let user = await data.currentUser, let clubID = await data.currentClub?.id {
            let firesotoreMovie = FirestoreMovie(title: movie.title, poster: movie.poster, startDate: date, author: user.name)
            do{
                let snapshot = await data.usersCollection()
                    .document(user.id ?? "").collection("memberships").document(clubID)
                var queue = try await snapshot.getDocument().data(as: Membership.self)
                queue.queue[index] = firesotoreMovie
                let encodedQueue = try Firestore.Encoder().encode(queue)
                try await snapshot.setData(encodedQueue)
                
            } catch {
                print("error getting details: \(error)")
            }
        }
    }
    
    
}
    
    
    
//}

