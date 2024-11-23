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
    @State var error: String = ""
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
                
                Text(error)
                    .foregroundStyle(.red)
                
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
        .alert(error, isPresented: $errorShowing) {
            Button("OK", role: .cancel) { }
        }
    }
    
    func handleSignIn() async throws {
        if userEmail.isEmpty || userPwd.isEmpty {
            error = "Please enter an email and password."
            errorShowing.toggle()
            return
        }
        print("Signing in...")
        do {
            try await data.signIn(email: userEmail, password: userPwd)
            
        } catch let error as NSError {
            switch error.userInfo[AuthErrorUserInfoNameKey] as? String {
            case "ERROR_INVALID_EMAIL":
                self.error = "Please enter a valid email."
            case "ERROR_WRONG_PASSWORD":
                self.error = "Incorrect password."
            case "ERROR_USER_NOT_FOUND":
                self.error = "User not found."
            case "ERROR_USER_DISABLED":
                self.error = "User disabled."
            default:
                self.error = "Error signing in: \(error)"
            }
            errorShowing.toggle()
        }
    }
}
