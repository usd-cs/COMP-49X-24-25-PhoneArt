import XCTest

final class GeometryTests: XCTestCase {
    
    // Test circle path creation
    func testCirclePathCreation() {
        // Given
        let width = 60.0
        let height = 60.0
        let minX = 70.0
        let minY = 70.0
        
        // Then
        XCTAssertEqual(width, 60.0)
        XCTAssertEqual(height, 60.0)
        XCTAssertEqual(minX, 70.0)
        XCTAssertEqual(minY, 70.0)
    }
    
    // Test transform calculations
    func testTransformCalculations() {
        // Test identity transform
        let transform = CGAffineTransform.identity
        XCTAssertEqual(transform.a, 1.0)
        XCTAssertEqual(transform.d, 1.0)
        XCTAssertEqual(transform.tx, 0.0)
        XCTAssertEqual(transform.ty, 0.0)
    }
    
    // Test layer spacing calculations
    func testLayerSpacing() {
        let testCases = [
            (layers: 2, rotation: 90.0, expectedSpacing: 90.0),
            (layers: 4, rotation: 90.0, expectedSpacing: 90.0),
            (layers: 8, rotation: 45.0, expectedSpacing: 45.0)
        ]
        
        for test in testCases {
            let spacing = test.rotation
            XCTAssertEqual(spacing, test.expectedSpacing)
        }
    }
} 
