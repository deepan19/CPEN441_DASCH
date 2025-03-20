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
    @State private var showingStrikeWarning = false
    @State private var bookingSuccess = false
    @State private var refreshToggle = false
    
    // Add state to track user's booking eligibility
    @State private var userCanBook: Bool = true
    
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
        _userCanBook = State(initialValue: DataStore.shared.currentUser.canBookRoom)
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
    
    // Modified validation - check if any slots are selected
    var hasValidSelection: Bool {
        return !selectedSlots.isEmpty
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Room image section
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
                
                // Room details section
                VStack(alignment: .leading, spacing: 10) {
                    // Room name and details without QR code button
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
                        ForEach(room.amenities, id: \.self) { amenity in
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
                
                // Strike warning if needed
                if !userCanBook {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        
                        Text("You have \(DataStore.shared.currentUser.strikes) strikes and cannot make new bookings.")
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                // Date selection
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
                
                // Time slots section
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
                            ForEach(timeSlots, id: \.id) { slot in
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
                    if !userCanBook {
                        showingStrikeWarning = true
                    } else {
                        showingBookingConfirmation = true
                    }
                }) {
                    Text("Book Room")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(hasValidSelection ? (userCanBook ? Color.blue : Color.gray) : Color.gray)
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
                if hasValidSelection && userCanBook {
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
        .alert("Booking Blocked", isPresented: $showingStrikeWarning) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You have \(DataStore.shared.currentUser.strikes) strikes and cannot make new bookings until your strikes are below 3.")
        }
        .alert("Booking Confirmed", isPresented: $bookingSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your room has been booked successfully. Remember to check in with the QR code within 10 minutes of your booking start time.")
        }
        .onAppear {
            // Process any missed check-ins
            DataStore.shared.processMissedCheckIns()
            
            // IMPORTANT: Update the userCanBook state when view appears
            userCanBook = DataStore.shared.currentUser.canBookRoom
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
