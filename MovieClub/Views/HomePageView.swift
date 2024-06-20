//
//  HomePageView.swift
//  Movie Club
//
//  Created by Marcus Lair on 5/7/24.
//

import SwiftUI

struct HomePageView: View {
    
    @Environment(DataManager.self) var data: DataManager
    
    let userClubs: [MovieClub]
    var body: some View {
        let _ = print("in homepageview")
        VStack{
            if userClubs.count > 0{
                VStack{
                    MovieClubScrollView()
                }
            }else{
                
                Text("Nothing to see here!")
            }
        }
    }
}
    
#Preview {
    HomePageView(userClubs: MovieClub.TestData)
        .environment(DataManager())
}


