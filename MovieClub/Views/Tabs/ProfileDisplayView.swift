//
//  ProfileDisplayView.swift
//  MovieClub
//
//  Created by Marcus Lair on 8/14/24.
//

import SwiftUI
import FirebaseAuth

struct ProfileDisplayView: View {
    @Environment(DataManager.self) private var data
    @Environment(\.editMode) private var editMode
    @Environment(\.dismiss) private var dismiss
    
    // If userId is nil, we'll use the current user
    var userId: String?
    
    // Use a computed property to get the correct user
    private var displayUser: User? {
        if let userId = userId {
            return user // Show the fetched user for the specified userId
        } else {
            return data.currentUser // Show the current user if no userId specified
        }
    }
    
    @State private var user: User?
    @State private var isProfileCollapsed: Bool = false
    @State private var scrollOffset: CGFloat = 0
    let tabs: [String] = ["Clubs", "Collection"]
    @State var selectedTabIndex: Int = 0
    
    // Constants for profile header size
    private let expandedHeaderHeight: CGFloat = 170 // Adjust based on your content
    private let collapsedHeaderHeight: CGFloat = 5 // Smaller collapsed height
    
    // Threshold for collapsing/expanding the profile
    private let collapseThreshold: CGFloat = 30
    
    var body: some View {
        ZStack(alignment: .top) {
            // Main content
            VStack(spacing: 0) {
                if let displayUser = displayUser {
                    // Profile header container
                    ZStack(alignment: .top) {
                        // Collapsed header view
                        HStack(spacing: 10) {
                            // Small profile picture for collapsed state
                            if let imageUrl = displayUser.image, let url = URL(string: imageUrl) {
                                CachedAsyncImage(url: url) {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                }
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 1))
                                .opacity(isProfileCollapsed ? 1 : 0)
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 24, height: 24)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 1))
                                    .opacity(isProfileCollapsed ? 1 : 0)
                            }
                            if isProfileCollapsed {
                                Text(displayUser.name)
                                    .font(.title)
                                    .fontWeight(.bold)
                            }
                            Spacer()
                        }
                        .padding(.top)
                        .padding(.leading)
                        .zIndex(isProfileCollapsed ? 1 : 0)
                        
                        // Expanded profile content
                        VStack {
                            if let imageUrl = displayUser.image, let url = URL(string: imageUrl) {
                                CachedAsyncImage(url: url) {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                }
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                .shadow(radius: 10)
                                .id(imageUrl)
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 100, height: 100)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                    .shadow(radius: 10)
                            }
                            
                            Text(displayUser.name)
                                .font(.title)
                                .fontWeight(.bold)
                                .padding(.bottom, 8)
                        }
                        .offset(y: isProfileCollapsed ? -expandedHeaderHeight : 0)
                        .opacity(isProfileCollapsed ? 0 : 1)
                    }
                    .frame(height: isProfileCollapsed ? collapsedHeaderHeight : expandedHeaderHeight)
                    .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isProfileCollapsed)
                    
                    // Tab bar (outside the TabView)
                    ClubTabView(tabs: tabs, selectedTabIndex: $selectedTabIndex)
                        .frame(height: 40)
                        .padding(.bottom, isProfileCollapsed ? 4 : 12) // Less padding when collapsed
                        .padding(.top, isProfileCollapsed ? 2 : 0) // Slight top padding when collapsed
                        .zIndex(1) // Make sure tabs stay on top
                    
                    // Content area taking remaining space
                    GeometryReader { geometry in
                        // Using GeometryReader to get precise control over tab content
                        ZStack {
                            // Tab 0 - Clubs
                            if selectedTabIndex == 0 {
                                ScrollViewWithOffset(showsIndicators: false, onOffsetChange: { offset in
                                    updateScrollOffset(offset)
                                }) {
                                    VStack(spacing: 0) {
                                        // Extra space at the top to prevent clipping
                                        Color.clear.frame(height: 20)
                                        
                                        UserMembershipsView(userId: displayUser.id)
                                            .padding(.horizontal, 2) // Small padding to prevent cards touching edge
                                    }
                                    .padding(.bottom, 20) // Space at bottom for better scrolling
                                }
                                .transition(.opacity)
                            }
                            
                            // Tab 1 - Collection
                            if selectedTabIndex == 1 {
                                ScrollViewWithOffset(showsIndicators: false, onOffsetChange: { offset in
                                    updateScrollOffset(offset)
                                }) {
                                    VStack(spacing: 0) {
                                        // Extra space at the top to prevent clipping
                                        Color.clear.frame(height: 20)
                                        
                                        UserCollectionView(userId: displayUser.id)
                                            .padding(.horizontal, 2) // Small padding to prevent cards touching edge
                                    }
                                    .padding(.bottom, 20) // Space at bottom for better scrolling
                                }
                                .transition(.opacity)
                            }
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                    .animation(.easeInOut(duration: 0.2), value: selectedTabIndex)
                }
            }
        }
        .padding(.leading, 4)
        .navigationTitle(isProfileCollapsed ? "" : "Profile")
        .toolbar {
            if displayUser?.id == Auth.auth().currentUser?.uid {
                ToolbarItem(placement: .topBarTrailing){
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
        .task {
            if let userId = userId {
                user = try? await data.fetchProfile(id: userId)
            }
        }
        .refreshable {
            if let userId = userId {
                user = try? await data.fetchProfile(id: userId)
            } else {
                await data.refreshUserProfile()
            }
        }
        .edgesIgnoringSafeArea(.bottom)
    }
    
    private func updateScrollOffset(_ offset: CGFloat) {
        self.scrollOffset = offset
        
        // Automatically collapse/expand based on scroll direction
        if offset > collapseThreshold && !isProfileCollapsed {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                isProfileCollapsed = true
            }
        } else if offset < 5 && isProfileCollapsed {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                isProfileCollapsed = false
            }
        }
    }
}

// Custom ScrollView that tracks offset
struct ScrollViewWithOffset<Content: View>: View {
    let axes: Axis.Set
    let showsIndicators: Bool
    let onOffsetChange: (CGFloat) -> Void
    let content: Content
    
    init(axes: Axis.Set = .vertical, 
         showsIndicators: Bool = true,
         onOffsetChange: @escaping (CGFloat) -> Void,
         @ViewBuilder content: () -> Content) {
        self.axes = axes
        self.showsIndicators = showsIndicators
        self.onOffsetChange = onOffsetChange
        self.content = content()
    }
    
    var body: some View {
        ScrollView(axes, showsIndicators: showsIndicators) {
            offsetReader
            content
        }
    }
    
    var offsetReader: some View {
        GeometryReader { geometry in
            Color.clear
                .preference(
                    key: OffsetPreferenceKey.self,
                    value: geometry.frame(in: .named("scrollView")).minY
                )
                .onPreferenceChange(OffsetPreferenceKey.self) { value in
                    onOffsetChange(value * -1) // Convert to positive for downward scrolling
                }
        }
        .frame(height: 0) // Zero height so it doesn't take up space
    }
}

// Preference key for scroll offset
struct OffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
