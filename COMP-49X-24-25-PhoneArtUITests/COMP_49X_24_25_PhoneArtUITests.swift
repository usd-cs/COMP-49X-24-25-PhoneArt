//
//  COMP_49X_24_25_PhoneArtUITests.swift
//  COMP-49X-24-25-PhoneArtUITests
//
//  Created by Aditya Prakash on 11/21/24.
//


import XCTest


/// UI test suite for verifying the core functionality of the canvas view and its interactions
final class COMP_49X_24_25_PhoneArtUITests: XCTestCase {


   var app: XCUIApplication!
   let isLowPerformanceDevice = ProcessInfo.processInfo.processorCount < 4
  
   /// Set up method called before each test case
   /// Configures the test environment to stop immediately on failures
   override func setUpWithError() throws {
       // In UI tests it is usually best to stop immediately when a failure occurs.
       continueAfterFailure = false
       app = XCUIApplication()
      
       // Add launch argument to make animations faster in UI tests
       app.launchArguments = ["-UITest_ReducedAnimations"]
      
       app.launch()
   }


   /// Tear down method called after each test case
   /// Currently empty but available for cleanup if needed
   override func tearDownWithError() throws {
       app = nil
   }


   /// Tests the initial state of the canvas view when the app launches
   /// Verifies that:
   /// - The canvas element exists and is visible
   /// - The reset button exists and is accessible
   @MainActor
   func testCanvasInitialState() throws {
       // Skip test on low-performance devices if necessary
       if isLowPerformanceDevice {
           throw XCTSkip("Skipping test on low-performance device")
       }
      
       // Verify canvas exists with a shorter timeout
       let canvas = app.otherElements["Canvas"]
       XCTAssertTrue(canvas.waitForExistence(timeout: 2), "Canvas should be visible")
      
       // Verify reset button exists with a shorter timeout
       let resetButton = app.buttons["Reset Position"]
       XCTAssertTrue(resetButton.waitForExistence(timeout: 2), "Reset button should be visible")
   }
  
   /// Tests the drag gesture functionality of the canvas
   /// Verifies that:
   /// - The canvas responds to drag gestures
   /// - The canvas position changes after dragging
   @MainActor
   func testCanvasDragGesture() throws {
       // Skip this test on low-performance devices
       if isLowPerformanceDevice {
           throw XCTSkip("Skipping drag test on low-performance device")
       }
      
       let canvas = app.otherElements["Canvas"]
       guard canvas.waitForExistence(timeout: 2) else {
           XCTFail("Canvas did not appear in time")
           return
       }
      
       // Record initial position
       let initialFrame = canvas.frame
      
       // Use a shorter drag with less duration
       let start = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
       let end = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.6))
       start.press(forDuration: 0.05, thenDragTo: end)
      
       // Use a shorter wait with a timeout
       let expectation = XCTestExpectation(description: "Canvas moved")
       DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
           if canvas.frame != initialFrame {
               expectation.fulfill()
           }
       }
      
       wait(for: [expectation], timeout: 1.0)
   }
  
   /// Tests the reset button functionality
   /// Verifies that:
   /// - The canvas can be dragged from its initial position
   /// - The reset button returns the canvas to the center
   /// - The final position matches the expected centered coordinates
   @MainActor
   func testResetButtonFunctionality() throws {
       // Skip extensive tests on slower hardware
       if isLowPerformanceDevice {
           throw XCTSkip("Skipping reset test on low-performance device")
       }
      
       let canvas = app.otherElements["Canvas"]
       let resetButton = app.buttons["Reset Position"]
      
       // Wait longer for initial UI setup
       guard canvas.waitForExistence(timeout: 10) &&
             resetButton.waitForExistence(timeout: 10) else {
           XCTFail("UI elements did not appear in time")
           return
       }
      
       // Wait for any initial animations to complete
       sleep(2)
      
       // Record initial position
       let initialFrame = canvas.frame
       print("Initial canvas position: \(initialFrame)")
      
       // Perform a very clear, large drag
       let start = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
       let end = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.9))
       start.press(forDuration: 0.5, thenDragTo: end)
      
       // Wait for drag to complete
       sleep(2)
      
       // Verify canvas has moved
       let draggedFrame = canvas.frame
       print("Position after drag: \(draggedFrame)")
       XCTAssertNotEqual(draggedFrame, initialFrame, "Canvas should move after drag")
      
       // Tap reset button
       resetButton.tap()
      
       // Wait longer for reset animation
       sleep(3)
      
       // Get final position
       let finalFrame = canvas.frame
       print("Final canvas position: \(finalFrame)")
      
       // Use very generous tolerance for position comparison
       let tolerance: CGFloat = 50
      
       // Compare positions with detailed error message
       let xDiff = abs(finalFrame.midX - initialFrame.midX)
       let yDiff = abs(finalFrame.midY - initialFrame.midY)
      
       XCTAssertTrue(
           xDiff < tolerance && yDiff < tolerance,
           """
           Canvas did not return to original position within \(tolerance) points.
           X difference: \(xDiff)
           Y difference: \(yDiff)
           Initial position: \(initialFrame)
           Final position: \(finalFrame)
           """
       )
   }


   /// Tests for the properties panel functionality
   @MainActor
   func testPropertiesPanel() throws {
       // Skip this resource-intensive test on slower devices
       if isLowPerformanceDevice {
           throw XCTSkip("Skipping properties panel test on low-performance device")
       }
      
       // Reset app state
       app.terminate()
       app.launch()
      
       let canvas = app.otherElements["Canvas"]
       let propertiesButton = app.buttons["Properties Button"]
      
       // Use shorter timeouts but with retry logic
       let maxAttempts = 3
       var attempt = 0
       var success = false
      
       while attempt < maxAttempts && !success {
           attempt += 1
          
           guard canvas.waitForExistence(timeout: 5) &&
                 propertiesButton.waitForExistence(timeout: 5) else {
               if attempt == maxAttempts {
                   XCTFail("UI elements did not appear after \(maxAttempts) attempts")
                   return
               }
               app.terminate()
               app.launch()
               continue
           }
          
           // Record initial position
           let initialPosition = canvas.frame.midY
          
           // Open properties panel
           propertiesButton.tap()
          
           // Wait briefly for animation (1 second)
           sleep(1)
          
           // Get new position
           let newPosition = canvas.frame.midY
          
           // Verify movement with very generous tolerance
           if newPosition < initialPosition - 10 {
               success = true
               break
           }
          
           // If we get here, the test failed this attempt
           app.terminate()
           app.launch()
       }
      
       XCTAssertTrue(success, "Failed to verify panel operation after \(maxAttempts) attempts")
      
       // Don't try to close the panel if we didn't succeed in opening it
       guard success else { return }
      
       // Simple close attempt - just tap the top right corner
       let topRightCorner = app.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.05))
       topRightCorner.tap()
   }
}
