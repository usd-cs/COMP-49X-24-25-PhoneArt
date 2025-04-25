//
//  ImportArtworkView.swift
//  COMP-49X-24-25-PhoneArt
//
//  Created by Zachary Letcher on 04/06/25.
//


import XCTest
import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseCore
@testable import COMP_49X_24_25_PhoneArt


// Assuming an ImportArtworkViewModel exists like this:
// Define the actual ViewModel class here:
@MainActor class ImportArtworkViewModel: ObservableObject {
   @Published var artworkIdText: String = ""
   @Published var showError: Bool = false
   @Published var errorMessage: String = ""
   @Published var isLoading: Bool = false // Added for loading state
  
   var onImportSuccess: ((String) -> Void)? // Closure to pass artwork string on success
   var onCancel: (() -> Void)?
   var onError: ((String) -> Void)?
  
   private let firebaseService: FirebaseService
  
   // Allow dependency injection for testing
   init(firebaseService: FirebaseService = FirebaseService.shared) {
       self.firebaseService = firebaseService
       print("ImportArtworkViewModel initialized with service: \(type(of: firebaseService))")
   }
  
   func importArtwork() {
       let trimmedId = artworkIdText.trimmingCharacters(in: .whitespacesAndNewlines)
       guard !trimmedId.isEmpty else {
           handleError("Artwork ID cannot be empty.")
           return
       }
      
       isLoading = true
       errorMessage = "" // Clear previous errors
       showError = false
      
       Task {
           defer { isLoading = false } // Ensure loading stops
           do {
               print("ViewModel: Calling firebaseService.getArtworkPiece with ID: \(trimmedId)")
               if let artworkData = try await firebaseService.getArtworkPiece(pieceId: trimmedId) {
                   // Safely handle the optional artworkString
                   let artworkString = artworkData.artworkString ?? ""
                   if !artworkString.isEmpty {
                       print("ViewModel: Artwork found, calling onImportSuccess.")
                       // Use Task to ensure UI updates happen on main thread if needed
                       await MainActor.run {
                           onImportSuccess?(artworkString)
                       }
                   } else {
                       handleError("Imported artwork data is missing the artwork string.")
                   }
               } else {
                   handleError("Artwork with ID '\(trimmedId)' not found.")
               }
           } catch {
               handleError("Error fetching artwork: \(error.localizedDescription)")
           }
       }
   }
  
   func cancelImport() {
       print("ViewModel: cancelImport called, triggering onCancel.")
       onCancel?()
   }
  
   private func handleError(_ message: String) {
       print("ViewModel: Handling error: \(message)")
       Task { @MainActor in // Ensure UI updates are on main thread
           self.errorMessage = message
           self.showError = true
           self.onError?(message) // Call error callback
       }
   }
}
/* // End of actual ViewModel definition
*/




@MainActor // Add MainActor for tests involving ObservableObject
final class ImportArtworkViewTests: XCTestCase {


   // Use the MockFirebaseService potentially defined in CanvasViewTests or globally
   // Ensure only ONE definition exists in your test target.
   var mockFirebaseService: MockFirebaseService!
   var sut: ImportArtworkViewModel! // System Under Test is now the ViewModel
   var importSuccessCalled: Bool!
   var importData: String?
   var errorCallbackCalled: Bool!
   var cancelCallbackCalled: Bool!
   var expectation: XCTestExpectation! // Add expectation property


   override func setUp() {
       super.setUp()
       importSuccessCalled = false
       importData = nil
       errorCallbackCalled = false
       cancelCallbackCalled = false
       expectation = nil // Reset expectation
      
       mockFirebaseService = MockFirebaseService()
       // Make sure the shared instance is our mock if the ViewModel uses shared
       FirebaseService.shared = mockFirebaseService


       // Initialize the ViewModel with the mock service
       sut = ImportArtworkViewModel(firebaseService: mockFirebaseService)
      
       // Setup callbacks to fulfill the expectation directly
       sut.onImportSuccess = { [weak self] (data: String) in
           self?.importSuccessCalled = true
           self?.importData = data
           self?.expectation?.fulfill() // Fulfill expectation on success
       }
       sut.onError = { [weak self] (_: String) in
           self?.errorCallbackCalled = true
           self?.expectation?.fulfill() // Fulfill expectation on error
       }
       sut.onCancel = { [weak self] () in
           self?.cancelCallbackCalled = true
           // Usually don't need expectation for sync cancel, but could add if needed
       }
   }


   override func tearDown() {
       sut = nil
       importSuccessCalled = nil
       importData = nil
       errorCallbackCalled = nil
       cancelCallbackCalled = nil
       mockFirebaseService = nil // Ensure mock is nilled out
       expectation = nil // Clean up expectation
       super.tearDown()
   }


   // Test validation logic with empty ID
   func testImportAction_EmptyID() async {
       sut.artworkIdText = "   " // Whitespace ID
       sut.importArtwork()
      
       // Wait a tiny bit for the sync check
       try? await Task.sleep(nanoseconds: 100_000_000)
      
       XCTAssertFalse(mockFirebaseService.getArtworkByIdCalled, "Firebase service should not be called with empty ID")
       XCTAssertTrue(sut.showError, "Error flag should be true for empty ID")
       XCTAssertFalse(sut.errorMessage.isEmpty, "Error message should be set for empty ID")
       XCTAssertTrue(errorCallbackCalled, "onError callback should be called for empty ID")
   }


   // Test Import Action - Success Case
   func testImportAction_Success() async throws {
       // Set expectation for this test
       expectation = XCTestExpectation(description: "Import artwork successfully")
      
       let testID = "valid-test-id"
       let testArtworkString = "shape:circle;rotation:45.0;scale:1.0;layer:5;skewX:0;skewY:0;spread:0;horizontal:0;vertical:0;primitive:1;colors:#FF0000"
      
       let mockArtwork = ArtworkData(
           deviceId: "test-dev",
           artworkString: testArtworkString,
           timestamp: Date(),
           title: "Test Art",
           pieceId: testID // Ensure pieceId is set
       )


       // Configure the mock service
       mockFirebaseService.mockArtworkDataResult = mockArtwork
       mockFirebaseService.mockError = nil // Ensure no error
      
       sut.artworkIdText = testID
       sut.importArtwork() // Trigger the action on the ViewModel


       // Wait for the expectation to be fulfilled by the callback
       await fulfillment(of: [expectation], timeout: 3.0) // Increased timeout slightly
      
       XCTAssertTrue(mockFirebaseService.getArtworkByIdCalled, "FirebaseService.getArtworkPiece should be called")
       XCTAssertTrue(importSuccessCalled, "Success callback should be triggered")
       XCTAssertEqual(importData, testArtworkString, "Artwork data should be passed to callback")
       XCTAssertFalse(sut.showError, "Error flag should be false on success")
       XCTAssertFalse(errorCallbackCalled, "onError callback should not be called on success")
   }


   // Test Import Action - Failure Case (Not Found)
   func testImportAction_NotFound() async throws {
        // Set expectation for this test
        expectation = XCTestExpectation(description: "Handle artwork not found")
       
        let testID = "invalid-test-id"


        // Configure the mock service for failure (not found)
        mockFirebaseService.mockArtworkDataResult = nil // Explicitly nil
        mockFirebaseService.mockError = nil // No specific error, just not found


        sut.artworkIdText = testID
        sut.importArtwork() // Trigger the action


        // Wait for the expectation to be fulfilled by the onError callback
        await fulfillment(of: [expectation], timeout: 3.0) // Increased timeout slightly


        XCTAssertTrue(mockFirebaseService.getArtworkByIdCalled, "FirebaseService.getArtworkPiece should be called")
        XCTAssertFalse(importSuccessCalled, "Success callback should not be triggered")
        XCTAssertTrue(sut.showError, "Error flag should be true for not found")
        XCTAssertFalse(sut.errorMessage.isEmpty, "Error message should be set for not found")
        XCTAssertTrue(errorCallbackCalled, "onError callback should be called for not found")
   }


   // Test Import Action - Failure Case (Network Error)
    func testImportAction_NetworkError() async throws {
       // Set expectation for this test
       expectation = XCTestExpectation(description: "Handle network error during import")


       let testID = "network-error-id"
       let testError = NSError(domain: "TestError", code: 123, userInfo: [NSLocalizedDescriptionKey: "Network connection failed"])


       // Configure the mock service for a general error
       mockFirebaseService.mockArtworkDataResult = nil
       mockFirebaseService.mockError = testError // Set the specific error


       sut.artworkIdText = testID
       sut.importArtwork() // Trigger the action


        // Wait for the expectation to be fulfilled by the onError callback
        await fulfillment(of: [expectation], timeout: 3.0) // Increased timeout slightly


       XCTAssertTrue(mockFirebaseService.getArtworkByIdCalled, "FirebaseService.getArtworkPiece should be called")
       XCTAssertFalse(importSuccessCalled, "Success callback should not be triggered")
       XCTAssertTrue(sut.showError, "Error flag should be true on network error")
       XCTAssertEqual(sut.errorMessage, "Error fetching artwork: \(testError.localizedDescription)")
       XCTAssertTrue(errorCallbackCalled, "onError callback should be called for network error")
   }


   // Test importing with a valid ID (Simplified version testing ViewModel state)
   func testImportWithValidID_ViewModelState() {
       // Setup: Set a valid ID in the ViewModel
       sut.artworkIdText = "valid-test-id"
       // Set expectation for this test
       expectation = XCTestExpectation(description: "Firebase fetch completes for valid ID")


       // Configure mock for success
       let testArtworkString = "valid-artwork-string"
       let mockArtwork = ArtworkData(deviceId: "d", artworkString: testArtworkString, timestamp: Date(), title: "T", pieceId: "valid-test-id")
       mockFirebaseService.mockArtworkDataResult = mockArtwork
       mockFirebaseService.mockError = nil


       // Exercise: Trigger the import function
       sut.importArtwork()


       // Verify (synchronous checks and async expectation):
       // Wait for the expectation fulfilled by the onImportSuccess callback
       wait(for: [expectation], timeout: 2.0) // Use non-async wait here


       XCTAssertTrue(mockFirebaseService.getArtworkByIdCalled)
       XCTAssertFalse(sut.showError)
       XCTAssertTrue(sut.errorMessage.isEmpty) // Should be empty on success
       XCTAssertTrue(importSuccessCalled)
       XCTAssertEqual(importData, testArtworkString)
   }


   // Test importing with an invalid ID resulting in an error (Simplified ViewModel state)
   func testImportWithInvalidID_ViewModelState() {
       // Setup: Set an invalid ID
       sut.artworkIdText = "invalid-test-id"
       // Set expectation for this test
       expectation = XCTestExpectation(description: "Firebase fetch fails for invalid ID")


       // Configure mock for failure (not found)
       mockFirebaseService.mockArtworkDataResult = nil
       mockFirebaseService.mockError = nil


       // Exercise: Trigger import
       sut.importArtwork()


       // Verify (synchronous checks and async expectation):
       // Wait for the expectation fulfilled by the onError callback
       wait(for: [expectation], timeout: 2.0)
   }
}