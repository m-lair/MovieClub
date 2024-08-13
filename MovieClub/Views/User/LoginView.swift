//
//  LoginView.swift
//  Movie Club
//
//  Created by Marcus Lair on 5/6/24.
//

import SwiftUI
import AuthenticationServices
import Observation

struct LoginView: View {
    
    @Environment(DataManager.self) private var data
    @Environment(\.dismiss) private var dismiss
    @State private var errorMessage: String = ""
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
                
                Text(errorMessage)
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
                        do{
                            try await data.signIn(email: userEmail, password: userPwd)
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                } label: {
                    switch btnDisabled{
                    case true:
                        Text("Sign In")
                            .foregroundColor(.white)
                            .frame(width: 200, height: 50)
                            .background(Color.gray)
                            .cornerRadius(8)
                    case false:
                        Text("Sign In")
                            .foregroundColor(.white)
                            .frame(width: 200, height: 50)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
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
            .padding()
        }
    }
}
    
#Preview {
    LoginView()
        .environment(DataManager())
}
