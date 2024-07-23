//
//  NewMovieForm.swift
//  MovieClub
//
//  Created by Marcus Lair on 7/14/24.
//

import SwiftUI
import FirebaseFirestore

struct NewMovieForm: View {
    @Environment(DataManager.self) private var data: DataManager
    @Environment(\.dismiss) private var dismiss
    var movie: APIMovie
    @State var selectedDate: Date = Date()
    var body: some View {
        Section{
            VStack{
                Text(movie.title)
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
                    VStack{
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
                HStack{
                    Text(movie.director ?? "")
                    Text(movie.released)
                    Text(movie.plot ?? "")
                }
                Button {
                    Task{
                        await addMovie(movie: movie)
                    }
                    dismiss()
    
                    
                } label: {
                    Text("Add Movie")
                    
                }

            }
            
        }
        Form{
            DatePicker("Select a date", selection: $selectedDate, displayedComponents: .date)
                               .datePickerStyle(GraphicalDatePickerStyle())
            
        }
    }
    private func addMovie(movie: APIMovie) async{
        let db = Firestore.firestore()
        if let name = await data.currentUser?.name {
            let firesotoreMovie = FirestoreMovie(title: movie.title, startDate: selectedDate, endDate: selectedDate + TimeInterval(14), author: name)
            do{
                var movie = try await data.fetchAPIMovie(title: movie.title)
                let encodedMovie = try Firestore.Encoder().encode(firesotoreMovie)
                try await db.collection("movieclubs").document(data.currentClub?.id ?? "").collection("movies").addDocument(from: firesotoreMovie)
                dismiss()
                
            } catch {
                print("error getting details: \(error)")
            }
        }
    }
}


