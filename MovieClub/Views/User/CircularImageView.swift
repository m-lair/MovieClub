//
//  CircularImageView.swift
//  MovieClub
//
//  Created by Marcus Lair on 8/12/24.
//

import SwiftUI

struct CircularImageView: View {
    @Environment(\.editMode) private var editMode
    var imageUrl: URL?
    var image: UIImage?
    
    
    private var imageText: String {
        if editMode?.wrappedValue.isEditing == true {
            return "Select Image"
        } else {
            return "No Image"
        }
    }
    var body: some View {
        if let image = image {
            // Display the UIImage (used for the preview)
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipShape(Circle())
                .frame(width: 150, height: 150)
                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                .shadow(radius: 10)
        } else if let imageUrl = imageUrl {
            // Display the image from the URL (used for the final saved image)
            AsyncImage(url: imageUrl) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(Circle())
                    .frame(width: 150, height: 150)
                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                    .shadow(radius: 10)
            } placeholder: {
                // Placeholder while the image is loading
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 150, height: 150)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    )
                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                    .shadow(radius: 10)
            }
        } else {
            // Placeholder for when there is no image selected or loaded
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 150, height: 150)
                .overlay(
                    Text(imageText)
                        .foregroundColor(.white)
                        .font(.caption)
                )
                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                .shadow(radius: 10)
        }
    }
}
#Preview {
    CircularImageView()
}
