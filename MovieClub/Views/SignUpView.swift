//
//  SignUpView.swift
//  Movie Club
//
//  Created by Marcus Lair on 5/10/24.
//

import SwiftUI
import Observation

struct SignupView: View {
    @Environment(DataManager.self) private var data
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    
    var body: some View {
        VStack {
            Image("logo")
                .resizable()
                .frame(width: 100, height: 100)
                .padding(.bottom, 50)
            
            TextField("Name", text: $name)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal, 50)
                .padding(.bottom, 20)
            
            TextField("Email", text: $email)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal, 50)
                .padding(.bottom, 20)
            
            SecureField("Password", text: $password)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal, 50)
                .padding(.bottom, 50)
            
            Button {
                Task {
                    
                    try await data.createUser(user: User(name: name, email: email, password: password))
                    try await data.signIn(email: email, password: password)
                    dismiss()
                }
            } label: {
                Text("Signup")
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            Button{
               dismiss()
            } label: {
                Text("Don't have an account?")
                Text("Sign Up!")
                    .bold()
            }
            Spacer()
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    SignupView()
}
