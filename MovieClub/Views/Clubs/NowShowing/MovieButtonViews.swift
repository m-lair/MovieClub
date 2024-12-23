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

struct ReviewThumbs: View {
    @Binding var liked: Bool
    @Binding var disliked: Bool
    var body: some View {
        HStack {
            Button {
                thumbUpFunction()
                liked.toggle()
                if liked {
                    disliked = false
                }
                
            } label: {
                Image(systemName: "hand.thumbsup.circle.fill")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(liked ? .green : .white)
            }
            
            Button {
                thumbDownFunction()
                disliked.toggle()
                if disliked {
                    liked = false
                }
                
            } label: {
                Image(systemName: "hand.thumbsdown.circle.fill")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(disliked ? .red : .white)
            }
        }
    }
}

func thumbUpFunction()
{
    //check state of dislike
    //increment the number of likes
}
func thumbDownFunction()
{
    //check state of like
    //decrement the number of likes
}


