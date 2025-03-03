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
    @State private var isTabSwitching: Bool = false  // Flag to track tab switching
    @State private var initialScrollAfterTabSwitch: Bool = false // Track initial scroll after tab switch
    @State private var lastTabSwitchTime: Date = Date()
    let tabs: [String] = ["Clubs", "Collection"]
    @State var selectedTabIndex: Int = 0
    
    // Constants for profile header size
    private let expandedHeaderHeight: CGFloat = 170 // Adjust based on your content
    private let collapsedHeaderHeight: CGFloat = 5 // Smaller collapsed height
    
    // Threshold for collapsing/expanding the profile
    private let collapseThreshold: CGFloat = 30
    
    // Timer to reset tab switching state
    private let tabSwitchResetDelay: TimeInterval = 0.4

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
                            
                            // Always include the text but control visibility with opacity
                            Text(displayUser.name)
                                .font(.title)
                                .fontWeight(.bold)
                                .opacity(isProfileCollapsed ? 1 : 0)
                                .offset(x: isProfileCollapsed ? 0 : -20) // Add slight movement for better animation
                            
                            Spacer()
                        }
                        .padding(.top)
                        .padding(.leading)
                        .zIndex(isProfileCollapsed ? 1 : 0)
                        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isProfileCollapsed)
                        
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
                            // Tab 0 - Clubs - Always keep in view hierarchy
                            ScrollViewWithOffset(showsIndicators: false, onOffsetChange: { offset in
                                if selectedTabIndex == 0 {
                                    updateScrollOffset(offset)
                                }
                            }) {
                                VStack(spacing: 0) {
                                    // Extra space at the top to prevent clipping
                                    Color.clear.frame(height: 20)
                                    
                                    UserMembershipsView(userId: displayUser.id)
                                        .padding(.horizontal, 2) // Small padding to prevent cards touching edge
                                }
                                .padding(.bottom, 20) // Space at bottom for better scrolling
                            }
                            .opacity(selectedTabIndex == 0 ? 1 : 0.3)
                            .offset(x: selectedTabIndex == 0 ? 0 : -geometry.size.width)
                            .zIndex(selectedTabIndex == 0 ? 1 : 0)
                            .allowsHitTesting(selectedTabIndex == 0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedTabIndex)
                            
                            // Tab 1 - Collection - Always keep in view hierarchy
                            ScrollViewWithOffset(showsIndicators: false, onOffsetChange: { offset in
                                if selectedTabIndex == 1 {
                                    updateScrollOffset(offset)
                                }
                            }) {
                                VStack(spacing: 0) {
                                    // Extra space at the top to prevent clipping
                                    Color.clear.frame(height: 20)
                                    
                                    UserCollectionView(userId: displayUser.id)
                                        .padding(.horizontal, 2) // Small padding to prevent cards touching edge
                                }
                                .padding(.bottom, 20) // Space at bottom for better scrolling
                            }
                            .opacity(selectedTabIndex == 1 ? 1 : 0.3)
                            .offset(x: selectedTabIndex == 1 ? 0 : geometry.size.width)
                            .zIndex(selectedTabIndex == 1 ? 1 : 0)
                            .allowsHitTesting(selectedTabIndex == 1)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedTabIndex)
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .gesture(
                            DragGesture()
                                .onEnded { gesture in
                                    let threshold: CGFloat = 50
                                    let horizontalDistance = gesture.translation.width
                                    
                                    // Ignore primarily vertical swipes
                                    guard abs(horizontalDistance) > abs(gesture.translation.height) else { return }
                                    
                                    if horizontalDistance > threshold && selectedTabIndex > 0 {
                                        // Swipe right - go to previous tab
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            isTabSwitching = true  // Set flag when switching tabs
                                            initialScrollAfterTabSwitch = true // Mark initial scroll state
                                            lastTabSwitchTime = Date()
                                            selectedTabIndex -= 1
                                        }
                                    } else if horizontalDistance < -threshold && selectedTabIndex < tabs.count - 1 {
                                        // Swipe left - go to next tab
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            isTabSwitching = true  // Set flag when switching tabs
                                            initialScrollAfterTabSwitch = true // Mark initial scroll state
                                            lastTabSwitchTime = Date()
                                            selectedTabIndex += 1
                                        }
                                    }
                                }
                        )
                    }
                    // Using onChange instead of inline animation for better control
                    .onChange(of: selectedTabIndex) {
                        // Reset tab switching flag after animation completes
                        Task { 
                            try? await Task.sleep(for: .seconds(tabSwitchResetDelay))
                            isTabSwitching = false
                        }
                    }
                }
            }
        }
        .padding(.leading, 4)
        .padding(.top, isProfileCollapsed ? (userId != nil ? 70 : 0) : 0) // Add top padding when collapsed in navigation context
        .navigationBarBackButtonHidden(isProfileCollapsed)
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
        
        // Skip collapse/expand logic during tab transitions
        if isTabSwitching {
            return
        }
        
        // Prevent uncollapse during initial scroll after tab switch
        if initialScrollAfterTabSwitch {
            // Only proceed with uncollapsing if it's been more than a second since tab switch
            // This prevents brief uncollapse when starting to scroll in new tab
            let timeSinceTabSwitch = Date().timeIntervalSince(lastTabSwitchTime)
            if timeSinceTabSwitch < 1.0 {
                // Always preserve collapsed state during tab transitions if already collapsed
                if isProfileCollapsed {
                    return
                }
            } else {
                // After 1 second, resume normal scrolling behavior
                initialScrollAfterTabSwitch = false
            }
        }
        
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
