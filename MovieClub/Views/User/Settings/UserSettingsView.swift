//
//  UserSettingsView.swift
//  MovieClub
//
<<<<<<< Updated upstream
//  Created by Marcus Lair on 11/9/24.
//

=======
//  Created by Marcus Lair on 11/10/24.
//


>>>>>>> Stashed changes
import SwiftUI

struct UserSettingsView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    SettingsSectionView(headerText: "Account", headerColor: .orange) {
                        SettingsRowView(icon: "person.circle", label: "Login Information", destination: LoginInformationView())
                        SettingsRowView(icon: "house", label: "Addresses", destination: AddressesView())
                        SettingsRowView(icon: "creditcard", label: "Payment Methods", destination: PaymentMethodsView())
                        SettingsRowView(icon: "person.3", label: "Referral Dashboard", destination: ReferralDashboardView())
                    }
                    
                    SettingsSectionView(headerText: "Orders & Subscriptions", headerColor: .green) {
                        SettingsRowView(icon: "shippingbox", label: "Orders", destination: OrdersView())
                        SettingsRowView(icon: "calendar", label: "Subscriptions", destination: SubscriptionsView())
                        SettingsRowView(icon: "arrowshape.turn.up.backward", label: "My Returns", destination: MyReturnsView())
                    }
                    
                    // Add other sections as needed
                }
                .padding()
            }
            .background(Color.black.edgesIgnoringSafeArea(.all)) // For dark mode style
        }
    }
}

struct SettingsSectionView<Content: View>: View {
    let headerText: String
    let headerColor: Color
    let content: Content
    
    init(headerText: String, headerColor: Color, @ViewBuilder content: () -> Content) {
        self.headerText = headerText
        self.headerColor = headerColor
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) { // No spacing to merge header and content
            Text(headerText)
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(headerColor)
                .cornerRadius(10)
                .cornerRadius(10) // Rounded top corners only
            
            
            VStack(spacing: 10) {
                content
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
        }
    }

struct SettingsRowView: View {
    let icon: String
    let label: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white)
                .padding(.trailing, 10)
            Text(label)
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(Color.gray.opacity(0.15))
        .cornerRadius(8)
    }
}
            .cornerRadius(10) // Rounded bottom corners only
        }
        .cornerRadius(10) // Overall card effect
        .padding(.horizontal) // Padding around each card for spacing
    }
}

struct SettingsRowView<Destination: View>: View {
    let icon: String
    let label: String
    let destination: Destination // Generic destination view
    
    var body: some View {
        NavigationLink(destination: destination) { // Use NavigationLink for navigation
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .padding(.trailing, 10)
                Text(label)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
            .background(Color.gray.opacity(0.15))
            .cornerRadius(8)
        }
    }
}

// Example destination views
struct LoginInformationView: View {
    @Environment(DataManager.self) var data
    @Environment(AuthManager.self) var auth
    
    var user: User? { data.currentUser }
    var body: some View {
        VStack {
            Text("Login Information")
                .font(.headline)
                .padding()
            if let user {
                Text("Username: \(user.name)")
                Text("Email: \(user.email)")
                Spacer()
                Button("Logout") { auth.signOut() }
                .padding()
                .background(Color.red)
                .cornerRadius(8)
                .padding()
                .foregroundColor(.white)
                .font(.headline)
                
                Button("Delete Account") { auth.deleteUserData() }
            
            } else {
                Text("No user logged in.")
            }
        }
    }
}


struct AddressesView: View { var body: some View { Text("Addresses Screen") } }
struct PaymentMethodsView: View { var body: some View { Text("Payment Methods Screen") } }
struct ReferralDashboardView: View { var body: some View { Text("Referral Dashboard Screen") } }
struct OrdersView: View { var body: some View { Text("Orders Screen") } }
struct SubscriptionsView: View { var body: some View { Text("Subscriptions Screen") } }
struct MyReturnsView: View { var body: some View { Text("My Returns Screen") } }
>>>>>>> Stashed changes
