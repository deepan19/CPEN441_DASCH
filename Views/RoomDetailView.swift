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
    @State private var selectedTimeSlots: Set<UUID> = []
    @State private var showingBookingConfirmation = false
    @State private var bookingSuccess = false
    @State private var refreshToggle = false
    
    // Set min date to today and max date to 4 weeks from now
    private var minDate: Date {
        return Calendar.current.startOfDay(for: Date())
    }
    
    private var maxDate: Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: 28, to: minDate)!
    }
    
    // Initialize selectedDate to today when the view is created
    init(room: Room) {
        self.room = room
        let today = Calendar.current.startOfDay(for: Date())
        _selectedDate = State(initialValue: today)
    }
    
    // Get time slots from DataStore with controlled availability
    var timeSlots: [TimeSlot] {
        // This is just to force SwiftUI to recalculate when refreshToggle changes
        let _ = refreshToggle
        
        return DataStore.shared.getTimeSlots(for: selectedDate, roomId: room.id)
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
                // Room image section (unchanged)
                ZStack(alignment: .bottomLeading) {
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
                
                // Room details section (unchanged)
                VStack(alignment: .leading, spacing: 10) {
                    Text(room.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(room.location)
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
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
                
                // Date selection - WITH UPDATED DATE RANGE
                VStack(alignment: .leading) {
                    HStack {
                        Text("Select Date")
                            .font(.headline)
                        
                        Spacer()
                        
                        // Add a helper text to show booking window
                        Text("Next 4 weeks only")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    DatePicker("", selection: $selectedDate, in: minDate...maxDate, displayedComponents: .date)
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .labelsHidden()
                        .padding(.horizontal)
                        .onChange(of: selectedDate) { _ in
                            // Clear selection when date changes
                            selectedTimeSlots.removeAll()
                        }
                }
                
                // Time slots section (unchanged)
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
                    
                    let availableSlots = timeSlots.filter({ $0.isAvailable })
                    if availableSlots.isEmpty {
                        Text("No time slots available for this date")
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 10) {
                            ForEach(timeSlots) { slot in
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
                
                // Book button (unchanged)
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
                    
                    // Clear selected slots after booking
                    selectedTimeSlots.removeAll()
                    
                    // Toggle refresh to update the UI
                    refreshToggle.toggle()
                    
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
    
    // Methods remain unchanged
    private func handleTimeSlotSelection(_ slot: TimeSlot) {
        if !slot.isAvailable { return }
        
        if selectedTimeSlots.contains(slot.id) {
            selectedTimeSlots.remove(slot.id)
        } else {
            selectedTimeSlots.insert(slot.id)
        }
    }
    
    private var formattedBookingTime: String {
        guard !selectedSlots.isEmpty else {
            return "No time selected"
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d, yyyy"
        let dateStr = dateFormatter.string(from: selectedDate)
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        
        let timeSlotTexts = selectedSlots.map {
            "\(timeFormatter.string(from: $0.startTime)) - \(timeFormatter.string(from: $0.endTime))"
        }.joined(separator: ", ")
        
        return "\(dateStr): \(timeSlotTexts)"
    }
}
