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
    #if DEBUG
    static var shared = FirebaseService() // Make it mutable for testing
    #else
    static let shared = FirebaseService()
    #endif
    private let db = Firestore.firestore()
    
    // Get unique device identifier - make internal so CanvasView can access it when creating ArtworkData
    internal func getDeviceId() -> String {
        if let deviceId = UIDevice.current.identifierForVendor?.uuidString {
            return deviceId
        }
        return UUID().uuidString
    }
    
    // Save artwork data with proper collection/document structure
    func saveArtwork(artworkData: String, title: String? = nil) async throws -> (DocumentReference?, Bool, [ArtworkData]) {
        let deviceId = getDeviceId()
        
        // First, ensure the device document exists
        let deviceRef = db.collection("artwork").document(deviceId)
        
        // Update the device document
        try await deviceRef.setData([
            "deviceId": deviceId,
            "lastUpdated": Timestamp(date: Date())
        ], merge: true)
        
        // Check if user already has 12 artworks
        let artworkLimit = 12
        let snapshot = try await deviceRef
            .collection("pieces")
            .order(by: "timestamp", descending: true) // Order by newest first for displaying
            .getDocuments()
        
        let existingArtworks = snapshot.documents.compactMap { document in
            try? document.data(as: ArtworkData.self)
        }
        
        // If at the limit, return information so UI can ask user what to do
        if existingArtworks.count >= artworkLimit {
            return (nil, true, existingArtworks)
        }
        
        // Not at limit, proceed with normal save
        let pieceRef = try await deviceRef
            .collection("pieces")
            .addDocument(data: [
                "deviceId": deviceId,
                "artworkString": artworkData,
                "timestamp": Timestamp(date: Date()),
                "title": title as Any,
                "pieceId": "" // Placeholder, will be updated below
            ])
        
        // Update the newly created document to include its own ID as a field
        try await pieceRef.updateData(["pieceId": pieceRef.documentID])
        
        print("Successfully saved artwork piece with ID: \(pieceRef.documentID) and added pieceId field.")
        
        // Decode and print the artwork string values
        print("\nDecoding saved artwork:")
        decodeArtworkString(artworkData)
        
        return (pieceRef, false, [])
    }
    
    /// Updates an existing artwork document in Firestore.
    /// - Parameters:
    ///   - artwork: The ArtworkData object containing the deviceId and pieceId of the document to update.
    ///   - newArtworkString: The new artwork string to save.
    /// - Throws: An error if the update fails or if the artwork is missing necessary IDs.
    func updateArtwork(artwork: ArtworkData, newArtworkString: String) async throws {
        guard let pieceId = artwork.pieceId else {
            throw NSError(domain: "FirebaseService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Missing pieceId for update"])
        }
        
        let deviceId = artwork.deviceId // Use the deviceId from the loaded artwork
        let pieceRef = db.collection("artwork").document(deviceId).collection("pieces").document(pieceId)
        
        // Update specific fields: artworkString and timestamp
        // Keep original deviceId, pieceId, and title (unless title update is desired)
        try await pieceRef.updateData([
            "artworkString": newArtworkString,
            "timestamp": Timestamp(date: Date())
        ])
        
        print("Successfully updated artwork piece with ID: \(pieceId)")
        print("\nDecoding updated artwork:")
        decodeArtworkString(newArtworkString)
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
    func saveArtworkWithFeedback(artworkData: String, title: String? = nil) async -> (success: Bool, message: String, isGalleryFull: Bool, existingArtworks: [ArtworkData]) {
        do {
            // Try to save the artwork
            let (_, isGalleryFull, existingArtworks) = try await saveArtwork(artworkData: artworkData, title: title)
            
            // Check if gallery is full
            if isGalleryFull {
                return (false, "Gallery is full. You've reached the limit of 12 artworks. Please select an artwork to replace.", true, existingArtworks)
            } else {
                return (true, "Artwork saved successfully!", false, [])
            }
        } catch {
            print("Error saving artwork: \(error)")
            return (false, "Failed to save artwork: \(error.localizedDescription)", false, [])
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
            _ = try await db.collection("artwork")
                .document(deviceId)
                .collection("pieces")
                .getDocuments()
            
            // print("\n=== All saved pieces ===")
            // for doc in snapshot.documents {
            //     print("Piece ID: \(doc.documentID)")
            //     print("Data: \(doc.data())")
            //     print("---")
            // }
        } catch {
            // print("Error listing pieces:", error)
        }
    }
    
    func decodeArtworkString(_ artworkString: String) {
        let pairs = artworkString.components(separatedBy: ";")
        // print("\n=== Decoded Artwork Values ===")
        
        for pair in pairs {
            let keyValue = pair.components(separatedBy: ":")
            if keyValue.count == 2 {
                let key = keyValue[0]
                let _ = keyValue[1]
                
                switch key {
                case "shape":
                    // print("Shape Type: \(value)")
                    break
                case "rotation":
                    // print("Rotation: \(value)°")
                    break
                case "scale":
                    // print("Scale: \(value)x")
                    break
                case "layer":
                    // print("Layer Count: \(value)")
                    break
                case "skewX":
                    // print("Skew X: \(value)%")
                    break
                case "skewY":
                    // print("Skew Y: \(value)%")
                    break
                case "spread":
                    // print("Spread: \(value)")
                    break
                case "horizontal":
                    // print("Horizontal Offset: \(value)")
                    break
                case "vertical":
                    // print("Vertical Offset: \(value)")
                    break
                case "colors":
                    // let colors = value.components(separatedBy: ",")
                    // print("Color Presets:")
                    // for (index, color) in colors.enumerated() {
                    //     print("  Color \(index + 1): \(color)")
                    // }
                    break
                case "background":
                    // print("Background Color: \(value)")
                    break
                default:
                    // print("Other parameter - \(key): \(value)")
                    break
                }
            }
        }
        // print("===========================")
    }
    
    // Function to fetch a specific artwork piece by its ID using a collection group query
       func getArtworkPiece(pieceId: String) async throws -> ArtworkData? {
           let querySnapshot = try await db.collectionGroup("pieces")
                                         .whereField("pieceId", isEqualTo: pieceId)
                                         .limit(to: 1) // Should only be one match
                                         .getDocuments()


           guard let document = querySnapshot.documents.first else {
               print("No document found with pieceId: \(pieceId)")
               return nil
           }


           // Assuming the document structure includes deviceId to reconstruct the path
           guard let deviceId = document.data()["deviceId"] as? String else {
                print("Document \(pieceId) missing deviceId field.")
                throw NSError(domain: "FirebaseService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Artwork data missing deviceId."])
           }


           // Optionally, you could directly decode here if needed, but often just confirming existence is enough
           // Or, fetch the full document data if required
           let pieceRef = db.collection("artwork").document(deviceId).collection("pieces").document(pieceId)
           let fullDoc = try await pieceRef.getDocument()
           return try? fullDoc.data(as: ArtworkData.self)
       }


       // Function to update the title of an existing artwork piece
       func updateArtworkTitle(artwork: ArtworkData, newTitle: String) async throws {
           guard let pieceId = artwork.pieceId else {
               throw NSError(domain: "FirebaseService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Missing pieceId for update"])
           }
          
           let deviceId = artwork.deviceId
           let pieceRef = db.collection("artwork").document(deviceId).collection("pieces").document(pieceId)
          
           try await pieceRef.updateData(["title": newTitle])
           print("Successfully updated title for artwork piece with ID: \(pieceId) to '\(newTitle)'")
       }


       // Function to delete an artwork piece
       func deleteArtwork(artwork: ArtworkData) async throws {
           guard let pieceId = artwork.pieceId else {
               throw NSError(domain: "FirebaseService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Missing pieceId for deletion"])
           }
          
           let deviceId = artwork.deviceId
           let pieceRef = db.collection("artwork").document(deviceId).collection("pieces").document(pieceId)
          
           try await pieceRef.delete()
           print("Successfully deleted artwork piece with ID: \(pieceId)")
       }

    // Function to delete all artworks for the current device (for testing purposes)
    func deleteAllArtworks() async throws {
        let deviceId = getDeviceId()
        let deviceRef = db.collection("artwork").document(deviceId)
        
        // Get all pieces
        let snapshot = try await deviceRef
            .collection("pieces")
            .getDocuments()
        
        // Delete each piece
        for document in snapshot.documents {
            try await deviceRef.collection("pieces").document(document.documentID).delete()
            print("Deleted artwork: \(document.documentID)")
        }
        
        print("Successfully deleted all \(snapshot.count) artworks")
    }
    
    // Save artwork when gallery is full by replacing a specific artwork
    func saveArtworkReplacing(artworkData: String, title: String?, replacingArtwork: ArtworkData) async throws -> DocumentReference {
        guard let pieceIdToReplace = replacingArtwork.pieceId else {
            throw NSError(domain: "FirebaseService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Missing pieceId for artwork being replaced"])
        }
        
        let deviceId = getDeviceId()
        let deviceRef = db.collection("artwork").document(deviceId)
        
        // Delete the artwork being replaced
        try await deviceRef.collection("pieces").document(pieceIdToReplace).delete()
        print("Deleted artwork with ID: \(pieceIdToReplace) to make room for new artwork")
        
        // Create a new document in the pieces subcollection
        let pieceRef = try await deviceRef
            .collection("pieces")
            .addDocument(data: [
                "deviceId": deviceId,
                "artworkString": artworkData,
                "timestamp": Timestamp(date: Date()),
                "title": title as Any,
                "pieceId": "" // Placeholder, will be updated below
            ])
        
        // Update the newly created document to include its own ID as a field
        try await pieceRef.updateData(["pieceId": pieceRef.documentID])
        
        print("Successfully saved replacement artwork piece with ID: \(pieceRef.documentID) and added pieceId field.")
        
        // Decode and print the artwork string values
        print("\nDecoding saved artwork:")
        decodeArtworkString(artworkData)
        
        return pieceRef
    }
}


// Extension for safer dictionary access (optional but good practice)
extension Dictionary where Key == String, Value == Any {
   func string(forKey key: String) -> String? {
       return self[key] as? String
   }
}

