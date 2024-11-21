//
//  WaveLoadingView.swift
//  MovieClub
//
//  Created by Marcus Lair on 11/9/24.
//
import SwiftUI

struct WaveLoadingView: View {
    private let circleCount = 5
    private let circleSize: CGFloat = 10
    private let offsetAmount: CGFloat = 10
    private let animationDuration: Double = 0.6
    private let animationDelay: Double = 0.1

    @State private var animate = false
    @State private var timer: Timer?

    var body: some View {
        HStack(spacing: circleSize / 2) {
            ForEach(0..<circleCount, id: \.self) { index in
                Circle()
                    .fill(Color.white)
                    .frame(width: circleSize, height: circleSize)
                    .offset(y: animate ? -offsetAmount : offsetAmount)
                    .animation(
                        waveAnimation
                            .delay(Double(index) * animationDelay),
                        value: animate
                    )
            }
        }
        .frame(height: circleSize + (offsetAmount * 2))
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
    }

    private var waveAnimation: Animation {
        Animation
            .easeInOut(duration: animationDuration)
            .repeatCount(1, autoreverses: true)
    }

    private func startAnimation() {
        animate = true
        timer = Timer.scheduledTimer(withTimeInterval: animationDuration * 2, repeats: true) { _ in
            animate.toggle()
        }
    }

    private func stopAnimation() {
        timer?.invalidate()
        timer = nil
        animate = false
    }
}
