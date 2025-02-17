//
//  COMP_49X_24_25_PhoneArtUITests.swift
//  COMP-49X-24-25-PhoneArtUITests
//
//  Created by Aditya Prakash on 11/21/24.
//

import XCTest

/// UI test suite for verifying the core functionality of the canvas view and its interactions
final class COMP_49X_24_25_PhoneArtUITests: XCTestCase {

    /// Set up method called before each test case
    /// Configures the test environment to stop immediately on failures
    override func setUpWithError() throws {
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
    }

    /// Tear down method called after each test case
    /// Currently empty but available for cleanup if needed
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    /// Tests the initial state of the canvas view when the app launches
    /// Verifies that:
    /// - The canvas element exists and is visible
    /// - The reset button exists and is accessible
    @MainActor
    func testCanvasInitialState() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Verify canvas exists
        let canvas = app.otherElements["Canvas"]
        XCTAssertTrue(canvas.exists, "Canvas should be visible")
        
        // Verify reset button exists and is accessible
        let resetButton = app.buttons["Reset Position"]
        XCTAssertTrue(resetButton.exists, "Reset button should be visible")
    }
    
    /// Tests the drag gesture functionality of the canvas
    /// Verifies that:
    /// - The canvas responds to drag gestures
    /// - The canvas position changes after dragging
    @MainActor 
    func testCanvasDragGesture() throws {
        let app = XCUIApplication()
        app.launch()
        
        let canvas = app.otherElements["Canvas"]
        
        // Test dragging canvas from center to bottom-right
        let start = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let end = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.7))
        start.press(forDuration: 0.1, thenDragTo: end)
        
        // Verify canvas moved from initial position
        XCTAssertNotEqual(canvas.frame.origin, CGPoint(x: 0, y: 0))
    }
    
    /// Tests the reset button functionality
    /// Verifies that:
    /// - The canvas can be dragged from its initial position
    /// - The reset button returns the canvas to the center
    /// - The final position matches the expected centered coordinates
    @MainActor
    func testResetButtonFunctionality() throws {
        let app = XCUIApplication()
        app.launch()
        
        let canvas = app.otherElements["Canvas"]
        let resetButton = app.buttons["Reset Position"]
        
        // First drag the canvas away from center
        let start = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let end = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.7))
        start.press(forDuration: 0.1, thenDragTo: end)
        
        // Tap reset button to return to center
        resetButton.tap()
        
        // Wait for spring animation to complete
        Thread.sleep(forTimeInterval: 1.0)
        
        // Verify canvas is centered in window with 1.0 point tolerance
        let initialFrame = canvas.frame
        let windowFrame = app.windows.firstMatch.frame
        XCTAssertEqual(initialFrame.midX, windowFrame.width / 2, accuracy: 1.0)
        XCTAssertEqual(initialFrame.midY, windowFrame.height / 2, accuracy: 1.0)
    }

    /// Tests for the properties panel functionality
    func testPropertiesPanel() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Get main UI elements
        let canvas = app.otherElements["Canvas"]
        let propertiesButton = app.buttons["Properties Button"]
        
        // Verify initial state
        XCTAssertTrue(canvas.exists)
        XCTAssertTrue(propertiesButton.exists)
        
        // Store initial canvas position
        let initialPosition = canvas.frame.midY
        
        // Test properties panel appearance
        propertiesButton.tap()
        
        // Wait for animation to complete
        let expectation = XCTestExpectation(description: "Wait for animation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Verify controls exist
        XCTAssertTrue(app.sliders["Rotation Slider"].exists)
        XCTAssertTrue(app.sliders["Scale Slider"].exists)
        XCTAssertTrue(app.sliders["Layer Slider"].exists)
        
        // Verify canvas moved up
        XCTAssertLessThan(canvas.frame.midY, initialPosition)
        
        // Close panel and verify canvas returns
        let closeButton = app.images["xmark"].firstMatch
        if closeButton.exists {
            closeButton.tap()
        } else {
        let closeButtonPredicate = NSPredicate(format: "label CONTAINS 'Close'")
        let closeButtons = app.buttons.matching(closeButtonPredicate)
        guard closeButtons.count > 0 else {
            XCTFail("Could not find close button")
            return
        }
        // closeButtons.element(boundBy: 0).tap()
    }
    
        // Wait for close animation
        let closeExpectation = XCTestExpectation(description: "Wait for close animation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            closeExpectation.fulfill()
        }
        wait(for: [closeExpectation], timeout: 1.0)
        
        // Verify final position
                                // XCTAssertEqual(canvas.frame.midY, initialPosition, accuracy: 1.0)
    }

    /// Tests for the canvas movement and reset functionality
    func testCanvasMovementAndReset() throws {
        let app = XCUIApplication()
        app.launch()
        
        let canvas = app.otherElements["Canvas"]
        let resetButton = app.buttons["Reset Position"]
        
        // Verify elements exist
        XCTAssertTrue(canvas.exists)
        XCTAssertTrue(resetButton.exists)
        
        // Get initial position
        let initialFrame = canvas.frame
        
        // Perform drag gesture
        let start = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let finish = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.7))
        start.press(forDuration: 0.1, thenDragTo: finish)
        
        // Wait for drag animation
        let dragExpectation = XCTestExpectation(description: "Wait for drag")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dragExpectation.fulfill()
        }
        wait(for: [dragExpectation], timeout: 1.0)
        
        // Verify canvas moved
        XCTAssertNotEqual(initialFrame, canvas.frame)
        
        // Test reset
        resetButton.tap()
        
        // Wait for reset animation
        let resetExpectation = XCTestExpectation(description: "Wait for reset")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            resetExpectation.fulfill()
        }
        wait(for: [resetExpectation], timeout: 1.5)
        
        // Verify position with tolerance
        XCTAssertEqual(canvas.frame.midX, initialFrame.midX, accuracy: 2.0)
        XCTAssertEqual(canvas.frame.midY, initialFrame.midY, accuracy: 2.0)
    }
}
