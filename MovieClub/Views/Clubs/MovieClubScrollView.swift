//
//  MovieClubScrollView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/13/24.
//

import SwiftUI

struct MovieClubScrollView: View {
    @Environment(DataManager.self) var data: DataManager
    var body: some View {
        NavigationStack{
            ScrollView(.vertical) {
                ScrollViewContent()
                
            }
        }
    }
}



#Preview {
    MovieClubScrollView()
        .environment(DataManager())
}
