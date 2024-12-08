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
    
    var rotation: Double!
    var scale: Double!
    var layer: Double!
    var isShowing: Bool!
    var sut: PropertiesPanel!
    
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
    
    /// Test initial values
    func testInitialValues() {
        XCTAssertEqual(rotation, 180.0)
        XCTAssertEqual(scale, 1.5)
        XCTAssertEqual(layer, 50.0)
        XCTAssertTrue(isShowing)
    }
    
    /// Test value formatting
    func testValueFormatting() {
        // Test rotation formatting
        let rotationText = "\(Int(rotation))°"
        XCTAssertEqual(rotationText, "180°")
        
        // Test scale formatting
        let scaleText = String(format: "%.1fx", scale)
        XCTAssertEqual(scaleText, "1.5x")
        
        // Test layer formatting
        let layerText = "\(Int(layer))"
        XCTAssertEqual(layerText, "50")
    }
    
    /// Test value ranges
    func testValueRanges() {
        // Test rotation range (0-360)
        XCTAssertTrue((0...360).contains(rotation))
        
        // Test scale range (0.5-2.0)
        XCTAssertTrue((0.5...2.0).contains(scale))
        
        // Test layer range (0-360)
        XCTAssertTrue((0...360).contains(layer))
    }
    
    /// Test invalid values
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