//
//  MovieClubTabsView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/28/24.
//

import SwiftUI


struct SwipeableView<Content: View>: View {
    let content: Content
    let numberOfPages: Int
    @GestureState private var offset: CGFloat = 0
    @State private var currentPage: Int = 0
    @State private var position: CGFloat = 0

    init(numberOfPages: Int, @ViewBuilder content: () -> Content) {
        self.numberOfPages = numberOfPages
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                content
                    .frame(width: geometry.size.width)
            }
            .frame(width: geometry.size.width, alignment: .leading)
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
                            newIndex = min(currentPage + 1, numberOfPages - 1)
                        } else if value.predictedEndTranslation.width > threshold {
                            newIndex = max(currentPage - 1, 0)
                        }
                        
                        currentPage = newIndex
                        withAnimation {
                            position = -CGFloat(currentPage) * geometry.size.width
                        }
                    }
            )
            .onChange(of: currentPage) {
                position = -CGFloat(currentPage) * geometry.size.width
            }
        }
    }
}
