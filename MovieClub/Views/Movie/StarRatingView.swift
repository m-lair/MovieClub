//
//  SwiftUIView.swift
//  Movie Club
//
//  Created by Marcus Lair on 5/10/24.
//

import SwiftUI


struct StarRatingView: View {
    @Binding var rating: Double
    let maximumRating: Int = 5

    var body: some View {
        HStack {
            ForEach(0..<maximumRating) { index in
                Image(systemName: self.starImageName(for: index))
                    .foregroundColor(self.starColor(for: index))
                    .onTapGesture {
                        self.rating = Double(index) + 0.5
                    }
            }
        }
    }

    func starImageName(for index: Int) -> String {
        if Double(index) + 0.5 <= rating {
            return "star.fill"
        } else if Double(index) <= rating {
            return "star.leadinghalf.fill"
        } else {
            return "star"
        }
    }

    func starColor(for index: Int) -> Color {
        if Double(index) + 0.5 <= rating {
            return .yellow
        } else if Double(index) <= rating {
            return .yellow
        } else {
            return .gray
        }
    }
}
