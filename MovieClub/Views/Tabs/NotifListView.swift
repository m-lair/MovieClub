//
//  NotifListView.swift
//  MovieClub
//
//  Created by Marcus Lair on 10/23/24.
//
 
import Foundation
import SwiftUI

struct NotificationListView: View {
    @Environment(NotificationManager.self) var notifManager
    @State var navPath: NavigationPath = NavigationPath()
    @Environment(DataManager.self) var data
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var selectedFilter: NotifFilter = .all
    
    enum NotifFilter: String, CaseIterable {
        case all = "All"
        case comments = "Comments"
        case movieClubs = "Movie Clubs"
        case posters = "Posters"
    }
  
    var filteredNotifications: [Notification] {
        switch selectedFilter {
        case .all:
            return notifManager.notifications
        case .comments:
            return notifManager.notifications.filter { $0.type == .commented || $0.type == .replied || $0.type == .liked }
        case .movieClubs:
            return notifManager.notifications.filter { $0.type == .joined || $0.type == .suggestion || $0.type == .rotated }
        case .posters:
            return notifManager.notifications.filter { $0.type == .collected }
        }
    }
    
    var groupedNotifications: [(String, [Notification])] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let todayNotifs = filteredNotifications.filter {
            calendar.startOfDay(for: $0.createdAt) == today
        }
        
        let earlierNotifs = filteredNotifications.filter {
            calendar.startOfDay(for: $0.createdAt) != today
        }
        
        var result: [(String, [Notification])] = []
        
        if !todayNotifs.isEmpty {
            result.append(("Today", todayNotifs))
        }
        
        if !earlierNotifs.isEmpty {
            result.append(("Earlier", earlierNotifs))
        }
        
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter tabs at the top
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(NotifFilter.allCases, id: \.self) { filter in
                        FilterTabView(filter: filter, isSelected: selectedFilter == filter) {
                            selectedFilter = filter
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 5)
            
            List {
                ForEach(groupedNotifications, id: \.0) { section, notifications in
                    Section(header: Text(section)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.vertical, 4)
                        .listRowInsets(EdgeInsets())) {
                            
                            ForEach(notifications) { notification in
                                NavigationLink(value: notification) {
                                    NotificationItemView(notification: notification)
                                }
                                .listRowBackground(Color.black)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        Task {
                                            do {
                                                try await notifManager.deleteNotification(notification)
                                            } catch {
                                                errorMessage = error.localizedDescription
                                                showError = true
                                            }
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .listSectionSeparator(.hidden)
                }
            }
            .listStyle(.grouped)
            .scrollContentBackground(.hidden)
        }
        .navigationDestination(for: Notification.self) { notification in
            switch notification.type {
            case .commented, .collected, .liked, .replied, .suggestion, .joined, .rotated:
                if let club = data.userClubs.first(where: { $0.id == notification.clubId }) {
                    ClubDetailView(navPath: $navPath, club: club)
                        .navigationTitle(club.name)
                        .navigationBarTitleDisplayMode(.inline)
                } else {
                    Text("Club not found")
                }
                
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .refreshable {
            await notifManager.fetchUserNotifications()
        }
        .navigationTitle("Notifications")
        .task {
            await notifManager.fetchUserNotifications()
        }
        .background(Color.black)
    }
}

struct FilterTabView: View {
    let filter: NotificationListView.NotifFilter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(filter.rawValue)
                .fontWeight(isSelected ? .bold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? filterColor : Color(.darkGray).opacity(0.3))
                .foregroundColor(isSelected ? .white : .gray)
                .clipShape(Capsule())
        }
    }
    
    private var filterColor: Color {
        switch filter {
        case .all:
            return Color(.darkGray).opacity(0.7)
        case .comments:
            return .blue.opacity(0.7)
        case .movieClubs:
            return .red.opacity(0.7)
        case .posters:
            return .yellow.opacity(0.7)
        }
    }
}

