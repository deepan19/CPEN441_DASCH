//
//  LoginView.swift
//  ubc_room_booking
//
//  Created by Deepan Chakravarthy on 2025-03-19.
//

import SwiftUI

struct LoginView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isLoggedIn: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                
                Text("University Room Booking")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer().frame(height: 40)
                
                VStack(spacing: 15) {
                    TextField("Username", text: $username)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                
                Button(action: {
                    // Hardcoded login for MVP
                    if username == "Student" && password == "password" {
                        isLoggedIn = true
                    }
                }) {
                    Text("Login")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                
                Spacer()
                
                NavigationLink(destination: RoomListView(), isActive: $isLoggedIn) {
                    EmptyView()
                }
            }
            .padding()
        }
    }
}
