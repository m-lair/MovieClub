//
//  UserCollection.swift
//  MovieClub
//
//  Created by Marcus Lair on 10/31/24.
//

import SwiftUI
import FirebaseFirestore


struct UserCollectionView: View {
    @Environment(DataManager.self) private var data: DataManager

    var collection: [CollectionItem] {
        data.currentCollection.sorted {
            guard let date1 = $0.collectedDate, let date2 = $1.collectedDate else { return false }
            return date1 > date2
        }
    }
    
    // Two columns. Feel free to adjust the minimum widths and spacing to make them bigger/smaller.
    private let columns = [
        GridItem(.flexible(minimum: 140), spacing: 16),
        GridItem(.flexible(minimum: 140), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns) {
                ForEach(collection) { item in
                    VStack {
                        if let url = URL(string: item.posterUrl) {
                            CachedAsyncImage(url: url) {
                                PlaceholderView()
                            }
                            .aspectRatio(2/3, contentMode: .fill) // gives that taller poster look
                            .clipped()
                        } else {
                            PlaceholderView()
                        }
                    }
                    .overlay(
                        Rectangle()
                            .stroke(item.color, lineWidth: 2)
                    )
                }
            }
            .padding(.top) // spacing on the left/right
        }
        .scrollIndicators(.hidden)
        .onAppear {
            Task {
                await data.fetchCurrentCollection()
            }
        }
    }

    @ViewBuilder
    private func PlaceholderView() -> some View {
        Rectangle()
            .fill(Color.gray)
            // match the same aspect ratio so you don’t get size jumps
            .aspectRatio(2/3, contentMode: .fill)
            .overlay(
                Text("?")
                    .font(.largeTitle)
                    .foregroundColor(.white)
            )
            .clipped()
    }
}
