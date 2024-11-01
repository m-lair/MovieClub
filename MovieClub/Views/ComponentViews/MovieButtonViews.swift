//
//  MovieButtonViews.swift
//  MovieClub
//
//  Created by Marcus Lair on 10/27/24.
//

import SwiftUI

struct CollectButton: View {
    @Binding var collected: Bool
    var body: some View {
        ZStack(alignment: .center) {
            Rectangle()
                .frame(width: 85, height: 30)
                .clipShape(.capsule)
                .foregroundStyle(collected ? .yellow : .white)
            Text("Collect")
                .fontWeight(.bold)
                .foregroundStyle(.black)
        }
    }
}
