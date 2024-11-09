//
//  WaveLoadingView.swift
//  MovieClub
//
//  Created by Marcus Lair on 11/9/24.
//
import SwiftUI

struct WaveLoadingView: View {
    @State private var animate = false

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<5) { index in
                Circle()
                    .fill(Color.white)
                    .frame(width: 10, height: 10)
                    .offset(y: self.animate ? -10 : 10)
                    .animation(
                        Animation
                            .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.1),
                        value: animate
                    )
            }
        }
        .onAppear {
            self.animate = true
        }
    }
}
