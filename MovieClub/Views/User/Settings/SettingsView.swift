//
//  SettingsView.swift
//  MovieClub
//
//  Created by Marcus Lair on 11/10/24.
//


import SwiftUI

struct SettingsView: View {
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
            
            VStack(spacing: 10) {
                content
            }
            .padding()
            .background(Color.gray.opacity(0.2))
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

struct LoginInformationView: View {
    @Environment(DataManager.self) var data
    
    var body: some View {
        VStack {
            if let user = data.currentUser {
                VStack(alignment: .leading, spacing: 8) {
                    Text("User Information")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.bottom, 10)
                    
                    HStack {
                        Text("Name:")
                            .fontWeight(.bold)
                        Text(user.name)
                    }
                    
                    HStack {
                        Text("Email:")
                            .fontWeight(.bold)
                        Text(user.email)
                    }
                    
                    Spacer().frame(height: 20)
                    
                    Button {
                        data.signOut()
                    } label: {
                        Text("Logout")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                    .padding(.top, 10)
                    
                    Button {
                        guard let userId = user.id else { return }
                        Task {
                            try await data.deleteUserAccount(userId: userId)
                            data.authCurrentUser = nil
                        }
                    } label: {
                        Text("Delete Account")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                    .padding(.top, 10)
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(12)
                .shadow(radius: 5)
                .padding()
            } else {
                Text("No user information available.")
                    .foregroundColor(.gray)
                    .italic()
                    .padding()
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
