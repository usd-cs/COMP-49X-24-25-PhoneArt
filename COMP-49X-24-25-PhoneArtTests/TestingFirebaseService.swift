//
//  TestingFirebaseService.swift
//  COMP-49X-24-25-PhoneArtTests
//
//  Created by Aditya Prakash on 11/21/24
//


import Foundation
import FirebaseFirestore
import FirebaseCore
import UIKit
import SwiftUI
@testable import COMP_49X_24_25_PhoneArt


// MARK: - Firebase Test Setup


/// Class for managing Firebase test environment
/// Provides access to a separate test collection to avoid polluting production data
class FirebaseTestSetup {
   // Singleton instance
   static let shared = FirebaseTestSetup()
  
   // Database references - made fileprivate to allow access within this file
   fileprivate let db = Firestore.firestore()
  
   // Test collection name - separate from production "artwork" collection
   let testCollection = "TestArtwork"
  
   // List of test device IDs for cleanup
   private var testDeviceIds: Set<String> = []
  
   init() {
       // Ensure Firebase is initialized
       if FirebaseApp.app() == nil {
           FirebaseApp.configure()
       }
   }
  
   /// Check if the test collection is accessible
   func isTestCollectionAccessible() async -> Bool {
       do {
           // Try a simple read operation to verify access
           let _ = try await db.collection(testCollection).limit(to: 1).getDocuments()
           return true
       } catch {
           return false
       }
   }
  
   /// Create a test piece in the test collection
   /// Returns the document ID of the created test piece
   func createTestPiece(deviceId: String, artworkString: String, title: String? = nil) async throws -> String {
       // Track this device ID for cleanup
       testDeviceIds.insert(deviceId)
      
       // Generate timestamp
       let timestamp = Timestamp(date: Date())
      
       // Create document data with the test artwork
       var data: [String: Any] = [
           "artworkData": artworkString,
           "timestamp": timestamp
       ]
      
       // Add title if provided
       if let title = title {
           data["title"] = title
       }
      
       // Create a document reference in the test collection
       let deviceRef = db.collection(testCollection).document(deviceId)
       let pieceRef = deviceRef.collection("pieces").document()
      
       // Save the test artwork
       try await pieceRef.setData(data)
      
       return pieceRef.documentID
   }
  
   /// Clean up all test data created during testing
   func cleanupTestData() async {
       // Loop through registered test device IDs and delete their documents
       for deviceId in testDeviceIds {
           do {
               // Get all pieces for this device
               let piecesRef = db.collection(testCollection).document(deviceId).collection("pieces")
               let pieces = try await piecesRef.getDocuments()
              
               // Delete each piece
               for document in pieces.documents {
                   try await document.reference.delete()
               }
              
               // Delete the device document
               try await db.collection(testCollection).document(deviceId).delete()
           } catch {
               // Silent error handling for cleanup
           }
       }
      
       // Clear the set of test device IDs
       testDeviceIds.removeAll()
   }
  
   /// Get artwork from the test collection for a specific device
   func getTestArtwork(for deviceId: String) async throws -> [ArtworkData] {
       let deviceRef = db.collection(testCollection).document(deviceId)
       let piecesCollection = deviceRef.collection("pieces")
       let snapshot = try await piecesCollection.getDocuments()
      
       var artworks: [ArtworkData] = []
      
       for document in snapshot.documents {
           let data = document.data()
          
           guard let artworkString = data["artworkData"] as? String,
                 let timestamp = data["timestamp"] as? Timestamp else {
               continue
           }
          
           let title = data["title"] as? String
          
           // Create ArtworkData object with correct parameters
           let artworkData = ArtworkData(
               deviceId: deviceId,
               artworkString: artworkString,
               timestamp: timestamp.dateValue(),  // Convert Timestamp to Date
               title: title
           )
          
           artworks.append(artworkData)
       }
      
       return artworks
   }
  
   /// Get all test artworks from the test collection
   func getAllTestArtworks() async throws -> [ArtworkData] {
       let snapshot = try await db.collection(testCollection).getDocuments()
       var allArtworks: [ArtworkData] = []
      
       for deviceDoc in snapshot.documents {
           let deviceId = deviceDoc.documentID
           let artworks = try await getTestArtwork(for: deviceId)
           allArtworks.append(contentsOf: artworks)
       }
      
       return allArtworks
   }
}


// MARK: - Testing Firebase Service


/// A Testing-specific implementation of Firebase service that writes to a separate
/// "TestArtwork" collection to avoid polluting production data
class TestingFirebaseService {
   // Use the FirebaseTestSetup singleton for database operations
   private let firebaseTestSetup = FirebaseTestSetup.shared
  
   // Flag to determine if we're in offline mock mode (for when Firebase isn't available)
   private var isOfflineMockMode: Bool
  
   // Last saved artwork string for verification
   private var lastSavedArtworkString: String?
   private var lastSavedTitle: String?
  
   // Flag to track if permission check has been completed
   private var permissionsChecked: Bool = false
  
   init(offlineMockMode: Bool = false) {
       self.isOfflineMockMode = offlineMockMode
      
       if offlineMockMode {
           self.permissionsChecked = true
       }
   }
  
   // Check if we have Firebase permissions, and fall back to mock mode if not
   private func checkFirebasePermissions() async {
       // Only check permissions once
       if permissionsChecked {
           return
       }
      
       let isAccessible = await firebaseTestSetup.isTestCollectionAccessible()
       if !isAccessible {
           self.isOfflineMockMode = true
       }
      
       permissionsChecked = true
   }
  
   // Get unique device identifier with test prefix
   private func getDeviceId() -> String {
       var deviceId = "TEST_"
       if let realDeviceId = UIDevice.current.identifierForVendor?.uuidString {
           deviceId += realDeviceId
       } else {
           deviceId += UUID().uuidString
       }
       return deviceId
   }
  
   // Save artwork data to testing collection
   func saveArtwork(artworkData: String, title: String? = nil) async throws {
       // Store the last saved data for verification
       self.lastSavedArtworkString = artworkData
       self.lastSavedTitle = title
      
       // Make sure permissions have been checked before proceeding
       if !permissionsChecked {
           await checkFirebasePermissions()
       }
      
       // If we're in offline mock mode, just return
       if isOfflineMockMode {
           return
       }
      
       // Otherwise proceed with Firebase using the test collection
       let deviceId = getDeviceId()
      
       do {
           // Create test piece using the FirebaseTestSetup
           let _ = try await firebaseTestSetup.createTestPiece(
               deviceId: deviceId,
               artworkString: artworkData,
               title: title
           )
       } catch {
           // If we get an error, switch to offline mode and retry
           self.isOfflineMockMode = true
       }
   }
  
   // Clean up all test data
   func cleanupTestData() async {
       // If we're in offline mock mode, just clear the stored data
       if isOfflineMockMode {
           lastSavedArtworkString = nil
           lastSavedTitle = nil
           return
       }
      
       // Otherwise use the FirebaseTestSetup to clean up
       await firebaseTestSetup.cleanupTestData()
   }
  
   // Add error handling and user feedback
   @MainActor
   func saveArtworkWithFeedback(artworkData: String, title: String? = nil) async -> (success: Bool, message: String) {
       do {
           try await saveArtwork(artworkData: artworkData, title: title)
           return (true, isOfflineMockMode ?
                  "Test artwork saved to mock storage" :
                  "Test artwork saved to Firebase collection: \(firebaseTestSetup.testCollection)")
       } catch {
           // If we're not already in offline mock mode, switch to it and try again
           if !isOfflineMockMode {
               isOfflineMockMode = true
               return await saveArtworkWithFeedback(artworkData: artworkData, title: title)
           }
          
           return (false, "Failed to save test artwork: \(error.localizedDescription)")
       }
   }
  
   // Helper to access the FirebaseTestSetup instance for direct cleanup
   func getFirebaseTestSetup() -> FirebaseTestSetup? {
       return firebaseTestSetup
   }
  
   // Utility method to get the last saved artwork info for verification
   func getLastSavedArtworkInfo() -> (artworkString: String?, title: String?) {
       return (lastSavedArtworkString, lastSavedTitle)
   }
  
   // Convert canvas elements to artwork string representation
   // Using the same format as ArtworkData.createArtworkString
   func generateArtworkString(from elements: [CanvasElement]) -> String {
       // Extract dominant shape type based on most frequent element
       let shapeType = getDominantShapeType(from: elements)
      
       // Default values for required parameters
       let rotation = 0.0
       let scale = 1.0
       let layer = Double(elements.count)
       let skewX = 0.0
       let skewY = 0.0
       let spread = 0.0
       let horizontal = 0.0
       let vertical = 0.0
       let primitive = 1.0
      
       // Extract unique colors from elements
       var colorSet = Set<Color>()
       for element in elements {
           colorSet.insert(element.strokeColor)
           colorSet.insert(element.fillColor)
       }
       let colorPresets = Array(colorSet)
      
       // Background is white by default
       let backgroundColor = Color.white
      
       // Generate artwork string using same format as ArtworkData
       return ArtworkData.createArtworkString(
           shapeType: shapeType,
           rotation: rotation,
           scale: scale,
           layer: layer,
           skewX: skewX,
           skewY: skewY,
           spread: spread,
           horizontal: horizontal,
           vertical: vertical,
           primitive: primitive,
           colorPresets: colorPresets,
           backgroundColor: backgroundColor,
           useDefaultRainbowColors: false,
           rainbowStyle: 0,
           hueAdjustment: 0.0,
           saturationAdjustment: 0.0,
           numberOfVisiblePresets: 5,
           strokeColor: .black,
           strokeWidth: 1.0,
           shapeAlpha: 1.0
       )
   }
  
   // Determine the most frequent shape type
   private func getDominantShapeType(from elements: [CanvasElement]) -> ShapesPanel.ShapeType {
       var shapeCounts: [ShapesPanel.ShapeType: Int] = [:]
      
       for element in elements {
           let shapeType: ShapesPanel.ShapeType
          
           if element is CircleElement {
               shapeType = .circle
           } else if element is RectangleElement {
               shapeType = .square
           } else if element is TriangleElement {
               shapeType = .triangle
           } else {
               // Default to circle if unknown
               shapeType = .circle
           }
          
           shapeCounts[shapeType, default: 0] += 1
       }
      
       // Find the shape with the highest count
       return shapeCounts.max(by: { $0.value < $1.value })?.key ?? .circle
   }
}
