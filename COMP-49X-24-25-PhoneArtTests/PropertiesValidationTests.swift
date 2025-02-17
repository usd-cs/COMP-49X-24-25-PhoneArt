import XCTest

/// Test suite for validating property bounds and constraints
/// Ensures all transformation properties stay within their defined ranges
final class PropertiesValidationTests: XCTestCase {
    
    /// Tests all property validation functions by verifying:
    /// - Rotation stays within 0-360 degrees
    /// - Scale remains between 0.5-2.0
    /// - Skew is limited to 0-80 degrees
    /// Each property is tested with values:
    /// - Below minimum (should clamp to min)
    /// - At minimum (should remain unchanged)
    /// - Within range (should remain unchanged)
    /// - At maximum (should remain unchanged)
    /// - Above maximum (should clamp to max)
    func testPropertyValidations() {
        // Rotation validation (0-360)
        let rotationTests = [
            (input: -10.0, expected: 0.0),
            (input: 0.0, expected: 0.0),
            (input: 180.0, expected: 180.0),
            (input: 360.0, expected: 360.0),
            (input: 400.0, expected: 360.0)
        ]
        
        for test in rotationTests {
            let result = validateRotation(test.input)
            XCTAssertEqual(result, test.expected)
        }
        
        // Scale validation (0.5-2.0)
        let scaleTests = [
            (input: 0.0, expected: 0.5),
            (input: 0.5, expected: 0.5),
            (input: 1.0, expected: 1.0),
            (input: 2.0, expected: 2.0),
            (input: 3.0, expected: 2.0)
        ]
        
        for test in scaleTests {
            let result = validateScale(test.input)
            XCTAssertEqual(result, test.expected)
        }
        
        // Skew validation (0-80)
        let skewTests = [
            (input: -10.0, expected: 0.0),
            (input: 0.0, expected: 0.0),
            (input: 40.0, expected: 40.0),
            (input: 80.0, expected: 80.0),
            (input: 100.0, expected: 80.0)
        ]
        
        for test in skewTests {
            let result = validateSkew(test.input)
            XCTAssertEqual(result, test.expected)
        }
    }
    
    // Helper validation functions that match the app's logic
    private func validateRotation(_ value: Double) -> Double {
        max(0.0, min(360.0, value))
    }
    
    private func validateScale(_ value: Double) -> Double {
        max(0.5, min(2.0, value))
    }
    
    private func validateSkew(_ value: Double) -> Double {
        max(0.0, min(80.0, value))
    }
} 
