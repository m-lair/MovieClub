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
    var body: some View {
        VStack{
            ClubDetailsForm()
            Spacer()
            Button{
                Task{
                    print("in task")
                    if let imageData = try await photoItem?.loadTransferable(type: Data.self) {
                        let documentString = data.db.collection("movieclubs").document().documentID
                        print(documentString)
                        if let endDate {
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




    



