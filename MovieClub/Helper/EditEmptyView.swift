//
//  EditEmptyView.swift
//  MovieClub
//
//  Created by Marcus Lair on 6/24/24.
//

import SwiftUI
import PhotosUI
import FirebaseFirestore

struct EditEmptyView: View {
    @Environment(DataManager.self) var data: DataManager
    @Environment(\.dismiss) private var dismiss
    @State private var banner: Image?
    @State private var photoItem: PhotosPickerItem?
    @State private var name = ""
    @State private var isPublic = false // Default to private
    @State private var selectedOwnerIndex = 0
    @State private var timeInterval: Int = 2
    @State private var movie: Movie?
    var created = Date()
    private var endDate: Date? {
        if let date = Calendar.current.date(byAdding: .weekOfYear, value: timeInterval, to: created) {
            return date
        }
        return nil
    }
    let weeks: [Int] = [1,2,3,4]
    @State private var desc = ""
    @State private var showPicker = false
    @State private var owners = ["User1"]
    @State private var screenWidth = UIScreen.main.bounds.size.width
    @State private var next: Bool = false
    var body: some View {
        VStack{
            Form {
                Section {
                    VStack(alignment: .leading){
                        HStack{
                            VStack(alignment: .leading) {
                                TextField("Name", text: $name)
                                    .font(.title)
                                    .fontWeight(.bold)
                                
                                TextField("Description", text: $desc)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("General Info")
                }
                Section {
                    HStack{
                        Button {
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
                    Picker("Week Interval", selection: $timeInterval) {
                        //ForEach(weeks, id: \.self) { option in
                        //    Text("\(option)").tag(option)
                        //}
                    }
                } header: {
                    Text("Club Settings")
                }
                
                FirstMovieView()
            }
            
                Spacer()
                Button{
                    Task{
                        print("in task")
                        if let imageData = try await photoItem?.loadTransferable(type: Data.self) {
                            let documentString = data.db.collection("movieclubs").document().documentID
                            print(documentString)
                            if let endDate{
                                let movieClub =
                                MovieClub(id: documentString, name: name,
                                          created: created, numMembers: 1,
                                          description: desc,
                                          ownerName: data.currentUser?.name ?? "",
                                          timeInterval: timeInterval,
                                          movieEndDate: endDate,
                                          ownerID: data.currentUser?.id ?? "",
                                          isPublic: isPublic,
                                          banner: imageData)
                                data.currentClub = movieClub
                                next = true
                            }
                        }
                    }
                }label:{
                    Text("Next")
                        .padding()
                        .background(Color(red: 0, green: 0, blue: 0.5))
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            
        }
    }
}


    



