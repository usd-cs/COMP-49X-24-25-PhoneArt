import XCTest

final class TransformationTests: XCTestCase {
    
    // Test rotation calculations
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
    
    // Test skew transformations
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
    
    // Test scale validation
    func testScaleValidation() {
        let testCases = [
            (input: 0.3, expected: 0.5),
            (input: 0.5, expected: 0.5),
            (input: 1.0, expected: 1.0),
            (input: 2.0, expected: 2.0),
            (input: 2.5, expected: 2.0)
        ]
        
        for testCase in testCases {
            let result = validateScale(testCase.input)
            XCTAssertEqual(result, testCase.expected)
        }
    }
    
    // Test layer count validation
    func testLayerValidation() {
        let testCases = [
            (input: -1, expected: 0),
            (input: 0, expected: 0),
            (input: 180, expected: 180),
            (input: 360, expected: 360),
            (input: 361, expected: 360)
        ]
        
        for testCase in testCases {
            let result = validateLayerCount(testCase.input)
            XCTAssertEqual(result, testCase.expected)
        }
    }
    
    // Test position calculations
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
    
    // Helper validation functions
    private func validateScale(_ value: Double) -> Double {
        max(0.5, min(2.0, value))
    }
    
    private func validateLayerCount(_ value: Int) -> Int {
        max(0, min(360, value))
    }
} 
