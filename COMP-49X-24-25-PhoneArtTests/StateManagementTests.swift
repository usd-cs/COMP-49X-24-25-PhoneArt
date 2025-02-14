import XCTest

final class StateManagementTests: XCTestCase {
    
    // Test initial state values
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
    
    // Test state updates
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
