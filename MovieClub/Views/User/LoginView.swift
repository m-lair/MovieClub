//
//  LoginView.swift
//  Movie Club
//
//  Created by Marcus Lair on 5/6/24.
//

import SwiftUI
import AuthenticationServices
import Observation
import FirebaseAuth

struct LoginView: View {
    
    @Environment(DataManager.self) private var data
    @Environment(\.dismiss) private var dismiss
    @State var error: Error? = nil
    @State var errorShowing: Bool = false
    @State private var userEmail = ""
    @State private var userPwd = ""
    private var btnDisabled: Bool {
        if userEmail.isEmpty || userPwd.isEmpty {
            return true
        }else{
            return false
        }
    }
    
    var body: some View {
        NavigationStack{
            VStack {
                Spacer()
                Text("Movie Club")
                    .font(.title)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)
                    .padding(.bottom, 50)
                
                TextField("Username", text: $userEmail)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal, 50)
                    .padding(.bottom, 20)
                
                SecureField("Password", text: $userPwd)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal, 50)
                    .padding(.bottom, 50)
                
                Button {
                    Task{
                        try await handleSignIn()
                    }
                } label: {
                    Text("Sign In")
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(btnDisabled ? Color.gray : Color.blue)
                        .cornerRadius(8)
                }
                .disabled(btnDisabled)
                Spacer()
                NavigationLink {
                    SignUpView()
                        .navigationBarBackButtonHidden(true)
                } label: {
                    HStack(spacing: 3){
                        Text("Don't have an account?")
                        Text("Sign Up!")
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(.blue)
                    .font(.system(size: 14))
                }
            }
        }
        .alert("Error", isPresented: .constant(error != nil), actions: {
            Button("OK") {
                error = nil
            }
        }, message: {
            if let error = error {
                Text(error.localizedDescription)
            }
        })
    }
    
    func handleSignIn() async throws {
        if userEmail.isEmpty || userPwd.isEmpty {
            error = "Please enter an email and password." as? any Error
            return
        }
        print("Signing in...")
        do {
            try await data.signIn(email: userEmail, password: userPwd)
            try await data.fetchUser()
        } catch {
            self.error = error
        }
    }
}
