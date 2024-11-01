//
//  ArchivesView.swift
//  MovieClub
//
//  Created by Marcus Lair on 10/24/24.
//

import SwiftUI

struct ArchivesView: View {
    let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
    let endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
    
    var body: some View {
        let testMovie: Movie = Movie(title: "The Matrix", startDate: startDate, endDate: endDate, userName: "duhmarcus", userId: "0001", authorAvi: "none")
        ScrollView {
            VStack {
                ForEach(1..<6, id: \.self) { index in
                    ArchiveRowView(movie: testMovie)
                    Divider()
                }
            }
        }
        .ignoresSafeArea()

    }
}
                                 
                                 

#Preview {
    ArchivesView()
}
