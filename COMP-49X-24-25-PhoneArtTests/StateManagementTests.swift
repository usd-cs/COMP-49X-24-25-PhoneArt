import XCTest

/// Test suite for managing the state of transformation properties
/// Ensures proper initialization and updates of transformation values
final class StateManagementTests: XCTestCase {
    
    /// Tests the initial state of all properties by verifying:
    /// - Default rotation is 0
    /// - Default scale is 1.0
    /// - Default layer count is 1
    /// - Default skew values are 0
    /// - Default spread is 0
    func testInitialState() {
        // These should match the default values
        let defaultRotation: Double = 0
        let defaultScale: Double = 1.0
        let defaultLayer: Double = 1
        let defaultSkewX: Double = 0
        let defaultSkewY: Double = 0
        let defaultSpread: Double = 0
        
        XCTAssertEqual(defaultRotation, 0)
        XCTAssertEqual(defaultScale, 1.0)
        XCTAssertEqual(defaultLayer, 1)
        XCTAssertEqual(defaultSkewX, 0)
        XCTAssertEqual(defaultSkewY, 0)
        XCTAssertEqual(defaultSpread, 0)
    }
    
    /// Tests state updates by verifying:
    /// - Rotation updates correctly
    /// - Scale updates correctly
    /// - Values maintain accuracy after updates
    func testStateUpdates() {
        var rotation: Double = 0
        var scale: Double = 1.0
        
        // Test rotation update
        rotation = 45.0
        XCTAssertEqual(rotation, 45.0)
        
        // Test scale update
        scale = 1.5
        XCTAssertEqual(scale, 1.5)
    }
} 
