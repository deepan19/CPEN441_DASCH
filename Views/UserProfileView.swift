//
//  UserProfileView.swift
//  ubc_room_booking
//
//  Created by Deepan Chakravarthy on 2025-03-19.
//

import SwiftUI

struct UserProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var user = DataStore.shared.currentUser
    @State private var isLoading = false
    @State private var showingSimulatorOptions = false
    @State private var showingBookingView = false
    var isTab: Bool = false
    
    // Computed properties for UI
    private var strikeColor: Color {
        if user.strikes >= 3 {
            return .red
        } else if user.strikes > 0 {
            return .orange
        } else {
            return .green
        }
    }
    
    // For demo - simulate strike reduction
    private func simulateStrikeReduction() {
        if user.strikes > 0 {
            isLoading = true
            
            // Simulate API call
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                // Reduce strikes
                DataStore.shared.reduceStrikes()
                // Update local user
                user = DataStore.shared.currentUser
                isLoading = false
            }
        }
    }
    
    // Simulate a missed check-in
    private func simulateMissedCheckIn() {
        isLoading = true
        
        // Create a simulated booking in the past with no check-in
        let calendar = Calendar.current
        
        // Create a time 15 minutes ago (beyond the 10-min check-in window)
        let startTime = calendar.date(byAdding: .minute, value: -15, to: Date())!
        let endTime = calendar.date(byAdding: .hour, value: 1, to: startTime)!
        
        // Find a random room
        if let room = DataStore.shared.rooms.first {
            let missedBooking = Booking(
                roomId: room.id,
                roomName: room.name,
                date: startTime,
                startTime: startTime,
                endTime: endTime,
                checkedIn: false,
                checkedInTime: nil,
                missedCheckIn: false,
                cancelled: false
            )
            
            // Add the booking
            DataStore.shared.bookings.append(missedBooking)
            
            // Process missed check-ins which will add a strike
            DataStore.shared.processMissedCheckIns()
            
            // Update the UI
            user = DataStore.shared.currentUser
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            showingSimulatorOptions = false
        }
    }
    
    // Simulate cancellation scenarios
    private func simulateCancellationScenarios() {
        isLoading = true
        
        // Create test bookings with different cancellation scenarios
        DataStore.shared.simulateCancellationScenarios()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            showingSimulatorOptions = false
            showingBookingView = true
        }
    }
    
    var body: some View {
        List {
            // User Info Section
            Section(header: Text("User Information")) {
                HStack(spacing: 15) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text(user.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(user.email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 10)
            }
            
            // Strike Status Section
            Section(header: Text("Booking Status")) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Current Strikes: \(user.strikes) / 5")
                        .font(.headline)
                    
                    // Strike visualization
                    HStack(spacing: 5) {
                        ForEach(0..<5) { index in
                            Circle()
                                .fill(index < user.strikes ? strikeColor : Color.gray.opacity(0.3))
                                .frame(width: 20, height: 20)
                        }
                    }
                    
                    if user.strikes >= 3 {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            
                            Text("You cannot make new bookings until your strikes are below 3")
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                        .padding(.top, 5)
                    } else {
                        Text("You can make bookings")
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .padding(.top, 5)
                    }
                }
                .padding(.vertical, 5)
                
                // Strike explanation
                VStack(alignment: .leading, spacing: 5) {
                    Text("About Strikes:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("• You get a strike when you don't check in within 10 minutes of your booking's start time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("• You get a strike when you cancel a booking less than 3 hours before start time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("• Strikes are automatically reduced by 1 every day")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("• You can have a maximum of 5 strikes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 5)
            }
            
            // Simulator Section - For demo purposes only
            Section(header: Text("Simulator")) {
                Button(action: {
                    showingSimulatorOptions.toggle()
                }) {
                    HStack {
                        Text("Simulation Options")
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Image(systemName: showingSimulatorOptions ? "chevron.up" : "chevron.down")
                            .foregroundColor(.gray)
                    }
                }
                
                if showingSimulatorOptions {
                    Button(action: simulateStrikeReduction) {
                        HStack {
                            Text("Simulate Daily Strike Reduction")
                                .foregroundColor(.blue)
                            
                            Spacer()
                            
                            if isLoading {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(user.strikes == 0 || isLoading)
                    
                    Button(action: {
                        if user.strikes < 5 {
                            DataStore.shared.addStrike()
                            user = DataStore.shared.currentUser
                        }
                    }) {
                        Text("Simulate Adding a Strike")
                            .foregroundColor(.red)
                    }
                    .disabled(user.strikes >= 5 || isLoading)
                    
                    Button(action: simulateMissedCheckIn) {
                        HStack {
                            Text("Simulate Missed Check-in")
                                .foregroundColor(.orange)
                            
                            Spacer()
                            
                            if isLoading {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(user.strikes >= 5 || isLoading)
                    
                    Button(action: simulateCancellationScenarios) {
                        HStack {
                            Text("Simulate Cancellation Scenarios")
                                .foregroundColor(.purple)
                            
                            Spacer()
                            
                            if isLoading {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isLoading)
                }
            }
            .font(.footnote)
            
            // App information section
            Section(header: Text("App Information")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Profile")
        .navigationBarItems(trailing: isTab ? nil : Button("Done") {
            presentationMode.wrappedValue.dismiss()
        })
        .onAppear {
            // Refresh user data when view appears
            user = DataStore.shared.currentUser
            
            // Process missed check-ins (for demo)
            DataStore.shared.processMissedCheckIns()
        }
        .sheet(isPresented: $showingBookingView) {
            NavigationView {
                MyBookingsView()
            }
        }
    }
}
