//
//  CreateClubView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/13/24.
//
//

import SwiftUI

struct NewClubView: View {
    @Environment(DataManager.self) private var data: DataManager
    
    var body: some View {
        
        
        CreateClubForm()
    }
    // thinking of using a plus button on the clubs view to bring up this page
    // after that the user should be presented with a search bar to search the name of the club
    // if the user wishes to create their own then lets make the top right of this search view a Create button
    // when button is clicked it will take the user to the form to create one from scratch
    
   
}

#Preview {
    NewClubView()
}

