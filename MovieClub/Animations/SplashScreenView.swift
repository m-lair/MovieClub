import SwiftUI
import Lottie

struct SplashScreenView: View {
    @State private var isAnimationFinished = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                LottieView(animation: .named("SplashAnimation"))
                    .playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce)))
                    .frame(width: 250, height: 250)
            }
        }
        .onAppear{
            withAnimation(.easeInOut(duration: 0.75)) {
            }
        }
    }
}
