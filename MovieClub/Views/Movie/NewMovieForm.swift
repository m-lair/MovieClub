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
                if movie.poster != "" {
                let url = URL(string: movie.poster)
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
                        //
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
}


