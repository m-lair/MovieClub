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
    
    @State private var apiMovie: APIMovie?
    @State private var searchText = ""
    @State private var searchBar = true
    @State private var sheetShowing = false
    @State private var banner: Image?
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
                    HStack{
                        Button{
                            showPicker = true
                        } label: {
                            if let banner {
                                banner
                                    .resizable()
                                    .scaledToFill()
                                    .padding(-20) /// expand the blur a bit to cover the edges
                                    .clipped() /// prevent blur overflow
                                    .frame(width: (screenWidth - 20), height:275)
                                    .mask(LinearGradient(stops:
                                                            [.init(color: .white, location: 0),
                                                             .init(color: .white, location: 0.85),
                                                             .init(color: .clear, location: 1.0),], startPoint: .top, endPoint: .bottom))
                            }else{
                                Image(systemName: "house.fill")
                                    .frame(width: (screenWidth - 20), height: 275)
                                    .clipShape(.rect(cornerRadius: 25))
                                    .shadow(radius: 8)
                            }
                        }
                    }
                    .onChange(of: photoItem) {
                        Task {
                            do {
                                if let loaded = try await photoItem?.loadTransferable(type: Image.self) {
                                    showPicker = false
                                    banner = loaded
                                    
                                } else {
                                    print("Failed")
                                }
                            }catch{
                                print("couldnt get photo \(error)")
                            }
                        }
                    }
                    .photosPicker(isPresented: $showPicker, selection: $photoItem)
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
                /*Section{
                    VStack(alignment: .center){
                        Button {
                            Task{
                                if let imageData = try await photoItem?.loadTransferable(type: Data.self) {
                                    let documentString = data.db.collection("movieclubs").document().documentID
                                    print(documentString)
                                    sheetShowing = true
                                    
                                }
                            }
                        } label: {
                            AsyncImage(url: URL(string: apiMovie?.poster ?? "")){ phase in
                                if let image = phase.image {
                                   // let _ = print("emptyView")
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        
                                        
                                } else {
                                   // let _ = print("emptyView")
                                    Text("Choose First Movie...")
                                }
                            }
                        }
                    }
                    .sheet(isPresented: $sheetShowing) {
                        AddMovieView() { movie in
                            apiMovie = movie
                        }
                    }
                }*/
                
                Button{
                    Task{
                        await submit()
                    }
                }label:{
                    Text("Create Club")
                }
            }
        }
    }
    
    @MainActor
    private func submit() async {
        do{
            /*if let image = try await photoItem?.loadTransferable(type: Data.self) {
             
             let documentString = data.db.collection("movieclubs").document().documentID
             if let imageData = UIImage(data: image) {
             
             // will need to rewrite for cloud function
             let urlString = try await data.uploadClubImage(image: imageData, clubId: documentString)
             */
            guard
                let user = data.currentUser,
                let userId = user.id
            else {
                
                return
            }
            
            let movieClub =
            MovieClub(name: name,
                      numMembers: 1,
                      desc: desc,
                      ownerName: user.name,
                      timeInterval: timeInterval,
                      ownerId: userId,
                      isPublic: isPublic,
                      bannerUrl: "",
                      numMovies: 1)
            
            /*let movie =
             Movie(created: created,
             title: apiMovie?.title ?? "",
             poster: apiMovie?.poster ?? "",
             endDate: endDate,
             userName: user.name,
             userId: userId,
             authorAvi: user.image ?? "")*/
            
            try await data.createMovieClub(movieClub: movieClub)
            navPath.removeLast(navPath.count)
            
        }catch{
            print("error submitting club \(error)")
        }
    }
    
}

