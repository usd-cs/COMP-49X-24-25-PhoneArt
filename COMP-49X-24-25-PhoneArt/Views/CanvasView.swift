//
//  CanvasView.swift
//  COMP-49X-24-25-PhoneArt
//
//  Created by Aditya Prakash on 12/06/24.
//

import SwiftUI

/// A view that displays a draggable canvas with coordinate axes and a red circle.
/// The canvas can be moved around the screen and reset to its original position.
/// Features:
/// - Draggable canvas with bounce effects
/// - Coordinate system with X and Y axes
/// - Properties panel for shape manipulation
/// - Reset position functionality
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
    
    /// Properties panel visibility state
    @State private var showProperties = false
    
    /// Shape transformation properties
    @State private var shapeRotation: Double = 0
    @State private var shapeScale: Double = 1.0
    @State private var shapeLayer: Double = 0
    @State private var shapeSkewX: Double = 0
    @State private var shapeSkewY: Double = 0
    @State private var shapeSpread: Double = 0
    
    private func validateLayerCount(_ count: Int) -> Int {
        max(0, min(360, count))
    }
    
    private func validateScale(_ scale: Double) -> Double {
        max(0.5, min(2.0, scale))
    }
    
    private func validateRotation(_ rotation: Double) -> Double {
        max(0.0, min(360.0, rotation))
    }
    
     
    private func validateSkewX(_ skewX: Double) -> Double {
        max(0.0, min(100.0, skewX))
    }
     
    private func validateSkewY(_ skewY: Double) -> Double {
        max(0.0, min(100.0, skewY))
    }
     
    private func validateSpread(_ spread: Double) -> Double {
        max(0.0, min(100.0, spread))
    }
     
    
    /// Computed vertical offset for the canvas when properties panel is shown
    private var canvasVerticalOffset: CGFloat {
        showProperties ? -UIScreen.main.bounds.height / 6 : 0
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                Canvas { context, size in
                    drawRedCircle(context: context, size: size)
                }
                .accessibilityIdentifier("Canvas")
                .frame(width: 800, height: 900)
                .border(Color.black, width: 2)
                .gesture(
                    DragGesture()
                        .onChanged(handleDragChange)
                        .onEnded(handleDragEnd)
                )
                .offset(x: offset.width, y: offset.height + canvasVerticalOffset)
                .animation(.spring(), value: showProperties)
            }
            
            VStack {
                HStack {
                    Spacer()
                    makeResetButton()
                }
                Spacer()
            }
            
            VStack {
                Spacer()
                HStack(spacing: 0) {
                    makePropertiesButton()
                    Spacer()
                    Button(action: {
                        withAnimation(.spring()) {
                            showProperties = false
                        }
                    }) {
                        Rectangle()
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .cornerRadius(8)
                            .overlay(
                                Image(systemName: "xmark")
                                    .font(.system(size: 24))
                                    .foregroundColor(.blue)
                            )
                            .shadow(radius: 2)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            
            if showProperties {
                VStack {
                    Spacer()
                    PropertiesPanel(
                        rotation: $shapeRotation,
                        scale: $shapeScale,
                        layer: $shapeLayer,
                        skewX: $shapeSkewX,
                        skewY: $shapeSkewY,
                        spread: $shapeSpread,
                        isShowing: $showProperties
                    )
                    .transition(.move(edge: .bottom))
                }
                .zIndex(3)
            }
        }
        .ignoresSafeArea()
    }
    
    /// Draws a red circle on the canvas above the origin point
    /// - Parameters:
    ///   - context: The graphics context to draw in
    ///   - size: The size of the canvas
    private func drawRedCircle(context: GraphicsContext, size: CGSize) {
        let circleRadius = 30.0
        let centerX = size.width/2
        let centerY = size.height/2
        let center = CGPoint(x: centerX, y: centerY)
        
        // Draw center point of the canvas
        drawCenterDot(context: context, at: center, color: .black)
        
        let numberOfLayers = max(0, min(360, Int(shapeLayer)))
        if numberOfLayers > 0 {
            drawLayers(
                context: context,
                layers: numberOfLayers,
                center: center,
                radius: circleRadius
            )
        }
    }
    
    /// Draws a small dot to indicate a center point
    /// - Parameters:
    ///   - context: The graphics context to draw in
    ///   - point: The position to draw the dot
    ///   - color: The color of the dot
    private func drawCenterDot(context: GraphicsContext, at point: CGPoint, color: Color) {
        let dotRadius = 2.0
        let dotPath = Path(ellipseIn: CGRect(
            x: point.x - dotRadius,
            y: point.y - dotRadius,
            width: dotRadius * 2,
            height: dotRadius * 2
        ))
        context.fill(dotPath, with: .color(color))
    }
    
    /// Draws multiple layers of shapes with cumulative rotation
    /// - Parameters:
    ///   - context: The graphics context to draw in
    ///   - layers: Number of layers to draw
    ///   - center: Center point for rotation
    ///   - radius: Radius of the circle
    private func drawLayers(
        context: GraphicsContext,
        layers: Int,
        center: CGPoint,
        radius: Double
    ) {
        for layerIndex in 0..<layers {
            drawSingleLayer(
                context: context,
                layerIndex: layerIndex,
                center: center,
                radius: radius
            )
        }
    }
    
    /// Draws a single layer with appropriate rotation and opacity
    /// - Parameters:
    ///   - context: The graphics context to draw in
    ///   - layerIndex: Current layer number (0 is base layer)
    ///   - center: Center point for rotation
    ///   - radius: Radius of the circle
    private func drawSingleLayer(
        context: GraphicsContext,
        layerIndex: Int,
        center: CGPoint,
        radius: Double
    ) {
        var layerContext = context
        
        // Apply rotation based on layer position
        let cumulativeRotation = shapeRotation * Double(layerIndex)
        applyTransformation(
            to: &layerContext,
            center: center,
            rotation: cumulativeRotation
        )
        
        // Calculate compounding scale based on previous layers
        let safeScale = max(0.5, min(2.0, shapeScale))
        let compoundScale = pow(safeScale, Double(layerIndex + 1))
        
        // Draw the shape
        let circlePath = createCirclePath(
            center: center,
            radius: radius,
            scale: compoundScale
        )
        
        // Base layer is solid, others are semi-transparent
        let opacity = layerIndex == 0 ? 1.0 : 0.5
        layerContext.fill(circlePath, with: .color(.red.opacity(opacity)))
        
        // Draw center dot for each layer
        drawCenterDot(context: layerContext, at: center, color: .blue)
    }
    
    /// Applies rotation transformation around a center point
    /// - Parameters:
    ///   - context: Graphics context to transform
    ///   - center: Point to rotate around
    ///   - rotation: Rotation angle in degrees
    private func applyTransformation(
        to context: inout GraphicsContext,
        center: CGPoint,
        rotation: Double
    ) {
        context.translateBy(x: center.x, y: center.y)
        context.rotate(by: .degrees(rotation))
        context.translateBy(x: -center.x, y: -center.y)
    }
    
    /// Creates a circular path with specified parameters
    /// - Parameters:
    ///   - center: Center point of the circle
    ///   - radius: Base radius before scaling
    ///   - scale: Scale factor to apply
    /// - Returns: Path describing the circle
    private func createCirclePath(
        center: CGPoint,
        radius: Double,
        scale: Double
    ) -> Path {
        Path(ellipseIn: CGRect(
            x: center.x - (radius * scale),
            y: center.y - (radius * 2 * scale),
            width: radius * 2 * scale,
            height: radius * 2 * scale
        ))
    }
    
    // MARK: - Gesture Handlers
    
    /// Handles continuous updates during drag gesture
    /// - Parameter value: The current drag gesture value
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
    
    /// Handles the end of drag gesture with bounce effect and bounds checking
    /// - Parameter value: The final drag gesture value
    private func handleDragEnd(value: DragGesture.Value) {
        var finalOffset = CGSize(
            width: value.translation.width + lastOffset.width,
            height: value.translation.height + lastOffset.height
        )
        
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
            
            finalOffset.width = max(min(bouncedOffset.width, 0), maxOffsetX)
            finalOffset.height = max(min(bouncedOffset.height, 0), maxOffsetY)
            offset = finalOffset
        }
        
        lastOffset = offset
    }
    
    /// Resets the canvas position to the center of the screen
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
    
    // MARK: - UI Components
    
    /// Creates the reset position button
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
    
    /// Creates the properties panel toggle button
    private func makePropertiesButton() -> some View {
        Button(action: {
            withAnimation(.spring()) {
                showProperties.toggle()
            }
        }) {
            VStack {
                Rectangle()
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                    )
                    .shadow(radius: 2)
            }
        }
        .accessibilityIdentifier("Properties Button")
    }
}
