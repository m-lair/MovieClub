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
    @State private var desc = ""
    @State private var showPicker = false
    @State private var owners = ["User1"]
    @State private var screenWidth = UIScreen.main.bounds.size.width
    var body: some View {
        NavigationStack{
            Form {
                Section(header: Text("Movie Club Info")){
                    VStack(alignment: .leading){
                        HStack{
                            Button {
                                showPicker.toggle()
                            } label: {
                                if let banner {
                                    banner
                                        .resizable()
                                        .scaledToFill()
                                        .padding(-20) /// expand the blur a bit to cover the edges
                                        .clipped() /// prevent blur overflow
                                        .frame(maxWidth: (screenWidth - 20))
                                        .blur(radius: 1.5, opaque: true)
                                    .mask(LinearGradient(stops:
                                     [.init(color: .white, location: 0),
                                     .init(color: .white, location: 0.85),
                                     .init(color: .clear, location: 1.0),], startPoint: .top, endPoint: .bottom))
                                }else{
                                    Image(systemName: "popcorn.circle")
                                        .resizable()
                                        .frame(width: 60, height: 60)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                        .shadow(radius: 10)
                                    
                                }
                            }
                            .onChange(of: banner) {
                                Task {
                                    if let loaded = try? await photoItem?.loadTransferable(type: Image.self) {
                                        banner = loaded
                                    } else {
                                        print("Failed")
                                    }
                                }
                            }
                            VStack(alignment: .leading) {
                                TextField("Name", text: $name)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .padding()
                                
                                TextField("Description", text: $desc)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .photosPicker(isPresented: $showPicker, selection: $photoItem)
                        Spacer()
                    }
                }
                Section(header: Text("Movie Club Settings")){
                    Toggle("Public Club", isOn: $isPublic)
                }
            }
            .toolbar{
                ToolbarItem(placement: .confirmationAction) {
                    Button{
                        Task{
                            // Call a method to save the club with the entered information
                            if let imageData = try await photoItem?.loadTransferable(type: Data.self) {
                                let documentString = data.db.collection("movieclubs").document().documentID
                                print(documentString)
                                let urlString = await data.uploadClubImage(image: UIImage(data: imageData)!, clubId: documentString)
                                
                                let movieClub = MovieClub(id: documentString, name: name,
                                                          created: Date(), numMembers: 1, description: desc,
                                                          ownerName: data.currentUser?.name ?? "",
                                                          ownerID: data.currentUser?.id ?? "",
                                                          isPublic: isPublic,
                                                          banner: urlString)
                                await saveClub(movieClub: movieClub)
                            }
                            dismiss()
                        }
                    }label: {
                        Text("Save")
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        
    }
    private func saveClub(movieClub: MovieClub) async {
        Task{
            await data.createMovieClub(movieClub: movieClub)
        }
        
        
    }
    private func generateUUID() -> String {
        let id = UUID()
        return id.uuidString
    }
}
    

#Preview {
    EditEmptyView()
}
