//
//  MovieClubCardView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/13/24.
//
import UIKit
import SwiftUI

struct MovieClubCardView: View {
    let movieClub: MovieClub
    @State private var bannerColor: Color = .clear
    @State private var hasAppeared = false
    @State private var currentFeaturedMovieId: String? = nil
    
    var featuredMovie: Movie? {
        movieClub.movies.first
    }
    
    // Download the image and update the banner color
    func updateBannerColor(with url: URL) {
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let uiImage = UIImage(data: data),
                  let dominantUIColor = dominantColor(from: uiImage) else { return }
            DispatchQueue.main.async {
                bannerColor = Color(dominantUIColor)
            }
        }.resume()
    }

    var body: some View {
        GeometryReader { geometry in
            let cardWidth = geometry.size.width * 0.9
            let cardHeight = cardWidth * 0.6

            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black)
                    .frame(width: cardWidth, height: cardHeight)
                    .shadow(color: .white.opacity(0.4), radius: 5, x: 0, y: 0)

                VStack {
                    ZStack {
                        if let movie = featuredMovie,
                           let verticalBackdrop = movie.apiData?.backdropHorizontal,
                           let backdropUrl = URL(string: verticalBackdrop) {
                            
                            CachedAsyncImage(url: backdropUrl, placeholder: {
                                // Placeholder view (e.g. black or a spinner)
                                Color.black
                            })
                            .id("\(movieClub.id ?? "")-\(movie.id ?? "")-backdrop") // Unique ID for proper refresh
                            .scaledToFill()
                            .frame(width: cardWidth - 20, height: cardHeight * 0.6)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .opacity(0.8)
                            .onAppear {
                                updateBannerColor(with: backdropUrl)
                                // Track the current featured movie ID
                                if currentFeaturedMovieId != movie.id {
                                    currentFeaturedMovieId = movie.id
                                }
                            }

                            VStack(alignment: .leading) {
                                Spacer()
                                Text(movieClub.name)
                                    .shadow(color: .black, radius: 2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 5)

                                // Use the computed dominant color for the banner
                                Rectangle()
                                    .fill(bannerColor)
                                    .frame(width: cardWidth - 20, height: cardHeight * 0.15)
                                    .overlay(
                                        Text("Now Showing: \(movie.title) (\(movie.yearFormatted))")
                                            .foregroundColor(.white)
                                            .font(.caption)
                                            .padding(.leading)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    )
                            }
                            .padding(.horizontal,5 )
                        } else {
                            VStack(alignment: .leading) {
                                Spacer()
                                HStack {
                                    Text(movieClub.name)
                                        .font(Font.custom("Stolzl", size: 24, relativeTo: .headline))
                                        .shadow(color: .black, radius: 2)
                                        .fontWeight(.bold)
                                        .padding(.horizontal)
                                    Spacer()
                                }
                            }
                        }
                    }

                    Spacer()

                    HStack {
                        VStack {
                            Text("Members")
                                .font(.caption)
                            Text("\(movieClub.numMembers ?? 0)")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        Spacer()
                        VStack {
                            Text("Movies")
                                .font(.caption)
                            Text("\(movieClub.numMovies ?? 0)")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        Spacer()
                        VStack {
                            Text("Queue")
                                .font(.caption)
                            Text("\(movieClub.suggestions?.count ?? 0)")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                    }
                    .padding(.horizontal)
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                }
                .frame(width: cardWidth, height: cardHeight)
            }
            .frame(width: geometry.size.width, height: cardHeight)
            .id("card-\(movieClub.id ?? "")-\(movieClub.numMovies ?? 0)-\(featuredMovie?.id ?? "none")")
        }
        .frame(height: UIScreen.main.bounds.width * 0.9 * 0.6)
        .onAppear {
            hasAppeared = true
        }
        .onChange(of: featuredMovie?.id) { oldValue, newValue in
            if oldValue != newValue {
                // Reset banner color when featured movie changes
                bannerColor = .clear
                currentFeaturedMovieId = newValue
            }
        }
    }
}

 
func dominantColor(from image: UIImage) -> UIColor? {
    guard let inputImage = CIImage(image: image) else { return nil }
    let extent = inputImage.extent
    let parameters = [kCIInputImageKey: inputImage,
                      kCIInputExtentKey: CIVector(cgRect: extent)] as [String: Any]
    guard let filter = CIFilter(name: "CIAreaAverage", parameters: parameters),
          let outputImage = filter.outputImage else { return nil }
    
    var bitmap = [UInt8](repeating: 0, count: 4)
    let context = CIContext(options: [.workingColorSpace: kCFNull])
    context.render(outputImage,
                   toBitmap: &bitmap,
                   rowBytes: 4,
                   bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                   format: .RGBA8,
                   colorSpace: CGColorSpaceCreateDeviceRGB())
    
    return UIColor(red: CGFloat(bitmap[0]) / 255.0,
                   green: CGFloat(bitmap[1]) / 255.0,
                   blue: CGFloat(bitmap[2]) / 255.0,
                   alpha: CGFloat(bitmap[3]) / 255.0)
}
