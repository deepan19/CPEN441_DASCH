//
//  FilterView.swift
//  ubc_room_booking
//
//  Created by Deepan Chakravarthy on 2025-03-19.
//

import SwiftUI

struct FilterView: View {
    @Binding var selectedAmenities: Set<Amenity>
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Amenity.allCases) { amenity in
                    Button(action: {
                        if selectedAmenities.contains(amenity) {
                            selectedAmenities.remove(amenity)
                        } else {
                            selectedAmenities.insert(amenity)
                        }
                    }) {
                        HStack {
                            Image(systemName: amenity.iconName)
                                .foregroundColor(.blue)
                            
                            Text(amenity.rawValue)
                            
                            Spacer()
                            
                            if selectedAmenities.contains(amenity) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Filter Rooms")
            .navigationBarItems(
                leading: Button("Clear All") {
                    selectedAmenities.removeAll()
                },
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}
