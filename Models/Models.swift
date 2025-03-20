//
//  Models.swift
//  ubc_room_booking
//
//  Created by Deepan Chakravarthy on 2025-03-19.
//

import Foundation
import SwiftUI

struct User {
    let id: String
    let name: String
    let email: String
    var strikes: Int
    var lastStrikeReduction: Date?
    
    var canBookRoom: Bool {
        return strikes < 3
    }
}

struct Room {
    let id: String
    let name: String
    let building: String
    let floor: Int
    let capacity: Int
    let amenities: [Amenity]
    let imageName: String
    
    var location: String {
        return "\(building), Floor \(floor)"
    }
    
    // Generate a mock QR code ID for this room
    var qrCodeId: String {
        return "UBC-ROOM-\(id)-\(name.replacingOccurrences(of: " ", with: "-"))"
    }
}

enum Amenity: String, CaseIterable, Identifiable {
    case whiteboard = "Whiteboard"
    case projector = "Projector"
    case charger = "Power Outlets"
    
    var id: String { self.rawValue }
    
    var iconName: String {
        switch self {
        case .whiteboard: return "square.and.pencil"
        case .projector: return "tv"
        case .charger: return "bolt.fill"
        }
    }
}

struct TimeSlot: Identifiable {
    let id: UUID
    let startTime: Date
    let endTime: Date
    let isAvailable: Bool
    
    init(startTime: Date, endTime: Date, isAvailable: Bool) {
        // Create a deterministic ID based on the start time
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH-mm"
        let timeString = formatter.string(from: startTime)
        
        // Create a UUID using a hash of the time string
        // This ensures the same start time always produces the same UUID
        let hash = timeString.hashValue
        let uuidString = String(format: "00000000-0000-0000-0000-%012x", abs(hash) % 0x1000000000000)
        self.id = UUID(uuidString: uuidString) ?? UUID()
        
        self.startTime = startTime
        self.endTime = endTime
        self.isAvailable = isAvailable
    }
    
    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }
    
    func isConsecutiveWith(_ other: TimeSlot) -> Bool {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.minute], from: self.endTime, to: other.startTime)
        return components.minute == 0
    }
}

struct Booking: Identifiable {
    let id = UUID()
    let roomId: String
    let roomName: String
    let date: Date
    let startTime: Date
    let endTime: Date
    var checkedIn: Bool
    var checkedInTime: Date?
    var missedCheckIn: Bool = false
    var cancelled: Bool = false
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }
    
    // Check if this booking is upcoming in the next 10 minutes or currently active
    var isCheckInEligible: Bool {
        if cancelled || missedCheckIn { return false }
        
        let now = Date()
        let calendar = Calendar.current
        
        // Time until the booking starts
        let startDiff = calendar.dateComponents([.minute], from: now, to: startTime)
        
        // Time since the booking started
        let activeTime = calendar.dateComponents([.minute], from: startTime, to: now)
        
        // Eligible if within 10 mins before start or already started but not checked in and not missed
        return (startDiff.minute ?? 100) <= 10 && (startDiff.minute ?? -100) >= 0 ||
               (activeTime.minute ?? -1) >= 0 && now < endTime && !checkedIn && !missedCheckIn
    }
    
    // Check if this booking is past the check-in window and the user hasn't checked in
    var isMissedCheckIn: Bool {
        if checkedIn || missedCheckIn || cancelled { return missedCheckIn }
        
        let now = Date()
        let calendar = Calendar.current
        
        // Time since the booking started
        let activeTime = calendar.dateComponents([.minute], from: startTime, to: now)
        
        // Missed check-in if more than 10 minutes since start and not checked in
        return (activeTime.minute ?? -1) > 10
    }
    
    // Check if this booking can be cancelled without penalty
    var canCancelWithoutPenalty: Bool {
        if cancelled || checkedIn || missedCheckIn { return false }
        
        let now = Date()
        let calendar = Calendar.current
        
        // Time until the booking starts
        let startDiff = calendar.dateComponents([.hour], from: now, to: startTime)
        
        // Can cancel without penalty if more than 3 hours before start time
        return (startDiff.hour ?? 0) >= 3
    }
    
    // Check if this booking can be cancelled with penalty (strike)
    var canCancelWithPenalty: Bool {
        if cancelled || checkedIn || missedCheckIn { return false }
        
        let now = Date()
        let calendar = Calendar.current
        
        // Time until the booking starts
        let startDiff = calendar.dateComponents([.hour], from: now, to: startTime)
        let startMins = calendar.dateComponents([.minute], from: now, to: startTime)
        
        // Can cancel with penalty if less than 3 hours before start and hasn't started yet
        return (startDiff.hour ?? 0) < 3 && (startMins.minute ?? 0) > 0
    }
    
    // Check if this booking is cancellable at all
    var isCancellable: Bool {
        return !cancelled && !checkedIn && !missedCheckIn && Date() < startTime
    }
    
    // Get status text for the booking
    var statusText: String {
        if cancelled {
            return "Cancelled"
        } else if checkedIn {
            return "Checked in"
        } else if missedCheckIn {
            return "Missed"
        } else if isCheckInEligible {
            return "Check in"
        } else if Date() > endTime {
            return "Expired"
        } else {
            return "Upcoming"
        }
    }
    
    // Get status color for the booking
    var statusColor: Color {
        if cancelled {
            return .gray
        } else if checkedIn {
            return .green
        } else if missedCheckIn {
            return .red
        } else if isCheckInEligible {
            return .blue
        } else {
            return .gray
        }
    }
    
    // Get status icon for the booking
    var statusIcon: String {
        if cancelled {
            return "xmark.circle.fill"
        } else if checkedIn {
            return "checkmark.circle.fill"
        } else if missedCheckIn {
            return "exclamationmark.triangle.fill"
        } else if isCheckInEligible {
            return "qrcode.viewfinder"
        } else if Date() > endTime {
            return "clock.badge.xmark"
        } else {
            return "clock"
        }
    }
}

class DataStore {
    static let shared = DataStore()
    
    // Hold a current user
    var currentUser: User = User(
        id: "student1",
        name: "Student",
        email: "student@ubc.ca",
        strikes: 0,
        lastStrikeReduction: nil
    )
    
    let rooms: [Room] = [
        Room(id: "1", name: "MCLD 1011", building: "MacLeod", floor: 1, capacity: 4,
             amenities: [.whiteboard, .charger], imageName: "mcld_1011"),
        Room(id: "2", name: "SBME 393", building: "SBME", floor: 3, capacity: 8,
             amenities: [.whiteboard, .projector], imageName: "sbme_393"),
        Room(id: "3", name: "ESC 2021", building: "ESC", floor: 2, capacity: 20,
             amenities: [.projector, .charger], imageName: "esc_2021"),
        Room(id: "4", name: "MCLD 2011", building: "MacLeod", floor: 2, capacity: 2,
             amenities: [.charger], imageName: "mcld_2011"),
        Room(id: "5", name: "SBME 493", building: "SBME", floor: 4, capacity: 6,
             amenities: [.whiteboard, .projector, .charger], imageName: "sbme_493"),
        Room(id: "6", name: "CEME 202", building: "CEME", floor: 2, capacity: 12,
             amenities: [.whiteboard, .projector], imageName: "ceme_202")
    ]
    
    var bookings: [Booking] = []
    
    // Returns hardcoded time slots for any given date
    func getTimeSlots(for date: Date, roomId: String) -> [TimeSlot] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        var slots: [TimeSlot] = []
        let openingHour = 8 // 8 AM
        let closingHour = 22 // 10 PM
        
        for hour in openingHour..<closingHour {
            let startTime = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: startOfDay)!
            let endTime = calendar.date(bySettingHour: hour + 1, minute: 0, second: 0, of: startOfDay)!
            
            // Check if this time slot is already booked
            let isBooked = bookings.contains { booking in
                booking.roomId == roomId &&
                calendar.isDate(booking.date, inSameDayAs: date) &&
                calendar.isDate(booking.startTime, inSameDayAs: startTime) &&
                calendar.compare(booking.startTime, to: endTime, toGranularity: .hour) == .orderedAscending &&
                calendar.compare(booking.endTime, to: startTime, toGranularity: .hour) == .orderedDescending
            }
            
            // If it's already booked, mark as unavailable
            let isAvailable = !isBooked
            
            slots.append(TimeSlot(startTime: startTime, endTime: endTime, isAvailable: isAvailable))
        }
        
        return slots
    }
    
    func addBooking(roomId: String, date: Date, timeSlot: TimeSlot) {
        // Find the room name
        let roomName = rooms.first(where: { $0.id == roomId })?.name ?? "Unknown Room"
        
        // Add the booking
        let newBooking = Booking(
            roomId: roomId,
            roomName: roomName,
            date: date,
            startTime: timeSlot.startTime,
            endTime: timeSlot.endTime,
            checkedIn: false,
            checkedInTime: nil
        )
        
        bookings.append(newBooking)
    }
    
    // Mark a booking as checked in
    func checkInBooking(bookingId: UUID) -> Bool {
        guard let index = bookings.firstIndex(where: { $0.id == bookingId }) else {
            return false
        }
        
        // Verify this booking is eligible for check-in
        if bookings[index].isCheckInEligible {
            bookings[index].checkedIn = true
            bookings[index].checkedInTime = Date()
            return true
        }
        
        return false
    }
    
    // Add a strike to the current user
    func addStrike() {
        if currentUser.strikes < 5 {
            currentUser.strikes += 1
        }
    }
    
    // Reduce strikes (mock the daily reduction)
    func reduceStrikes() {
        let now = Date()
        
        // For the demo/prototype, we'll always reduce strikes when requested
        // In a real app, we would check if reduction already happened today
        
        // Reduce one strike if we have any
        if currentUser.strikes > 0 {
            currentUser.strikes -= 1
            currentUser.lastStrikeReduction = now
        }
    }
    
    // Process missed check-ins and assign strikes
    func processMissedCheckIns() {
        for index in bookings.indices {
            // If this booking has already been processed for a strike, skip it
            if bookings[index].isMissedCheckIn && !bookings[index].missedCheckIn && !bookings[index].checkedIn {
                // Mark as missed check-in instead of checked in
                bookings[index].missedCheckIn = true
                
                // Don't mark as checked in
                bookings[index].checkedIn = false
                
                // Add a strike to the user
                addStrike()
            }
        }
    }

    // Cancel a booking by ID
    func cancelBooking(bookingId: UUID) -> (success: Bool, penaltyApplied: Bool) {
        guard let index = bookings.firstIndex(where: { $0.id == bookingId }) else {
            return (false, false)
        }
        
        let booking = bookings[index]
        
        // Can't cancel if already checked in, missed, or cancelled
        if booking.checkedIn || booking.missedCheckIn || booking.cancelled {
            return (false, false)
        }
        
        // Can't cancel if the booking has already started
        if Date() > booking.startTime {
            return (false, false)
        }
        
        // Check if cancellation will incur a penalty (less than 3 hours before start)
        let penaltyApplied = booking.canCancelWithPenalty
        
        // Apply penalty if needed
        if penaltyApplied {
            addStrike()
        }
        
        // Mark the booking as cancelled
        bookings[index].cancelled = true
        
        return (true, penaltyApplied)
    }

    // Simulate cancellation functions for testing
    func simulateCancellationScenarios() {
        // Get the first room for our test bookings
        guard let firstRoom = rooms.first else { return }
        
        let calendar = Calendar.current
        let now = Date()
        
        // 1. Booking that can be cancelled without penalty (4 hours from now)
        let noPenaltyStartTime = calendar.date(byAdding: .hour, value: 4, to: now)!
        let noPenaltyEndTime = calendar.date(byAdding: .hour, value: 5, to: noPenaltyStartTime)!
        
        let noPenaltyBooking = Booking(
            roomId: firstRoom.id,
            roomName: firstRoom.name,
            date: noPenaltyStartTime,
            startTime: noPenaltyStartTime,
            endTime: noPenaltyEndTime,
            checkedIn: false,
            checkedInTime: nil,
            missedCheckIn: false,
            cancelled: false
        )
        
        // 2. Booking that can be cancelled with penalty (2 hours from now)
        let penaltyStartTime = calendar.date(byAdding: .hour, value: 2, to: now)!
        let penaltyEndTime = calendar.date(byAdding: .hour, value: 1, to: penaltyStartTime)!
        
        let penaltyBooking = Booking(
            roomId: firstRoom.id,
            roomName: firstRoom.name,
            date: penaltyStartTime,
            startTime: penaltyStartTime,
            endTime: penaltyEndTime,
            checkedIn: false,
            checkedInTime: nil,
            missedCheckIn: false,
            cancelled: false
        )
        
        // 3. Booking that has already started (can't be cancelled)
        let startedStartTime = calendar.date(byAdding: .minute, value: -15, to: now)!
        let startedEndTime = calendar.date(byAdding: .hour, value: 1, to: startedStartTime)!
        
        let startedBooking = Booking(
            roomId: firstRoom.id,
            roomName: firstRoom.name,
            date: startedStartTime,
            startTime: startedStartTime,
            endTime: startedEndTime,
            checkedIn: false,
            checkedInTime: nil,
            missedCheckIn: false,
            cancelled: false
        )
        
        // Add all test bookings
        bookings.append(noPenaltyBooking)
        bookings.append(penaltyBooking)
        bookings.append(startedBooking)
    }
}
