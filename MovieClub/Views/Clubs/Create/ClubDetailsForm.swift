//
//  ClubDetailsForm.swift
//  MovieClub
//
//  Created by Marcus Lair on 7/29/24.
//

import SwiftUI
import PhotosUI
import FirebaseFirestore

// MARK: - Club Details Card View
private struct ClubDetailsCardView: View {
    @Binding var name: String
    @Binding var desc: String
    let validationError: String?
    let nameFieldShake: Bool
    let cardOffset: CGFloat
    let cardOpacity: Double
    
    private let textColor = Color.white
    private let subtitleColor = Color.white.opacity(0.7)
    private let fieldBackgroundColor = Color.white.opacity(0.1)
    private let borderColor = Color.white.opacity(0.2)
    private let errorColor = Color.red.opacity(0.9)
    private let cardColor = Color(.gray.opacity(0.25))
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Club Details")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(textColor)
                .padding(.top, 16)
            
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(cardColor)
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Club Name")
                            .font(.headline)
                            .foregroundColor(subtitleColor)
                        
                        HStack {
                            Image(systemName: "person.3.fill")
                                .foregroundColor(borderColor)
                                .font(.subheadline)
                            
                            TextField("Enter club name", text: $name)
                                .font(.body)
                                .foregroundColor(textColor)
                                .padding(.vertical, 8)
                        }
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(fieldBackgroundColor)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(validationError != nil ? errorColor : borderColor, lineWidth: 1)
                        )
                        .frame(height: 44) // Reduced height for smaller screens
                        .modifier(ShakeEffect(animatableData: nameFieldShake ? 1 : 0))
                        
                        if let error = validationError {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(errorColor)
                                    .font(.caption)
                                
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(errorColor)
                            }
                            .padding(.horizontal, 4)
                            .transition(.opacity)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Description")
                            .font(.headline)
                            .foregroundColor(subtitleColor)
                        
                        HStack(alignment: .top) {
                            Image(systemName: "text.bubble")
                                .foregroundColor(borderColor)
                                .font(.subheadline)
                                .padding(.top, 8)
                            
                            TextField("What's your club about?", text: $desc, axis: .vertical)
                                .font(.body)
                                .foregroundColor(textColor)
                                .lineLimit(3...)
                                .padding(.vertical, 6)
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 90, alignment: .topLeading) // Reduced height for smaller screens
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(fieldBackgroundColor)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(borderColor, lineWidth: 1)
                        )
                    }
                }
                .padding(20) // Reduced padding for smaller screens
            }
            .offset(y: cardOffset)
            .opacity(cardOpacity)
        }
    }
}

// MARK: - Privacy Toggle View
private struct PrivacyToggleView: View {
    @Binding var isPublic: Bool
    let cardOffset: CGFloat
    let cardOpacity: Double
    
    private let textColor = Color.white
    private let cardColor = Color(.gray.opacity(0.25))
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(cardColor)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            
            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(isPublic ? .green.opacity(0.2) : .red.opacity(0.2))
                            .frame(width: 32, height: 32) // Reduced size
                            .animation(.spring(response: 0.3), value: isPublic)
                        
                        Image(systemName: isPublic ? "globe" : "lock.fill")
                            .foregroundColor(isPublic ? .green.opacity(0.7) : .red.opacity(0.7))
                            .font(.system(size: 14, weight: .medium)) // Smaller icon
                            .contentTransition(.symbolEffect(.replace.downUp.byLayer))
                    }
                    
                    Text(isPublic ? "Public club" : "Private club")
                        .font(.headline)
                        .foregroundColor(textColor)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                        .animation(.snappy(duration: 0.4), value: isPublic)
                        .id(isPublic)
                }
                
                Spacer()
                
                Toggle("", isOn: $isPublic)
                    .toggleStyle(SwitchToggleStyle(tint: .green.opacity(0.5)))
                    .labelsHidden()
            }
            .padding(20) // Reduced padding
        }
        .offset(y: cardOffset)
        .opacity(cardOpacity)
    }
}

// MARK: - Movie Rotation Interval View
private struct MovieRotationIntervalView: View {
    @Binding var timeInterval: Int
    let cardOffset: CGFloat
    let cardOpacity: Double
    
    private let textColor = Color.white
    private let subtitleColor = Color.white.opacity(0.7)
    private let fieldBackgroundColor = Color.white.opacity(0.1)
    private let cardColor = Color(.gray.opacity(0.25))
    private let accentColor = Color(.blue.opacity(0.5))
    private let weeks: [Int] = [1, 2, 3, 4]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Movie Details")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(textColor)
                .padding(.top, 16)
            
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(cardColor)
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(textColor)
                            .font(.headline)
                        
                        Text("Movie Rotation Interval")
                            .font(.headline)
                            .foregroundColor(subtitleColor)
                    }
                    
                    Text("How long should your clubs watch period be?")
                        .font(.caption)
                        .padding([.bottom, .top], 5)
                    
                    // Use GeometryReader to make the week buttons responsive
                    GeometryReader { geometry in
                        let buttonWidth = min(100, (geometry.size.width - 36) / 4)
                        HStack(spacing: 8) {
                            ForEach(weeks, id: \.self) { option in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        timeInterval = option
                                    }
                                } label: {
                                    Text("\(option) \(option == 1 ? "Week" : "Weeks")")
                                        .font(.subheadline)
                                        .foregroundColor(textColor)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(timeInterval == option ? accentColor : fieldBackgroundColor)
                                        )
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                    }
                    .frame(height: 44)
                }
                .padding(20)
            }
        }
        .offset(y: cardOffset)
        .opacity(cardOpacity)
    }
}

// MARK: - Create Button View
private struct CreateButtonView: View {
    let isValidating: Bool
    let showSuccessAnimation: Bool
    let name: String
    let cardOffset: CGFloat
    let cardOpacity: Double
    let action: () async -> Void
    
    private let textColor = Color.white
    private let accentColor = Color(.blue.opacity(0.5))
    
    var body: some View {
        Button {
            Task {
                await action()
            }
        } label: {
            HStack {
                if isValidating {
                    ProgressView()
                        .tint(.black)
                        .padding(.trailing, 8)
                } else if showSuccessAnimation {
                    Image(systemName: "checkmark")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.trailing, 8)
                }
                
                Text("Create Club")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(name.isEmpty ? .white.opacity(0.5) : .white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48) // Consistent height
            .background(
                Capsule()
                    .fill(accentColor)
                    .opacity(isValidating || name.isEmpty ? 0.6 : 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(isValidating || name.isEmpty)
        .padding(.top, 24)
        .padding(.bottom, 40)
        .offset(y: cardOffset)
        .opacity(cardOpacity)
        .sensoryFeedback(.impact, trigger: showSuccessAnimation)
    }
}

// MARK: - Main View
struct ClubDetailsForm: View {
    @Environment(DataManager.self) var data: DataManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Binding var navPath: NavigationPath
    
    @State private var photoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var name = ""
    @State private var isPublic = true
    @State private var timeInterval: Int = 2
    @State private var desc = ""
    
    @State private var validationError: String? = nil
    @State private var isValidating = false
    @State private var showSuccessAnimation = false
    
    @State private var nameFieldShake = false
    @State private var formAppeared = false
    @State private var cardOffset: [CGFloat] = [100, 130, 160]
    @State private var cardOpacity: [Double] = [0, 0, 0]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ClubDetailsCardView(
                        name: $name,
                        desc: $desc,
                        validationError: validationError,
                        nameFieldShake: nameFieldShake,
                        cardOffset: cardOffset[0],
                        cardOpacity: cardOpacity[0]
                    )
                    
                    PrivacyToggleView(
                        isPublic: $isPublic,
                        cardOffset: cardOffset[1],
                        cardOpacity: cardOpacity[1]
                    )
                    
                    MovieRotationIntervalView(
                        timeInterval: $timeInterval,
                        cardOffset: cardOffset[2],
                        cardOpacity: cardOpacity[2]
                    )
                    
                    CreateButtonView(
                        isValidating: isValidating,
                        showSuccessAnimation: showSuccessAnimation,
                        name: name,
                        cardOffset: cardOffset[2],
                        cardOpacity: cardOpacity[2],
                        action: validateAndSubmit
                    )
                }
                .padding(16) // Reduced padding for smaller devices
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack {
                    Text("MovieClub")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            animateFormAppearance()
        }
    }
    
    private func animateFormAppearance() {
        withAnimation(.easeOut(duration: 0.5)) {
            formAppeared = true
        }
        
        for i in 0..<cardOffset.count {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(i) * 0.15)) {
                cardOffset[i] = 0
                cardOpacity[i] = 1
            }
        }
    }
    
    func encodeImageToBase64(_ image: UIImage) -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return nil
        }
        return imageData.base64EncodedString()
    }
    
    private func validateAndSubmit() async {
        isValidating = true
        validationError = nil
        
        // Basic validation
        let basicResult = ValidationService.validateClubNameBasic(name)
        
        switch basicResult {
        case .failure(let error):
            withAnimation(.spring) {
                validationError = error.localizedDescription
                nameFieldShake = true
            }
            // Reset shake animation after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                nameFieldShake = false
            }
            isValidating = false
            return
        case .success:
            // Continue with server validation with fallback
            let serverResult = await ValidationService.validateClubNameWithFallback(name)
            
            switch serverResult {
            case .failure(let error):
                withAnimation(.spring) {
                    validationError = error.localizedDescription
                }
                isValidating = false
                return
            case .success:
                // All validation passed, create the club
                do {
                    try await submit()
                    
                    // Show success animation briefly before navigating
                    withAnimation(.spring) {
                        showSuccessAnimation = true
                    }
                    
                    // Small delay to show success animation
                    try? await Task.sleep(for: .milliseconds(600))
                    
                    navPath.removeLast(navPath.count)
                } catch {
                    withAnimation(.spring) {
                        validationError = "Failed to create club: \(error.localizedDescription)"
                    }
                }
                isValidating = false
            }
        }
    }
    
    private func submit() async throws{
        guard
            let user = data.currentUser,
            let userId = user.id
        else { return }
        
        let movieClub = MovieClub(name: name,
                                  desc: desc,
                                  ownerName: user.name,
                                  timeInterval: timeInterval,
                                  ownerId: userId,
                                  isPublic: isPublic,
                                  bannerUrl: "no-image")
        
        do {
            try await data.createMovieClub(movieClub: movieClub)
        } catch {
            print("error submitting club \(error)")
            throw error
        }
    }
}
    
    // Custom button style with scale animation
    struct ScaleButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
        }
    }
    
    // Shake effect modifier
    struct ShakeEffect: GeometryEffect {
        var animatableData: CGFloat
        
        func effectValue(size: CGSize) -> ProjectionTransform {
            ProjectionTransform(CGAffineTransform(translationX: 10 * sin(animatableData * .pi * 2), y: 0))
        }
    }

