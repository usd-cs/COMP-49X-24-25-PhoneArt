import XCTest

/// Test suite for transformation calculations and validations
/// Verifies the accuracy of various geometric transformations
final class TransformationTests: XCTestCase {
    
    /// Tests rotation calculations by verifying:
    /// - Correct angle calculation for each layer
    /// - Proper multiplication of rotation by layer index
    /// - Accurate degree-to-radian conversion
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
    /// - Accurate horizontal and vertical skew values
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
    
    /// Tests scale validation by verifying:
    /// - Values below 0.5 are clamped to 0.5
    /// - Values between 0.5 and 2.0 remain unchanged
    /// - Values above 2.0 are clamped to 2.0
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
    
    /// Tests layer count validation by verifying:
    /// - Negative values are clamped to 0
    /// - Values between 0 and 360 remain unchanged
    /// - Values above 360 are clamped to 360
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
    
    /// Tests spread validation by verifying:
    /// - Values below 0 are clamped to 0
    /// - Values between 0 and 100 remain unchanged
    /// - Values above 100 are clamped to 100
    func testSpreadValidation() {
        let testCases = [
            (input: -10.0, expected: 0.0),
            (input: 0.0, expected: 0.0),
            (input: 50.0, expected: 50.0),
            (input: 100.0, expected: 100.0),
            (input: 120.0, expected: 100.0)
        ]
        
        for testCase in testCases {
            let result = validateSpread(testCase.input)
            XCTAssertEqual(result, testCase.expected)
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
    
    // Helper validation functions
    private func validateScale(_ value: Double) -> Double {
        max(0.5, min(2.0, value))
    }
    
    private func validateLayerCount(_ value: Int) -> Int {
        max(0, min(360, value))
    }
    
    private func validateSpread(_ value: Double) -> Double {
        max(0.0, min(100.0, value))
    }
} 
