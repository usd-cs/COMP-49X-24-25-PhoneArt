//
//  CanvasViewTests.swift
//  COMP-49X-24-25-PhoneArtTests
//
//  Created by Noah Huang on 12/09/24.
//


import XCTest
import SwiftUI
@testable import COMP_49X_24_25_PhoneArt


final class CanvasViewTests: XCTestCase {
  
   var sut: CanvasView!
  
   override func setUp() {
       super.setUp()
       sut = CanvasView()
   }
  
   override func tearDown() {
       sut = nil
       super.tearDown()
   }
  
   // MARK: - Circle Path Tests
  
   func testCreateCirclePath() {
       // Given
       let center = CGPoint(x: 100, y: 100)
       let radius = 30.0
       let scale = 1.0
      
       // When
       let path = sut.createCirclePath(
           center: center,
           radius: radius,
           scale: scale
       )
      
       // Then
       XCTAssertFalse(path.isEmpty)
       let bounds = path.boundingRect
       XCTAssertEqual(bounds.width, radius * 2 * scale, accuracy: 0.001)
       XCTAssertEqual(bounds.height, radius * 2 * scale, accuracy: 0.001)
   }
  
   // MARK: - Layer Tests
  
   func testLayerCount() {
       // Given
       let testCases = [
           (input: -1, expected: 0),
           (input: 0, expected: 0),
           (input: 1, expected: 1),
           (input: 360, expected: 360),
           (input: 361, expected: 360)
       ]
      
       for testCase in testCases {
           // When
           let result = sut.validateLayerCount(testCase.input)
          
           // Then
           XCTAssertEqual(
               result,
               testCase.expected,
               "For input \(testCase.input), expected \(testCase.expected) but got \(result)"
           )
       }
   }
  
   // MARK: - Scale Tests
  
   func testScaleBounds() {
       // Given
       let testCases = [
           (input: 0.0, expected: 0.5),
           (input: 0.5, expected: 0.5),
           (input: 1.0, expected: 1.0),
           (input: 2.0, expected: 2.0),
           (input: 3.0, expected: 2.0)
       ]
      
       for testCase in testCases {
           // When
           let result = sut.validateScale(testCase.input)
          
           // Then
           XCTAssertEqual(
               result,
               testCase.expected,
               "For input \(testCase.input), expected \(testCase.expected) but got \(result)"
           )
       }
   }
  
   // MARK: - Rotation Tests
  
   func testRotationBounds() {
       // Given
       let testCases = [
           (input: -360.0, expected: 0.0),
           (input: 0.0, expected: 0.0),
           (input: 180.0, expected: 180.0),
           (input: 360.0, expected: 360.0),
           (input: 720.0, expected: 360.0)
       ]
      
       for testCase in testCases {
           // When
           let result = sut.validateRotation(testCase.input)
          
           // Then
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
   func createCirclePath(center: CGPoint, radius: Double, scale: Double) -> Path {
       Path(ellipseIn: CGRect(
           x: center.x - radius,
           y: center.y - (radius * 2),
           width: radius * 2 * scale,
           height: radius * 2 * scale
       ))
   }
  
   func validateLayerCount(_ count: Int) -> Int {
       max(0, min(360, count))
   }
  
   func validateScale(_ scale: Double) -> Double {
       max(0.5, min(2.0, scale))
   }
  
   func validateRotation(_ rotation: Double) -> Double {
       max(0.0, min(360.0, rotation))
   }
}
