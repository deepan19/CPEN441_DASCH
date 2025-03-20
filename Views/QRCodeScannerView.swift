//
//  QRCodeScannerView.swift
//  ubc_room_booking
//
//  Created by Deepan Chakravarthy on 2025-03-19.
//

import SwiftUI
import AVFoundation

// Mock Camera View for prototype purposes
struct CameraMockView: View {
    @State private var mockScanComplete = false
    @State private var mockScanProgress: Double = 0.0
    
    var onScanResult: (String) -> Void
    
    var body: some View {
        ZStack {
            // Mock camera background
            Color.black
            
            // Mock camera frame
            VStack {
                // Simulated camera feed (static noise)
                Rectangle()
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(
                        Image(systemName: "qrcode.viewfinder")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .opacity(0.3)
                            .foregroundColor(.white)
                            .frame(width: 200, height: 200)
                    )
                
                // Mock scanning feedback
                if mockScanProgress > 0 {
                    ProgressView(value: mockScanProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(width: 250)
                        .padding()
                }
            }
            
            // Processing overlay
            if mockScanComplete {
                RoundedRectangle(cornerRadius: 20)
                    .foregroundColor(.black.opacity(0.8))
                    .frame(width: 200, height: 200)
                    .overlay(
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                            
                            Text("Processing...")
                                .foregroundColor(.white)
                                .padding(.top, 20)
                        }
                    )
            }
        }
        .ignoresSafeArea()
        .onAppear {
            simulateScan()
        }
    }
    
    private func simulateScan() {
        // Mock progress increases over time
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            if mockScanProgress < 1.0 {
                mockScanProgress += 0.2
            } else {
                timer.invalidate()
                mockScanComplete = true
                
                // Complete the scan with a mock QR code after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    // Use the first room's QR code for demo purposes
                    let mockedQRCodeValue = DataStore.shared.rooms.first?.qrCodeId ?? "UBC-ROOM-1-MCLD-1011"
                    onScanResult(mockedQRCodeValue)
                }
            }
        }
    }
}

struct QRCodeScannerView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var scannedCode: String?
    @State private var showingResult = false
    @State private var checkInSuccess = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            // Camera view
            CameraMockView { result in
                self.scannedCode = result
                self.processScannedCode(result)
            }
            
            // Overlay instructions
            VStack {
                Spacer()
                
                Text("Scan the room's QR code")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                
                Spacer()
                
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(10)
                .padding(.bottom, 30)
            }
            .padding()
            
            // Success/Failure alert
            if showingResult {
                VStack {
                    Spacer()
                    
                    VStack(spacing: 20) {
                        if checkInSuccess {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 70))
                                .foregroundColor(.green)
                            
                            Text("Check-in Successful!")
                                .font(.title)
                                .fontWeight(.bold)
                        } else {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 70))
                                .foregroundColor(.red)
                            
                            Text("Check-in Failed")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text(errorMessage ?? "No matching booking found")
                                .multilineTextAlignment(.center)
                        }
                        
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Done")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding()
                                .frame(width: 200)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .padding(.top, 10)
                    }
                    .padding(30)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 10)
                    
                    Spacer()
                }
                .transition(.opacity)
                .animation(.easeInOut, value: showingResult)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.5))
                .ignoresSafeArea()
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            HStack {
                Image(systemName: "arrow.left")
                Text("Back")
            }
        })
        .navigationTitle("Scan QR Code")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Process the scanned QR code
    private func processScannedCode(_ code: String) {
        // Find a matching room
        guard let room = DataStore.shared.rooms.first(where: { $0.qrCodeId == code }) else {
            errorMessage = "Invalid room QR code"
            checkInSuccess = false
            showingResult = true
            return
        }
        
        // Find any eligible bookings for this room
        let eligibleBookings = DataStore.shared.bookings.filter { booking in
            booking.roomId == room.id && booking.isCheckInEligible
        }
        
        if let booking = eligibleBookings.first, let index = DataStore.shared.bookings.firstIndex(where: { $0.id == booking.id }) {
            // Check in to the booking
            DataStore.shared.bookings[index].checkedIn = true
            DataStore.shared.bookings[index].checkedInTime = Date()
            
            errorMessage = nil
            checkInSuccess = true
        } else {
            // No eligible booking found
            errorMessage = "You don't have an active booking for this room within the check-in window"
            checkInSuccess = false
        }
        
        showingResult = true
    }
}
