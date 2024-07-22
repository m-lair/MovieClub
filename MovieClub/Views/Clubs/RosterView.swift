//
//  RosterView.swift
//  MovieClub
//
//  Created by Marcus Lair on 7/20/24.
//

import SwiftUI
import FirebaseFirestore

struct RosterView: View {
    @Environment(DataManager.self) var data: DataManager
    @State var rosterUsers: [User] = []
    let currentEndDate: Date
    var body: some View {
        LazyVStack {
            ForEach(rosterUsers) { user in
                let _ = print("3: \(rosterUsers)")
                HStack{
                    Text("name \(user.name)")
                    Text("Date \(currentEndDate.formatted(date: .numeric, time: .omitted))")
                }
            }
        }
        .onAppear() {
            Task{
                await getUserData()
            }
        }
    }
    
    func getUserData() async {
        let db = Firestore.firestore()
        do {
            if let ids = await data.currentClub?.roster {
                print("1: \(ids)")
                for id in ids {
                    let snapshot = try await db.collection("users").document(id).getDocument()
                    var userList: [User] = []
                    if let user = try? snapshot.data(as: User.self) {
                        print("2: \(user)")
                        userList.append(user)
                        
                    }
                    self.rosterUsers = userList
                }
            }
        } catch {
            print("couldnt get roster")
        }
    }
}


