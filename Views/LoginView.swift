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
    @State private var showingAlert: Bool = false
    @State private var alertMessage: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                
                Text("UBC DASCH")
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
                        // Check strike count before allowing login
                        let currentUser = DataStore.shared.currentUser
                        
                        // Process any missed check-ins before login
                        DataStore.shared.processMissedCheckIns()
                        
                        // Allow login regardless of strikes, but show warning if needed
                        isLoggedIn = true
                        
                        // For the prototype, we'll simply show a warning if strikes >= 3
                        if !currentUser.canBookRoom {
                            alertMessage = "Warning: You have \(currentUser.strikes) strikes. You cannot make new bookings until your strikes are below 3."
                            showingAlert = true
                        }
                    } else {
                        alertMessage = "Invalid username or password"
                        showingAlert = true
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
                .alert(isPresented: $showingAlert) {
                    Alert(
                        title: Text("Notice"),
                        message: Text(alertMessage),
                        dismissButton: .default(Text("OK"))
                    )
                }
                
                Spacer()
                
                // Updated to navigate to MainTabView instead of RoomListView
                NavigationLink(destination: MainTabView().navigationBarBackButtonHidden(true), isActive: $isLoggedIn) {
                    EmptyView()
                }
            }
            .padding()
        }
    }
}
