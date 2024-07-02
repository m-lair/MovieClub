//
//  CreateClubForm.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/14/24.
//

import SwiftUI
import PhotosUI

struct CreateClubForm: View {
    @Environment(DataManager.self) var data: DataManager
    var body: some View {
        EditEmptyView()
        
    }
}
    
    


#Preview {
    CreateClubForm()
        .environment(DataManager())
}
