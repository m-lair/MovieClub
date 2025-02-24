//
//  ClubTabView.swift
//  MovieClub
//
//  Created by Marcus Lair on 10/16/24.
//

import SwiftUI
import Foundation

struct ClubTabView: View {
    let tabs: [String]
    @State var width = UIScreen.main.bounds.size.width
    @Binding var selectedTabIndex: Int

    var body: some View {
        HStack {
            Spacer()
            ForEach(tabs.indices, id: \.self) { index in
                Button {
                    selectedTabIndex = index
                } label: {
                    Text(tabs[index])
                        .fontWeight(.semibold)
                        .foregroundColor(selectedTabIndex == index ? .white : .gray)
                        .lineLimit(1)
                        
                }
                .background(selectedTabIndex == index ? Color.clear : Color.clear)
                Spacer()
            }
        }
    }
}

