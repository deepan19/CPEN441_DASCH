//
//  MainTabView.swift
//  ubc_room_booking
//
//  Created by Deepan Chakravarthy on 2025-03-19.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showingQRScanner = false

    var body: some View {
        TabView(selection: $selectedTab) {
            // Rooms tab
            NavigationView {
                RoomListView()
            }
            .tabItem {
                Label("Rooms", systemImage: "building.2.fill")
            }
            .tag(0)
            
            // QR Scanner tab
            Button(action: {
                showingQRScanner = true
            }) {
                Color.clear
            }
            .tabItem {
                Label("Check In", systemImage: "qrcode.viewfinder")
            }
            .tag(1)
            
            // My Bookings tab
            NavigationView {
                MyBookingsView(isTab: true)
            }
            .tabItem {
                Label("My Bookings", systemImage: "calendar")
            }
            .tag(2)
            
            // Profile tab
            NavigationView {
                UserProfileView(isTab: true)
            }
            .tabItem {
                Label("Profile", systemImage: "person.circle")
                    .overlay(
                        // We'll handle the badge in a different way for tab bar
                        DataStore.shared.currentUser.strikes > 0 ?
                        Text("\(DataStore.shared.currentUser.strikes)")
                            .font(.system(size: 10))
                            .foregroundColor(.white)
                            .background(Circle().fill(Color.red))
                            .offset(x: 10, y: -10) : nil
                    )
            }
            .tag(3)
        }
        .onChange(of: selectedTab) { newValue in
            // If QR Scanner tab is selected, show the scanner and reset tab selection
            if newValue == 1 {
                showingQRScanner = true
                // Reset to rooms tab after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    selectedTab = 0
                }
            }
        }
        .sheet(isPresented: $showingQRScanner) {
            NavigationView {
                QRCodeScannerView()
            }
        }
        .onAppear {
            // Process any missed check-ins on app launch
            DataStore.shared.processMissedCheckIns()
            
            // Set tab bar appearance
            UITabBar.appearance().backgroundColor = UIColor.systemBackground
        }
    }
}
