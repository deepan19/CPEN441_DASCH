//
//  RoomDetailView.swift
//  ubc_room_booking
//
//  Created by Deepan Chakravarthy on 2025-03-19.
//

import SwiftUI

struct RoomDetailView: View {
    let room: Room
    @State private var selectedDate = Date()
    @State private var selectedTimeSlots: Set<UUID> = []  // Track multiple selected slots by ID
    @State private var showingBookingConfirmation = false
    @State private var bookingSuccess = false
    
    // Get time slots from DataStore with controlled availability
    var timeSlots: [TimeSlot] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        
        var slots: [TimeSlot] = []
        let openingHour = 8 // 8 AM
        let closingHour = 22 // 10 PM
        
        for hour in openingHour..<closingHour {
            let startTime = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: startOfDay)!
            let endTime = calendar.date(bySettingHour: hour + 1, minute: 0, second: 0, of: startOfDay)!
            
            // Make every third slot unavailable for demo purposes
            let isAvailable = (hour % 3 != 0)
            
            // Also check if there's an existing booking in DataStore
            let isBooked = DataStore.shared.bookings.contains { booking in
                booking.roomId == room.id &&
                calendar.isDate(booking.date, inSameDayAs: selectedDate) &&
                calendar.isDate(booking.startTime, inSameDayAs: startTime)
            }
            
            slots.append(TimeSlot(
                startTime: startTime,
                endTime: endTime,
                isAvailable: isAvailable && !isBooked
            ))
        }
        
        return slots
    }
    
    // Get only the selected time slots
    var selectedSlots: [TimeSlot] {
        return timeSlots.filter { selectedTimeSlots.contains($0.id) }
            .sorted { $0.startTime < $1.startTime }
    }
    
    // Modified validation - simply check if any slots are selected
    var hasValidSelection: Bool {
        return !selectedSlots.isEmpty
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Room image
                ZStack(alignment: .bottomLeading) {
                    // Room image with proper sizing
                    Image(room.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                    
                    // Capacity badge
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                        
                        Text("\(room.capacity)")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(15)
                    .padding(12)
                }
                .padding(.horizontal)
                
                // Room details
                VStack(alignment: .leading, spacing: 10) {
                    Text(room.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(room.location)
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    // Amenities
                    Text("Amenities")
                        .font(.headline)
                        .padding(.top, 5)
                    
                    HStack(spacing: 10) {
                        ForEach(room.amenities) { amenity in
                            HStack {
                                Image(systemName: amenity.iconName)
                                Text(amenity.rawValue)
                            }
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Date selection
                VStack(alignment: .leading) {
                    Text("Select Date")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    DatePicker("", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .labelsHidden()
                        .padding(.horizontal)
                        .onChange(of: selectedDate) { _ in
                            // Clear selection when date changes
                            selectedTimeSlots.removeAll()
                        }
                }
                
                // Time slots
                VStack(alignment: .leading) {
                    HStack {
                        Text("Available Time Slots")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("Select any available time slots")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    if timeSlots.filter({ $0.isAvailable }).isEmpty {
                        Text("No time slots available for this date")
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 10) {
                            ForEach(timeSlots) { slot in
                                // Use the TimeSlotCell component
                                TimeSlotCell(
                                    slot: slot,
                                    isSelected: selectedTimeSlots.contains(slot.id),
                                    onTap: {
                                        handleTimeSlotSelection(slot)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Book button
                Button(action: {
                    showingBookingConfirmation = true
                }) {
                    Text("Book Room")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(hasValidSelection ? Color.blue : Color.gray)
                        .cornerRadius(8)
                }
                .disabled(!hasValidSelection)
                .padding()
            }
        }
        .navigationTitle("Room Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Confirm Booking", isPresented: $showingBookingConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Book") {
                if hasValidSelection {
                    // Create separate bookings for each selected time slot
                    for slot in selectedSlots {
                        DataStore.shared.addBooking(
                            roomId: room.id,
                            date: selectedDate,
                            timeSlot: slot
                        )
                    }
                    
                    bookingSuccess = true
                }
            }
        } message: {
            Text("Book \(room.name) for \(formattedBookingTime)")
        }
        .alert("Booking Confirmed", isPresented: $bookingSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your room has been booked successfully.")
        }
    }
    
    // Handle time slot selection
    private func handleTimeSlotSelection(_ slot: TimeSlot) {
        if !slot.isAvailable { return }
        
        if selectedTimeSlots.contains(slot.id) {
            // If already selected, unselect it
            selectedTimeSlots.remove(slot.id)
        } else {
            // If not selected, add it to the selection
            selectedTimeSlots.insert(slot.id)
        }
    }
    
    // Format the booking time for display in confirmation
    private var formattedBookingTime: String {
        guard !selectedSlots.isEmpty else {
            return "No time selected"
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d, yyyy"
        let dateStr = dateFormatter.string(from: selectedDate)
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        
        // Join all selected time slots
        let timeSlotTexts = selectedSlots.map {
            "\(timeFormatter.string(from: $0.startTime)) - \(timeFormatter.string(from: $0.endTime))"
        }.joined(separator: ", ")
        
        return "\(dateStr): \(timeSlotTexts)"
    }
}
