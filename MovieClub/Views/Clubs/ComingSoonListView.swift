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
    private var movies: [FirestoreMovie] {
        membership?.queue ?? []
    }
    var clubName: String {
        membership?.clubName ?? ""
    }
    @State private var showSheet = false
    @State private var selectedMovie: APIMovie?
    @State private var selectedIndex: Int = 0
    @State private var membership: Membership?
    
    var body: some View {
        Text("Manage Your Queue for \(clubName)")
            .font(.title2)
        List {
          //  let _ = print("\(data.queue?.queue)")
            ForEach(movies.indices, id: \.self) { index in
                HStack {
                    AsyncImage(url: URL(string: movies[index].poster ?? "")) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 100)
                        }else {
                            Text("?")
                                .frame(width: 100, height: 100)
                        }
                    }

                    Text(movies[index].title)  // Assuming 'title' is a property of Movie
                    Spacer()
                    Button {
                        // selectedMovie = movies[index]
                        
                        selectedIndex = index
                        let _ = print("showSheet before true \(showSheet)")
                        showSheet = true
                        
                    } label: {
                        Image(systemName: "pencil")
                    }
                }
            }
            
        }
        .sheet(isPresented: $showSheet) {
            AddMovieView() { newMovie in
                let _ = print("NEW MOVIE: \(newMovie)")
                if var membership = membership {
                    membership.queue[selectedIndex].title = newMovie.title
                    membership.queue[selectedIndex].poster = newMovie.poster
                    self.membership = membership  // Reassign to update
                    //let _ = print("poster \(String(describing: membership.queue[selectedIndex].poster))")
                }
            }
        }
        .onAppear(){
            Task{
                await data.loadQueue()
                await loadQueue()
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
        if let membership {
            print("MEMBERSHIP \(membership)")
            await data.updateQueue(membership: membership)
        }
    }
    private func loadQueue() async {
        if let membership = await data.queue {
            self.membership = membership
        }
        print("self.movies \(movies)")
    }
}





