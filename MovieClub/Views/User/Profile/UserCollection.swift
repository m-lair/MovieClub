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
    @Environment(\.dismiss) var dismiss
    var collection: [CollectionItem] {
        data.currentCollection.sorted {
            guard let date1 = $0.collectedDate, let date2 = $1.collectedDate else { return false }
            return date1 > date2
        }
    }
    @State var showInspectView: Bool = false
    @State var selectedItem: CollectionItem?
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
                            .onTapGesture {
                                selectedItem = item
                                showInspectView = true
                            }
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
        .fullScreenCover(item: $selectedItem) { item in
            //CollectionCardView(collectionItem: item)
            DiamondCardView(posterUrl: URL(string: item.posterUrl)!, color: item.color, item: item)
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

struct CollectionCardView: View {
    let collectionItem: CollectionItem

    @Environment(\.dismiss) private var dismiss

    @State private var dragOffset: CGSize = .zero

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Fullscreen background
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Poster image, scaled up for fullscreen
                AsyncImage(url: URL(string: collectionItem.posterUrl)) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 300, maxHeight: 450)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } placeholder: {
                    ProgressView()
                        .frame(width: 140, height: 200)
                }
                .padding()

                // Could add more details here if desired:
                // Text(collectionItem.title)
                //     .font(.headline)
                //     .foregroundColor(.white)
            }
            // 3D tilt effect
            .rotation3DEffect(
                .degrees(Double(dragOffset.width) / 8),
                axis: (x: 0, y: 1, z: 0),
                anchor: .center,
                perspective: 0.4
            )
            .rotation3DEffect(
                .degrees(-Double(dragOffset.height) / 12),
                axis: (x: 1, y: 0, z: 0),
                anchor: .center,
                perspective: 0.4
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { _ in
                        withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.6)) {
                            dragOffset = .zero
                        }
                    }
            )

            // 'X' button for dismissing full screen
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.title)
                    .padding()
                    .foregroundColor(.white)
            }
            .padding(.top, 40) // Move it away from top edge if you want
            .padding(.trailing)
        }
    }
}
