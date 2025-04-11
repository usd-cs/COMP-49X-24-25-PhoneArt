import XCTest
import SwiftUI
@testable import COMP_49X_24_25_PhoneArt

/// Test suite for verifying the functionality of ShapeUtils
final class ShapeUtilsTests: XCTestCase {

    /// Tests the createPolygonPath function with various parameters
    func testCreatePolygonPath() {
        // Test creating shapes with different centers
        let center1 = CGPoint(x: 100, y: 100)
        let center2 = CGPoint(x: 200, y: 150)
        
        // Test creating shapes with different radii
        let radius1 = 50.0
        let radius2 = 100.0
        
        // Test creating shapes with different side counts
        let sides3 = 3   // Triangle
        let sides4 = 4   // Square
        let sides6 = 6   // Hexagon
        let sides12 = 12 // Dodecagon
        
        // Create different polygons to test combinations
        let triangle = ShapeUtils.createPolygonPath(center: center1, radius: radius1, sides: sides3)
        let square = ShapeUtils.createPolygonPath(center: center1, radius: radius1, sides: sides4)
        let hexagon = ShapeUtils.createPolygonPath(center: center2, radius: radius1, sides: sides6)
        let dodecagon = ShapeUtils.createPolygonPath(center: center2, radius: radius2, sides: sides12)
        
        // Verify none of the paths are empty
        XCTAssertFalse(triangle.isEmpty, "Triangle path should not be empty")
        XCTAssertFalse(square.isEmpty, "Square path should not be empty")
        XCTAssertFalse(hexagon.isEmpty, "Hexagon path should not be empty")
        XCTAssertFalse(dodecagon.isEmpty, "Dodecagon path should not be empty")
        
        // Test boundary condition: 0 or negative sides
        let emptyPath = ShapeUtils.createPolygonPath(center: center1, radius: radius1, sides: 0)
        XCTAssertTrue(emptyPath.isEmpty, "Path with 0 sides should be empty")
        
        let negativeSidesPath = ShapeUtils.createPolygonPath(center: center1, radius: radius1, sides: -1)
        XCTAssertTrue(negativeSidesPath.isEmpty, "Path with negative sides should be empty")
        
        // Test with minimum required sides (3)
        let minSidesPath = ShapeUtils.createPolygonPath(center: center1, radius: radius1, sides: 3)
        XCTAssertFalse(minSidesPath.isEmpty, "Path with 3 sides should not be empty")
        
        // Verify the path's bounds for a simple case
        let bounds = square.boundingRect
        // The square should be approximately centered and have a width and height close to 2*radius
        XCTAssertEqual(bounds.width, CGFloat(radius1 * 2), accuracy: 1.0)
        XCTAssertEqual(bounds.height, CGFloat(radius1 * 2), accuracy: 1.0)
    }
    
    /// Tests the createStarPath function with various parameters
    func testCreateStarPath() {
        // Test creating stars with different centers
        let center1 = CGPoint(x: 100, y: 100)
        let center2 = CGPoint(x: 200, y: 150)
        
        // Test creating stars with different radii
        let innerRadius1 = 25.0
        let outerRadius1 = 50.0
        let innerRadius2 = 40.0
        let outerRadius2 = 100.0
        
        // Test creating stars with different point counts
        let points3 = 3  // 3-pointed star
        let points5 = 5  // 5-pointed star (common)
        let points8 = 8  // 8-pointed star
        
        // Create different stars to test combinations
        let star3 = ShapeUtils.createStarPath(center: center1, innerRadius: innerRadius1, outerRadius: outerRadius1, points: points3)
        let star5 = ShapeUtils.createStarPath(center: center1, innerRadius: innerRadius1, outerRadius: outerRadius1, points: points5)
        let star8 = ShapeUtils.createStarPath(center: center2, innerRadius: innerRadius2, outerRadius: outerRadius2, points: points8)
        
        // Verify none of the paths are empty
        XCTAssertFalse(star3.isEmpty, "3-pointed star path should not be empty")
        XCTAssertFalse(star5.isEmpty, "5-pointed star path should not be empty")
        XCTAssertFalse(star8.isEmpty, "8-pointed star path should not be empty")
        
        // Test boundary condition: 0 or negative points
        let emptyPath = ShapeUtils.createStarPath(center: center1, innerRadius: innerRadius1, outerRadius: outerRadius1, points: 0)
        XCTAssertTrue(emptyPath.isEmpty, "Star path with 0 points should be empty")
        
        let negativePath = ShapeUtils.createStarPath(center: center1, innerRadius: innerRadius1, outerRadius: outerRadius1, points: -1)
        XCTAssertTrue(negativePath.isEmpty, "Star path with negative points should be empty")
        
        // Test with minimum required points (2)
        let minPointsPath = ShapeUtils.createStarPath(center: center1, innerRadius: innerRadius1, outerRadius: outerRadius1, points: 2)
        XCTAssertFalse(minPointsPath.isEmpty, "Star path with 2 points should not be empty")
        
        // Test with inner radius greater than outer radius (unusual case)
        let reversedRadii = ShapeUtils.createStarPath(center: center1, innerRadius: outerRadius1, outerRadius: innerRadius1, points: points5)
        XCTAssertFalse(reversedRadii.isEmpty, "Star path with reversed radii should not be empty")
        
        // Verify the path's bounds for a simple case
        let bounds = star5.boundingRect
        // Stars don't have a perfect circular bounding box due to their points
        // The actual measurements can vary based on point placement angles
        XCTAssertGreaterThan(bounds.width, CGFloat(outerRadius1))
        XCTAssertGreaterThan(bounds.height, CGFloat(outerRadius1))
        // The maximum size shouldn't exceed 2*outerRadius by much
        XCTAssertLessThanOrEqual(bounds.width, CGFloat(outerRadius1 * 2.1))
        XCTAssertLessThanOrEqual(bounds.height, CGFloat(outerRadius1 * 2.1))
    }
    
    /// Tests the createArrowPath function with various parameters
    func testCreateArrowPath() {
        // Test creating arrows with different centers
        let center1 = CGPoint(x: 100, y: 100)
        let center2 = CGPoint(x: 200, y: 150)
        
        // Test creating arrows with different sizes
        let size1 = 50.0
        let size2 = 100.0
        let smallSize = 10.0
        let largeSize = 200.0
        
        // Create different arrows to test combinations
        let arrow1 = ShapeUtils.createArrowPath(center: center1, size: size1)
        let arrow2 = ShapeUtils.createArrowPath(center: center2, size: size2)
        let smallArrow = ShapeUtils.createArrowPath(center: center1, size: smallSize)
        let largeArrow = ShapeUtils.createArrowPath(center: center2, size: largeSize)
        
        // Verify none of the paths are empty
        XCTAssertFalse(arrow1.isEmpty, "Arrow path with size \(size1) should not be empty")
        XCTAssertFalse(arrow2.isEmpty, "Arrow path with size \(size2) should not be empty")
        XCTAssertFalse(smallArrow.isEmpty, "Small arrow path should not be empty")
        XCTAssertFalse(largeArrow.isEmpty, "Large arrow path should not be empty")
        
        // Test with zero size (edge case)
        let zeroSizeArrow = ShapeUtils.createArrowPath(center: center1, size: 0)
        XCTAssertFalse(zeroSizeArrow.isEmpty, "Arrow path with zero size should not be empty, just very small")
        
        // Test with negative size (unusual case)
        let negativeSizeArrow = ShapeUtils.createArrowPath(center: center1, size: -10)
        XCTAssertFalse(negativeSizeArrow.isEmpty, "Arrow path with negative size should not be empty")
        
        // Verify the path's bounds for a simple case
        let bounds = arrow1.boundingRect
        // The arrow's height should be approximately equal to 2*size
        XCTAssertEqual(bounds.height, CGFloat(size1 * 2), accuracy: 1.0)
        // The arrow's width should be approximately equal to size*1.5
        XCTAssertEqual(bounds.width, CGFloat(size1 * 1.5), accuracy: 1.0)
    }
    
    /// Tests all shape functions with edge cases and combinations
    func testShapeFunctionsWithEdgeCases() {
        // Test with extreme values for centers
        let extremeCenter = CGPoint(x: CGFloat.greatestFiniteMagnitude / 2, y: CGFloat.greatestFiniteMagnitude / 2)
        let originCenter = CGPoint.zero
        
        // Create shapes with extreme centers
        let extremePolygon = ShapeUtils.createPolygonPath(center: extremeCenter, radius: 50, sides: 6)
        let originPolygon = ShapeUtils.createPolygonPath(center: originCenter, radius: 50, sides: 6)
        
        // These should still generate valid paths
        XCTAssertFalse(extremePolygon.isEmpty, "Polygon with extreme center should not be empty")
        XCTAssertFalse(originPolygon.isEmpty, "Polygon with origin center should not be empty")
        
        // Test with extreme values for radius
        let tinyRadius = 0.001
        let hugeRadius = Double.greatestFiniteMagnitude / 1000 // Not too huge to cause overflows
        
        // Create shapes with extreme radii
        let tinyPolygon = ShapeUtils.createPolygonPath(center: CGPoint(x: 100, y: 100), radius: tinyRadius, sides: 6)
        // Huge radius test might cause numerical issues, so only test if expected to work
        if hugeRadius.isFinite {
            let hugePolygon = ShapeUtils.createPolygonPath(center: CGPoint(x: 100, y: 100), radius: hugeRadius, sides: 6)
            XCTAssertFalse(hugePolygon.isEmpty, "Polygon with huge radius should not be empty")
        }
        
        XCTAssertFalse(tinyPolygon.isEmpty, "Polygon with tiny radius should not be empty")
        
        // Test with large number of sides
        let manyPolygon = ShapeUtils.createPolygonPath(center: CGPoint(x: 100, y: 100), radius: 50, sides: 1000)
        XCTAssertFalse(manyPolygon.isEmpty, "Polygon with many sides should not be empty")
        
        // Test with large number of points for a star
        let manyStar = ShapeUtils.createStarPath(center: CGPoint(x: 100, y: 100), innerRadius: 25, outerRadius: 50, points: 100)
        XCTAssertFalse(manyStar.isEmpty, "Star with many points should not be empty")
    }
} 