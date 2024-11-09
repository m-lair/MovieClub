//
//  UserCollection.swift
//  MovieClub
//
//  Created by Marcus Lair on 10/31/24.
//

import SwiftUI


struct CollectionItem: Identifiable, Hashable {
    let id = UUID()
    let url: String
    let color: Color
}

struct UserCollectionView: View {
    @Environment(DataManager.self) private var data: DataManager
    let colors: [Color] = [.red, .blue, .green, .yellow, .orange]
    let flexibleColumns = [
            GridItem(.flexible(minimum: 50, maximum: 200)),
            GridItem(.flexible(minimum: 50, maximum: 200)),
            GridItem(.flexible(minimum: 50, maximum: 200))
            ]
    var body: some View {
        ScrollView {
            LazyVGrid(columns: flexibleColumns, spacing: 10) {
                ForEach(data.currentCollection, id: \.id) { item in
                    let randomColor = colors.randomElement() ?? Color.black
                    AsyncImage(url: URL(string: item.url)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 250)
                                .overlay(Rectangle()
                                    .stroke(randomColor, lineWidth: 2))
                                .padding()
                        case .failure:
                            Image("\(item.url)")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 250)
                                .overlay(Rectangle()
                                    .stroke(randomColor, lineWidth: 2))
                                .padding()
                        
                        case .empty:
                            Image("\(item.url)")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 250)
                                .overlay(Rectangle()
                                    .stroke(randomColor, lineWidth: 2))
                                .padding()
                        
                        @unknown default:
                            Image("\(item.url)")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 250)
                                .overlay(Rectangle()
                                    .stroke(randomColor, lineWidth: 2))
                                .padding()
                        }
                    }
                }
            }
        }
       /* .onAppear {
            let collection: [String] = [
                "https://m.media-amazon.com/images/M/MV5BYTFmNTFlOTAtNzEyNi00MWU2LTg3MGEtYjA2NWY3MDliNjlkXkEyXkFqcGc@._V1_SX300.jpg",
                "https://m.media-amazon.com/images/M/MV5BYTFmNTFlOTAtNzEyNi00MWU2LTg3MGEtYjA2NWY3MDliNjlkXkEyXkFqcGc@._V1_SX300.jpg",
                "https://m.media-amazon.com/images/M/MV5BYTFmNTFlOTAtNzEyNi00MWU2LTg3MGEtYjA2NWY3MDliNjlkXkEyXkFqcGc@._V1_SX300.jpg",
                "https://m.media-amazon.com/images/M/MV5BYTFmNTFlOTAtNzEyNi00MWU2LTg3MGEtYjA2NWY3MDliNjlkXkEyXkFqcGc@._V1_SX300.jpg"
            ]
            
            self.collectionItems = collection.map { url in
                CollectionItem(
                    url: url,
                    color: colors.randomElement() ?? .black
                )
            }
        }*/
    }
}

