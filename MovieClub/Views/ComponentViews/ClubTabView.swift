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
            ForEach(tabs.indices, id: \.self) { index in
                Button {
                    selectedTabIndex = index
                } label: {
                    Text(tabs[index])
                        .fontWeight(.semibold)
                        .foregroundColor(selectedTabIndex == index ? .white : .gray)
                        
                }
                .padding(.horizontal, 10)
                .background(selectedTabIndex == index ? Color.clear : Color.clear)
            }
        }
    }
}

