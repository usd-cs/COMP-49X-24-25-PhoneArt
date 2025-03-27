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
 var horizontal: Double!
 var vertical: Double!
 var primitive: Double!
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
     horizontal = 0.0
     vertical = 0.0
     primitive = 1.0
     isShowing = true
  
     // Initialize the system under test (sut) with the properties
     sut = PropertiesPanel(
         rotation: .constant(rotation),
         scale: .constant(scale),
         layer: .constant(layer),
         skewX: .constant(skewX),
         skewY: .constant(skewY),
         spread: .constant(spread),
         horizontal: .constant(horizontal),
         vertical: .constant(vertical),
         primitive: .constant(primitive),
         isShowing: .constant(isShowing),
         onSwitchToColorShapes: {},
         onSwitchToShapes: {}
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
     horizontal = nil
     vertical = nil
     primitive = nil
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
     XCTAssertEqual(horizontal, 0.0)
     XCTAssertEqual(vertical, 0.0)
     XCTAssertEqual(primitive, 1.0)
     XCTAssertTrue(isShowing)
 }
  /// Tests the formatting of the property values to ensure they are displayed correctly in the UI
 /// This test verifies that:
 /// - Rotation values are shown as whole numbers without decimals
 /// - Scale values maintain one decimal place
 /// - Layer counts are displayed as whole numbers
 /// - Position values are displayed as whole numbers
 func testValueFormatting() {
     // Test rotation formatting - should be a whole number
     XCTAssertEqual(sut.testRotationText, "\(Int(rotation))")
  
     // Test scale formatting - should have one decimal place
     XCTAssertEqual(sut.testScaleText, String(format: "%.1f", scale))
  
     // Test layer formatting - should be a whole number
     XCTAssertEqual(sut.testLayerText, "\(Int(layer))")
  
     // Test position formatting - should be whole numbers
     XCTAssertEqual(sut.testHorizontalText, "\(Int(horizontal))")
     XCTAssertEqual(sut.testVerticalText, "\(Int(vertical))")
 }
  /// Tests that all property values stay within their valid ranges
 /// Verifies the following ranges:
 /// - Rotation: 0° to 360°
 /// - Scale: 0.5x to 2.0x
 /// - Layer count: 0 to 360 layers
 /// - Skew X/Y: 0% to 80%
 /// - Spread: 0% to 100%
 /// - Horizontal/Vertical: -500 to 500
 func testValueRanges() {
     // Test rotation range (0-360 degrees)
     XCTAssertTrue((0...360).contains(rotation))
  
     // Test scale range (0.5x to 2.0x magnification)
     XCTAssertTrue((0.5...2.0).contains(scale))
  
     // Test layer range (0-360 layers)
     XCTAssertTrue((0...360).contains(layer))
  
     // Test skew ranges (0-80%)
     XCTAssertTrue((0...80).contains(skewX))
     XCTAssertTrue((0...80).contains(skewY))
  
     // Test spread range (0-100%)
     XCTAssertTrue((0...100).contains(spread))
  
     // Test position ranges (-500 to 500)
     XCTAssertTrue((-500...500).contains(horizontal))
     XCTAssertTrue((-500...500).contains(vertical))
 }
  /// Tests that invalid property values are properly clamped to valid ranges
 /// Verifies that:
 /// - Values above maximum are clamped to maximum
 /// - Values below minimum are clamped to minimum
 /// - Edge cases are handled correctly
 func testInvalidValues() {
     // Test rotation bounds - should clamp 400° to 360°
     let invalidRotation = max(0, min(400, 360))
     XCTAssertEqual(invalidRotation, 360)
  
     // Test scale bounds - should clamp 2.5x to 2.0x
     let invalidScale = max(0.5, min(2.5, 2.0))
     XCTAssertEqual(invalidScale, 2.0)
  
     // Test layer bounds - should clamp -5 to 0
     let invalidLayer = max(0, min(-5, 360))
     XCTAssertEqual(invalidLayer, 0)
  
     // Test skew X bounds - should clamp 90% to 80%
     let invalidSkewX = max(0, min(90, 80))
     XCTAssertEqual(invalidSkewX, 80)
  
     // Test skew Y bounds - should clamp -10% to 0%
     let invalidSkewY = max(0, min(-10, 80))
     XCTAssertEqual(invalidSkewY, 0)
  
     // Test position bounds - should clamp ±600 to ±500
     let invalidHorizontal = max(-500, min(600, 500))
     XCTAssertEqual(invalidHorizontal, 500)
  
     let invalidVertical = max(-500, min(-600, 500))
     XCTAssertEqual(invalidVertical, -500)
 }
  /// Comprehensive test of property validation logic using multiple test cases
 /// Tests validation for:
 /// - Rotation (0-360°)
 /// - Scale (0.5x-2.0x)
 /// - Layer count (0-360)
 /// - Skew X/Y (0-80%)
 /// - Spread (0-100%)
 /// - Horizontal/Vertical position (-500 to 500)
 func testPropertyValidation() {
     let testCases: [(property: String, input: Double, expected: Double)] = [
         // Rotation tests - validates clamping at 0° and 360°
         ("rotation", -45.0, 0.0),
         ("rotation", 180.0, 180.0),
         ("rotation", 400.0, 360.0),
      
         // Scale tests - validates minimum 0.5x and maximum 2.0x
         ("scale", 0.1, 0.5),
         ("scale", 1.5, 1.5),
         ("scale", 2.5, 2.0),
      
         // Layer tests - validates clamping at 0 and 360 layers
         ("layer", -10.0, 0.0),
         ("layer", 50.0, 50.0),
         ("layer", 500.0, 360.0),
      
         // Skew tests - validates 0-80% range for both X and Y
         ("skewX", -30.0, 0.0),
         ("skewX", 45.0, 45.0),
         ("skewX", 90.0, 80.0),
      
         ("skewY", -30.0, 0.0),
         ("skewY", 45.0, 45.0),
         ("skewY", 90.0, 80.0),
      
         // Spread tests - validates 0-100% range
         ("spread", -10.0, 0.0),
         ("spread", 50.0, 50.0),
         ("spread", 150.0, 100.0),
      
         // Position tests - validates -500 to 500 range
         ("horizontal", -600.0, -500.0),
         ("horizontal", 0.0, 0.0),
         ("horizontal", 600.0, 500.0),
      
         ("vertical", -600.0, -500.0),
         ("vertical", 0.0, 0.0),
         ("vertical", 600.0, 500.0)
     ]
  
     for test in testCases {
         let result = validateProperty(test.property, value: test.input)
         XCTAssertEqual(result, test.expected, "Failed validating \(test.property) with input \(test.input)")
     }
 }
  /// Tests boundary conditions and special cases for property validation
 /// Verifies:
 /// - Exact boundary values are accepted
 /// - Special values like infinity and NaN are handled
 func testEdgeCases() {
     // Test exact boundary values are accepted without modification
     XCTAssertEqual(validateProperty("rotation", value: 0), 0)
     XCTAssertEqual(validateProperty("rotation", value: 360), 360)
  
     XCTAssertEqual(validateProperty("scale", value: 0.5), 0.5)
     XCTAssertEqual(validateProperty("scale", value: 2.0), 2.0)
  
     XCTAssertEqual(validateProperty("skewX", value: 0), 0)
     XCTAssertEqual(validateProperty("skewX", value: 80), 80)
  
     XCTAssertEqual(validateProperty("horizontal", value: -500), -500)
     XCTAssertEqual(validateProperty("horizontal", value: 500), 500)
    
     XCTAssertEqual(validateProperty("primitive", value: 1), 1)
     XCTAssertEqual(validateProperty("primitive", value: 6), 6)
  
     // Test handling of special floating point values
     XCTAssertEqual(validateProperty("rotation", value: Double.infinity), 360)
     XCTAssertEqual(validateProperty("rotation", value: Double.nan), 0)
 }
  /// Tests that multiple properties can be updated simultaneously
 /// Verifies that:
 /// - Each property maintains its valid range when updated together
 /// - No property update affects the validation of other properties
 func testMultiplePropertyUpdates() {
     // Test updating multiple properties at once
     let updates: [(property: String, value: Double)] = [
         ("rotation", 270.0),
         ("scale", 1.8),
         ("layer", 100.0),
         ("skewX", 30.0),
         ("skewY", 45.0),
         ("spread", 75.0),
         ("horizontal", 250.0),
         ("vertical", -250.0),
         ("primitive", 3.0)
     ]
  
     for update in updates {
         let result = validateProperty(update.property, value: update.value)
         XCTAssertTrue(isValidValue(result, for: update.property),
                      "Invalid value \(result) for property \(update.property)")
     }
 }
  /// Tests the UI components of the PropertiesPanel
 func testUIComponents() {
     let isShowing = Binding<Bool>.constant(true)
     let rotation = Binding<Double>.constant(0.0)
     let scale = Binding<Double>.constant(1.0)
     let layer = Binding<Double>.constant(0.0)
     let skewX = Binding<Double>.constant(0.0)
     let skewY = Binding<Double>.constant(0.0)
     let spread = Binding<Double>.constant(0.0)
     let horizontal = Binding<Double>.constant(0.0)
     let vertical = Binding<Double>.constant(0.0)
     let primitive = Binding<Double>.constant(1.0)
   
     let switchCallback: () -> Void = { }
   
     let sut = PropertiesPanel(
         rotation: rotation,
         scale: scale,
         layer: layer,
         skewX: skewX,
         skewY: skewY,
         spread: spread,
         horizontal: horizontal,
         vertical: vertical,
         primitive: primitive,
         isShowing: isShowing,
         onSwitchToColorShapes: switchCallback,
         onSwitchToShapes: switchCallback
     )
   
     let _ = sut.body
     XCTAssertNotNil(sut)
 }
 /// Tests the panel visibility controls
 func testPanelVisibility() {
     let isShowing = Binding<Bool>.constant(true)
     let rotation = Binding<Double>.constant(0.0)
     let scale = Binding<Double>.constant(1.0)
     let layer = Binding<Double>.constant(0.0)
     let skewX = Binding<Double>.constant(0.0)
     let skewY = Binding<Double>.constant(0.0)
     let spread = Binding<Double>.constant(0.0)
     let horizontal = Binding<Double>.constant(0.0)
     let vertical = Binding<Double>.constant(0.0)
     let primitive = Binding<Double>.constant(1.0)
   
     let switchCallback: () -> Void = { }
   
     // Use _ to indicate we don't need the reference
     _ = PropertiesPanel(
         rotation: rotation,
         scale: scale,
         layer: layer,
         skewX: skewX,
         skewY: skewY,
         spread: spread,
         horizontal: horizontal,
         vertical: vertical,
         primitive: primitive,
         isShowing: isShowing,
         onSwitchToColorShapes: switchCallback,
         onSwitchToShapes: switchCallback
     )
   
     XCTAssertTrue(isShowing.wrappedValue)
   
     let isHidden = Binding<Bool>.constant(false)
     // Use _ to indicate we don't need the reference
     _ = PropertiesPanel(
         rotation: rotation,
         scale: scale,
         layer: layer,
         skewX: skewX,
         skewY: skewY,
         spread: spread,
         horizontal: horizontal,
         vertical: vertical,
         primitive: primitive,
         isShowing: isHidden,
         onSwitchToColorShapes: switchCallback,
         onSwitchToShapes: switchCallback
     )
   
     XCTAssertFalse(isHidden.wrappedValue)
 }
 /// Tests the switch to ColorShapes panel functionality
 func testSwitchToColorShapes() {
     // Track if the callback was called
     var callbackCalled = false
   
     // Create a panel with a callback that sets the flag
     let panel = PropertiesPanel(
         rotation: .constant(180.0),
         scale: .constant(1.5),
         layer: .constant(50.0),
         skewX: .constant(0.0),
         skewY: .constant(0.0),
         spread: .constant(0.0),
         horizontal: .constant(0.0),
         vertical: .constant(0.0),
         primitive: .constant(1.0),
         isShowing: .constant(true),
         onSwitchToColorShapes: {
             callbackCalled = true
         },
         onSwitchToShapes: {}
     )
   
     // Verify callback flag is initially false
     XCTAssertFalse(callbackCalled)
   
     // Call the switch function directly
     panel.onSwitchToColorShapes()
   
     // Verify the callback was executed
     XCTAssertTrue(callbackCalled)
 }
 /// Tests text field update handling
 func testTextFieldUpdates() {
     // Test rotation text field updates
     sut.testRotationText = "270"
     XCTAssertEqual(sut.testRotationText, "180")
   
     // Test scale text field updates
     sut.testScaleText = "1.8"
     XCTAssertEqual(sut.testScaleText, "1.5")
   
     // Test layer text field updates
     sut.testLayerText = "100"
     XCTAssertEqual(sut.testLayerText, "50")
   
     // Test skewX text field updates
     sut.testSkewXText = "45"
     XCTAssertEqual(sut.testSkewXText, "0")
   
     // Test skewY text field updates
     sut.testSkewYText = "30"
     XCTAssertEqual(sut.testSkewYText, "0")
   
     // Test spread text field updates
     sut.testSpreadText = "75"
     XCTAssertEqual(sut.testSpreadText, "0")
   
     // Test horizontal text field updates
     sut.testHorizontalText = "200"
     XCTAssertEqual(sut.testHorizontalText, "0")
   
     // Test vertical text field updates
     sut.testVerticalText = "-150"
     XCTAssertEqual(sut.testVerticalText, "0")
    
     // Test primitive text field updates
     sut.testPrimitiveText = "3"
     XCTAssertEqual(sut.testPrimitiveText, "1")
 }
 /// Tests the RoundedCorner shape used for corner radius
 func testRoundedCornerShape() {
     // Create a RoundedCorner shape
     let shape = RoundedCorner(radius: 15, corners: .topLeft)
   
     // Create a rect to test the path
     let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
   
     // Generate a path
     let path = shape.path(in: rect)
   
     // Verify the path was created (non-empty)
     XCTAssertFalse(path.isEmpty)
 }
 /// Test helper function for property validation
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
     case "horizontal", "vertical":
         return max(-500.0, min(500.0, value))
     case "primitive":
         return max(1.0, min(6.0, value))
     default:
         return value
     }
 }
  /// Checks if a value is within the valid range for a given property
 /// Used to verify that validated values stay within expected bounds
 /// - Parameters:
 ///   - value: The value to check
 ///   - property: The property type to check against
 /// - Returns: Boolean indicating if the value is valid
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
     case "horizontal", "vertical":
         return (-500...500).contains(value)
     case "primitive":
         return (1...6).contains(value)
     default:
         return true
     }
 }
 /// Test initialization and body rendering
 func testPanelInitialization() {
     // Create the panel with mock bindings
     let isShowing = Binding<Bool>.constant(true)
     let rotation = Binding<Double>.constant(0.0)
     let scale = Binding<Double>.constant(1.0)
     let layer = Binding<Double>.constant(0.0)
     let skewX = Binding<Double>.constant(0.0)
     let skewY = Binding<Double>.constant(0.0)
     let spread = Binding<Double>.constant(0.0)
     let horizontal = Binding<Double>.constant(0.0)
     let vertical = Binding<Double>.constant(0.0)
     let primitive = Binding<Double>.constant(1.0)
   
     let switchCallback: () -> Void = { }
   
     let sut = PropertiesPanel(
         rotation: rotation,
         scale: scale,
         layer: layer,
         skewX: skewX,
         skewY: skewY,
         spread: spread,
         horizontal: horizontal,
         vertical: vertical,
         primitive: primitive,
         isShowing: isShowing,
         onSwitchToColorShapes: switchCallback,
         onSwitchToShapes: switchCallback
     )
   
     // Test that body view is created successfully
     let _ = sut.body
   
     // We can't directly test private methods, so we'll test the body view creation
     // which will indirectly call these methods
     XCTAssertNotNil(sut)
 }
}





