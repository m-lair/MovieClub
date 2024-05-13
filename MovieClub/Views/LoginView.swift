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
    @State private var userEmail = ""
    @State private var userPwd = ""
        
    
    var body: some View {
        NavigationView {
            VStack {
                Image("logo")
                    .resizable()
                    .frame(width: 100, height: 100)
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
                        
                        try await data.signIn(email: userEmail, password: userPwd)
                        await data.fetchUser()
                    }
                    
                } label: {
                    Text("Sign In")
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
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
                    .font(.system(size: 14))
                }
            }
            .padding()
        }
    }
    }
    

    
    
#Preview {
    LoginView()
}
