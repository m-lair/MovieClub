import SwiftUI

struct WhatsNewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(VersionManager.self) private var versionManager
    
    @State private var featureItems: [FeatureItem] = [
        FeatureItem(
            icon: "person.2.fill",
            title: "Enhanced Movie Clubs",
            description: "Improved club experience with better movie recommendations and social features."
        ),
        FeatureItem(
            icon: "heart.fill",
            title: "Favorites List",
            description: "Save your favorite movies to watch later or recommend to friends."
        ),
        FeatureItem(
            icon: "bolt.fill",
            title: "Performance Boost",
            description: "Faster loading times and smoother animations throughout the app."
        )
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("What's New")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 32)
                
                Text("Version \(versionManager.currentVersion)")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                ScrollView {
                    VStack(spacing: 24) {
                        ForEach(featureItems) { item in
                            FeatureRow(feature: item)
                        }
                    }
                    .padding()
                }
                
                Button(action: {
                    versionManager.markCurrentVersionAsSeen()
                    versionManager.showWhatsNew = false
                    dismiss()
                }) {
                    Text("Got it!")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                }
                .padding(.bottom, 32)
                .padding(.horizontal)
            }
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding()
        }
    }
}

struct FeatureItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}

struct FeatureRow: View {
    let feature: FeatureItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: feature.icon)
                .font(.system(size: 28))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                )
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(feature.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(feature.description)
                    .font(.body)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal)
    }
}

#Preview {
    WhatsNewView()
        .environment(VersionManager())
} 