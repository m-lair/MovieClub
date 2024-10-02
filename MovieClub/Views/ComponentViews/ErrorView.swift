//
//  ErrorView.swift
//  MovieClub
//
//  Created by Marcus Lair on 10/1/24.
//

import SwiftUI

struct ErrorView: View {
    let errorString: String
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .foregroundColor(.red)
            .frame(height: 200)
            .padding()
            .overlay {
                
                VStack {
                    Text(errorString)
                        .font(.largeTitle)
                        .foregroundColor(.white)
                    
                    Button("OK") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
            }
    
    }
}

