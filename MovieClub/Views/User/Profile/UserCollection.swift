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
    let flexibleColumns = [
        GridItem(.flexible(minimum: 50, maximum: 200)),
        GridItem(.flexible(minimum: 50, maximum: 200)),
        GridItem(.flexible(minimum: 50, maximum: 200))
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: flexibleColumns, spacing: 10) {
                ForEach(collection) { item in
                    VStack {
                        if let url = URL(string: item.posterUrl) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(maxHeight: 250)
                                        .clipped()
                                case .failure, .empty:
                                    PlaceholderView()
                                @unknown default:
                                    PlaceholderView()
                                }
                            }
                        } else {
                            PlaceholderView()
                        }
                    }
                    .overlay(
                        Rectangle()
                            .stroke(item.color, lineWidth: 2)
                    )
                    .padding()
                }
            }
            .padding()
        }
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
            .frame(maxHeight: 250)
            .overlay(
                Text("?")
                    .font(.largeTitle)
                    .foregroundColor(.white)
            )
    }
}
