//
//  QRCodeGenerator.swift
//  ubc_room_booking
//
//  Created by Deepan Chakravarthy on 2025-03-19.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeGenerator: View {
    let room: Room
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Scan to Check In")
                .font(.title)
                .fontWeight(.bold)
            
            Text(room.name)
                .font(.headline)
            
            Image(uiImage: generateQRCode(from: room.qrCodeId))
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 250, height: 250)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 5)
            
            Text("Room ID: \(room.qrCodeId)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    // Generate a QR code image from a string
    func generateQRCode(from string: String) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        filter.message = Data(string.utf8)
        filter.correctionLevel = "H" // High error correction
        
        if let outputImage = filter.outputImage {
            // Scale the image
            let scale = 10.0
            let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        
        // Return a placeholder if generation fails
        return UIImage(systemName: "qrcode") ?? UIImage()
    }
}
