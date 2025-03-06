//
//  DiamondCardView.swift
//  MovieClub
//
//  Created by Marcus Lair on 2/12/25.
//

import SwiftUI
import Vortex
import FirebaseFirestore

struct DiamondCardView: View {
    let posterUrl: URL
    let color: Color
    let item: CollectionItem
    
    @Environment(DataManager.self) var data
    @Environment(\.dismiss) var dismiss
    @State private var translation: CGSize = .zero
    @State private var isDragging = false
    @GestureState private var press = false
    
    @State var likedBy: [String] = []
    @State var dislikedBy: [String] = []
    @State var collectedBy: [String] = []

    var body: some View {
        NavigationStack {
            ZStack {
                // Accent glow behind the card
                accentGlow
                    .overlay(VortexView(.fireflies) {
                        Circle()
                            .fill(color.opacity(0.3))
                            .frame(width: 32)
                            .blur(radius: 3)
                            .blendMode(.plusLighter)
                            .tag("circle")
                    })

                // The card itself
                ZStack {
                    VStack {
                        Color(.black)
                            .overlay(gloss1.blendMode(.softLight))
                            .overlay(gloss1.blendMode(.luminosity))
                            .overlay(
                                LinearGradient(
                                    colors: [color.opacity(0.5), color],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .blendMode(.overlay)
                            )
                            .overlay(gloss1.blendMode(.overlay))
                            .overlay(
                                LinearGradient(
                                    colors: [.clear, color.opacity(0.5), .clear],
                                    startPoint: .topLeading,
                                    endPoint: UnitPoint(
                                        x: abs(translation.height)/100 + 1,
                                        y: abs(translation.height)/100 + 1
                                    )
                                )
                            )
                        // Stroke borders with color
                            .overlay(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(
                                            LinearGradient(
                                                colors: [.clear, color, .clear, color, .clear],
                                                startPoint: .topLeading,
                                                endPoint: UnitPoint(
                                                    x: abs(translation.width)/100 + 0.5,
                                                    y: abs(translation.height)/100 + 0.5
                                                )
                                            )
                                        )
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(
                                            LinearGradient(
                                                colors: [.clear, color, .clear, color, .clear],
                                                startPoint: .topLeading,
                                                endPoint: UnitPoint(
                                                    x: abs(translation.width)/100 + 0.8,
                                                    y: abs(translation.height)/100 + 0.8
                                                )
                                            ),
                                            lineWidth: 10
                                        )
                                        .blur(radius: 10)
                                }
                            )
                            .overlay(
                                CachedAsyncImage(url: posterUrl) {
                                    EmptyView()
                                }
                                .frame(width: 320, height: 510)
                            )
                            .cornerRadius(10)
                            .frame(width: 340, height: 530)
                            .scaleEffect(0.9)
                            .rotation3DEffect(
                                .degrees(isDragging ? 10 : 0),
                                axis: (x: -translation.height, y: translation.width, z: 0)
                            )
                            .rotation3DEffect(
                                .degrees(Double(translation.width) / 8),
                                axis: (x: 0, y: 1, z: 0),
                                anchor: .center,
                                perspective: 0.4
                            )
                            .rotation3DEffect(
                                .degrees(-Double(translation.height) / 12),
                                axis: (x: 1, y: 0, z: 0),
                                anchor: .center,
                                perspective: 0.4
                            )
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        translation = value.translation
                                        isDragging = true
                                    }
                                    .onEnded { _ in
                                        withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.6)) {
                                            translation = .zero
                                            isDragging = false
                                        }
                                    }
                            )
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                    }
                }
            }
            .onAppear {
                Task {
                    let moviesSnapshot = try await data.movieClubCollection()
                        .document(item.clubId)
                        .collection("movies")
                        .document(item.movieId ?? "")
                        .getDocument()
                    
                    let movieData = try moviesSnapshot.data(as: Movie.self)
                    self.collectedBy = movieData.collectedBy
                    self.likedBy = movieData.likedBy
                    self.dislikedBy = movieData.dislikedBy
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    // Soft color glow behind the card
    var accentGlow: some View {
        // Slight offset, a big blur, plus color
        RoundedRectangle(cornerRadius: 30)
            .fill(color.opacity(0.5))
            .frame(width: 400, height: 580)
            .blur(radius: 60)
            .opacity(0.7)
            .offset(y: 20)
            // Makes the glow move/scale slightly with the drag
            .scaleEffect(1 + abs(translation.width)/1000 + abs(translation.height)/1000)
    }

    var gloss1: some View {
        Image("Gloss 1")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .mask(
                LinearGradient(
                    colors: [.clear, .white, .clear, .white, .clear, .white, .clear],
                    startPoint: .topLeading,
                    endPoint: UnitPoint(
                        x: abs(translation.height)/100 + 1,
                        y: abs(translation.height)/100 + 1
                    )
                )
                .frame(width: 392)
            )
    }
    
    var posterStats: some View {
        HStack {
            VStack {
                Text("\(likedBy.count)")
                Image(systemName: "hand.thumbsup.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.green)
                    .frame(width: 100, height: 100)
                
            }
            
            
            VStack {
                Text("\(dislikedBy.count)")
                Image(systemName: "hand.thumbsdown.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundStyle(.red)
                   
            }
           

            VStack {
                Text("\(collectedBy.count)")
                CollectIcon()
                    .frame(width: 100, height: 100)
            }
        }
    }
}

struct CollectIcon: View {
    var body: some View {
        ZStack {
            // Yellow circle
            Circle()
                .fill(Color.yellow)
                .frame(width: 100, height: 100)
            
            // Stacked rectangles in the center
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black)
                    .frame(width: 50, height: 70)
            }
        }
    }
}
