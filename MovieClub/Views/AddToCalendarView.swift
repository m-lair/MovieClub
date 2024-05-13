//
//  AddToCalendarView.swift
//  Movie Club
//
//  Created by Marcus Lair on 5/10/24.
//

import SwiftUI
import EventKitUI
import AuthenticationServices

struct AddToCalendarButton: View {
    let movieTitle: String
    let dueDate: Date

    var body: some View {
        Button(action: {
            self.addToCalendar()
        }) {
            Text("Add to Calendar")
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }

    func addToCalendar() {
        let eventStore = EKEventStore()

        eventStore.requestFullAccessToEvents(completion:) { (granted, error) in
            if granted && error == nil {
                let event = EKEvent(eventStore: eventStore)
                event.title = self.movieTitle
                event.startDate = self.dueDate
                event.endDate = self.dueDate
                event.calendar = eventStore.defaultCalendarForNewEvents

                do {
                    try eventStore.save(event, span: .thisEvent)
                    print("Event saved to calendar")
                } catch let error as NSError {
                    print("Failed to save event to calendar: \(error)")
                }
            } else {
                print("Access denied or error in requesting access to calendar")
            }
        }
    }
}
