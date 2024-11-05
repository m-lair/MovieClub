//
//  BannerSelector.swift
//  MovieClub
//
//  Created by Marcus Lair on 10/12/24.
//
import SwiftUI
import Foundation
import PhotosUI

struct BannerSelector: View {
    @State var showPicker: Bool = false
    @Binding var banner: UIImage?
    @Binding var photoItem: PhotosPickerItem?
    @State private var screenWidth = UIScreen.main.bounds.size.width
    var body: some View {
        HStack{
            Button{
                showPicker = true
            } label: {
                if let banner {
                   Image(uiImage: banner)
                        .resizable()
                        .scaledToFill()
                        .padding(-20) /// expand the blur a bit to cover the edges
                        .clipped() /// prevent blur overflow
                        .frame(width: (screenWidth - 20), height:275)
                        .mask(LinearGradient(stops:
                                                [.init(color: .white, location: 0),
                                                 .init(color: .white, location: 0.85),
                                                 .init(color: .clear, location: 1.0),], startPoint: .top, endPoint: .bottom))
                }else{
                    Image(systemName: "house.fill")
                        .frame(width: (screenWidth - 20), height: 275)
                        .clipShape(.rect(cornerRadius: 25))
                        .shadow(radius: 8)
                }
            }
        }
        .onChange(of: photoItem) {
            Task {
                do {
                    if let data = try await photoItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        banner = image
                    } else {
                        print("Failed to load image")
                    }
                } catch {
                    print("Error loading image: \(error)")
                }
            }
        }
        .photosPicker(isPresented: $showPicker, selection: $photoItem)
    
    }
}
