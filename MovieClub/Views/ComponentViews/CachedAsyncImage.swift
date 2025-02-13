//
//  CachedAsyncImage.swift
//  MovieClub
//
//  Created by Marcus Lair on 2/10/25.
//


import SwiftUI
struct CachedAsyncImage<Placeholder: View>: View {
    @Environment(DataManager.self) private var dataManager
    
    let url: URL?
    // You can pass in a placeholder view for loading/failure states
    let placeholder: () -> Placeholder
    
    @State private var loadedImage: UIImage?
    @State private var loadError: Error?
    @State private var isLoading: Bool = false
    
    var body: some View {
        Group {
            if let image = loadedImage {
                // Successful image load
                Image(uiImage: image)
                    .resizable()
            } else if isLoading {
                // While loading, show placeholder
                placeholder()
            } else if loadError != nil {
                // Failed to load, show placeholder or error view
                placeholder()
            } else {
                // Nothing has started yet
                placeholder()
            }
        }
        .onAppear {
            loadIfNeeded()
        }
    }
    
    private func loadIfNeeded() {
        guard let url = url, loadedImage == nil && loadError == nil && !isLoading else {
            return
        }
        
        isLoading = true
        Task {
            do {
                let image = try await dataManager.loadImage(from: url)
                loadedImage = image
            } catch {
                loadError = error
            }
            isLoading = false
        }
    }
    
}
