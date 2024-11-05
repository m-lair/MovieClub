//
//  ComingSoonRowView.swift
//  MovieClub
//
//  Created by Marcus Lair on 8/16/24.
//

import SwiftUI

struct ComingSoonRowView: View {
    @Environment(DataManager.self) private var data
    @State var suggestion: Suggestion
    @State var imageUrl: String? = ""
    var body: some View {
        let _ = print("in row view")
        HStack{
            CircularImageView(size: 30)
            Text(suggestion.userName)
                .font(.headline)
                .foregroundColor(.primary)
            Spacer()
        }
    }
}
