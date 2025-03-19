//
//  MyBookingsView.swift
//  ubc_room_booking
//
//  Created by Deepan Chakravarthy on 2025-03-19.
//

import SwiftUI

struct MyBookingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var bookings = DataStore.shared.bookings
    
    var body: some View {
        NavigationView {
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
                        
                        Button("Close") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .padding(.top, 20)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(bookings) { booking in
                            VStack(alignment: .leading, spacing: 5) {
                                Text(booking.roomName)
                                    .font(.headline)
                                
                                Text(booking.formattedDate)
                                    .font(.subheadline)
                                
                                Text(booking.formattedTime)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 5)
                        }
                    }
                }
            }
            .navigationTitle("My Bookings")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear {
                // Refresh the bookings list when the view appears
                bookings = DataStore.shared.bookings
            }
        }
    }
}
