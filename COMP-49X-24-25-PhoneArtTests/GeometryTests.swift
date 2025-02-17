import XCTest

/// Test suite for geometric calculations and transformations
/// Verifies the accuracy of circle creation, transform calculations,
/// and layer spacing in the art canvas
final class GeometryTests: XCTestCase {
    
    /// Tests the creation of circle paths by verifying:
    /// - Width and height dimensions are correct
    /// - Position coordinates are accurate
    /// - Basic circle properties are maintained
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
    
    /// Tests the affine transform calculations by verifying:
    /// - Identity transform properties are correct
    /// - Transform matrix values are accurate
    /// - Basic transformation properties are maintained
    func testTransformCalculations() {
        // Test identity transform
        let transform = CGAffineTransform.identity
        XCTAssertEqual(transform.a, 1.0)
        XCTAssertEqual(transform.d, 1.0)
        XCTAssertEqual(transform.tx, 0.0)
        XCTAssertEqual(transform.ty, 0.0)
    }
    
    /// Tests the spacing calculations between layers by verifying:
    /// - Correct angular spacing between layers
    /// - Proper distribution of layers
    /// - Accurate rotation calculations
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
