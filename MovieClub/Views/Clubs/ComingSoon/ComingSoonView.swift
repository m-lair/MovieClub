//
//  RosterView.swift
//  MovieClub
//
//  Created by Marcus Lair on 7/20/24.
//

import SwiftUI
import FirebaseFirestore

struct ComingSoonView: View {

    @Environment(DataManager.self) var data: DataManager
    @State var i: Int = 0
    @State private var screenWidth = UIScreen.main.bounds.size.width
    @State var comingSoon: [Suggestion] = [Suggestion(id: "0001", title: "Minions 2: The Rise of Gru", userImage: "", username: "RobbieDobbie", clubId: "aLcJUEMjlQ4MZAlqTB0L"), Suggestion(id: "0002", title: "Tropic Thunder", userImage: "", username: "user12345", clubId: "aLcJUEMjlQ4MZAlqTB0L"), Suggestion(id: "0003", title: "Black Swan", userImage: "", username: "MarshHatesMovies", clubId: "aLcJUEMjlQ4MZAlqTB0L")]
    
    @State var imageUrl: String = ""
    @State var creatingSuggestion: Bool = false
    
    let startDate: Date?
    let timeInterval: Int
    var body: some View {
        if comingSoon.isEmpty {
            Text("No Suggestions Yet")
            Button("Create a Suggestion") {
                
            }
        } else {
            ScrollView{
                VStack {
                    ForEach(Array(comingSoon.enumerated()), id: \.offset) { index, suggestion in
                        HStack {
                            ComingSoonRowView(suggestion: suggestion)
                            Spacer()
                            if let dateString = computedDateString(for: index) {
                                Text(dateString)
                            } else {
                                Text("No Date")
                            }
                        }
                    }
                    .padding([.top, .leading])
                    
                    
                    Button("New Suggestion"){
                        creatingSuggestion = true
                    }
                    .foregroundStyle(.black)
                    .buttonStyle(.borderedProminent)
                
                }
                .sheet(isPresented: $creatingSuggestion) {
                    CreateSuggestionView()
                }
                
            }
            .onAppear() {
                Task{
                    // Do something
                }
            }
        }
    }
    func computedDateString(for index: Int) -> String? {
        guard let startDate = startDate else { return nil }
        let weeksToAdd = timeInterval * (index + 1)
        if let date = Calendar.current.date(byAdding: .weekOfYear, value: weeksToAdd, to: startDate) {
            return date.formatted(date: .abbreviated, time: .omitted)
        }
        return nil
    }
}

