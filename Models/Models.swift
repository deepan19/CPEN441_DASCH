//
//  Models.swift
//  ubc_room_booking
//
//  Created by Deepan Chakravarthy on 2025-03-19.
//

import Foundation

struct User {
    let id: String
    let name: String
    let email: String
}

struct Room {
    let id: String
    let name: String
    let building: String
    let floor: Int
    let capacity: Int
    let amenities: [Amenity]
    
    var location: String {
        return "\(building), Floor \(floor)"
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
}

class DataStore {
    static let shared = DataStore()
    
    let rooms: [Room] = [
        Room(id: "1", name: "Study Room 101", building: "Main Library", floor: 1, capacity: 4,
             amenities: [.whiteboard, .charger]),
        Room(id: "2", name: "Collaboration Space", building: "Student Center", floor: 2, capacity: 8,
             amenities: [.whiteboard, .projector]),
        Room(id: "3", name: "Computer Lab", building: "Engineering Building", floor: 3, capacity: 20,
             amenities: [.projector, .charger]),
        Room(id: "4", name: "Quiet Study Room", building: "Main Library", floor: 2, capacity: 2,
             amenities: [.charger]),
        Room(id: "5", name: "Group Study Room", building: "Science Center", floor: 1, capacity: 6,
             amenities: [.whiteboard, .projector, .charger]),
        Room(id: "6", name: "Conference Room A", building: "Business School", floor: 4, capacity: 12,
             amenities: [.whiteboard, .projector])
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
                endTime: timeSlot.endTime
            )
            
            bookings.append(newBooking)
        }
}
