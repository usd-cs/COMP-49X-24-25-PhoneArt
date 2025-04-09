import SwiftUI
import UIKit // Needed for CGPoint

/// Provides utility functions for creating specific shape paths.
struct ShapeUtils {

    /// Creates a regular polygon path.
    static func createPolygonPath(center: CGPoint, radius: Double, sides: Int) -> Path {
        var path = Path()
        guard sides >= 3 else { return path } // Need at least 3 sides

        let angle = (2.0 * .pi) / Double(sides)

        for i in 0..<sides {
            let currentAngle = angle * Double(i) - (.pi / 2) // Start from top
            let x = center.x + CGFloat(radius * cos(currentAngle))
            let y = center.y + CGFloat(radius * sin(currentAngle))

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        path.closeSubpath()
        return path
    }

    /// Creates a star path.
    static func createStarPath(center: CGPoint, innerRadius: Double, outerRadius: Double, points: Int) -> Path {
        var path = Path()
        guard points >= 2 else { return path } // Need at least 2 points for a star shape

        let totalPoints = points * 2
        let angle = (2.0 * .pi) / Double(totalPoints)

        for i in 0..<totalPoints {
            let radius = i % 2 == 0 ? outerRadius : innerRadius
            let currentAngle = angle * Double(i) - (.pi / 2) // Start from top
            let x = center.x + CGFloat(radius * cos(currentAngle))
            let y = center.y + CGFloat(radius * sin(currentAngle))

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        path.closeSubpath()
        return path
    }

    /// Creates an arrow path.
    static func createArrowPath(center: CGPoint, size: Double) -> Path {
        let width = size * 1.5
        let height = size * 2
        let stemWidth = width * 0.3

        var path = Path()

        // Arrow head (triangle)
        path.move(to: CGPoint(x: center.x, y: center.y - height * 0.5))       // Top center point
        path.addLine(to: CGPoint(x: center.x + width * 0.5, y: center.y))     // Right point at middle height
        path.addLine(to: CGPoint(x: center.x + stemWidth * 0.5, y: center.y)) // Right edge of stem at middle height
        path.addLine(to: CGPoint(x: center.x + stemWidth * 0.5, y: center.y + height * 0.5)) // Bottom right of stem
        path.addLine(to: CGPoint(x: center.x - stemWidth * 0.5, y: center.y + height * 0.5)) // Bottom left of stem
        path.addLine(to: CGPoint(x: center.x - stemWidth * 0.5, y: center.y)) // Left edge of stem at middle height
        path.addLine(to: CGPoint(x: center.x - width * 0.5, y: center.y))     // Left point at middle height

        path.closeSubpath()
        return path
    }
} 