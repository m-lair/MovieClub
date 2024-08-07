//
//  MovieClubTabsView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/28/24.
//

import SwiftUI


struct SwipeableView: View {
    let contents: [AnyView]
    @GestureState private var offset: CGFloat = 0
    @State private var currentPage: Int = 0
    @State private var position: CGFloat = 0

    init(contents: [AnyView]) {
        self.contents = contents
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 4) {
                ForEach(0..<contents.count, id: \.self) { index in
                    contents[index]
                        .frame(width: geometry.size.width - 2)
                }
            }
            .frame(width: geometry.size.width * CGFloat(contents.count), alignment: .leading)
            .offset(x: -CGFloat(currentPage) * geometry.size.width + offset)
            .gesture(
                DragGesture()
                    .updating(self.$offset) { value, state, _ in
                        state = value.translation.width
                    }
                    .onEnded { value in
                        let threshold = geometry.size.width / 2
                        var newIndex = currentPage
                        
                        if value.predictedEndTranslation.width < -threshold {
                            newIndex = min(currentPage + 1, contents.count - 1)
                        } else if value.predictedEndTranslation.width > threshold {
                            newIndex = max(currentPage - 1, 0)
                        }
                        
                        currentPage = newIndex
                        withAnimation(.interactiveSpring(response: 0.7, dampingFraction: 0.7, blendDuration: 0.7)){
                            position = -CGFloat(currentPage) * geometry.size.width
                        }
                    }
            )
        }
    }
}
