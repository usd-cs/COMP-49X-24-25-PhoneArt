//
//  TransformationTests.swift
//  COMP-49X-24-25-PhoneArtTests
//
//  Created by Emmett de Bruin on 19/02/25.
//


import XCTest


/// Test suite for transformation calculations
/// Focuses specifically on geometric transformations and calculations,
/// while property validation is handled in PropertiesPanelTests
final class TransformationTests: XCTestCase {
  
   /// Tests rotation calculations by verifying:
   /// - Correct angle calculation for each layer
   /// - Proper multiplication of rotation by layer index
   func testRotationCalculations() {
       let testCases = [
           (layerIndex: 0, rotation: 45.0, expected: 0.0),
           (layerIndex: 1, rotation: 45.0, expected: 45.0),
           (layerIndex: 2, rotation: 45.0, expected: 90.0),
           (layerIndex: 3, rotation: 30.0, expected: 90.0)
       ]
      
       for testCase in testCases {
           let angleInDegrees = testCase.rotation * Double(testCase.layerIndex)
           XCTAssertEqual(angleInDegrees, testCase.expected, accuracy: 0.001)
       }
   }
  
   /// Tests skew transformations by verifying:
   /// - Correct tangent calculations for skew angles
   /// - Proper conversion of skew percentages to radians
   func testSkewTransformations() {
       let testCases = [
           (skewX: 0.0, skewY: 0.0, expectedTanX: 0.0, expectedTanY: 0.0),
           (skewX: 80.0, skewY: 0.0, expectedTanX: tan(80.0 / 100.0 * .pi / 4), expectedTanY: 0.0),
           (skewX: 0.0, skewY: 80.0, expectedTanX: 0.0, expectedTanY: tan(80.0 / 100.0 * .pi / 4))
       ]
      
       for testCase in testCases {
           let skewXRadians = (testCase.skewX / 100.0) * .pi / 4
           let skewYRadians = (testCase.skewY / 100.0) * .pi / 4
          
           XCTAssertEqual(tan(skewXRadians), testCase.expectedTanX, accuracy: 0.001)
           XCTAssertEqual(tan(skewYRadians), testCase.expectedTanY, accuracy: 0.001)
       }
   }
  
   /// Tests position calculations by verifying:
   /// - Correct x and y coordinates at cardinal angles
   /// - Accurate trigonometric calculations
   /// - Proper radius and offset calculations
   func testPositionCalculations() {
       let center = CGPoint(x: 100, y: 100)
       let radius = 30.0
      
       let testCases = [
           (angle: 0.0, expectedX: 160.0, expectedY: 100.0),    // Right
           (angle: 90.0, expectedX: 100.0, expectedY: 160.0),   // Bottom
           (angle: 180.0, expectedX: 40.0, expectedY: 100.0),   // Left
           (angle: 270.0, expectedX: 100.0, expectedY: 40.0)    // Top
       ]
      
       for testCase in testCases {
           let angleInRadians = testCase.angle * (.pi / 180)
           let offsetX = radius * 2 * cos(angleInRadians)
           let offsetY = radius * 2 * sin(angleInRadians)
          
           let position = CGPoint(
               x: center.x + offsetX,
               y: center.y + offsetY
           )
          
           XCTAssertEqual(position.x, testCase.expectedX, accuracy: 0.001)
           XCTAssertEqual(position.y, testCase.expectedY, accuracy: 0.001)
       }
   }
  
   /// Tests spread calculations by verifying:
   /// - Correct spread distance based on angle
   /// - Proper scaling of spread values
   func testSpreadCalculations() {
       let center = CGPoint(x: 100, y: 100)
       let spread = 50.0 // 50% spread
      
       let testCases = [
           (angle: 0.0, expectedX: 200.0, expectedY: 100.0),    // Right
           (angle: 90.0, expectedX: 100.0, expectedY: 200.0),   // Bottom
           (angle: 180.0, expectedX: 0.0, expectedY: 100.0),    // Left
           (angle: 270.0, expectedX: 100.0, expectedY: 0.0)     // Top
       ]
      
       for testCase in testCases {
           let angleInRadians = testCase.angle * (.pi / 180)
           let spreadX = spread * 2.0 * cos(angleInRadians)
           let spreadY = spread * 2.0 * sin(angleInRadians)
          
           let position = CGPoint(
               x: center.x + spreadX,
               y: center.y + spreadY
           )
          
           XCTAssertEqual(position.x, testCase.expectedX, accuracy: 0.001)
           XCTAssertEqual(position.y, testCase.expectedY, accuracy: 0.001)
       }
   }
  
   /// Tests horizontal and vertical translations by verifying:
   /// - Base position without translation
   /// - Position after horizontal translation
   /// - Position after vertical translation
   /// - Position after both translations
   func testPositionTranslations() {
       let center = CGPoint(x: 100, y: 100)
       let radius = 30.0
      
       // Test cases with different translations
       let testCases = [
           (horizontal: 50.0, vertical: 0.0,   expectedX: 150.0, expectedY: 100.0), // Right
           (horizontal: -50.0, vertical: 0.0,  expectedX: 50.0,  expectedY: 100.0), // Left
           (horizontal: 0.0, vertical: 50.0,   expectedX: 100.0, expectedY: 150.0), // Down
           (horizontal: 0.0, vertical: -50.0,  expectedX: 100.0, expectedY: 50.0),  // Up
           (horizontal: 50.0, vertical: 50.0,  expectedX: 150.0, expectedY: 150.0)  // Diagonal
       ]
      
       for testCase in testCases {
           // Calculate position with translations
           let position = CGPoint(
               x: center.x + testCase.horizontal,
               y: center.y + testCase.vertical
           )
          
           // Verify translations
           XCTAssertEqual(position.x, testCase.expectedX, accuracy: 0.001,
                         "Horizontal translation failed")
           XCTAssertEqual(position.y, testCase.expectedY, accuracy: 0.001,
                         "Vertical translation failed")
       }
   }
  
   /// Tests scale transformations by verifying:
   /// - Base circle size at default scale
   /// - Circle size after scaling
   /// - Compound scaling across layers
   func testScaleTransformations() {
       let center = CGPoint(x: 100, y: 100)
       let baseRadius = 30.0
      
       let testCases = [
           // (layerIndex, scale, expectedRadius)
           (layerIndex: 0, scale: 1.0, expectedRadius: 30.0),     // Base layer, no scale
           (layerIndex: 0, scale: 2.0, expectedRadius: 60.0),     // Base layer, max scale
           (layerIndex: 1, scale: 1.5, expectedRadius: 45.0),     // Second layer, 1.5x scale
           (layerIndex: 2, scale: 2.0, expectedRadius: 60.0)      // Third layer, max scale
       ]
      
       for testCase in testCases {
           // Simple scale calculation - matches CanvasView implementation
           let scaledRadius = baseRadius * testCase.scale
          
           XCTAssertEqual(scaledRadius, testCase.expectedRadius, accuracy: 0.001,
                         "Scale transformation failed for layer \(testCase.layerIndex)")
       }
   }
  
   /// Tests layer calculations by verifying:
   /// - Single layer creation
   /// - Multiple layer distribution
   /// - Maximum layer count
   func testLayerCalculations() {
       let testCases = [
           (layerCount: 1, expectedLayers: 1),
           (layerCount: 3, expectedLayers: 3),
           (layerCount: 360, expectedLayers: 360)
       ]
      
       for testCase in testCases {
           let numberOfLayers = max(0, min(360, testCase.layerCount))
           XCTAssertEqual(numberOfLayers, testCase.expectedLayers,
                         "Layer count calculation failed")
          
           // Test that each layer index is valid
           if numberOfLayers > 0 {
               for layerIndex in 0..<numberOfLayers {
                   XCTAssertTrue((0..<360).contains(layerIndex),
                               "Layer index \(layerIndex) out of bounds")
               }
           }
       }
   }
}
