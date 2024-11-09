//
//  CircularImageView.swift
//  MovieClub
//
//  Created by Marcus Lair on 8/12/24.
//

import SwiftUI
import FirebaseStorage

struct CircularImageView: View {
    @Environment(DataManager.self) var data: DataManager
    @Environment(\.editMode) private var editMode
    @State var imageUrl: URL?
    @State var userId: String?
    var image: UIImage?
    var size: CGFloat? = 0
    var path: String? = ""
    
    private var imageText: String {
        editMode?.wrappedValue.isEditing == true ? "Select Image" : "No Image"
    }
    
    var body: some View {
        Group{
            if let image = image {
                // Display the UIImage (used for the preview)
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(Circle())
                    .frame(width: size, height: size)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .shadow(radius: 10)
            } else if let imageUrl = imageUrl {
                // Display the image from the URL (used for the final saved image)
                AsyncImage(url: imageUrl) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(Circle())
                        .frame(width: size, height: size)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .shadow(radius: 10)
                } placeholder: {
                    // Placeholder while the image is loading
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: size, height: size)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        )
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .shadow(radius: 10)
                }
            } else {
                // Placeholder for when there is no image selected or loaded
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: size, height: size)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                        
                    )
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .shadow(radius: 10)
            }
        }
        .task {
            guard let userId = userId else { return }
                
            do {
                if let profileImageUrl = try await data.getProfileImage(userId: userId) {
                    self.imageUrl = URL(string: profileImageUrl)
                }
            } catch {
                
            }
        }
    }
}
