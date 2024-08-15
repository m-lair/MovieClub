//
//  AviSelector.swift
//  MovieClub
//
//  Created by Marcus Lair on 8/12/24.
//

import SwiftUI
import PhotosUI

struct AviSelector: View {
    @Environment(DataManager.self) private var data
    @Environment(\.editMode) private var editMode
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data? = nil
    @State private var showPicker: Bool = false
    
    private var croppedImage: UIImage? {
        if let selectedImageData {
            return UIImage(data: selectedImageData)
        } else {
            return nil
        }
    }
    // bring in current photo using url
    // user chooses new photo, can we update and change the currentUser.image
    // or
    // should we update the UIimage to the selected image using UIImage and then put that data in the storage
    var body: some View {
        VStack {
            if let selectedImageData = selectedImageData {
                // Show the preview of the selected image
                CircularImageView(image: UIImage(data: selectedImageData))
                    .frame(width: 150, height: 150)
                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                    .shadow(radius: 10)
                    .onTapGesture {
                        if editMode?.wrappedValue.isEditing == true {
                            showPicker.toggle()
                        }
                    }
            } else if let profileImageURL = data.currentUser?.image {
                // Show the existing profile image from Firebase
                CircularImageView(imageUrl: URL(string: profileImageURL))
                    .frame(width: 150, height: 150)
                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                    .shadow(radius: 10)
                    .onTapGesture {
                        if editMode?.wrappedValue.isEditing == true {
                            showPicker.toggle()
                        }
                    }
            } else {
                // Show a placeholder if no image is available
                CircularImageView(imageUrl: nil)
                    .frame(width: 150, height: 150)
                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                    .shadow(radius: 10)
                    .onTapGesture {
                        if editMode?.wrappedValue.isEditing == true {
                            showPicker.toggle()
                        }
                    }
            }
        }
        .onChange(of: selectedItem) {
            Task {
                selectedImageData = try await selectedItem?.loadTransferable(type: Data.self)
                if let selectedImageData {
                    try await data.updateProfilePicture(imageData: selectedImageData)
                }
            }
        }
        .photosPicker(isPresented: $showPicker, selection: $selectedItem)
    }
}


#Preview {
    AviSelector()
}
