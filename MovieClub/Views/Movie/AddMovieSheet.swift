//
//  AddMovieSheet.swift
//  Movie Club
//
//  Created by Marcus Lair on 5/7/24.
//

import SwiftUI


struct AddMovieSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(DataManager.self) var data: DataManager
    
    
    @State private var title = ""
    @State private var rating = 0.0
    @State private var date: Date = Date()
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Title", text: $title)
                StarRatingView(rating: $rating)
                
                DatePicker("Watch by date", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    
                    
                    
                
            }
            .navigationTitle("Add Movie")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    
                    dismiss()
                    
                }
                
            )
            
        }
        AddToCalendarButton(movieTitle: title, dueDate: date)
    }
}

#Preview {
    AddMovieSheet()
}
