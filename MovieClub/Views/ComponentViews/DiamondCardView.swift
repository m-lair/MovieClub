//
//  DiamondCardView.swift
//  MovieClub
//
//  Created by Marcus Lair on 2/12/25.
//

import SwiftUI
import Vortex

struct DiamondCardView: View {
    let posterUrl: URL
    let color: Color
    @Environment(\.dismiss) var dismiss
    @State private var translation: CGSize = .zero
    @State private var isDragging = false
    @GestureState private var press = false

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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                    }
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
}


