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
    var created = Date()
    private var endDate: Date {
        return Calendar.current.date(byAdding: .weekOfYear, value: timeInterval, to: created) ?? Date()
    }
    let weeks: [Int] = [1,2,3,4]
    @State private var desc = ""
    @State private var showPicker = false
    var body: some View {
        VStack{
            Form {
                Section {
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
                }header: {
                    Text("General Info")
                }
                Section{
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
                } header: {
                    Text("Club Banner")
                }
                .listRowInsets(EdgeInsets())
                Section {
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
                } header: {
                    Text("Club Settings")
                }
                Section {
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
                                        .frame(width: 200, height: 300)
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
                }
                Button{
                    Task{
                        await submit()
                        navPath.removeLast(navPath.count)
                    }
                }label:{
                    Text("Next")
                }
            }
        }
    }
    @MainActor
    private func submit() async {
        do{
            if let image = try await photoItem?.loadTransferable(type: Data.self) {
                let documentString = data.db.collection("movieclubs").document().documentID
                if let imageData = UIImage(data: image) {
                    print(documentString)
                    let urlString =  await data.uploadClubImage(image: imageData, clubId: documentString)
                    var movieClub =
                    MovieClub(id: documentString, name: name,
                              created: created, numMembers: 1,
                              description: desc,
                              ownerName: data.currentUser?.name ?? "",
                              timeInterval: timeInterval,
                              movieEndDate: endDate,
                              ownerID: data.currentUser?.id ?? "",
                              isPublic: isPublic, bannerUrl: urlString)
                    
                    let movie = Movie(title: apiMovie?.title ?? "", poster: apiMovie?.poster ?? "", endDate: endDate, author: data.currentUser?.name ?? "", authorID: data.currentUser?.id ?? "", authorAvi: data.currentUser?.image ?? "")
                        print("MovieClub \(movieClub)")
                        data.currentClub = movieClub
                    await data.createMovieClub(movieClub: movieClub, movie: movie)
                    
                }
            }
        }catch{
            print("error submitting club \(error)")
        }
    }
    
}

