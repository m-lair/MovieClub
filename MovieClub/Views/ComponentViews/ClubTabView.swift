//
//  ClubTabView.swift
//  MovieClub
//
//  Created by Marcus Lair on 10/16/24.
//

import SwiftUI
import Foundation

struct ClubTabView: View {
    let tabs = ["Bullentin", "Now Showing", "Upcoming", "Archives"]
    @State var selectedTab: String = "Now Showing"
    var body: some View {
        Picker("Select a Club", selection: $selectedTab) {
            ForEach(tabs, id: \.self) { tab in
                Text(tab)
                    .fontWeight(.semibold)
            }
        }
        .pickerStyle(.segmented)
    }
}

#Preview {
    ClubTabView()
}
