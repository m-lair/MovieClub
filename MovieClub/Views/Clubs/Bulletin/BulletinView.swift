//
//  Bulletin.swift
//  MovieClub
//
//  Created by Marcus Lair on 10/29/24.
//

import SwiftUI

struct BulletinView: View {
    let announcements: [Announcement] = [
        Announcement(id: UUID(), title: "New Movie Release", body: "The latest movie release is out!", date: Date(), likes: 5, userName: "Duhmarcus"),
        Announcement(id: UUID(), title: "New Movie Release", body: "The latest movie release is out!", date: Date(), likes: 5, userName: "Duhmarcus"),
        Announcement(id: UUID(), title: "New Movie Release", body: "The latest movie release is out!", date: Date(), likes: 5, userName: "Duhmarcus")
    ]
    var body: some View {
        VStack{
            ScrollView {
                ForEach(announcements){ announcement in
                    AnnouncementView(announcement: announcement)
                    Divider()
                }
            }
        }
    }
}
