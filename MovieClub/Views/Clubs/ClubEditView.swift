//
//  ClubEditView.swift
//  MovieClub
//
//  Created by Marcus Lair on 10/10/24.
//

/*
   description: string;
   image: string;
   isPublic: boolean;
   name: string;
   ownerId: string;
   ownerName: string;
   timeInterval: string;

 */

import SwiftUI
import Foundation
import PhotosUI

struct ClubEditView: View {
    
    @Environment(DataManager.self) var data: DataManager
    @State var errorShowing: Bool = false
    @State var errorMessage: String = ""
    
    let movieClub: MovieClub
    @State var name = ""
    @State var description = ""
    @State var isPublic: Bool = false
    @State var image: String = ""
    @State var banner: UIImage?
    @State var photoItem: PhotosPickerItem?
    @State var timeInterval: Int = 0
    @State var ownerId: String = ""
    
    var body: some View {
        VStack(spacing: 5){
            TextField(movieClub.name, text: $name)
            Divider()
            TextField(movieClub.desc ?? " ", text: $description)
            Divider()
            BannerSelector(banner: $banner, photoItem: $photoItem)
            Divider()
            Toggle("Public", isOn: $isPublic)
            Divider()
            TextField("Image", text: $image)
            Picker("Week Interval", selection: $timeInterval) {
                ForEach(1..<4, id: \.self) { option in
                    Text("\(option)").tag(option)
                }
            }
            .pickerStyle(.segmented)
            Divider()
            TextField("Owner Id", text: $ownerId)
            Divider()
            Spacer()
            Button("Update") {
                Task {
                   try await submit()
                }
            }
        }
        
        .alert(errorMessage, isPresented: $errorShowing) {
            Button("OK", role: .cancel) {}
        }
        .onAppear {
            name = movieClub.name
            description = movieClub.desc ?? ""
            isPublic = movieClub.isPublic
            image = "no-image"
            timeInterval = movieClub.timeInterval
            ownerId = movieClub.ownerId
        }
    }
    
    private func submit() async throws {
        guard let user = data.currentUser else {
            errorShowing = true
            errorMessage = "You must be logged in to update a club"
            return
        }
        guard !name.isEmpty else {
            errorShowing = true
            errorMessage = "Name cannot be empty"
            return
        }
        guard !description.isEmpty else {
            errorShowing = true
            errorMessage = "description cannot be empty"
            return
        }
        guard timeInterval != 0 else {
            errorShowing = true
            errorMessage = "Time Interval cannot be empty"
            return
        }
        
        let updatedClub = MovieClub(id: movieClub.id, name: name, desc: description, ownerName: user.name, timeInterval: timeInterval, ownerId: ownerId, isPublic: isPublic)
        do {
            try await data.updateMovieClub(movieClub: updatedClub)
        } catch {
            errorShowing = true
            errorMessage = "Error updating club: \(error)"
        }
    }
}
