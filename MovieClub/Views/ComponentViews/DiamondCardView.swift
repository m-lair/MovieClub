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

    @State private var effectiveRevealDate: Date?
    @State private var isLoading: Bool = true
    @State private var showScoreInfo: Bool = false
    @State private var compositeScore: Double = 0.0
    
    private var shouldReveal: Bool {
        guard let revealDate = effectiveRevealDate ?? item.revealDate else {
            return true // If no reveal date is set, always show
        }
        return Date.now >= revealDate
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Accent glow behind the card
                accentGlow
                    .overlay(VortexView(VortexSystem(
                        tags: ["circle"],
                        shape: .ellipse(radius: 0.5),
                        birthRate: 200,
                        lifespan: 2,
                        speed: 0,
                        speedVariation: 0.25,
                        angleRange: .degrees(360),
                        colors: colorToVortex(color),
                        size: 0.01,
                        sizeMultiplierAtDeath: 100
                    )) {
                        Circle()
                            .fill(.white)
                            .frame(width: 32)
                            .blur(radius: 3)
                            .blendMode(.plusLighter)
                            .tag("circle")
                    })
                    .offset(y: -100)
                    .frame(maxWidth: .infinity)
                    

                // The card itself
                cardContent
                
                // Loading indicator
                if isLoading {
                    ProgressView()
                        .scaleEffect(2.0)
                        .tint(.white)
                }
                
                // Score info sheet
                if showScoreInfo {
                    scoreInfoCard
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showScoreInfo.toggle() }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.white)
                    }
                    .disabled(isLoading) // Disable while loading
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                    }
                }
            }
            .onAppear {
                // Initialize the effective reveal date from the item
                effectiveRevealDate = item.revealDate
                
                Task {
                    do {
                        let moviesSnapshot = try await data.movieClubCollection()
                            .document(item.clubId)
                            .collection("movies")
                            .document(item.movieId ?? "")
                            .getDocument()
                        
                        guard let movieData = try? moviesSnapshot.data(as: Movie.self) else {
                            isLoading = false
                            return
                        }
                        
                        // If the item doesn't have a reveal date, try to get it from the movie
                        if item.revealDate == nil {
                            // Update our state variable with the movie's end date
                            self.effectiveRevealDate = movieData.endDate
                        }
                        
                        // Get club member count
                        let clubDoc = try await data.db
                            .collection("movieclubs")
                            .document(item.clubId)
                            .getDocument()
                        
                        let totalMembers = (clubDoc.data()?["memberCount"] as? Int) ?? 10
                        
                        // Calculate composite score
                        let likes = item.likes ?? 0
                        let dislikes = item.dislikes ?? 0
                        let collections = item.collections ?? 0
                        
                        // Skip score calculation if no data
                        if likes > 0 || dislikes > 0 {
                            // Calculate composite score
                            let totalReactions = likes + dislikes
                            let approvalRatio = totalReactions > 0 ? Double(likes) / Double(totalReactions) : 0.5
                            let collectionRate = Double(collections) / Double(max(1, totalMembers))
                            let engagementRate = Double(totalReactions) / Double(max(1, totalMembers))
                            
                            // Calculate and round to 2 decimal places
                            let score = (approvalRatio * 0.6) + (collectionRate * 0.3) + (engagementRate * 0.1)
                            self.compositeScore = (score * 100).rounded() / 100
                        }
                        
                        isLoading = false
                    } catch {
                        isLoading = false
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
    }
    
    // Extracted the card content to simplify the body
    private var cardContent: some View {
        ZStack {
            VStack {
                cardBackgroundView
                    .overlay(posterContentView)
                    .cornerRadius(10)
                    .frame(width: 340, height: 530)
                    .scaleEffect(0.9)
                
                VStack(spacing: 16) {
                    // Overall score display
                    if compositeScore > 0 && shouldReveal {
                        Text("Score: \(String(format: "%.2f", compositeScore))")
                            .font(.title2.bold())
                            .foregroundStyle(color)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 20)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.7))
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(color, lineWidth: 2)
                                    )
                            )
                    }
                    
                    // Stats row
                    HStack {
                        Label {
                            Text("\(item.likes ?? 0)")
                        } icon: {
                            Image(systemName: "hand.thumbsup.circle.fill")
                                .resizable()
                                .frame(width: 60, height: 60)
                        }
                        .foregroundStyle(.green)
                        .padding(.horizontal)
                        
                        Label {
                            Text("\(item.dislikes ?? 0)")
                        } icon: {
                            Image(systemName: "hand.thumbsdown.circle.fill")
                                .resizable()
                                .frame(width: 60, height: 60)
                        }
                        .foregroundStyle(.red)
                        .padding(.horizontal)

                        
                        Label {
                            Text("\(item.collections ?? 0)")
                        } icon: {
                            Image("collectIcon")
                                .resizable()
                                .frame(width: 60, height: 60)
                        }
                        .foregroundStyle(.yellow)
                        .padding(.horizontal)

                    }
                    .font(.title)
                }
                .padding()
            }
            .applyCardEffects(translation: translation, isDragging: isDragging)
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
    
    // Score info explanation card
    private var scoreInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("How Poster Scores Work")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                Button {
                    showScoreInfo = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.title3)
                }
            }
            .padding(.bottom, 8)
            
            Divider()
                .background(Color.white.opacity(0.3))
                
            // Simple overview
            VStack(alignment: .leading, spacing: 8) {
                Text("Your poster score is based on three factors:")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.bottom, 4)
                
                HStack {
                    Text("Current Score:")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(String(format: "%.2f", compositeScore))
                        .font(.title3.bold())
                        .foregroundColor(color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.black.opacity(0.5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .strokeBorder(color.opacity(0.5), lineWidth: 1)
                                )
                        )
                }
            }
            .padding(.bottom, 8)
            
            Group {
                scoreFactorRow(
                    title: "Likes vs. Dislikes (60%)",
                    icon: "hand.thumbsup",
                    description: "How many members liked vs. disliked this movie. This is the most important factor in your score.",
                    value: { 
                        if let likes = item.likes, let dislikes = item.dislikes, likes + dislikes > 0 {
                            return "\(likes) likes, \(dislikes) dislikes"
                        }
                        return "No ratings yet"
                    }()
                )
                
                scoreFactorRow(
                    title: "Collection Popularity (30%)",
                    icon: "square.stack.fill",
                    description: "How many club members have collected this poster compared to the total club size.",
                    value: {
                        guard let collections = item.collections else { return "None collected" }
                        return "\(collections) collections"
                    }()
                )
                
                scoreFactorRow(
                    title: "Member Engagement (10%)",
                    icon: "person.3.fill",
                    description: "How many club members have rated this movie compared to the total club size.",
                    value: {
                        if let likes = item.likes, let dislikes = item.dislikes {
                            return "\(likes + dislikes) ratings"
                        }
                        return "No ratings yet"
                    }()
                )
            }
            
            Divider()
                .background(Color.white.opacity(0.3))
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Poster Border Colors")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.bottom, 2)
                
                Text("The border color changes based on your movie's score:")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.bottom, 6)
                
                colorExplanationRow(range: "0.00-0.20", color: "negative", description: "Poorly received")
                colorExplanationRow(range: "0.21-0.35", color: "mixed", description: "Mixed reception")
                colorExplanationRow(range: "0.36-0.50", color: "balanced", description: "Balanced reception")
                colorExplanationRow(range: "0.51-0.65", color: "positive", description: "Moderately positive")
                colorExplanationRow(range: "0.66-0.80", color: "verygood", description: "Very positive")
                colorExplanationRow(range: "0.81-1.00", color: "excellent", description: "Exceptional")
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.85))
                .shadow(color: color.opacity(0.6), radius: 15)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(color.opacity(0.6), lineWidth: 2)
        )
        .frame(width: 350, height: 550)
        .transition(.opacity)
        .zIndex(10)
    }
    
    // Simplified score factor explanation
    private func scoreFactorRow(title: String, icon: String, description: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.headline)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            HStack(alignment: .top) {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(value)
                        .font(.callout.bold())
                        .foregroundColor(color)
                        .padding(.top, 2)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func explanationRow(title: String, icon: String, description: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.white)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text(value)
                    .font(.subheadline.bold())
                    .foregroundColor(color)
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.vertical, 4)
    }
    
    private func colorExplanationRow(range: String, color: String, description: String) -> some View {
        HStack(spacing: 10) {
            Text(range)
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
                .frame(width: 80, alignment: .leading)
            
            Circle()
                .fill(colorFromString(color))
                .frame(width: 16, height: 16)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.vertical, 2)
    }
    
    private func colorFromString(_ colorStr: String) -> Color {
        switch colorStr {
        case "neutral":
            return Color(red: 0.6, green: 0.6, blue: 0.6) // Medium gray
        case "negative":
            return Color(red: 0.8, green: 0.2, blue: 0.2) // Deep red
        case "mixed":
            return Color(red: 0.9, green: 0.6, blue: 0.2) // Orange
        case "balanced":
            return Color(red: 0.9, green: 0.8, blue: 0.2) // Yellow
        case "positive":
            return Color(red: 0.2, green: 0.7, blue: 0.3) // Green
        case "verygood":
            return Color(red: 0.2, green: 0.5, blue: 0.8) // Blue
        case "excellent":
            return Color(red: 0.5, green: 0.2, blue: 0.8) // Purple
        default: return Color(red: 0.2, green: 0.2, blue: 0.2) // Dark gray for unknown
        }
    }
    
    // Card background with all the gradients and effects
    private var cardBackgroundView: some View {
        Color(.black)
            .overlay(
                ZStack {
                    // Base gloss layers
                    gloss1.blendMode(.softLight)
                    gloss2.blendMode(.softLight).opacity(0.7)
                    
                    // Primary color gradient with improved contrast
                    LinearGradient(
                        colors: [color.opacity(0.6),
                                 color.opacity(0.8),
                                 color],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .blendMode(.overlay)
                    
                    // Adding depth with cross-gloss effects
                    gloss1.blendMode(.overlay).opacity(0.8)
                    gloss2.blendMode(.plusLighter).opacity(0.4)
                    
                    // Dynamic highlight based on card movement
                    LinearGradient(
                        colors: [.clear, 
                                 shouldReveal ? color.opacity(0.6) : Color.gray.opacity(0.4), 
                                 .clear],
                        startPoint: .topLeading,
                        endPoint: UnitPoint(
                            x: abs(translation.height)/100 + 1,
                            y: abs(translation.height)/100 + 1
                        )
                    )
                    
                    // Subtle inner glow for depth
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [color.opacity(0.7), color.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .blendMode(.softLight)
                }
            )
            .overlay(cardBorderView)
    }
    
    // Card border with gradient effects
    private var cardBorderView: some View {
        ZStack {
            // Primary border stroke
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(
                    AngularGradient(
                        colors: [
                            shouldReveal ? color.opacity(0.8) : Color.gray.opacity(0.5),
                            shouldReveal ? color.opacity(0.5) : Color.gray.opacity(0.3),
                            shouldReveal ? color.opacity(0.8) : Color.gray.opacity(0.5),
                            shouldReveal ? color.opacity(0.9) : Color.gray.opacity(0.6)
                        ],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    )
                )
            
            // Outer glow
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    AngularGradient(
                        colors: [
                            shouldReveal ? color.opacity(0.7) : Color.gray.opacity(0.4),
                            shouldReveal ? color.opacity(0.5) : Color.gray.opacity(0.3),
                            shouldReveal ? color.opacity(0.7) : Color.gray.opacity(0.4),
                            shouldReveal ? color.opacity(0.9) : Color.gray.opacity(0.6)
                        ],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    lineWidth: 10
                )
                .blur(radius: 10)
            
            // Additional light source for bottom-right corner
            RoundedRectangle(cornerRadius: 10)
                .trim(from: 0.5, to: 0.75) // Focus on bottom-right quadrant
                .stroke(
                    shouldReveal ? color.opacity(0.9) : Color.gray.opacity(0.6),
                    lineWidth: 8
                )
                .blur(radius: 12)
                .rotationEffect(.degrees(translation.width/20))
        }
    }
    
    // Poster content with conditional reveal logic
    private var posterContentView: some View {
        ZStack {
            // The poster image with proper placeholder
            AsyncImage(url: posterUrl) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 320, height: 510)
                        .overlay(
                            ProgressView()
                                .tint(.white)
                        )
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 320, height: 510)
                        .clipped()
                case .failure:
                    Rectangle()
                        .fill(Color.red.opacity(0.3))
                        .frame(width: 320, height: 510)
                        .overlay(
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.white)
                        )
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 320, height: 510)
            
            // Conditional overlay for unrevealed posters
            if !shouldReveal {
                unrevealedContentView
            }
        }
    }
    
    // Content shown when poster is not yet revealed
    private var unrevealedContentView: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: 320, height: 510)
            .background(.ultraThinMaterial)
            .colorInvert()
            .blur(radius: 1.5)
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
                    
                    VStack(spacing: 16) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                        
                        if let revealDate = effectiveRevealDate ?? item.revealDate {
                            Text("Reveals")
                                .font(.headline)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.9))
                            
                            Text(revealDate, style: .date)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
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

    // Soft color glow behind the card
    var accentGlow: some View {
        // Slight offset, a big blur, plus color
        RoundedRectangle(cornerRadius: 30)
            .fill(shouldReveal ? color.opacity(0.5) : Color.gray.opacity(0.3))
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
    
    // New rotated gloss for added dimension and light effect
    var gloss2: some View {
        Image("Gloss 1")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .rotationEffect(.degrees(180))  // Rotate the image 180 degrees
            .mask(
                LinearGradient(
                    colors: [.white, .clear, .white, .clear, .white],
                    startPoint: .bottomTrailing,
                    endPoint: UnitPoint(
                        x: 1 - abs(translation.width)/150,
                        y: 1 - abs(translation.width)/150
                    )
                )
                .frame(width: 392)
            )
    }
}

// Extension to apply 3D card effects
extension View {
    func applyCardEffects(translation: CGSize, isDragging: Bool) -> some View {
        self
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

// Helper function to map SwiftUI colors to Vortex colors
private func colorToVortex(_ uiColor: Color) -> VortexSystem.ColorMode {
    // Extract the UIColor/NSColor for proper color conversion
    #if canImport(UIKit)
    let components = UIColor(uiColor).cgColor.components ?? [0, 0, 0, 1]
    #else
    let components = NSColor(uiColor).cgColor.components ?? [0, 0, 0, 1]
    #endif
    
    // Basic mapping from common colors to Vortex predefined colors
    if uiColor == .red { return .ramp(.red, .red, .red.opacity(0)) }
    if uiColor == .blue { return .ramp(.blue, .blue, .blue.opacity(0)) }
    if uiColor == .green { return .ramp(.green, .green, .green.opacity(0)) }
    if uiColor == .yellow { return .ramp(.yellow, .yellow, .yellow.opacity(0)) }
    if uiColor == .orange { return .ramp(.orange, .orange, .orange.opacity(0)) }
    if uiColor == .purple { return .ramp(.purple, .purple, .purple.opacity(0)) }
    if uiColor == .pink { return .ramp(.pink, .pink, .pink.opacity(0)) }
    
    // For custom colors, create a custom Vortex.Color from components
    let vortexColor = VortexSystem.Color(
        red: Double(components[0]),
        green: Double(components.count > 1 ? components[1] : 0),
        blue: Double(components.count > 2 ? components[2] : 0),
        opacity: Double(components.count > 3 ? components[3] : 1)
    )
    
    return .ramp(vortexColor, vortexColor, vortexColor.opacity(0))
}
