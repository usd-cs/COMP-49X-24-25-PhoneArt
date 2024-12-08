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
    
    /// Computed vertical offset for the canvas when properties panel is shown
    private var canvasVerticalOffset: CGFloat {
        showProperties ? -UIScreen.main.bounds.height / 6 : 0
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                Canvas { context, size in
                    drawCoordinateAxes(context: context, size: size)
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
                        isShowing: $showProperties
                    )
                    .transition(.move(edge: .bottom))
                }
                .zIndex(3)
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Drawing Methods
    
    /// Draws the coordinate axes on the canvas
    /// - Parameters:
    ///   - context: The graphics context to draw in
    ///   - size: The size of the canvas
    private func drawCoordinateAxes(context: GraphicsContext, size: CGSize) {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: size.height/2))
        path.addLine(to: CGPoint(x: size.width, y: size.height/2))
        path.move(to: CGPoint(x: size.width/2, y: 0))
        path.addLine(to: CGPoint(x: size.width/2, y: size.height))
        context.stroke(path, with: .color(.gray), lineWidth: 1)
    }
    
    /// Draws a red circle on the canvas above the origin point
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
