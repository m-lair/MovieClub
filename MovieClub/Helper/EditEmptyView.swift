//
//  EditEmptyView.swift
//  MovieClub
//
//  Created by Marcus Lair on 6/24/24.
//

import SwiftUI
import PhotosUI

struct EditEmptyView: View {
    @Environment(DataManager.self) var data: DataManager
    @Environment(\.dismiss) private var dismiss
    @State private var aviImage: Image?
    @State private var aviImageItem: PhotosPickerItem?
    @State private var name = ""
    @State private var isPublic = false // Default to private
    @State private var selectedOwnerIndex = 0
    @State private var desc = ""
    @State private var showPicker = false
    @State private var owners = ["User1"]
    var body: some View {
        NavigationStack{
            Form {
                Section(header: Text("Movie Club Info")){
                    VStack(alignment: .leading){
                        HStack{
                            Button {
                                showPicker.toggle()
                            } label: {
                                if let aviImage = aviImage{
                                    aviImage
                                        .resizable()
                                        .frame(width: 60, height: 60)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                        .shadow(radius: 10)
                                }else{
                                    Image(systemName: "popcorn.circle")
                                        .resizable()
                                        .frame(width: 60, height: 60)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                        .shadow(radius: 10)
                                    
                                }
                            }
                            .onChange(of: aviImageItem) {
                                Task {
                                    if let loaded = try? await aviImageItem?.loadTransferable(type: Image.self) {
                                        aviImage = loaded
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
                        
                        .photosPicker(isPresented: $showPicker, selection: $aviImageItem)
                        Spacer()
                    }
                }
                Section(header: Text("Movie Club Settings")){
                }
            }
            .toolbar{
                ToolbarItem(placement: .confirmationAction) {
                    Button{
                        Task{
                            // Call a method to save the club with the entered information
                            
                            let movieClub = MovieClub(id: generateUUID(), name: name,
                                                      created: Date(), numMembers: 1, description: "",
                                                      ownerName: data.currentUser?.name ?? "",
                                                      ownerID: data.currentUser?.id ?? "",
                                                      isPublic: isPublic)
                            await saveClub(movieClub: movieClub)
                            dismiss()
                        }
                    }label: {
                        Text("Save")
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
