//
//  ClubDetailsForm.swift
//  MovieClub
//
//  Created by Marcus Lair on 7/29/24.
//

import SwiftUI
import PhotosUI
import FirebaseFirestore

struct ClubDetailsForm: View {
    @Environment(DataManager.self) var data: DataManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Binding var navPath: NavigationPath
    
    @State private var photoItem: PhotosPickerItem?
    @State private var name = ""
    @State private var isPublic = true // Default to public
    @State private var selectedOwnerIndex = 0
    @State private var timeInterval: Int = 2
    @State private var screenWidth = UIScreen.main.bounds.size.width
   
    @State private var validationError: String? = nil
    @State private var isValidating = false
    @State private var showSuccessAnimation = false
    
    let weeks: [Int] = [1,2,3,4]
    @State private var desc = ""
    @State private var showPicker = false
    
    // Colors for modern UI
    private var accentColor: Color { Color.blue }
    private var errorColor: Color { Color.red }
    private var backgroundColor: Color { colorScheme == .dark ? Color(white: 0.15) : Color(white: 0.97) }
    private var cardColor: Color { colorScheme == .dark ? Color(white: 0.2) : .white }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                Text("Create New Club")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                // Club details card
                VStack(spacing: 16) {
                    // Name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Club Name")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        TextField("Enter club name", text: $name)
                            .font(.title3)
                            .fontWeight(.medium)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(backgroundColor)
                            )
                            .onChange(of: name) { _, _ in
                                validationError = nil
                            }
                        
                        if let error = validationError {
                            Label(error, systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(errorColor)
                                .padding(.horizontal, 4)
                                .transition(.opacity)
                        }
                    }
                    
                    // Description field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        TextField("What's your club about?", text: $desc, axis: .vertical)
                            .font(.body)
                            .padding()
                            .frame(minHeight: 100, alignment: .topLeading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(backgroundColor)
                            )
                            .lineLimit(4...)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(cardColor)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal)
                
                // Settings card
                VStack(spacing: 16) {
                    Text("Settings")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Public/Private toggle
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Club Visibility")
                                .font(.headline)
                            
                            Text(isPublic ? "Anyone can find and join your club" : "Only people with a direct link can join")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $isPublic)
                            .toggleStyle(.switch)
                            .tint(accentColor)
                            .labelsHidden()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(backgroundColor)
                    )
                    
                    // Week interval
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Movie Rotation Interval")
                            .font(.headline)
                        
                        Text("How often should movies rotate in your club?")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Picker("Week Interval", selection: $timeInterval) {
                            ForEach(weeks, id: \.self) { option in
                                Text("\(option) \(option == 1 ? "Week" : "Weeks")").tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.top, 4)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(backgroundColor)
                    )
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(cardColor)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal)
                
                // Create button
                Button {
                    Task {
                        await validateAndSubmit()
                    }
                } label: {
                    HStack {
                        if isValidating {
                            ProgressView()
                                .tint(.white)
                                .padding(.trailing, 8)
                        } else if showSuccessAnimation {
                            Image(systemName: "checkmark")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.trailing, 8)
                        }
                        
                        Text("Create Club")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isValidating || validationError != nil ? accentColor.opacity(0.6) : accentColor)
                    )
                }
                .buttonStyle(.plain)
                .disabled(isValidating || name.isEmpty)
                .padding(.horizontal)
                .padding(.top, 10)
            }
            .padding(.vertical, 20)
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationBarTitleDisplayMode(.inline)
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
