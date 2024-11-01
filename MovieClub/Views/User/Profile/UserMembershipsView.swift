//
//  UserMembershipsView.swift
//  MovieClub
//
//  Created by Marcus Lair on 8/13/24.
//

import SwiftUI

struct UserMembershipsView: View {
    @Environment(DataManager.self) private var data
    private let flexibleColumn = [
        
        GridItem(.flexible(minimum: 100, maximum: 200)),
        GridItem(.flexible(minimum: 100, maximum: 200)),
        GridItem(.flexible(minimum: 100, maximum: 200))
    ]
    var body: some View {
        ScrollView {
            LazyVGrid(columns: flexibleColumn, spacing: 10) {
                ForEach(data.userClubs) { club in
                    Text(club.name)
                        .frame(width: 100, height: 100, alignment: .center)
                        .background(.gray)
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .font(.title)
                    
                }
            }
        }
    }
}


