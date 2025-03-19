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
                    VStack(alignment: .leading, spacing: 8) {
                        Text(room.name)
                            .font(.headline)
                        
                        Text(room.location)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // Amenities icons
                        HStack {
                            ForEach(room.amenities) { amenity in
                                Image(systemName: amenity.iconName)
                                    .foregroundColor(.blue)
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
