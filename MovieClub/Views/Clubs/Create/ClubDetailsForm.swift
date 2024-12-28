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
    @Binding var navPath: NavigationPath
    
    @State private var photoItem: PhotosPickerItem?
    @State private var name = ""
    @State private var isPublic = true // Default to public
    @State private var selectedOwnerIndex = 0
    @State private var timeInterval: Int = 2
    @State private var screenWidth = UIScreen.main.bounds.size.width
   
    let weeks: [Int] = [1,2,3,4]
    @State private var desc = ""
    @State private var showPicker = false
    var body: some View {
        VStack{
            Form {
                Section("General"){
                    HStack{
                        VStack {
                            TextField("Name", text: $name)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            TextField("Description", text: $desc)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section("Settings") {
                    Toggle("Public Club", isOn: $isPublic)
                    HStack {
                        Text("Week Interval")
                            .font(.subheadline)
                        Picker("Week Interval", selection: $timeInterval) {
                            ForEach(weeks, id: \.self) { option in
                                Text("\(option)").tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                Button{
                    Task{
                        try await submit()
                        print("navPath: \(navPath)")
                        navPath.removeLast(navPath.count)
                    }
                }label:{
                    Text("Create Club")
                }
            }
        }
    }
    
    func encodeImageToBase64(_ image: UIImage) -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return nil
        }
        return imageData.base64EncodedString()
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
            data.userClubs.append(movieClub)
        }catch{
            print("error submitting club \(error)")
        }
    }
}

