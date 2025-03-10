import SwiftUI

struct WhatsNewView: View {
    @Environment(VersionManager.self) private var versionManager
    @Binding var isPresented: Bool
    
    // New features for the current version
    private var currentVersionFeatures: [WhatsNewFeature] {
        // Updated for each new version
        if versionManager.isRunningVersion("0.2.12") {
            return [
                WhatsNewFeature(
                    title: "Poster Scores",
                    description: "Collected posters now get rated based on club feedback",
                    icon: "10.square.fill"
                ),
                WhatsNewFeature(
                    title: "Profile Avatars",
                    description: "Select your first avatar in the profile menu",
                    icon: "person.crop.circle.fill"
                ),
                WhatsNewFeature(
                    title: "Join us on Discord",
                    description: "Connect with the community and share your feedback",
                    icon: "bubble.left.and.bubble.right.fill",
                    url: URL(string: "https://discord.gg/Vvtdcbsd47")
                ),
                WhatsNewFeature(
                    title: "UI Refinements",
                    description: "Updated visuals throughout the app",
                    icon: "sparkles"
                )
            ]
        } else {
            // Default features if version-specific ones aren't available
            return [
                WhatsNewFeature(
                    title: "New Features",
                    description: "We've added some great new features to enhance your experience",
                    icon: "star.fill"
                ),
                WhatsNewFeature(
                    title: "Bug Fixes",
                    description: "We've fixed some bugs to make the app more stable",
                    icon: "checkmark.circle.fill"
                )
            ]
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("What's New")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Version \(versionManager.currentVersion)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 20)
            
            // Features list
            VStack(spacing: 16) {
                ForEach(currentVersionFeatures) { feature in
                    FeatureRow(feature: feature)
                }
            }
            .padding(.vertical)
            
            Spacer()
            
            // Acknowledgment button
            Button(action: {
                versionManager.markCurrentVersionAsSeen()
                isPresented = false
            }) {
                Text("Continue")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 24)
        .background(Color.black)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Feature data model
struct WhatsNewFeature: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let url: URL? // Optional URL for linking to external resources
    
    // Initializer with optional URL parameter
    init(title: String, description: String, icon: String, url: URL? = nil) {
        self.title = title
        self.description = description
        self.icon = icon
        self.url = url
    }
}

// Individual feature row
private struct FeatureRow: View {
    let feature: WhatsNewFeature
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: feature.icon)
                .font(.title)
                .foregroundStyle(.blue.opacity(0.8))
                .frame(width: 36, height: 36)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.headline)
                
                Text(feature.description)
                    .font(.subheadline)
                    .foregroundStyle(.gray.gradient)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Show link button if URL is provided
                if let url = feature.url {
                    Link(destination: url) {
                        HStack(spacing: 4) {
                            Text("Learn more")
                                .font(.footnote.bold())
                            
                            Image(systemName: "arrow.up.right")
                                .font(.footnote)
                        }
                        .foregroundStyle(.blue)
                        .padding(.top, 4)
                    }
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// Preview
#Preview {
    @State var isPresented = true
    
    return WhatsNewView(isPresented: $isPresented)
        .environment(VersionManager())
} 
