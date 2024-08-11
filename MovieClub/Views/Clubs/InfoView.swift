//
//  InfoView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/28/24.
//

import SwiftUI

struct InfoView: View {
    var imageName: String
    var count: Int
    var label: String

    var body: some View {
        HStack {
            Image(systemName: imageName)
            Text("\(count) \(label)")
        }
        .padding(8)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(8)
    }
}

#Preview {
    InfoView(imageName: "imageName", count: 0, label: "label")
}
