//
//  TimeSlotCell.swift
//  ubc_room_booking
//
//  Created by Deepan Chakravarthy on 2025-03-19.
//

import SwiftUI

struct TimeSlotCell: View {
    let slot: TimeSlot
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(slot.formattedTimeRange)
                    .font(.subheadline)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding(10)
            .background(backgroundColor)
            .foregroundColor(textColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle()) // This prevents the default button animation
        .disabled(!slot.isAvailable)
    }
    
    private var backgroundColor: Color {
        if !slot.isAvailable {
            return Color(.systemGray4)
        }
        return isSelected ? Color.blue.opacity(0.15) : Color(.systemGray6)
    }
    
    private var textColor: Color {
        if !slot.isAvailable {
            return Color(.systemGray)
        }
        return isSelected ? Color.blue : Color.primary
    }
}
