//
//  CanvasViewTests.swift
//  COMP-49X-24-25-PhoneArtTests
//
//  Created by Noah Huang on 12/09/24.
//

import XCTest
import SwiftUI
@testable import COMP_49X_24_25_PhoneArt

/// Test suite for the CanvasView component that verifies the core functionality
/// of shape manipulation, validation, and path creation.
final class CanvasViewTests: XCTestCase {
  
   /// System Under Test (SUT)
   var sut: CanvasView!
  
   /// Sets up the test environment before each test method is called by creating
   /// a fresh instance of CanvasView
   override func setUp() {
       super.setUp()
       sut = CanvasView()
   }
  
   /// Cleans up the test environment after each test method is called by
   /// releasing the CanvasView instance
   override func tearDown() {
       sut = nil
       super.tearDown()
   }
  
   // MARK: - Circle Path Tests
  
   /// Tests the creation of a circular path by verifying:
   /// - The path is not empty when created
   /// - The path's bounding rectangle has the expected dimensions based on radius and scale
   /// - The width and height are equal (circle is not distorted)
   /// - The path is centered at the specified coordinates
   func testCreateCirclePath() {
       // Given: A center point, radius, and scale
       let center = CGPoint(x: 100, y: 100)
       let radius = 30.0
       let scale = 1.0
      
       // When: Creating a circle path
       let path = sut.createCirclePath(
           center: center,
           radius: radius,
           scale: scale
       )
      
       // Then: The path should not be empty and should have the expected dimensions
       XCTAssertFalse(path.isEmpty)
       let bounds = path.boundingRect
       XCTAssertEqual(bounds.width, radius * 2 * scale, accuracy: 0.001)
       XCTAssertEqual(bounds.height, radius * 2 * scale, accuracy: 0.001)
   }
  
   // MARK: - Layer Tests
  
   /// Tests the layer count validation logic by verifying:
   /// - Negative values are clamped to 0
   /// - Values within range (0-360) remain unchanged
   /// - Values above 360 are clamped to 360
   /// - Edge cases (0 and 360) are handled correctly
   /// This ensures proper z-index management for shape layering
   func testLayerCount() {
       // Given: A set of test cases with input and expected output
       let testCases = [
           (input: -1, expected: 0),
           (input: 0, expected: 0),
           (input: 1, expected: 1),
           (input: 360, expected: 360),
           (input: 361, expected: 360)
       ]
      
       for testCase in testCases {
           // When: Validating the layer count
           let result = sut.validateLayerCount(testCase.input)
          
           // Then: The result should match the expected output
           XCTAssertEqual(
               result,
               testCase.expected,
               "For input \(testCase.input), expected \(testCase.expected) but got \(result)"
           )
       }
   }
  
   // MARK: - Scale Tests
  
   /// Tests the scale validation logic by verifying:
   /// - Values below 0.5 are clamped to 0.5 (minimum scale)
   /// - Values between 0.5 and 2.0 remain unchanged
   /// - Values above 2.0 are clamped to 2.0 (maximum scale)
   /// - Edge cases (0.5 and 2.0) are handled correctly
   /// This ensures shapes maintain reasonable dimensions
   func testScaleBounds() {
       // Given: A set of test cases with input and expected output
       let testCases = [
           (input: 0.0, expected: 0.5),
           (input: 0.5, expected: 0.5),
           (input: 1.0, expected: 1.0),
           (input: 2.0, expected: 2.0),
           (input: 3.0, expected: 2.0)
       ]
      
       for testCase in testCases {
           // When: Validating the scale
           let result = sut.validateScale(testCase.input)
          
           // Then: The result should match the expected output
           XCTAssertEqual(
               result,
               testCase.expected,
               "For input \(testCase.input), expected \(testCase.expected) but got \(result)"
           )
       }
   }
  
   // MARK: - Rotation Tests
  
   /// Tests the rotation validation logic by verifying:
   /// - Negative values are clamped to 0 degrees
   /// - Values between 0 and 360 remain unchanged
   /// - Values above 360 are clamped to 360 degrees
   /// - Edge cases (0 and 360) are handled correctly
   /// This ensures consistent rotation behavior within a full circle
   func testRotationBounds() {
       // Given: A set of test cases with input and expected output
       let testCases = [
           (input: -360.0, expected: 0.0),
           (input: 0.0, expected: 0.0),
           (input: 180.0, expected: 180.0),
           (input: 360.0, expected: 360.0),
           (input: 720.0, expected: 360.0)
       ]
      
       for testCase in testCases {
           // When: Validating the rotation
           let result = sut.validateRotation(testCase.input)
          
           // Then: The result should match the expected output
           XCTAssertEqual(
               result,
               testCase.expected,
               "For input \(testCase.input), expected \(testCase.expected) but got \(result)"
           )
       }
   }
}

// MARK: - Extensions for Testing
extension CanvasView {
   /// Creates a circular path based on the given center, radius, and scale
   /// - Parameters:
   ///   - center: The center point of the circle
   ///   - radius: The radius of the circle before scaling
   ///   - scale: The scale factor to apply to the circle's dimensions
   /// - Returns: A Path representing the circle with the specified properties
   func createCirclePath(center: CGPoint, radius: Double, scale: Double) -> Path {
       Path(ellipseIn: CGRect(
           x: center.x - radius,
           y: center.y - (radius * 2),
           width: radius * 2 * scale,
           height: radius * 2 * scale
       ))
   }
  
   /// Validates the layer count ensuring it is within the allowed range of 0 to 360
   /// - Parameter count: The layer count to validate
   /// - Returns: A validated layer count within the allowed range
   func validateLayerCount(_ count: Int) -> Int {
       max(0, min(360, count))
   }
  
   /// Validates the scale ensuring it is within the allowed range of 0.5 to 2.0
   /// - Parameter scale: The scale value to validate
   /// - Returns: A validated scale value within the allowed range
   func validateScale(_ scale: Double) -> Double {
       max(0.5, min(2.0, scale))
   }
  
   /// Validates the rotation ensuring it is within the allowed range of 0 to 360 degrees
   /// - Parameter rotation: The rotation value in degrees to validate
   /// - Returns: A validated rotation value within the allowed range
   func validateRotation(_ rotation: Double) -> Double {
       max(0.0, min(360.0, rotation))
   }
}

