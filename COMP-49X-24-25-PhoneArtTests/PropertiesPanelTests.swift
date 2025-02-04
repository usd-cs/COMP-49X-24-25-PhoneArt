//
//  PropertiesPanelTests.swift
//  COMP-49X-24-25-PhoneArtTests
//
//  Created by Zachary Letcher on 12/08/24.
//

import XCTest
import SwiftUI
@testable import COMP_49X_24_25_PhoneArt

final class PropertiesPanelTests: XCTestCase {
    
    var sut: PropertiesPanel!
    var rotation: Double!
    var scale: Double!
    var layer: Double!
    var isShowing: Bool!
    
    override func setUp() {
        super.setUp()
        rotation = 180.0
        scale = 1.5
        layer = 50.0
        isShowing = true
        
        sut = PropertiesPanel(
            rotation: .constant(rotation),
            scale: .constant(scale),
            layer: .constant(layer),
            isShowing: .constant(isShowing)
        )
    }
    
    override func tearDown() {
        rotation = nil
        scale = nil
        layer = nil
        isShowing = nil
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialValues() {
        XCTAssertEqual(sut.rotation, rotation)
        XCTAssertEqual(sut.scale, scale)
        XCTAssertEqual(sut.layer, layer)
        XCTAssertEqual(sut.isShowing, isShowing)
    }
    
    func testInitialTextFieldValues() {
        XCTAssertEqual(sut.testRotationText, "\(Int(rotation))")
        XCTAssertEqual(sut.testScaleText, String(format: "%.1f", scale))
        XCTAssertEqual(sut.testLayerText, "\(Int(layer))")
    }
    
    // MARK: - Text Field Validation Tests
    
    func testRotationTextValidation() {
        let testCases = [
            (input: "0", expectedValue: 0.0),
            (input: "360", expectedValue: 360.0),
            (input: "-1", expectedValue: 360.0),
            (input: "361", expectedValue: 360.0),
            (input: "abc", expectedValue: 360.0)
        ]
        
        for testCase in testCases {
            sut.testRotationText = testCase.input
            XCTAssertEqual(sut.rotation, testCase.expectedValue, "Failed for input: \(testCase.input)")
        }
    }
    
    func testScaleTextValidation() {
        let testCases = [
            (input: "0.5", expectedValue: 0.5),
            (input: "1.0", expectedValue: 1.0),
            (input: "2.0", expectedValue: 2.0),
            (input: "0.4", expectedValue: 0.5),
            (input: "2.1", expectedValue: 0.5),
            (input: "abc", expectedValue: 0.5)
        ]
        
        for testCasje in testCases {
            sut.testScaleText = testCase.input
            XCTAssertEqual(sut.scale, testCase.expectedValue, "Failed for input: \(testCase.input)")
        }
    }
    
    func testLayerTextValidation() {
        let testCases = [
            (input: "0", expectedValue: 0.0),
            (input: "360", expectedValue: 360.0),
            (input: "-1", expectedValue: 0),
            (input: "361", expectedValue: 360),
            (input: "abc", expectedValue: 360)
        ]
        
        for testCase in testCases {
            sut.testLayerText = testCase.input
            XCTAssertEqual(sut.layer, testCase.expectedValue, "Failed for input: \(testCase.input)")
        }
    }
    
    // MARK: - Slider Sync Tests
    
    func testRotationSliderSync() {
        let testValues = [0.0, 90.0, 180.0, 270.0, 360.0]
        
        for value in testValues {
            sut.rotation = value
            XCTAssertEqual(sut.testRotationText, String(format: "%.0f", value))
        }
    }
    
    func testScaleSliderSync() {
        let testValues = [0.5, 1.0, 1.5, 2.0]
        
        for value in testValues {
            sut.scale = value
            XCTAssertEqual(sut.testScaleText, String(format: "%.1f", value))
        }
    }
    
    func testLayerSliderSync() {
        let testValues = [0.0, 90.0, 180.0, 270.0, 360.0]
        
        for value in testValues {
            sut.layer = value
            XCTAssertEqual(sut.testLayerText, String(format: "%.0f", value))
        }
    }
    
    // MARK: - UI Element Tests
    
    func testVisibilityToggle() {
        sut.isShowing = true
        XCTAssertTrue(sut.isShowing)
        
        sut.isShowing = false
        XCTAssertFalse(sut.isShowing)
    }
    
    func testAccessibilityIdentifiers() {
        let view = sut.body
        
        // Define expected identifiers
        let expectedIdentifiers = [
            "rotation-slider",
            "scale-slider",
            "layer-slider",
            "properties-button",
            "close-button"
        ]
        
        // Get all accessibility identifiers from the view hierarchy
        let viewIdentifiers = extractAccessibilityIdentifiers(from: view)
        
        // Verify each expected identifier exists
        for identifier in expectedIdentifiers {
            XCTAssertTrue(
                viewIdentifiers.contains { $0.lowercased().contains(identifier) },
                "Missing accessibility identifier: \(identifier)"
            )
        }
    }
    
    // MARK: - Format Tests
    
    func testNumberFormatting() {
        // Test rotation format (integer)
        XCTAssertEqual(sut.testRotationText, "\(Int(rotation))")
        
        // Test scale format (one decimal place)
        XCTAssertEqual(sut.testScaleText, String(format: "%.1f", scale))
        
        // Test layer format (integer)
        XCTAssertEqual(sut.testLayerText, "\(Int(layer))")
    }
}

// MARK: - Helper Methods

private func extractAccessibilityIdentifiers(from view: Any) -> Set<String> {
    var identifiers = Set<String>()
    
    let mirror = Mirror(reflecting: view)
    for child in mirror.children {
        if let identifier = child.value as? String,
           identifier.contains("Identifier") {
            identifiers.insert(identifier)
        }
        
        // Recursively check child views
        identifiers.formUnion(extractAccessibilityIdentifiers(from: child.value))
    }
    
    return identifiers
}
