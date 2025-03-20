//
//  MyBookingsView.swift
//  ubc_room_booking
//
//  Created by Deepan Chakravarthy on 2025-03-19.
//

import SwiftUI

// Define notification name for booking check-in
extension Notification.Name {
    static let bookingCheckedIn = Notification.Name("bookingCheckedIn")
}

struct MyBookingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var bookings = DataStore.shared.bookings
    @State private var showingQRScanner = false
    @State private var selectedRoomForQR: Room?
    @State private var showingCancelConfirmation = false
    @State private var selectedBookingForCancel: Booking? = nil
    @State private var showingCancelResult = false
    @State private var cancelResultMessage = ""
    @State private var cancelSuccess = false
    @State private var needsRefresh: Bool = false
    var isTab: Bool = false
    
    var body: some View {
        Group {
            if bookings.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No Bookings")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("You don't have any room bookings yet")
                        .foregroundColor(.secondary)
                    
                    if !isTab {
                        Button("Close") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .padding(.top, 20)
                    }
                }
                .padding()
            } else {
                List {
                    ForEach(bookings) { booking in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .center) {
                                // Room details section
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(booking.roomName)
                                        .font(.headline)
                                        .foregroundColor(booking.cancelled ? .gray : .primary)
                                    
                                    Text(booking.formattedDate)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Text(booking.formattedTime)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                // Status with fixed alignment and size
                                VStack(alignment: .center, spacing: 2) {
                                    Image(systemName: booking.statusIcon)
                                        .foregroundColor(booking.statusColor)
                                        .font(.system(size: 24))
                                        .frame(width: 30, height: 30)
                                    
                                    Text(booking.statusText)
                                        .font(.caption)
                                        .foregroundColor(booking.statusColor)
                                        .frame(width: 70)
                                        .lineLimit(1)
                                }
                                .frame(width: 70, height: 50)
                                .onTapGesture {
                                    if booking.isCheckInEligible {
                                        if let room = DataStore.shared.rooms.first(where: { $0.id == booking.roomId }) {
                                            selectedRoomForQR = room
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 5)
                            
                            // Action buttons based on booking state
                            if booking.isCheckInEligible {
                                // Check-in prompt
                                HStack {
                                    Text("Time window for check-in is open!")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        showingQRScanner = true
                                    }) {
                                        Text("Scan QR")
                                            .font(.caption)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(Color.blue)
                                            .foregroundColor(.white)
                                            .cornerRadius(15)
                                    }
                                }
                                .padding(.top, 5)
                            }
                            
                            // Cancellation options
                            if booking.isCancellable && !booking.cancelled {
                                HStack {
                                    if booking.canCancelWithoutPenalty {
                                        Text("Can be cancelled without penalty")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    } else if booking.canCancelWithPenalty {
                                        Text("Cancellation will incur a strike")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                    
                                    Spacer()
                                    
                                    Button("Cancel Booking") {
                                        self.selectedBookingForCancel = booking
                                        self.showingCancelConfirmation = true
                                    }
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.red.opacity(0.1))
                                    .foregroundColor(.red)
                                    .cornerRadius(15)
                                }
                                .padding(.top, 5)
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
        .navigationTitle("My Bookings")
        .navigationBarItems(
            trailing: HStack {
                // Add a "Simulate" button for demos
                if isTab {
                    Button(action: {
                        DataStore.shared.simulateCancellationScenarios()
                        bookings = DataStore.shared.bookings
                    }) {
                        Text("Demo")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(15)
                    }
                    .padding(.trailing, 8)
                }
                
                if !isTab {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        )
        .onAppear {
            // Refresh the bookings list when the view appears
            bookings = DataStore.shared.bookings
            
            // Process any missed check-ins
            DataStore.shared.processMissedCheckIns()
            
            // Set up notification observer for check-ins
            NotificationCenter.default.addObserver(forName: .bookingCheckedIn, object: nil, queue: .main) { _ in
                // Update bookings when check-in occurs
                self.bookings = DataStore.shared.bookings
            }
        }
        .onChange(of: needsRefresh) { _ in
            bookings = DataStore.shared.bookings
        }
        .sheet(isPresented: $showingQRScanner) {
            NavigationView {
                QRCodeScannerView()
            }
            .onDisappear {
                // Trigger refresh when QR scanner disappears
                needsRefresh.toggle()
            }
        }
        .sheet(item: $selectedRoomForQR) { room in
            NavigationView {
                QRCodeGenerator(room: room)
                    .navigationTitle("Room QR Code")
                    .navigationBarItems(trailing: Button("Close") {
                        selectedRoomForQR = nil
                    })
            }
        }
        .alert("Confirm Cancellation", isPresented: $showingCancelConfirmation) {
            Button("Keep Booking", role: .cancel) {
                self.selectedBookingForCancel = nil
            }
            
            Button("Cancel Booking", role: .destructive) {
                if let booking = selectedBookingForCancel {
                    let result = DataStore.shared.cancelBooking(bookingId: booking.id)
                    
                    if result.success {
                        if result.penaltyApplied {
                            cancelResultMessage = "Your booking has been cancelled. A strike has been added to your account."
                        } else {
                            cancelResultMessage = "Your booking has been cancelled successfully."
                        }
                        cancelSuccess = true
                    } else {
                        cancelResultMessage = "Unable to cancel booking. It may have already started or been checked in."
                        cancelSuccess = false
                    }
                    
                    // Refresh the bookings
                    bookings = DataStore.shared.bookings
                    
                    // Clear the selection
                    selectedBookingForCancel = nil
                    
                    // Show the result alert
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showingCancelResult = true
                    }
                }
            }
        } message: {
            if let booking = selectedBookingForCancel {
                if booking.canCancelWithoutPenalty {
                    Text("Are you sure you want to cancel this booking? This action cannot be undone.")
                } else {
                    Text("Are you sure you want to cancel this booking? This is within 3 hours of the start time and will result in a strike. This action cannot be undone.")
                }
            } else {
                Text("An error occurred. Please try again.")
            }
        }
        .alert("Booking Cancellation", isPresented: $showingCancelResult) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(cancelResultMessage)
        }
    }
}

// Extension to make Room Identifiable for sheet presentation
extension Room: Identifiable { }
