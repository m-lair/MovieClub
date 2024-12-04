//
//  MovieButtonViews.swift
//  MovieClub
//
//  Created by Marcus Lair on 10/27/24.
//

import SwiftUI

struct CollectButton: View {
    @Binding var collected: Bool
    var body: some View {
        ZStack(alignment: .center) {
            Rectangle()
                .frame(width: 85, height: 30)
                .clipShape(.capsule)
                .foregroundStyle(collected ? .yellow : .white)
            Text("Collect")
                .fontWeight(.bold)
                .foregroundStyle(.black)
        }
    }
}

struct ThumbsUpButton: View {
    @Binding var liked: Bool
    var body: some View {
        
        Button {
            liked.toggle()
            
        } label: {
            Image(systemName: "hand.thumbsup.circle.fill")
                .resizable()
                .frame(width: 30, height: 30)
                .foregroundStyle(liked ? .green : .white)
        }
    }
    
}


struct ThumbsDownButton: View {
    @Binding var disliked: Bool
    var body: some View {
        
        
        Button {
            disliked.toggle()
            
        } label: {
            Image(systemName: "hand.thumbsdown.circle.fill")
                .resizable()
                .frame(width: 30, height: 30)
                .foregroundStyle(disliked ? .red : .white)
        }
        
    }
    
}
