import SwiftUI
import Observation

struct MovieClubCardView: View {
    var movieClub: MovieClub
    @State private var screenWidth = UIScreen.main.bounds.size.width

    var body: some View {
        ZStack {
            VStack {
                AsyncImage(url: URL(string: "")) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .padding(-20) // expand the blur a bit to cover the edges
                            .clipped() // prevent blur overflow
                            .frame(maxWidth: (screenWidth - 20))
                            .blur(radius: 1.5, opaque: true)
                            .mask(LinearGradient(stops: [
                                .init(color: .white, location: 0),
                                .init(color: .white, location: 0.85),
                                .init(color: .clear, location: 1.0)
                            ], startPoint: .top, endPoint: .bottom))
                    } else {
                        Image(systemName: "house.fill")
                            .resizable()
                            .scaledToFit()
                            .padding(-20) // expand the blur a bit to cover the edges
                            .clipped() // prevent blur overflow
                            .frame(maxWidth: (screenWidth - 20))
                            .opacity(0.5)
                    }
                }
            }
            .frame(width: (screenWidth - 20), height: 185)
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(.white, lineWidth: 2)
            )
            .shadow(radius: 8)

            VStack(alignment: .leading) {
                if !movieClub.name.isEmpty {
                    Text(movieClub.name)
                        .font(.title)
                    Text("Movie: \(movieClub.numMovies ?? 0)")
                    Text("Members: \(movieClub.numMembers ?? 0)")
                    // You can add more information about the movie club here
                }
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: (screenWidth - 20), maxHeight: 185, alignment: .bottomLeading)
        }
    }
}
