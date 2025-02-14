//
//  PropertiesPanelTests.swift
//  COMP-49X-24-25-PhoneArtTests
//
//  Created by Zachary Letcher on 12/08/24.
//

import XCTest
import SwiftUI
@testable import COMP_49X_24_25_PhoneArt

/// Test suite for the PropertiesPanel component
final class PropertiesPanelTests: XCTestCase {
    
    // Properties for testing
    var rotation: Double!
    var scale: Double!
    var layer: Double!
    var skewX: Double!
    var skewY: Double!
    var spread: Double!
    var isShowing: Bool!
    var sut: PropertiesPanel!
    
    /// Sets up the test environment before each test method is called
    override func setUp() {
        super.setUp()
        // Initialize properties with default values
        rotation = 180.0
        scale = 1.5
        layer = 50.0
        skewX = 0.0
        skewY = 0.0
        spread = 0.0
        isShowing = true
        
        // Initialize the system under test (sut) with the properties
        sut = PropertiesPanel(
            rotation: .constant(rotation),
            scale: .constant(scale),
            layer: .constant(layer),
            skewX: .constant(skewX),
            skewY: .constant(skewY),
            spread: .constant(spread),
            isShowing: .constant(isShowing)
        )
    }
    
    /// Cleans up the test environment after each test method is called
    override func tearDown() {
        // Deallocate properties and sut
        rotation = nil
        scale = nil
        layer = nil
        skewX = nil
        skewY = nil
        spread = nil
        isShowing = nil
        sut = nil
        super.tearDown()
    }
    
    /// Tests the initial values of the properties
    func testInitialValues() {
        // Verify that the initial values are set correctly
        XCTAssertEqual(rotation, 180.0)
        XCTAssertEqual(scale, 1.5)
        XCTAssertEqual(layer, 50.0)
        XCTAssertEqual(skewX, 0.0)
        XCTAssertEqual(skewY, 0.0)
        XCTAssertEqual(spread, 0.0)
        XCTAssertTrue(isShowing)
    }
    
    /// Tests the formatting of the property values
    func testValueFormatting() {
        // Test rotation formatting
        let rotationText = sut.testRotationText
        XCTAssertEqual(rotationText, "180")
        
        // Test scale formatting
        let scaleText = sut.testScaleText
        XCTAssertEqual(scaleText, "1.5")
        
        // Test layer formatting
        let layerText = sut.testLayerText
        XCTAssertEqual(layerText, "50")
    }
    
    /// Tests the valid ranges of the property values
    func testValueRanges() {
        // Test rotation range (0-360)
        XCTAssertTrue((0...360).contains(rotation))
        
        // Test scale range (0.5-2.0)
        XCTAssertTrue((0.5...2.0).contains(scale))
        
        // Test layer range (0-360)
        XCTAssertTrue((0...360).contains(layer))
    }
    
    /// Tests the handling of invalid property values
    func testInvalidValues() {
        // Test rotation bounds
        let invalidRotation = max(0, min(400, 360))
        XCTAssertEqual(invalidRotation, 360)
        
        // Test scale bounds
        let invalidScale = max(0.5, min(2.5, 2.0))
        XCTAssertEqual(invalidScale, 2.0)
        
        // Test layer bounds
        let invalidLayer = max(0, min(-5, 360))
        XCTAssertEqual(invalidLayer, 0)
    }
    
}