//
//  MovieClubTabsView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/28/24.
//

import SwiftUI

struct MovieClubTabView: View {
    var body: some View {
        HStack {
            TabViewItem(label: "Archives")
            TabViewItem(label: "Now Playing")
            TabViewItem(label: "Upcoming")
        }
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(8)
    }
}

#Preview {
    MovieClubTabView()
}
