# UBC Room Booking App

A SwiftUI application that allows University of British Columbia (UBC) students to browse, filter, and book study rooms across campus buildings.

## Features

- **User Authentication**: Simple login system for students
- **Room Browsing**: View available study rooms with details and images
- **Search & Filtering**: Find rooms by name, building, or filter by amenities
- **Booking System**: Book rooms for specific time slots on selected dates
- **Booking Management**: View and manage your room bookings

## Project Structure

```
ubc_room_booking/
├── Assets.xcassets/         # Asset catalog containing app images
│   └── RoomImages/          # Folder containing room preview images
├── ubc_room_bookingApp.swift # App entry point
├── ContentView.swift         # Main content view
├── Models/                  # Data models
│   ├── Room.swift           # Room model
│   ├── Amenity.swift        # Amenity enum
│   ├── TimeSlot.swift       # TimeSlot model
│   ├── Booking.swift        # Booking model
│   └── DataStore.swift      # Shared data store
├── Views/                   # UI Views
│   ├── LoginView.swift      # Login screen
│   ├── RoomListView.swift   # Room listing screen
│   ├── RoomDetailView.swift # Room details and booking
│   ├── FilterView.swift     # Amenity filtering
│   ├── MyBookingsView.swift # User bookings management
│   └── TimeSlotCell.swift   # Time slot selection component
```

## Setup and Installation

1. Clone the repository
2. Open the project in Xcode 15.0 or later
3. Add room images to the asset catalog:
   - Open Assets.xcassets
   - Create a folder named "RoomImages"
   - Add image sets for each room (e.g., "room_iccs246")
   - Add images to these sets
4. Build and run the application on iOS 15.0 or later

## Adding Room Images

Room images should be added to the asset catalog:

1. Open Assets.xcassets in Xcode
2. Create a new folder named "RoomImages"
3. Inside this folder, create a new Image Set for each room
4. Name each Image Set to match the room's imageName property (e.g., "room_iccs246")
5. Add the appropriate images to each set

## Room Model Structure

The Room model includes the following properties:

```swift
struct Room: Identifiable {
    let id: UUID
    let name: String
    let building: String
    let location: String
    let capacity: Int
    let amenities: [Amenity]
    let imageName: String
    
    var location: String {
        return "\(building), \(location)"
    }
}
```

## Amenities

The app supports filtering rooms by amenities:

- Projector
- Whiteboard
- Power Outlets
- Computers
- Video Conferencing
- Accessibility

## Time Slot Selection

When booking a room:

1. Select a date from the calendar
2. Choose any available time slot(s)
3. Click "Book Room" to confirm your booking

## Testing the App

For testing purposes, use:
- Username: "Student"
- Password: "password"
