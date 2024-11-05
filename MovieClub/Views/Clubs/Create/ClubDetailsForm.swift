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
    
    @State var banner: UIImage?
    @State private var photoItem: PhotosPickerItem?
    @State private var name = ""
    @State private var isPublic = false // Default to private
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
                Section("Banner"){
                    BannerSelector(banner: $banner, photoItem: $photoItem)
                }
                .listRowInsets(EdgeInsets())
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
    
    
    @MainActor
    private func submit() async throws{
        guard
            let user = data.currentUser,
            let userId = user.id
        else { return }
        
        guard let bannerData = try await photoItem?.loadTransferable(type: Data.self) else { return }
            let movieClub =
            MovieClub(name: name,
                      desc: desc,
                      ownerName: user.name,
                      timeInterval: timeInterval,
                      ownerId: userId,
                      isPublic: isPublic,
                      banner: bannerData,
                      bannerUrl: "no-image")
        
            /*let movie =
             Movie(created: created,
             title: apiMovie?.title ?? "",
             poster: apiMovie?.poster ?? "",
             endDate: endDate,
             userName: user.name,
             userId: userId,
             authorAvi: user.image ?? "")*/
        do {
            try await data.createMovieClub(movieClub: movieClub)
            navPath.removeLast(navPath.count)
            
        }catch{
            print("error submitting club \(error)")
            
        }
    }
    
}

