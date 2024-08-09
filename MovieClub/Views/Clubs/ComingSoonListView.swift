//
//  ComingSoonListView.swift
//  MovieClub
//
//  Created by Marcus Lair on 8/7/24.
//

import SwiftUI

struct ComingSoonListView: View {
    @Environment(DataManager.self) var data: DataManager
    @Environment(\.dismiss) var dismiss
    @State private var movies: [FirestoreMovie] = []
    @State private var showSheet = false
    @State private var selectedMovie: APIMovie?
    @State private var selectedIndex: Int = 0
    @State private var isAddingNewMovie = false
    var body: some View {
        Text("Manage Your Queue for \(data.queue?.clubName)")
            .font(.title)
        List {
          //  let _ = print("\(data.queue?.queue)")
            ForEach(movies.indices, id: \.self) { index in
                HStack {
                    AsyncImage(url: URL(string: movies[index].poster ?? ""))
                    Text(movies[index].title)  // Assuming 'title' is a property of Movie
                    Spacer()
                    Button {
                        // selectedMovie = movies[index]
                        selectedIndex = index
                        showSheet = true
                    } label: {
                        Image(systemName: "pencil")
                    }
                }
            }
            .onMove(perform: move)
            .sheet(isPresented: $showSheet) {
                AddMovieView() { newMovie in
                    let _ = print("NEW MOVIE: \(newMovie)")
                    // Update existing movie
                    movies[selectedIndex].title = newMovie.title
                    movies[selectedIndex].poster = newMovie.poster
                    
                    showSheet = false
                }
            }
        }
        .onAppear(){
            Task{
                await data.loadQueue()
                await loadQueue()
                //okay we are getting the list back but the entries are empty
                //need to get the poster and title onto the queue now
                //easiest to just grab these values off the api movie and add them to queue
            }
        }
        .onChange(of: movies) {
            Task {
                //nothing now
            }
        }
        .toolbar{
            ToolbarItem(placement: .topBarTrailing) {
                Button{
                    Task{
                        await save()
                        dismiss()
                    }
                } label: {
                    Text("Save")
                }
            }
        }
    }
    private func save() async {
        await data.updateQueue(movies: self.movies)
    }
    private func move(from source: IndexSet, to destination: Int) {
        movies.move(fromOffsets: source, toOffset: destination)
    }
    private func loadQueue() async {
        self.movies = await data.queue?.queue ?? []
        print("self.movies \(movies)")
    }
}





