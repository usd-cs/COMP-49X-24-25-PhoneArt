//
//  ShapesPanelIntegrationTests.swift
//  COMP-49X-24-25-PhoneArtTests
//
//  Created by Assistant on current_date
//

import XCTest
import SwiftUI
@testable import COMP_49X_24_25_PhoneArt

/// Test suite for integration of ShapesPanel with other components
final class ShapesPanelIntegrationTests: XCTestCase {
    // Properties for testing
    var selectedShape: ShapesPanel.ShapeType!
    var isShowing: Bool!
    var switchedToProperties: Bool!
    var switchedToColorProperties: Bool!
    
    /// Sets up the test environment before each test method is called
    override func setUp() {
        super.setUp()
        // Initialize properties with default values
        selectedShape = .circle
        isShowing = true
        switchedToProperties = false
        switchedToColorProperties = false
    }
    
    /// Cleans up after each test method is executed
    override func tearDown() {
        selectedShape = nil
        isShowing = nil
        switchedToProperties = nil
        switchedToColorProperties = nil
        super.tearDown()
    }
    
    // MARK: - Integration Tests
    
    /// Tests the panel's integration with parent view state management
    func testPanelStateManagement() {
        // Create bindings that track changes
        let selectedShapeBinding = Binding<ShapesPanel.ShapeType>(
            get: { self.selectedShape },
            set: { self.selectedShape = $0 }
        )
        
        let isShowingBinding = Binding<Bool>(
            get: { self.isShowing },
            set: { self.isShowing = $0 }
        )
        
        // Create the panel
        let panel = ShapesPanel(
            selectedShape: selectedShapeBinding,
            isShowing: isShowingBinding,
            onSwitchToProperties: { self.switchedToProperties = true },
            onSwitchToColorProperties: { self.switchedToColorProperties = true }
        )
        
        // Test that hiding the panel updates the parent state
        isShowingBinding.wrappedValue = false
        XCTAssertFalse(self.isShowing)
        
        // Test that showing the panel updates the parent state
        isShowingBinding.wrappedValue = true
        XCTAssertTrue(self.isShowing)
        
        // Test that changing the selected shape updates the parent state
        selectedShapeBinding.wrappedValue = .square
        XCTAssertEqual(self.selectedShape, .square)
        
        // Test that switching to properties updates the parent state
        panel.onSwitchToProperties()
        XCTAssertTrue(self.switchedToProperties)
        
        // Test that switching to color properties updates the parent state
        panel.onSwitchToColorProperties()
        XCTAssertTrue(self.switchedToColorProperties)
    }
    
    /// Tests that all shape types are available and selectable
    func testAllShapesAreSelectable() {
        // Create a binding that tracks changes
        let selectedShapeBinding = Binding<ShapesPanel.ShapeType>(
            get: { self.selectedShape },
            set: { self.selectedShape = $0 }
        )
        
        // Create the panel
        _ = ShapesPanel(
            selectedShape: selectedShapeBinding,
            isShowing: .constant(true),
            onSwitchToProperties: { },
            onSwitchToColorProperties: { }
        )
        
        // Test setting each shape type
        for shape in ShapesPanel.ShapeType.allCases {
            selectedShapeBinding.wrappedValue = shape
            XCTAssertEqual(self.selectedShape, shape)
        }
    }
    
    /// Tests the panel interacts properly with multiple panels
    func testMultiplePanelInteraction() {
        // Create bindings that track changes
        let isShapesShowing = Binding<Bool>(
            get: { self.isShowing },
            set: { self.isShowing = $0 }
        )
        
        // Note: These variables aren't used in the test, but kept for reference
        // since they represent how you might track other panel visibility states
        let _ = Binding<Bool>(
            get: { false },
            set: { _ in self.switchedToProperties = true }
        )
        
        let _ = Binding<Bool>(
            get: { false },
            set: { _ in self.switchedToColorProperties = true }
        )
        
        // Create a simulation of panel switching logic
        let onSwitchToProperties = {
            self.isShowing = false
            self.switchedToProperties = true
        }
        
        let onSwitchToColorProperties = {
            self.isShowing = false
            self.switchedToColorProperties = true
        }
        
        // Create the panel
        let panel = ShapesPanel(
            selectedShape: .constant(.circle),
            isShowing: isShapesShowing,
            onSwitchToProperties: onSwitchToProperties,
            onSwitchToColorProperties: onSwitchToColorProperties
        )
        
        // Test switching to properties panel
        panel.onSwitchToProperties()
        XCTAssertFalse(self.isShowing) // ShapesPanel should be hidden
        XCTAssertTrue(self.switchedToProperties) // Properties panel should be shown
        
        // Reset and test switching to color properties panel
        self.isShowing = true
        self.switchedToProperties = false
        self.switchedToColorProperties = false
        
        panel.onSwitchToColorProperties()
        XCTAssertFalse(self.isShowing) // ShapesPanel should be hidden
        XCTAssertTrue(self.switchedToColorProperties) // Color properties panel should be shown
    }
} 
