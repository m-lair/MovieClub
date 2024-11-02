//
//  AnnouncementView.swift
//  MovieClub
//
//  Created by Marcus Lair on 10/29/24.
//

import SwiftUI

struct AnnouncementView: View {
    let announcement: Announcement
    @State var liked: Bool = false
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    CircularImageView(userId: announcement.userName, size: 30)
                    Text(announcement.userName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Circle()
                        .frame(width: 5, height: 5)
                        .opacity(0.5)
                    
                    Text(announcement.date, format: .dateTime.day().month())
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading) {
                    Text(announcement.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text(announcement.body)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                }
                .padding([.leading, .vertical], 10)
                
                HStack {
                    Button("reply") {
                        // do nothing yet
                    }
                    .padding(.leading)
                    
                    Spacer()
                    
                    Button {
                        liked.toggle()
                        
                    } label: {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(liked ? .red : .gray)
                        Text(announcement.likes, format: .number)
                    }
                    .padding(.trailing)
                }
                .padding(.bottom)
               
            }
            Spacer()
        }
        .padding(2)
    }
}
