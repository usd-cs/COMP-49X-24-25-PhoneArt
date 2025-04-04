//
//  FirebaseService.swift
//  COMP-49X-24-25-PhoneArt
//
//  Created by Zachary Letcher on 03/24/25.
//


import Foundation
import FirebaseFirestore
import UIKit

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    private let db = Firestore.firestore()
    
    // Get unique device identifier
    private func getDeviceId() -> String {
        if let deviceId = UIDevice.current.identifierForVendor?.uuidString {
            return deviceId
        }
        return UUID().uuidString
    }
    
    // Save artwork data with proper collection/document structure
    func saveArtwork(artworkData: String, title: String? = nil) async throws -> DocumentReference {
        let deviceId = getDeviceId()
        
        // First, ensure the device document exists
        let deviceRef = db.collection("artwork").document(deviceId)
        
        // Update the device document
        try await deviceRef.setData([
            "deviceId": deviceId,
            "lastUpdated": Timestamp(date: Date())
        ], merge: true)
        
        // Create a new document in the pieces subcollection
        let pieceRef = try await deviceRef
            .collection("pieces")
            .addDocument(data: [
                "deviceId": deviceId,
                "artworkString": artworkData,
                "timestamp": Timestamp(date: Date()),
                "title": title as Any
            ])
        
        print("Successfully saved artwork piece with ID: \(pieceRef.documentID)")
        
        // Decode and print the artwork string values
        print("\nDecoding saved artwork:")
        decodeArtworkString(artworkData)
        
        return pieceRef
    }
    
    // Get all artwork for current device
    func getArtwork() async throws -> [ArtworkData] {
        let deviceId = getDeviceId()
        let snapshot = try await db.collection("artwork")
            .document(deviceId)
            .collection("pieces")
            .order(by: "timestamp", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: ArtworkData.self)
        }
    }
    
    // Add error handling and user feedback
    @MainActor
    func saveArtworkWithFeedback(artworkData: String, title: String? = nil) async -> (success: Bool, message: String) {
        do {
            try await saveArtwork(artworkData: artworkData, title: title)
            return (true, "Artwork saved successfully!")
        } catch {
            print("Error saving artwork: \(error)")
            return (false, "Failed to save artwork: \(error.localizedDescription)")
        }
    }
    
    // Helper function to verify saved data
    func verifyLastSavedArtwork() async {
        let deviceId = getDeviceId()
        do {
            let snapshot = try await db.collection("artwork")
                .document(deviceId)
                .collection("pieces")
                .order(by: "timestamp", descending: true)
                .limit(to: 1)
                .getDocuments()
            
            if let lastDoc = snapshot.documents.first {
                print("Last saved artwork data:", lastDoc.data())
            }
        } catch {
            print("Error verifying saved artwork:", error)
        }
    }
    
    // Helper function to list all pieces for the current device
    func listAllPieces() async {
        let deviceId = getDeviceId()
        do {
            let snapshot = try await db.collection("artwork")
                .document(deviceId)
                .collection("pieces")
                .getDocuments()
            
            print("\n=== All saved pieces ===")
            for doc in snapshot.documents {
                print("Piece ID: \(doc.documentID)")
                print("Data: \(doc.data())")
                print("---")
            }
        } catch {
            print("Error listing pieces:", error)
        }
    }
    
    func decodeArtworkString(_ artworkString: String) {
        let pairs = artworkString.components(separatedBy: ";")
        print("\n=== Decoded Artwork Values ===")
        
        for pair in pairs {
            let keyValue = pair.components(separatedBy: ":")
            if keyValue.count == 2 {
                let key = keyValue[0]
                let value = keyValue[1]
                
                switch key {
                case "shape":
                    print("Shape Type: \(value)")
                case "rotation":
                    print("Rotation: \(value)°")
                case "scale":
                    print("Scale: \(value)x")
                case "layer":
                    print("Layer Count: \(value)")
                case "skewX":
                    print("Skew X: \(value)%")
                case "skewY":
                    print("Skew Y: \(value)%")
                case "spread":
                    print("Spread: \(value)")
                case "horizontal":
                    print("Horizontal Offset: \(value)")
                case "vertical":
                    print("Vertical Offset: \(value)")
                case "colors":
                    let colors = value.components(separatedBy: ",")
                    print("Color Presets:")
                    for (index, color) in colors.enumerated() {
                        print("  Color \(index + 1): \(color)")
                    }
                case "background":
                    print("Background Color: \(value)")
                default:
                    print("Other parameter - \(key): \(value)")
                }
            }
        }
        print("===========================")
    }
} 
