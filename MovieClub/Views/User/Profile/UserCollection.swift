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
    let userId: String?
    @State var collection: [CollectionItem] = []
    var sortedCollection: [CollectionItem] {
        collection.sorted {
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
                ForEach(sortedCollection) { item in
                    VStack {
                        if let url = URL(string: item.posterUrl) {
                            CachedAsyncImage(url: url) {
                                PlaceholderView()
                            }
                            .aspectRatio(2/3, contentMode: .fill) // gives that taller poster look
                            .clipped()
                            .modifier(PosterRevealModifier(revealDate: item.revealDate))
                            .onTapGesture {
                                selectedItem = item
                                showInspectView = true
                            }
                        } else {
                            PlaceholderView()
                        }
                    }
                    .overlay(
                        // Only show colored border if the poster should be revealed
                        shouldRevealPoster(revealDate: item.revealDate) ?
                        Rectangle()
                            .stroke(item.color, lineWidth: 2) :
                        Rectangle()
                            .stroke(Color.clear, lineWidth: 2)
                    )
                }
            }
            .padding(.top) // spacing on the left/right
        }
        .scrollIndicators(.hidden)
        .onAppear {
            Task {
                if let userId {
                    self.collection = try await data.fetchCollectionItems(for: userId)
                }
            }
        }
        .fullScreenCover(item: $selectedItem) { item in
            if let url = URL(string: item.posterUrl) {
                DiamondCardView(posterUrl: url, color: item.color, item: item)
            } else {
                // Fallback to a placeholder if URL is invalid
                DiamondCardView(
                    posterUrl: URL(string: "https://image.tmdb.org/t/p/original/placeholder.jpg")!,
                    color: item.color,
                    item: item
                )
            }
        }
    }
    
    // Helper function to check if a poster should be revealed
    private func shouldRevealPoster(revealDate: Date?) -> Bool {
        guard let revealDate = revealDate else {
            return true // If no reveal date is set, always show
        }
        return Date.now >= revealDate
    }
    
    @ViewBuilder
    private func PlaceholderView() -> some View {
        Rectangle()
            .fill(Color.gray)
        // match the same aspect ratio so you don't get size jumps
            .aspectRatio(2/3, contentMode: .fill)
            .overlay(
                Text("?")
                    .font(.largeTitle)
                    .foregroundColor(.white)
            )
            .clipped()
    }
}

// Custom modifier to apply negative effect when poster shouldn't be revealed
struct PosterRevealModifier: ViewModifier {
    let revealDate: Date?
    
    private var shouldReveal: Bool {
        guard let revealDate = revealDate else {
            return true // If no reveal date is set, always show
        }
        return Date.now >= revealDate
    }
    
    func body(content: Content) -> some View {
        if shouldReveal {
            content
        } else {
            content
                .colorInvert() // Apply negative effect
                .blur(radius: 1) // Slight blur for unrevealed posters
                .overlay(
                    ZStack {
                        // Dark overlay with gradient
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.7),
                                Color.black.opacity(0.5)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        
                        VStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            
                            if let revealDate = revealDate {
                                Text("Reveals")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white.opacity(0.9))
                                
                                Text(revealDate, style: .date)
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color.white.opacity(0.2))
                                    )
                            }
                        }
                        .padding()
                    }
                )
        }
    }
}

struct CollectionCardView: View {
    let collectionItem: CollectionItem

    @Environment(\.dismiss) private var dismiss

    @State private var dragOffset: CGSize = .zero
    
    private var shouldReveal: Bool {
        guard let revealDate = collectionItem.revealDate else {
            return true // If no reveal date is set, always show
        }
        return Date.now >= revealDate
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Fullscreen background
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Poster image, scaled up for fullscreen
                CachedAsyncImage(url: URL(string: collectionItem.posterUrl)) {
                    ProgressView()
                    
                }
                .scaledToFit()
                .frame(maxWidth: 300, maxHeight: 450)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .modifier(PosterRevealModifier(revealDate: collectionItem.revealDate))
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
