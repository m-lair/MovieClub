//
//  ProfileHeaderView.swift
//  MovieClub
//
//  Created by Marcus Lair on 6/24/24.
//

import SwiftUI

struct ProfileHeaderView: View {
    let user: User
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "person.crop.circle.fill") // Placeholder image
                    .resizable()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                    .shadow(radius: 10)
                
                VStack(alignment: .leading) {
                    Text(user.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(user.bio ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
        }
    }
   
}


#Preview {
    ProfileHeaderView(user: User(email: "", bio: "", name: "", password: ""))
}
