//
//  PropertiesPanel.swift
//  COMP-49X-24-25-PhoneArt
//
//  Created by Zachary Letcher on 12/08/24.
//

import SwiftUI

/// A panel that displays and controls various properties for shapes on the canvas.
/// Features:
/// - Rotation control (0-360 degrees)
/// - Scale control (0.5x-2.0x)
/// - Layer control (0-360)
/// - Animated transitions
/// - Custom UI elements with game-like styling
struct PropertiesPanel: View {
    // MARK: - Properties
    
    /// The rotation angle of the shape in degrees (0-360)
    @Binding var rotation: Double
    
    /// The scale factor of the shape (0.5-2.0)
    @Binding var scale: Double
    
    /// The layer position of the shape (0-360)
    @Binding var layer: Double
    
    /// Controls the visibility of the properties panel
    @Binding var isShowing: Bool
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 20) {
                makePropertiesButton()
                Spacer()
                Image(systemName: "xmark")
                    .font(.system(size: 20))
                    .accessibilityLabel("Close")
                    .accessibilityIdentifier("CloseButton")
                    .onTapGesture {
                        withAnimation(.spring()) {
                            isShowing = false
                        }
                    }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
            .background(Color(UIColor.systemGray5))
            .cornerRadius(8, corners: [.topLeft, .topRight])
            
            ScrollView {
                VStack(spacing: 12) {
                    propertyRow(
                        title: "Rotation",
                        subtitle: "\(Int(rotation))°",
                        icon: "rotate.right"
                    ) {
                        Slider(value: $rotation, in: 0...360)
                            .accessibilityIdentifier("Rotation Slider")
                    }
                    
                    propertyRow(
                        title: "Scale",
                        subtitle: String(format: "%.1fx", scale),
                        icon: "arrow.up.left.and.arrow.down.right"
                    ) {
                        Slider(value: $scale, in: 0.5...2.0)
                            .accessibilityIdentifier("Scale Slider")
                    }
                    
                    propertyRow(
                        title: "Layer",
                        subtitle: "\(Int(layer))",
                        icon: "square.3.stack.3d"
                    ) {
                        Slider(value: $layer, in: 0...360)
                            .accessibilityIdentifier("Layer Slider")
                    }
                    
                    Color.clear.frame(height: 20)
                }
                .padding()
            }
            .background(Color(UIColor.systemBackground))
        }
        .frame(maxWidth: .infinity)
        .frame(height: UIScreen.main.bounds.height / 3)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(15, corners: [.topLeft, .topRight])
        .shadow(radius: 10)
    }
    
    // MARK: - UI Components
    
    /// Creates a button that toggles the properties panel visibility
    private func makePropertiesButton() -> some View {
        Button(action: {
            withAnimation(.spring()) {
                isShowing.toggle()
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
    
    /// Creates a custom property control row with an icon, title, and adjustable value
    /// - Parameters:
    ///   - title: The name of the property
    ///   - subtitle: The current value display string
    ///   - icon: SF Symbol name for the property icon
    ///   - content: The control view (usually a slider) for adjusting the property
    private func propertyRow<Content: View>(
        title: String,
        subtitle: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .frame(width: 40, height: 40)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
                
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            content()
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Corner Radius Helper

/// Adds the ability to apply corner radius to specific corners of a view
extension View {
    /// Applies a corner radius to specific corners of a view
    /// - Parameters:
    ///   - radius: The radius of the rounded corners
    ///   - corners: The corners to apply the radius to
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

/// A custom shape that allows for selective corner rounding
struct RoundedCorner: Shape {
    /// The radius of the rounded corners
    var radius: CGFloat = .infinity
    
    /// The corners to apply the radius to
    var corners: UIRectCorner = .allCorners
    
    /// Creates the path for the rounded rectangle
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview
#Preview {
    PropertiesPanel(
        rotation: .constant(0),
        scale: .constant(1.0),
        layer: .constant(0),
        isShowing: .constant(true)
    )
}