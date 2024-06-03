//
//  TabViewItem.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/28/24.
//

import SwiftUI

struct TabViewItem: View {
    var label: String

    var body: some View {
        Text(label)
            .font(.headline)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
}

#Preview {
    TabViewItem(label: "label")
}
