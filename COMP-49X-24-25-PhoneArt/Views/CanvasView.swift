//
//  CanvasView.swift
//  COMP-49X-24-25-PhoneArt
//
//  Created by Aditya Prakash on 12/06/24.
//

import SwiftUI

/// A view that displays a draggable canvas with coordinate axes and a red circle.
/// The canvas can be moved around the screen and reset to its original position using a button.
/// The canvas includes:
/// - A coordinate system with X and Y axes
/// - A red circle positioned above the origin
/// - Drag gesture support for moving the canvas
/// - A reset button to return to center position
struct CanvasView: View {
    // MARK: - Properties
    
    /// Current offset position of the canvas relative to its initial centered position
    @State private var offset = CGSize(
        width: (UIScreen.main.bounds.width - 800) / 2,
        height: (UIScreen.main.bounds.height - 900) / 2
    )
    
    /// Previous offset position of the canvas, used for calculating the next position during drag gestures
    @State private var lastOffset: CGSize = CGSize(
        width: (UIScreen.main.bounds.width - 800) / 2,
        height: (UIScreen.main.bounds.height - 900) / 2
    )
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Canvas that displays the coordinate axes and red circle
            GeometryReader { geometry in
                Canvas { context, size in
                    drawCoordinateAxes(context: context, size: size)
                    drawRedCircle(context: context, size: size)
                }
                .accessibilityIdentifier("Canvas")
                // Fixed size canvas
                .frame(width: 800, height: 900)
                .border(Color.black, width: 2)
                // Drag gesture support
                .gesture(
                    DragGesture()
                        .onChanged(handleDragChange)
                        .onEnded(handleDragEnd)
                )
                .offset(x: offset.width, y: offset.height)
            }
            
            // Fixed position reset button in top-right corner
            VStack {
                HStack {
                    Spacer()
                    makeResetButton()
                }
                Spacer()
            }
            .zIndex(2)
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Drawing Methods
    
    /// Draws the x and y coordinate axes on the canvas.
    /// The axes intersect at the center of the canvas, creating four quadrants.
    /// - Parameters:
    ///   - context: The graphics context to draw in
    ///   - size: The size of the canvas
    private func drawCoordinateAxes(context: GraphicsContext, size: CGSize) {
        var path = Path()
        // X-axis
        path.move(to: CGPoint(x: 0, y: size.height/2))
        path.addLine(to: CGPoint(x: size.width, y: size.height/2))
        // Y-axis
        path.move(to: CGPoint(x: size.width/2, y: 0))
        path.addLine(to: CGPoint(x: size.width/2, y: size.height))
        context.stroke(path, with: .color(.gray), lineWidth: 1)
    }
    
    /// Draws a red circle on the canvas positioned above the origin point.
    /// The circle has a fixed radius and is centered horizontally above the axes intersection.
    /// - Parameters:
    ///   - context: The graphics context to draw in
    ///   - size: The size of the canvas
    private func drawRedCircle(context: GraphicsContext, size: CGSize) {
        let circleRadius = 30
        context.fill(
            Path(ellipseIn: CGRect(
                x: size.width/2 - CGFloat(circleRadius),
                y: size.height/2 - CGFloat(circleRadius * 2),
                width: CGFloat(circleRadius * 2),
                height: CGFloat(circleRadius * 2))),
            with: .color(.red)
        )
    }
    
    // MARK: - Gesture Handlers
    
    /// Handles continuous updates during drag gesture.
    /// Updates the canvas position with smooth animation as the user drags.
    /// - Parameter value: The current drag gesture value containing translation information
    private func handleDragChange(value: DragGesture.Value) {
        withAnimation(.interactiveSpring(
            response: 0.15,
            dampingFraction: 0.5,
            blendDuration: 0.1
        )) {
            offset.width = value.translation.width + lastOffset.width
            offset.height = value.translation.height + lastOffset.height
        }
    }
    
    /// Handles the end of drag gesture with bounce effect and bounds checking.
    /// Ensures the canvas stays within screen bounds and adds a subtle bounce animation.
    /// - Parameter value: The final drag gesture value containing the final translation
    private func handleDragEnd(value: DragGesture.Value) {
        var finalOffset = CGSize(
            width: value.translation.width + lastOffset.width,
            height: value.translation.height + lastOffset.height
        )
        
        // Calculate maximum allowed offsets based on screen bounds
        let maxOffsetX = UIScreen.main.bounds.width - 800
        let maxOffsetY = UIScreen.main.bounds.height - 900
        
        withAnimation(.spring(
            response: 0.8,
            dampingFraction: 0.5,
            blendDuration: 1.0
        )) {
            let bounceMultiplier = 1.1
            let bouncedOffset = CGSize(
                width: finalOffset.width * bounceMultiplier,
                height: finalOffset.height * bounceMultiplier
            )
            
            // Constrain the offset within screen bounds
            finalOffset.width = max(min(bouncedOffset.width, 0), maxOffsetX)
            finalOffset.height = max(min(bouncedOffset.height, 0), maxOffsetY)
            offset = finalOffset
        }
        
        lastOffset = offset
    }
    
    /// Resets the canvas position to the center of the screen with a spring animation.
    /// This provides a smooth transition back to the initial centered position.
    private func resetPosition() {
        withAnimation(.spring(
            response: 0.8,
            dampingFraction: 0.5,
            blendDuration: 1.0
        )) {
            offset = CGSize(
                width: (UIScreen.main.bounds.width - 800) / 2,
                height: (UIScreen.main.bounds.height - 900) / 2
            )
            lastOffset = offset
        }
    }
    
    /// Creates a blue reset button with a system icon.
    /// The button is positioned in the top-right corner and triggers the reset animation when tapped.
    /// - Returns: A customized button view with a blue background and white icon
    private func makeResetButton() -> some View {
        Button(action: resetPosition) {
            Rectangle()
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    Image(systemName: "arrow.down.forward.and.arrow.up.backward")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                )
        }
        .accessibilityIdentifier("Reset Position")
        .padding(.top, 50)
        .padding(.trailing)
    }
}
