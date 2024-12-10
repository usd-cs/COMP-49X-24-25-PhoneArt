//
//  CanvasViewTests.swift
//  COMP-49X-24-25-PhoneArtTests
//
//  Created by Noah Huang on 12/09/24.
//

import XCTest
import SwiftUI
@testable import COMP_49X_24_25_PhoneArt

/// Test suite for the CanvasView component
final class CanvasViewTests: XCTestCase {
  
   /// System Under Test (SUT)
   var sut: CanvasView!
  
   /// Sets up the test environment before each test method is called
   override func setUp() {
       super.setUp()
       sut = CanvasView()
   }
  
   /// Cleans up the test environment after each test method is called
   override func tearDown() {
       sut = nil
       super.tearDown()
   }
  
   // MARK: - Circle Path Tests
  
   /// Tests the creation of a circular path
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
  
   /// Tests the validation of layer count
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
  
   /// Tests the validation of scale bounds
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
  
   /// Tests the validation of rotation bounds
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
   func createCirclePath(center: CGPoint, radius: Double, scale: Double) -> Path {
       Path(ellipseIn: CGRect(
           x: center.x - radius,
           y: center.y - (radius * 2),
           width: radius * 2 * scale,
           height: radius * 2 * scale
       ))
   }
  
   /// Validates the layer count ensuring it is within the allowed range
   func validateLayerCount(_ count: Int) -> Int {
       max(0, min(360, count))
   }
  
   /// Validates the scale ensuring it is within the allowed range
   func validateScale(_ scale: Double) -> Double {
       max(0.5, min(2.0, scale))
   }
  
   /// Validates the rotation ensuring it is within the allowed range
   func validateRotation(_ rotation: Double) -> Double {
       max(0.0, min(360.0, rotation))
   }
}
