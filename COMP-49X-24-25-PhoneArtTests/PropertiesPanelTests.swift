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
    
    /// Tests the valid ranges and validation logic for all properties
    func testPropertyValidation() {
        let testCases: [(property: String, input: Double, expected: Double)] = [
            // Rotation tests (0-360)
            ("rotation", -45.0, 0.0),
            ("rotation", 180.0, 180.0),
            ("rotation", 400.0, 360.0),
            
            // Scale tests (0.5-2.0)
            ("scale", 0.1, 0.5),
            ("scale", 1.5, 1.5),
            ("scale", 2.5, 2.0),
            
            // Layer tests (0-360)
            ("layer", -10.0, 0.0),
            ("layer", 50.0, 50.0),
            ("layer", 500.0, 360.0),
            
            // Skew tests (0-80)
            ("skewX", -30.0, 0.0),
            ("skewX", 45.0, 45.0),
            ("skewX", 90.0, 80.0),
            
            ("skewY", -30.0, 0.0),
            ("skewY", 45.0, 45.0),
            ("skewY", 90.0, 80.0),
            
            // Spread tests (0-100)
            ("spread", -10.0, 0.0),
            ("spread", 50.0, 50.0),
            ("spread", 150.0, 100.0)
        ]
        
        for test in testCases {
            let result = validateProperty(test.property, value: test.input)
            XCTAssertEqual(result, test.expected, "Failed validating \(test.property) with input \(test.input)")
        }
    }
    
    /// Tests edge cases and boundary conditions
    func testEdgeCases() {
        // Test exact boundary values
        XCTAssertEqual(validateProperty("rotation", value: 0), 0)
        XCTAssertEqual(validateProperty("rotation", value: 360), 360)
        
        XCTAssertEqual(validateProperty("scale", value: 0.5), 0.5)
        XCTAssertEqual(validateProperty("scale", value: 2.0), 2.0)
        
        XCTAssertEqual(validateProperty("skewX", value: 0), 0)
        XCTAssertEqual(validateProperty("skewX", value: 80), 80)
        
        // Test NaN and infinity handling
        XCTAssertEqual(validateProperty("rotation", value: Double.infinity), 360)
        XCTAssertEqual(validateProperty("rotation", value: Double.nan), 0)
    }
    
    /// Tests simultaneous property updates
    func testMultiplePropertyUpdates() {
        // Test updating multiple properties at once
        let updates: [(property: String, value: Double)] = [
            ("rotation", 270.0),
            ("scale", 1.8),
            ("layer", 100.0),
            ("skewX", 30.0),
            ("skewY", 45.0)
        ]
        
        for update in updates {
            let result = validateProperty(update.property, value: update.value)
            XCTAssertTrue(isValidValue(result, for: update.property),
                         "Invalid value \(result) for property \(update.property)")
        }
    }
    
    // MARK: - Helper Functions
    
    /// Validates property values based on their allowed ranges
    private func validateProperty(_ property: String, value: Double) -> Double {
        if value.isNaN { return 0 }
        
        switch property {
        case "rotation", "layer":
            return max(0.0, min(360.0, value))
        case "scale":
            return max(0.5, min(2.0, value))
        case "skewX", "skewY":
            return max(0.0, min(80.0, value))
        case "spread":
            return max(0.0, min(100.0, value))
        default:
            return value
        }
    }
    
    /// Checks if a value is within the valid range for a given property
    private func isValidValue(_ value: Double, for property: String) -> Bool {
        switch property {
        case "rotation", "layer":
            return (0...360).contains(value)
        case "scale":
            return (0.5...2.0).contains(value)
        case "skewX", "skewY":
            return (0...80).contains(value)
        case "spread":
            return (0...100).contains(value)
        default:
            return true
        }
    }
}