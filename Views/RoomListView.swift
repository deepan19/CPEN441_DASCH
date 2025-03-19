//
//  RoomListView.swift
//  ubc_room_booking
//
//  Created by Deepan Chakravarthy on 2025-03-19.
//

import SwiftUI

struct RoomListView: View {
    @State private var searchText: String = ""
    @State private var showingFilterSheet: Bool = false
    @State private var selectedAmenities: Set<Amenity> = []
    @State private var showingMyBookings: Bool = false
    
    // Get rooms from our data store
    let rooms = DataStore.shared.rooms
    
    var filteredRooms: [Room] {
        let searchFiltered = searchText.isEmpty ? rooms : rooms.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.building.localizedCaseInsensitiveContains(searchText)
        }
        
        if selectedAmenities.isEmpty {
            return searchFiltered
        } else {
            return searchFiltered.filter { room in
                selectedAmenities.allSatisfy { amenity in
                    room.amenities.contains(amenity)
                }
            }
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search rooms", text: $searchText)
                        .foregroundColor(.primary)
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // Filter button
                Button(action: {
                    showingFilterSheet = true
                }) {
                    Image(systemName: "line.horizontal.3.decrease.circle")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                }
            }
            .padding()
            
            // Selected filters display
            if !selectedAmenities.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(Array(selectedAmenities)) { amenity in
                            HStack {
                                Text(amenity.rawValue)
                                    .font(.footnote)
                                
                                Button(action: {
                                    selectedAmenities.remove(amenity)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color(.systemGray6))
                            .cornerRadius(15)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // Room list
            List(filteredRooms, id: \.id) { room in
                NavigationLink(destination: RoomDetailView(room: room)) {
                    HStack(spacing: 12) {
                        // Room thumbnail image
                        Image(room.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 60)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(room.name)
                                .font(.headline)
                            
                            Text(room.location)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            // Amenities icons
                            HStack(spacing: 8) {
                                // Capacity indicator
                                HStack(spacing: 2) {
                                    Image(systemName: "person.2.fill")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text("\(room.capacity)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                // Divider
                                Text("•")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                // Amenity icons
                                ForEach(room.amenities.prefix(3)) { amenity in
                                    Image(systemName: amenity.iconName)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                                
                                // Show +X more if there are more amenities
                                if room.amenities.count > 3 {
                                    Text("+\(room.amenities.count - 3)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
        .navigationTitle("Study Rooms")
        .navigationBarItems(
            trailing: Button(action: {
                showingMyBookings = true
            }) {
                Image(systemName: "calendar")
                    .font(.system(size: 22))
            }
        )
        .sheet(isPresented: $showingFilterSheet) {
            FilterView(selectedAmenities: $selectedAmenities)
        }
        .sheet(isPresented: $showingMyBookings) {
            MyBookingsView()
        }
    }
}
