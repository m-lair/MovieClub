//
//  CircularImageView.swift
//  MovieClub
//
//  Created by Marcus Lair on 8/12/24.
//

import SwiftUI
import FirebaseStorage


//TODO: you left off thinking it would be easiest to change some of the circle image logic to just get passed a userId and then do the fetch from here. so loop through, hstack a circleImage(userId: object.userId) and then do use that everywhere







struct CircularImageView: View {
    @Environment(DataManager.self) var data: DataManager
    @Environment(\.editMode) private var editMode
    @State var imageUrl: URL?
    @State var userId: String?
    var image: UIImage?
    var size: CGFloat? = 0
    var path: String? = ""
    
    private var imageText: String {
        if editMode?.wrappedValue.isEditing == true {
            return "Select Image"
        } else {
            return "No Image"
        }
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
        .task{
            if let userId = userId {
                self.imageUrl = await URL(string: data.getProfileImage(userId: userId))
            }
        }
    }
}
